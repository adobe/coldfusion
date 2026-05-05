<cfscript>
// inputGuardrails accepts an array of CFC paths. Each CFC runs validate(userMessage)
// before the message reaches the LLM and can block it with a 'fatal' result.
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
        collectionName : "demo_guardrails",
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
        collectionName : "demo_guardrails",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["guardrails-input"] = agent({
        chatModel : chatModel,
        ingestion : {
            source              : expandPath("../Documents/product-docs.txt"),
            documentSplitter    : { chunkSize: 400, chunkOverlap: 80 },
            vectorStoreIngestor : { vectorStore: vs }
        },
        retrievalAugmentor : {
            queryRouter : {
                contentRetrievers : [{
                    vectorStore : vs,
                    maxResults  : 3,
                    minScore    : 0.1,
                    description : "Product docs"
                }]
            }
        },
        inputGuardrails : [
            expandPath("../guardrails/SensitiveDataGuardrail.cfc")
        ]
    });
    session.demos["guardrails-input"].ingest();

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
