<cfscript>
// simpleRAG().chat() keeps the turn history, so follow-up questions stay on topic.
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
        collectionName : "demo_chat",
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
        collectionName : "demo_chat",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["basic-chat"] = simpleRAG(
        expandPath("../Documents/company-handbook.txt"),
        chatModel,
        {
            vectorStore  : vs,
            chunkSize    : 500,
            chunkOverlap : 100,
            maxResults   : 5,
            minScore     : 0.1
        }
    );
    session.demos["basic-chat"].ingest();

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
