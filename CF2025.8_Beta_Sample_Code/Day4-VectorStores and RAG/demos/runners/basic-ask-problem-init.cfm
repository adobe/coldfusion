<cfscript>
// Same simpleRAG() API, but the vector store only contains irrelevant general trivia.
// The LLM has nothing product-specific to ground its answer in.
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
        collectionName : "demo_ask_noprod",
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
        collectionName : "demo_ask_noprod",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["basic-ask-problem"] = simpleRAG(
        expandPath("../Documents/general-info.txt"),
        chatModel,
        {
            vectorStore  : vs,
            chunkSize    : 500,
            chunkOverlap : 100,
            maxResults   : 5,
            minScore     : 0.1
        }
    );
    session.demos["basic-ask-problem"].ingest();

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
