<cfscript>
// Tight content retriever: top-3 chunks that clear the similarity threshold.
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
        collectionName : "demo_retriever_tight",
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
        collectionName : "demo_retriever_tight",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    topK     = 3;
    minScore = 0.3;

    session.demos["advanced-retriever"] = agent({
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
                    description : "Focused company knowledge base"
                }]
            }
        }
    });
    session.demos["advanced-retriever"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-retriever"] = [{
        vectorStore : vs,
        topK        : topK,
        minScore    : minScore,
        label       : "Tuned retriever (topK=" & topK & ", minScore=" & minScore & ")"
    }];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
