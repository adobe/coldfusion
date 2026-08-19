component {

    STREAMER_CFC = "api.agent.s6.lab.Streamer";
    MCP_SERVER_CONFIG_TEMPLATE_FILE = "mcp-servers-template.json";
    MCP_SERVER_CONFIG_FILE = "mcp-servers.json";

    public struct function getOrCreateAgent(required string sessionId, required string userId) {
        if (!structKeyExists(application, "s6Agents")) application.s6Agents = {};

        if (!structKeyExists(application.s6Agents, arguments.sessionId)) {
            lock name="s6-agent-init-#arguments.sessionId#" type="exclusive" timeout="10" {
                if (!structKeyExists(application.s6Agents, arguments.sessionId)) {
                    var cfg = loadConfig();
                    var buildFrames = [];

                    var model = buildModel(cfg);
                    var memoryConfig = buildMemoryConfig(cfg);
                    var mcpClients = [];
                    try { mcpClients = getOrCreateMcpClients(cfg, buildFrames); } catch (any e) {
                        cflog(text="[S6] MCP init error (non-fatal): #e.message#", type="warning", file="mcp-debug");
                    }
                    var toolsConfig = buildToolsConfig(cfg, mcpClients);

                    var agentConfig = {
                        CHATMODEL:        model,
                        STREAMINGHANDLER: STREAMER_CFC,
                        CHATMEMORY:       memoryConfig,
                        TOOLS:            toolsConfig
                    };

                    var ragCfg    = cfg.rag ?: {};
                    var ragActive = false;
                    var ragAugmentor = buildRagAugmentor(cfg, model, buildFrames);
                    if (!isNull(ragAugmentor)) {
                        agentConfig.retrievalAugmentor = ragAugmentor;
                        ragActive = true;
                    }

                    attachGuardrails(agentConfig, cfg);

                    var sessionAgent = agent(agentConfig);

                    var basePrompt = replace(cfg.systemPrompt, "{preferences}", "(provided with each message under ""Known preferences"")");
                    sessionAgent.systemMessage(basePrompt, arguments.userId);

                    application.s6Agents[arguments.sessionId] = {
                        "cfg":         cfg,
                        "model":       model,
                        "agent":       sessionAgent,
                        "userId":      arguments.userId,
                        "createdAt":   now(),
                        // Diagnostic frames captured during construction (mcp.error,
                        // rag.not_ready). ChatService replays these on the first turn
                        // since they can't be streamed at build time.
                        "buildFrames": buildFrames,
                        "ragActive":   ragActive,
                        "ragCfg":      ragCfg
                    };
                }
            }
        }
        return application.s6Agents[arguments.sessionId];
    }

    public void function evict(required string sessionId) {
        if (structKeyExists(application, "s6Agents") && structKeyExists(application.s6Agents, arguments.sessionId)) {
            structDelete(application.s6Agents, arguments.sessionId);
        }
    }

    public struct function loadConfig() {
        var here = getCurrentTemplatePath();
        var side = ( findNoCase("/lab/", here) || findNoCase("\\lab\\", here) ) ? "lab" : "ref";
        var configDir = createObject("java", "java.io.File").init(
            getDirectoryFromPath(here) & "../config/"
        ).getCanonicalPath() & "/";

        var raw = fileRead(configDir & "ai." & side & ".json");
        var cfg = deserializeJSON(raw);

        var promptName = listLast(cfg.systemPromptFile ?: "system-prompt.txt", "/");
        cfg.systemPrompt = fileRead(configDir & promptName);

        if (structKeyExists(cfg, "promptExtensions") && isArray(cfg.promptExtensions)) {
            for (var ext in cfg.promptExtensions) {
                var extPath = configDir & ext;
                if (fileExists(extPath)) {
                    cfg.systemPrompt &= "

" & fileRead(extPath);
                }
            }
        }

        cfg._configDir = configDir;
        cfg._side      = side;
        return cfg;
    }

    private any function buildModel(required struct cfg) {
        var modelArgs = {
            PROVIDER:    arguments.cfg.provider,
            MODELNAME:   arguments.cfg.modelName,
            APIKEY:      application.OPENAI_API_KEY,
            TEMPERATURE: arguments.cfg.temperature ?: 0.5,
            TOPP:        arguments.cfg.topP ?: 0.9,
            MAXTOKENS:   arguments.cfg.maxTokens ?: 1200
        };
        if (structKeyExists(arguments.cfg, "topK")) modelArgs.TOPK = arguments.cfg.topK;
        if (len(trim(arguments.cfg.baseUrl ?: ""))) modelArgs.BASEURL = arguments.cfg.baseUrl;
        return ChatModel(modelArgs);
    }

    private struct function buildMemoryConfig(required struct cfg) {
        var memCfg = {
            TYPE:        arguments.cfg.chatMemory.type ?: "messageWindowChatMemory",
            MAXMESSAGES: arguments.cfg.chatMemory.maxMessages ?: 20,
            PERUSER:     arguments.cfg.chatMemory.perUser ?: true
        };
        if (len(arguments.cfg.chatMemory.persistentStore ?: "")) {
            memCfg.PERSISTENTSTORE = arguments.cfg.chatMemory.persistentStore;
        }
        return memCfg;
    }

    private array function buildToolsConfig(required struct cfg, required array mcpClients) {
        var toolsConfig = [];
        if (arrayLen(arguments.mcpClients)) {
            arrayAppend(toolsConfig, {MCPCLIENT: arguments.mcpClients});
        }
        for (var t in (arguments.cfg.tools ?: [])) {
            arrayAppend(toolsConfig, t);
        }
        return toolsConfig;
    }

    private any function buildRagAugmentor(required struct cfg, required any model, array buildFrames = []) {
        var ragCfg = arguments.cfg.rag ?: {};
        if (!(ragCfg.enabled ?: false)) return javacast("null", "");
        var stores = application.ragVectorStoresLab ?: {};
        if (structIsEmpty(stores)) {
            arrayAppend(arguments.buildFrames, {
                "type": "error",
                "payload": {
                    "type":   "rag.not_ready",
                    "title":  "RAG not initialized",
                    "detail": "VectorStores not available — app may still be starting. Try again in 30 seconds.",
                    "rule":   "rag"
                }
            });
            return javacast("null", "");
        }

        var contentRetrievers = [];
        if (structKeyExists(stores, "policy")) {
            arrayAppend(contentRetrievers, {
                vectorStore: stores.policy,
                maxResults:  6,
                minScore:    0.4,
                description: "Store policies: returns, exchanges, refunds, shipping costs, sale item restrictions, gift returns, size guides, care instructions"
            });
        }
        if (structKeyExists(stores, "catalog")) {
            arrayAppend(contentRetrievers, {
                vectorStore: stores.catalog,
                maxResults:  3,
                minScore:    0.6,
                description: "Product catalog with names, descriptions, prices, materials, available sizes and colors"
            });
        }
        if (structKeyExists(stores, "reviews")) {
            arrayAppend(contentRetrievers, {
                vectorStore: stores.reviews,
                maxResults:  3,
                minScore:    0.6,
                description: "Customer product reviews with ratings, review text, and purchase verification"
            });
        }
        if (structKeyExists(stores, "orders")) {
            arrayAppend(contentRetrievers, {
                vectorStore: stores.orders,
                maxResults:  2,
                minScore:    0.5,
                description: "Order history and purchase records for the current user"
            });
        }
        if (!arrayLen(contentRetrievers)) return javacast("null", "");

        return {
            queryRouter: {
                type:              "languageModel",
                contentRetrievers: contentRetrievers,
                routingModel:      arguments.model
            },
            contentInjector: {
                promptTemplate: ragCfg.contentInjectorTemplate ?: "Context: {{contents}}
Question: {{userMessage}}",
                metadataKeys:   ["file_name"]
            }
        };
    }

    private void function attachGuardrails(required struct agentConfig, required struct cfg) {
        if (!structKeyExists(arguments.cfg, "guardrails")) return;
        var side = arguments.cfg._side ?: "lab";
        var base = "/api/agent/s6/" & side & "/";

        // ===== ATTENDEE ZONE (Wire input + output guardrails onto the agent) =====
        // arguments.agentConfig is handed to us from upstream (getOrCreateAgent)
        // already populated with the core agent wiring — model, streamer, memory,
        // tools, and (optionally) the RAG retrievalAugmentor:
        //
        //   arguments.agentConfig = {
        //       CHATMODEL          : chatModel,                  // ChatModel({...}) — provider, modelName, temp, etc.
        //       STREAMINGHANDLER   : "api.agent.s6.lab.Streamer",
        //       CHATMEMORY         : { TYPE, MAXMESSAGES, PERUSER, PERSISTENTSTORE? },
        //       TOOLS              : [ {MCPCLIENT: [...]}, {cfc: "...SearchCatalog"}, ... ],
        //       retrievalAugmentor : { queryRouter, contentInjector }   // only when RAG is enabled
        //   };
        //
        // Our job here is to INJECT two more keys — INPUTGUARDRAILS and OUTPUTGUARDRAILS —
        // so CF runs each validate() in array order BEFORE the LLM call (input) and
        // AFTER the LLM responds (output). End result we want the struct to look like —
        // clean, declarative, ColdFusion-y:
        //
        //   arguments.agentConfig = {
        //       CHATMODEL          : chatModel,
        //       STREAMINGHANDLER   : "api.agent.s6.lab.Streamer",
        //       CHATMEMORY         : { ... },
        //       TOOLS              : [ ... ],
        //       retrievalAugmentor : { ... },
        //
        //       INPUTGUARDRAILS : [
        //           expandPath("./guardrails/input/DiscountFabricationGuard.cfc"),
        //           expandPath("./guardrails/input/PromptInjectionGuard.cfc"),
        //           expandPath("./guardrails/input/PiiIntakeGuard.cfc")
        //       ],
        //
        //       OUTPUTGUARDRAILS : [
        //           expandPath("./guardrails/output/FitGuaranteeGuard.cfc"),
        //           expandPath("./guardrails/output/FakeDiscountGuard.cfc"),
        //           expandPath("./guardrails/output/PiiLeakGuard.cfc"),
        //           expandPath("./guardrails/output/MisleadingScarcityGuard.cfc")
        //       ]
        //   };
        //
        //   // ...downstream, getOrCreateAgent does:
        //   //     var sessionAgent = agent(arguments.agentConfig);
        //
        // We keep the list in ai.lab.json (so attendees can edit JSON, not code) and
        // just translate each MODE-RELATIVE path into an absolute path via expandPath().

        // arguments.cfg.guardrails was loaded by loadConfig() from ai.lab.json — the
        // "guardrails" block in that file is the source of truth:
        //
        //   // ai.lab.json
        //   "guardrails": {
        //       "input":  [ "guardrails/input/DiscountFabricationGuard.cfc",  ... ],
        //       "output": [ "guardrails/output/FitGuaranteeGuard.cfc",        ... ]
        //   }
        var guardrails = arguments.cfg.guardrails;

        // Step 1 — INPUT guardrails: run on the user message before it hits the LLM.
        // guardrails.input comes straight from ai.lab.json -> "guardrails": { "input": [...] }
        //
        // TODO-S6-1a: Loop guardrails.input, prefix each path with `base`, and call
        //             expandPath() to build absolute paths. Assign the resulting
        //             array to arguments.agentConfig.INPUTGUARDRAILS.
        //   Hint:
        //     if (structKeyExists(guardrails, "input") && isArray(guardrails.input)) {
        //         var inputGuardrails = [];
        //         for (var path in guardrails.input) {
        //             arrayAppend(inputGuardrails, expandPath(base & path));
        //         }
        //         arguments.agentConfig.INPUTGUARDRAILS = inputGuardrails;
        //     }
        /* TODO-S6-1a */

        // Step 2 — OUTPUT guardrails: run on the LLM response before it reaches the user.
        // guardrails.output comes straight from ai.lab.json -> "guardrails": { "output": [...] }
        //
        // TODO-S6-1b: Same shape as Step 1, but for guardrails.output -> OUTPUTGUARDRAILS.
        //   Hint:
        //     if (structKeyExists(guardrails, "output") && isArray(guardrails.output)) {
        //         var outputGuardrails = [];
        //         for (var path in guardrails.output) {
        //             arrayAppend(outputGuardrails, expandPath(base & path));
        //         }
        //         arguments.agentConfig.OUTPUTGUARDRAILS = outputGuardrails;
        //     }
        /* TODO-S6-1b */



        // After this method returns, agentConfig now carries INPUTGUARDRAILS and
        // OUTPUTGUARDRAILS as arrays of absolute CFC paths, and the agent({...})
        // call in getOrCreateAgent() will look exactly like the snippet above.
        // ===== END ATTENDEE ZONE =================================================
    }

    public array function getOrCreateMcpClients(required struct cfg, array buildFrames = []) {
        if (structKeyExists(application, "s6McpClients") && isArray(application.s6McpClients) && arrayLen(application.s6McpClients)) {
            return application.s6McpClients;
        }
        lock name="s6-mcp-init" type="exclusive" timeout="10" {
            if (!structKeyExists(application, "s6McpClients") || !isArray(application.s6McpClients) || arrayIsEmpty(application.s6McpClients)) {
                try {
                    var mcpConfigPath = resolveMcpConfig(arguments.cfg._configDir);
                    application.s6McpClients = MCPClient({configFile: mcpConfigPath});
                    sleep(2000);
                    if (!isArray(application.s6McpClients)) application.s6McpClients = [application.s6McpClients];
                    cflog(text="[S6] MCP clients initialized: #arrayLen(application.s6McpClients)#", type="info", file="mcp-debug");
                } catch (any e) {
                    cflog(text="[S6-MCP] init FAILED: #e.message#", type="error", file="mcp-debug");
                    application.s6McpClients = [];
                    arrayAppend(arguments.buildFrames, {
                        "type": "mcp.error",
                        "payload": {
                            "code":   "mcp_init_failed",
                            "title":  "MCP init failed",
                            "detail": e.message,
                            "source": "init"
                        }
                    });
                }
            }
        }
        return application.s6McpClients;
    }

    private string function resolveMcpConfig(required string configDir) {
        var templatePath = arguments.configDir & MCP_SERVER_CONFIG_TEMPLATE_FILE;
        var outputPath = arguments.configDir & MCP_SERVER_CONFIG_FILE;
        var content = fileRead(templatePath);
        var port = CGI.SERVER_PORT ?: "8500";
        var webroot = replace(expandPath("/"), chr(92), "/", "all");
        if (right(webroot, 1) == "/") webroot = left(webroot, len(webroot) - 1);
        // Use the JRE the CF JVM itself is running on. java.home is set by every
        // JVM and avoids fragile assumptions about <cfRoot>/jre layout (which is a
        // stub on dev boxes where CF runs under system Java instead of a bundled JRE).
        var jreDir = replace(createObject("java", "java.lang.System").getProperty("java.home"), chr(92), "/", "all");
        content = replace(content, "{{PORT}}", port, "all");
        content = replace(content, "{{WEBROOT}}", webroot, "all");
        content = replace(content, "{{JAVA_HOME}}", jreDir, "all");
        var javaBin = findNoCase("windows", server.os.name) ? "java.exe" : "java";
        content = replace(content, "{{JAVA_BIN}}", javaBin, "all");
        fileWrite(outputPath, content);
        return outputPath;
    }
}
