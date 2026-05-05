<cfscript>
// One mixed store holding HR + product + FAQ. Every query searches everything.
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
        collectionName : "demo_routing_mixed",
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
        collectionName : "demo_routing_mixed",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["advanced-routing-problem"] = agent({
        chatModel : chatModel,
        ingestion : {
            source              : expandPath("../Documents/"),
            documentSplitter    : { chunkSize: 400, chunkOverlap: 80 },
            vectorStoreIngestor : { vectorStore: vs }
        },
        retrievalAugmentor : {
            queryRouter : {
                contentRetrievers : [{
                    vectorStore : vs,
                    maxResults  : 5,
                    minScore    : 0.1,
                    description : "Everything in one store"
                }]
            }
        }
    });
    session.demos["advanced-routing-problem"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-routing-problem"] = [{
        vectorStore : vs,
        topK        : 5,
        minScore    : 0.0,
        label       : "Single mixed store (HR + product + FAQ)"
    }];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
