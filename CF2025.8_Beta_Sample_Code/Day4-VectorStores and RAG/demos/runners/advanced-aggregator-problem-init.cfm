<cfscript>
// No aggregator, one retriever, one store mixing every topic together.
// Multi-topic questions get top-K chunks that cluster on whichever topic has the stronger
// vector match, so other topics get starved out.
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
        collectionName : "demo_aggregator_single",
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
        collectionName : "demo_aggregator_single",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    topK     = 5;
    minScore = 0.1;

    session.demos["advanced-aggregator-problem"] = agent({
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
                    maxResults  : topK,
                    minScore    : minScore,
                    description : "Company knowledge base"
                }]
            }
        }
    });
    session.demos["advanced-aggregator-problem"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-aggregator-problem"] = [{
        vectorStore : vs,
        topK        : topK,
        minScore    : minScore,
        label       : "Single mixed store — top " & topK & " chunks"
    }];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
