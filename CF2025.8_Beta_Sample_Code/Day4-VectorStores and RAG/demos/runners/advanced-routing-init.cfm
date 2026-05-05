<cfscript>
// Intelligent routing: two vector stores, each with a description.
// A routingModel (LLM) reads the descriptions and routes each query to the best store.
try {
    chatModel = chatModel({
        provider  : "openai",
        modelName : "gpt-4o-mini",
        apiKey    : application.openaiKey
    });

    // HR knowledge base
    hrStore = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_routing_hr",
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
        collectionName : "demo_routing_hr",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    // Product knowledge base
    productStore = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_routing_product",
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
        collectionName : "demo_routing_product",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    docService = documentService();
    docService.ingest(
        docService.split(
            docService.load({ path: expandPath("../Documents/company-handbook.txt") }),
            { chunkSize: 400, chunkOverlap: 80 }
        ),
        hrStore
    );
    docService.ingest(
        docService.split(
            docService.load({ path: expandPath("../Documents/product-docs.txt") }),
            { chunkSize: 400, chunkOverlap: 80 }
        ),
        productStore
    );
    docService.ingest(
        docService.split(
            docService.load({ path: expandPath("../Documents/faq.txt") }),
            { chunkSize: 400, chunkOverlap: 80 }
        ),
        productStore
    );
    docService.close();

    session.demos["advanced-routing"] = agent({
        chatModel : chatModel,
        retrievalAugmentor : {
            queryRouter : {
                contentRetrievers : [
                    {
                        vectorStore : hrStore,
                        maxResults  : 3,
                        minScore    : 0.1,
                        description : "HR policies, leave, remote work, expenses, code of conduct"
                    },
                    {
                        vectorStore : productStore,
                        maxResults  : 3,
                        minScore    : 0.1,
                        description : "Product features, pricing, integrations, FAQ, billing, support"
                    }
                ],
                routingModel : chatModel
            }
        }
    });

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-routing"] = [
        { vectorStore: hrStore,      topK: 3, minScore: 0.0, label: "HR store" },
        { vectorStore: productStore, topK: 3, minScore: 0.0, label: "Product + FAQ store" }
    ];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
