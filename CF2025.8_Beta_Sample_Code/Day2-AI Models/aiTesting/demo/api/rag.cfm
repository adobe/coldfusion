<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        data     = deserializeJSON(toString(getHTTPRequestData().content));
        action   = data.action   ?: "ask";
        question = data.question ?: "What is ColdFusion and what AI features does it support?";
        provider = data.provider ?: "anthropic";
        mode     = data.mode     ?: "simple";

        docsPath = expandPath("/aiTesting/demo/docs/");

        switch (provider) {
            case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
            case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
            default:          apiKey = application.openaiKey;    modelName = application.openaiModel;
        }

        embedProvider  = application.embedProvider;
        embedModelName = application.embedModelName;
        embedApiKey    = application.embedApiKey;

        cacheKey = "ragBot_" & provider & "_" & mode;

        if (action == "status") {
            docFiles = directoryList(docsPath, false, "name", "*.txt|*.md");
            writeOutput(serializeJSON({
                success:  true,
                docsPath: docsPath,
                docCount: arrayLen(docFiles),
                docFiles: docFiles,
                ingested: structKeyExists(application, cacheKey)
            }));
            return;
        }

        if (action == "ingest") {
            structDelete(application, cacheKey);
            t0 = getTickCount();
            docFiles = directoryList(docsPath, false, "name", "*.txt|*.md");

            chatModel = ChatModel({
                PROVIDER:  provider,
                APIKEY:    apiKey,
                MODELNAME: modelName,
                MAXTOKENS: 500
            });

            if (mode == "simple") {
                ragBot = simpleRAG(docsPath, chatModel, {
                    chunkSize:    500,
                    chunkOverlap: 100,
                    vectorStore: {
                        provider: "INMEMORY",
                        embeddingModel: {
                            provider:  embedProvider,
                            modelName: embedModelName,
                            apiKey:    embedApiKey
                        }
                    }
                });
                ragBot.ingest();
                application[cacheKey] = ragBot;

                // getStatistics() returns chunk/doc counts unique to simpleRAG
                try {
                    stats = ragBot.getStatistics();
                } catch (any e) {
                    stats = {};
                }

                elapsed = getTickCount() - t0;
                writeOutput(serializeJSON({
                    success:    true,
                    action:     "ingest",
                    mode:       "simple",
                    docCount:   arrayLen(docFiles),
                    elapsed:    elapsed,
                    statistics: stats,
                    message:    "Ingested " & arrayLen(docFiles) & " documents via Simple RAG"
                }));

            } else {
                ragAgent = agent({
                    CHATMODEL: chatModel,
                    CHATMEMORY: { MAXMESSAGES: javacast("int", 20) },
                    INGESTION: {
                        source:       docsPath,
                        chunkSize:    500,
                        chunkOverlap: 100,
                        embeddingModel: {
                            provider:  embedProvider,
                            modelName: embedModelName,
                            apiKey:    embedApiKey
                        },
                        vectorStoreIngestor: {
                            vectorStore: { provider: "INMEMORY" }
                        }
                    },
                    retrievalAugmentor: {
                        queryTransformer: { type: "compressing" }
                    }
                });

                // Agent.ingest() returns { documentsLoaded, segmentsCreated, segmentsIngested, segmentsFailed }
                ingestResult = ragAgent.ingest();
                application[cacheKey] = ragAgent;

                elapsed = getTickCount() - t0;
                writeOutput(serializeJSON({
                    success:          true,
                    action:           "ingest",
                    mode:             "advanced",
                    docCount:         arrayLen(docFiles),
                    elapsed:          elapsed,
                    documentsLoaded:  ingestResult.documentsLoaded  ?: 0,
                    segmentsCreated:  ingestResult.segmentsCreated  ?: 0,
                    segmentsIngested: ingestResult.segmentsIngested ?: 0,
                    segmentsFailed:   ingestResult.segmentsFailed   ?: 0,
                    message:          "Ingested " & arrayLen(docFiles) & " documents via Advanced RAG"
                }));
            }
            return;
        }

        // ask / default
        if (!structKeyExists(application, cacheKey)) {
            writeOutput(serializeJSON({
                success: false,
                error:   "Documents not ingested yet. Click 'Ingest Docs' first."
            }));
            return;
        }

        t0        = getTickCount();
        cachedBot = application[cacheKey];

        resp   = (mode == "simple") ? cachedBot.ask(question) : cachedBot.chat(question);
        answer = isSimpleValue(resp) ? resp : (resp.message ?: resp.toString());

        // Extract token metadata (only available from agent() response)
        inputTokens  = 0;
        outputTokens = 0;
        if (!isSimpleValue(resp) && structKeyExists(resp, "metadata")) {
            meta = resp.metadata;
            if (isStruct(meta)) {
                inputTokens  = val(meta.input_token  ?: 0);
                outputTokens = val(meta.output_token ?: 0);
            }
        }

        elapsed = getTickCount() - t0;

        result = {
            success:      true,
            action:       "ask",
            provider:     provider,
            mode:         mode,
            question:     question,
            answer:       isSimpleValue(answer) ? answer : answer.toString(),
            elapsed:      elapsed,
            inputTokens:  inputTokens,
            outputTokens: outputTokens
        };

    } catch (any e) {
        result = { success: false, error: e.message ?: e.type ?: "Unknown server error", detail: e.detail ?: "" };
    }
    writeOutput(serializeJSON(result));
</cfscript>
