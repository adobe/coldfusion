<cfscript>
// agent() exposes every retrieval knob — splitter type, chunk size,
// top-k (maxResults) and similarity threshold (minScore).
// Values are read from URL parameters so the demo UI can retune them live.
try {
    chatModel = chatModel({
        provider  : "openai",
        modelName : "gpt-4o-mini",
        apiKey    : application.openaiKey
    });

    maxResults   = val(url.maxResults   ?: 3);
    minScore     = val(url.minScore     ?: 0.1);
    splitterType =     url.splitterType ?: "sentence";
    chunkSize    = val(url.chunkSize    ?: 400);

    vs = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_precision",
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
        collectionName : "demo_precision",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["advanced-precision"] = agent({
        chatModel : chatModel,
        ingestion : {
            source              : expandPath("../Documents/product-docs.txt"),
            documentSplitter    : {
                splitterType : splitterType,
                chunkSize    : chunkSize,
                chunkOverlap : 80
            },
            vectorStoreIngestor : { vectorStore: vs }
        },
        retrievalAugmentor : {
            queryRouter : {
                contentRetrievers : [{
                    vectorStore : vs,
                    maxResults  : maxResults,
                    minScore    : minScore,
                    description : "Product documentation"
                }]
            }
        }
    });
    session.demos["advanced-precision"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-precision"] = [{
        vectorStore : vs,
        topK        : maxResults,
        minScore    : minScore,
        label       : splitterType & " | chunkSize=" & chunkSize & " | topK=" & maxResults & " | minScore=" & minScore
    }];

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
