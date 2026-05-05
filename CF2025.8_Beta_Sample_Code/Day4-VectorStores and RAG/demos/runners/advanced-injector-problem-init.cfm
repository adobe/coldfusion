<cfscript>
// No contentInjector — the built-in prompt is used. Free-form prose, no source citations.
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
        collectionName : "demo_injector_default",
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
        collectionName : "demo_injector_default",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["advanced-injector-problem"] = agent({
        chatModel : chatModel,
        ingestion : {
            source              : expandPath("../Documents/"),
            documentSplitter    : { chunkSize: 300, chunkOverlap: 50 },
            vectorStoreIngestor : { vectorStore: vs }
        },
        retrievalAugmentor : {
            queryRouter : {
                contentRetrievers : [{
                    vectorStore : vs,
                    maxResults  : 5,
                    minScore    : 0.1,
                    description : "Company knowledge base"
                }]
            }
        }
    });
    session.demos["advanced-injector-problem"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-injector-problem"] = [{
        vectorStore : vs,
        topK        : 5,
        minScore    : 0.1,
        label       : "Chunks fed into the built-in default prompt"
    }];

    if (!structKeyExists(session, "prompts")) session.prompts = {};
    session.prompts["advanced-injector-problem"] =
        "Answer the following question to the best of your ability:" & chr(10) & chr(10) &
        "{{userMessage}}" & chr(10) & chr(10) &
        "Base your answer on the following information:" & chr(10) &
        "{{contents}}";

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
