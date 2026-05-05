<cfscript>
// Default chunking and retrieval values — the starting point before any tuning.
try {
    chatModel = chatModel({
        provider  : "openai",
        modelName : "gpt-4o-mini",
        apiKey    : application.openaiKey
    });

    vs = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_precision_defaults",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    try { vs.deleteCollection(); } catch (any c) {}

    vs = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_precision_defaults",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["advanced-precision-problem"] = agent({
        chatModel : chatModel,
        ingestion : {
            source              : expandPath("../Documents/product-docs.txt"),
            documentSplitter    : {
                splitterType : "recursive",
                chunkSize    : 800,
                chunkOverlap : 0
            },
            vectorStoreIngestor : { vectorStore: vs }
        },
        retrievalAugmentor : {
            queryRouter : {
                contentRetrievers : [{
                    vectorStore : vs,
                    maxResults  : 1,
                    minScore    : 0.0,
                    description : "Product documentation"
                }]
            }
        }
    });
    session.demos["advanced-precision-problem"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-precision-problem"] = [{
        vectorStore : vs,
        topK        : 1,
        minScore    : 0.0,
        label       : "recursive | chunkSize=800 | topK=1 | minScore=0"
    }];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
