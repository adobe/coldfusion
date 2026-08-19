component {

    STREAMER_CFC = "api.agent.s5.lab.Streamer";
    MCP_SERVER_CONFIG_TEMPLATE_FILE = "mcp-servers-template.json";
    MCP_SERVER_CONFIG_FILE = "mcp-servers.json";

    public struct function getOrCreateAgent(required string sessionId, required string userId) {
        if (!structKeyExists(application, "s5Agents")) application.s5Agents = {};

        if (!structKeyExists(application.s5Agents, arguments.sessionId)) {
            lock name="s5-agent-init-#arguments.sessionId#" type="exclusive" timeout="10" {
                if (!structKeyExists(application.s5Agents, arguments.sessionId)) {
                    var cfg = loadConfig();

                    var model = buildModel(cfg);
                    var memoryConfig = buildMemoryConfig(cfg);
                    var mcpClients = [];
                    try { mcpClients = getOrCreateMcpClients(cfg); } catch (any e) {
                        cflog(text="[S5] MCP init error (non-fatal): #e.message#", type="warning", file="mcp-debug");
                    }
                    var toolsConfig = buildToolsConfig(cfg, mcpClients);

                    var agentConfig = {
                        CHATMODEL:        model,
                        STREAMINGHANDLER: STREAMER_CFC,
                        CHATMEMORY:       memoryConfig,
                        TOOLS:            toolsConfig
                    };

                    var ragAugmentor = buildRagAugmentor(cfg, model);
                    if (!isNull(ragAugmentor)) {
                        agentConfig.retrievalAugmentor = ragAugmentor;
                    }

                    var sessionAgent = agent(agentConfig);

                    sessionAgent.systemMessage(cfg.systemPrompt, arguments.userId);

                    application.s5Agents[arguments.sessionId] = {
                        "cfg":       cfg,
                        "model":     model,
                        "agent":     sessionAgent,
                        "userId":    arguments.userId,
                        "createdAt": now()
                    };
                }
            }
        }
        return application.s5Agents[arguments.sessionId];
    }

    public void function evict(required string sessionId) {
        if (structKeyExists(application, "s5Agents") && structKeyExists(application.s5Agents, arguments.sessionId)) {
            structDelete(application.s5Agents, arguments.sessionId);
        }
    }

    public struct function loadConfig() {
        // Pick the side-specific JSON — ref/AgentService reads ai.lab.json so
        // cfg.tools points at ref/tools/, and lab/AgentService reads
        // ai.lab.json so its agent runs lab/tools/. Without this split lab
        // would silently load ref tools.
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

    // Builds the retrievalAugmentor struct from cfg.rag if RAG is enabled and
    // application.ragVectorStoresLab has been populated by init-rag.cfm. Returns
    // null when RAG is off or vector stores aren't ready yet (callers fall
    // back to a non-RAG agent).
    private any function buildRagAugmentor(required struct cfg, required any model) {
        var ragCfg = arguments.cfg.rag ?: {};
        if (!(ragCfg.enabled ?: false)) return javacast("null", "");
        var stores = application.ragVectorStoresLab ?: {};
        if (structIsEmpty(stores)) return javacast("null", "");

        // ===== ATTENDEE TODO ZONE (Multi-retriever RAG with query router) =====

        // TODO-S5-3: Build the contentRetrievers array — one entry per corpus
        //   present in `stores` (policy, catalog, reviews, orders). Each entry
        //   needs: vectorStore, maxResults, minScore, description.
        //   The DESCRIPTION is what the LanguageModelQueryRouter sees when
        //   deciding whether to query that corpus — make it specific.
        //   Tunings used in the workshop demo:
        //     policy : maxResults=6 minScore=0.4  (longer chunks, recall-friendly)
        //     catalog: maxResults=3 minScore=0.6  (precision over recall)
        //     reviews: maxResults=3 minScore=0.6
        //     orders : maxResults=2 minScore=0.5
        //   Hint: arrayAppend(contentRetrievers, {
        //           vectorStore: stores.policy, maxResults: 6, minScore: 0.4,
        //           description: "Store policies: return policy, exchange policy,
        //             refund timelines, sale item restrictions, size guides,
        //             clothing care instructions, washing guidelines"
        //         });
        var contentRetrievers = [] 
        if (structKeyExists(stores, "policy")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.policy,
    maxResults: 6, minScore: 0.4,
    description: "Store policies: return policy, "
      & "exchange policy, refund timelines, "
      & "sale item restrictions, size guides, "
      & "clothing care instructions, "
      & "washing guidelines"
  });
}
if (structKeyExists(stores, "catalog")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.catalog,
    maxResults: 3, minScore: 0.6,
    description: "Product catalog: "
      & "descriptions, materials, features"
  });
}
if (structKeyExists(stores, "reviews")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.reviews,
    maxResults: 3, minScore: 0.6,
    description: "Customer reviews: "
      & "fit, quality, sentiment"
  });
}
if (structKeyExists(stores, "orders")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.orders,
    maxResults: 2, minScore: 0.5,
    description: "Order history context"
  });
}

        if (!arrayLen(contentRetrievers)) return javacast("null", "");

        // TODO-S5-4: Build the contentInjector — the template that decides how
        //   retrieved chunks get spliced into the user's prompt before the
        //   model sees it. Read ragCfg.contentInjectorTemplate; fall back to
        //   the simple "Context: {{contents}}\nQuestion: {{userMessage}}"
        //   form if absent. Keep metadataKeys=["file_name"] so the citation
        //   chips render.
        //   Hint: var contentInjector = {
        //           promptTemplate: ragCfg.contentInjectorTemplate ?: (...),
        //           metadataKeys:   ["file_name"]
        //         };
        var contentInjector = {
  promptTemplate:
    ragCfg.contentInjectorTemplate
    ?: ("Context: {{contents}}" & chr(10)
       & "Question: {{userMessage}}"),
  metadataKeys: ["file_name"]
};

        // TODO-S5-5: Assemble + return the retrievalAugmentor struct that the
        //   agent({...}) call expects. The queryRouter type is "languageModel"
        //   so the LLM picks WHICH retriever to query for each user turn.
        //   Hint: return {
        //           queryRouter: {
        //             type:              "languageModel",
        //             contentRetrievers: contentRetrievers,
        //             routingModel:      arguments.model
        //           },
        //           contentInjector: contentInjector
        //         };
        return {
  queryRouter: {
    type: "languageModel",
    contentRetrievers: contentRetrievers,
    routingModel: arguments.model
  },
  contentInjector: contentInjector
};

        // ===== END ATTENDEE TODO ZONE =========================================
    }

    public array function getOrCreateMcpClients(required struct cfg) {
        if (structKeyExists(application, "s5McpClients") && isArray(application.s5McpClients) && arrayLen(application.s5McpClients)) {
            return application.s5McpClients;
        }
        lock name="s5-mcp-init" type="exclusive" timeout="10" {
            if (!structKeyExists(application, "s5McpClients") || !isArray(application.s5McpClients) || arrayIsEmpty(application.s5McpClients)) {
                try {
                    var mcpConfigPath = resolveMcpConfig(arguments.cfg._configDir);
                    application.s5McpClients = MCPClient({configFile: mcpConfigPath});
                    sleep(2000);
                    if (!isArray(application.s5McpClients)) application.s5McpClients = [application.s5McpClients];
                    cflog(text="[S5] MCP clients initialized: #arrayLen(application.s5McpClients)#", type="info", file="mcp-debug");
                } catch (any e) {
                    application.s5McpClients = [];
                    cflog(text="[S5] MCP init failed (non-fatal): #e.message#", type="warning", file="mcp-debug");
                }
            }
        }
        return application.s5McpClients;
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
