<cfscript>
// contentInjector takes full control of the final prompt:
// {{contents}} is the retrieved chunks, {{userMessage}} is the user's question.
// metadataKeys decides which per-chunk metadata (here: file_name) is exposed in {{contents}}.
try {
    chatModel = chatModel({
        provider    : "openai",
        modelName   : "gpt-4o-mini",
        apiKey      : application.openaiKey,
        temperature : 0
    });

    vs = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_injector",
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
        collectionName : "demo_injector",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    session.demos["advanced-injector"] = agent({
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
            },
            contentInjector : {
                promptTemplate :
                    "You are a support assistant. You MUST format every answer using EXACTLY this template and nothing else. Do not add preamble. Do not add closing remarks." & chr(10) & chr(10) &
                    "Template:" & chr(10) &
                    "SUMMARY: <one sentence>" & chr(10) &
                    "DETAILS:" & chr(10) &
                    "- <fact from the context>" & chr(10) &
                    "- <fact from the context>" & chr(10) &
                    "- <fact from the context>" & chr(10) &
                    "SOURCES: <comma separated file_name values from the context>" & chr(10) & chr(10) &
                    "Context chunks (each tagged with file_name):" & chr(10) &
                    "{{contents}}" & chr(10) & chr(10) &
                    "User question: {{userMessage}}" & chr(10) & chr(10) &
                    "Now produce the answer strictly in the template above.",
                metadataKeys : ["file_name"]
            }
        }
    });
    session.demos["advanced-injector"].ingest();

    if (!structKeyExists(session, "retrievers")) session.retrievers = {};
    session.retrievers["advanced-injector"] = [{
        vectorStore : vs,
        topK        : 5,
        minScore    : 0.1,
        label       : "Chunks fed into the custom promptTemplate"
    }];

    // Expose the template so the UI can show which prompt is sent to the LLM
    if (!structKeyExists(session, "prompts")) session.prompts = {};
    session.prompts["advanced-injector"] =
        "You are a support assistant. You MUST format every answer using EXACTLY this template and nothing else. Do not add preamble. Do not add closing remarks." & chr(10) & chr(10) &
        "Template:" & chr(10) &
        "SUMMARY: <one sentence>" & chr(10) &
        "DETAILS:" & chr(10) &
        "- <fact from the context>" & chr(10) &
        "- <fact from the context>" & chr(10) &
        "- <fact from the context>" & chr(10) &
        "SOURCES: <comma separated file_name values from the context>" & chr(10) & chr(10) &
        "Context chunks (each tagged with file_name):" & chr(10) &
        "{{contents}}" & chr(10) & chr(10) &
        "User question: {{userMessage}}" & chr(10) & chr(10) &
        "Now produce the answer strictly in the template above.";

    writeOutput("ready");
} catch (any e) {
    writeOutput("error:" & e.message);
}
</cfscript>
