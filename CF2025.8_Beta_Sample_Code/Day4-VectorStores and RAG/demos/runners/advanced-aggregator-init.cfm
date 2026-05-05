<cfscript>
// Two dedicated stores (HR + Product/FAQ), both queried for every question.
// No routingModel, so the default query router sends the query to BOTH retrievers.
// contentAggregator then merges the two result lists into one context block for the LLM.
try {
    chatModel = chatModel({
        provider  : "openai",
        modelName : "gpt-4o-mini",
        apiKey    : application.openaiKey
    });

    // HR store
    hrStore = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_aggregator_hr",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });
    try { hrStore.deleteCollection(); } catch (any c) {}
    hrStore = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_aggregator_hr",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    // Product + FAQ store
    productStore = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_aggregator_product",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });
    try { productStore.deleteCollection(); } catch (any c) {}
    productStore = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_aggregator_product",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    docSvc = documentService();
    docSvc.ingest(
        docSvc.split(
            docSvc.load({ path: expandPath("../Documents/company-handbook.txt") }),
            { chunkSize: 400, chunkOverlap: 80 }
        ),
        hrStore
    );
    docSvc.ingest(
        docSvc.split(
            docSvc.load({ path: expandPath("../Documents/product-docs.txt") }),
            { chunkSize: 400, chunkOverlap: 80 }
        ),
        productStore
    );
    docSvc.ingest(
        docSvc.split(
            docSvc.load({ path: expandPath("../Documents/faq.txt") }),
            { chunkSize: 400, chunkOverlap: 80 }
        ),
        productStore
    );
    docSvc.close();

    perRetrieverTopK = 3;
    minScore         = 0.1;

    session.demos["advanced-aggregator"] = agent({
        chatModel : chatModel,
        retrievalAugmentor : {
            queryRouter : {
                // No routingModel => default router queries BOTH retrievers for every question
                contentRetrievers : [
                    {
                        vectorStore : hrStore,
                        maxResults  : perRetrieverTopK,
                        minScore    : minScore,
                        description : "HR store"
                    },
                    {
                        vectorStore : productStore,
                        maxResults  : perRetrieverTopK,
                        minScore    : minScore,
                        description : "Product + FAQ store"
                    }
                ]
            },
            contentAggregator : {
                // A visible separator demarcates chunks in the merged context so the
                // LLM can tell one retriever's chunk from another.
                separator : chr(10) & chr(10) & "--- source boundary ---" & chr(10) & chr(10),
                maxTokens : 1200
            }
        }
    });

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-aggregator"] = [
        { vectorStore: hrStore,      topK: perRetrieverTopK, minScore: minScore, label: "HR store — top " & perRetrieverTopK },
        { vectorStore: productStore, topK: perRetrieverTopK, minScore: minScore, label: "Product + FAQ store — top " & perRetrieverTopK }
    ];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
