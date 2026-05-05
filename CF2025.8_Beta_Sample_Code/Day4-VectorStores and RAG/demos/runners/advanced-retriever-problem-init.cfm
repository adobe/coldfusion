<cfscript>
// Loose retrieval: top-10, no minScore — lots of context, some of it weakly related.
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
        collectionName : "demo_retriever_loose",
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
        collectionName : "demo_retriever_loose",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    topK     = 10;
    minScore = 0.0;

    session.demos["advanced-retriever-problem"] = agent({
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
                    description : "Unfiltered company knowledge base"
                }]
            }
        }
    });
    session.demos["advanced-retriever-problem"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-retriever-problem"] = [{
        vectorStore : vs,
        topK        : topK,
        minScore    : minScore,
        label       : "Loose retriever (topK=" & topK & ", minScore=" & minScore & ")"
    }];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
