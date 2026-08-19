component {

    STREAMER_CFC = "api.agent.s4.ref.Streamer";
    MCP_SERVER_CONFIG_TEMPLATE_FILE = "mcp-servers-template.json";
    MCP_SERVER_CONFIG_FILE = "mcp-servers.json";

    public struct function getOrCreateAgent(required string sessionId, required string userId) {
        if (!structKeyExists(application, "s4Agents")) application.s4Agents = {};

        if (!structKeyExists(application.s4Agents, arguments.sessionId)) {
            lock name="s4-agent-init-#arguments.sessionId#" type="exclusive" timeout="10" {
                if (!structKeyExists(application.s4Agents, arguments.sessionId)) {
                    var cfg = loadConfig();

                    var model = buildModel(cfg);
                    var memoryConfig = buildMemoryConfig(cfg);
                    var mcpClients = [];
                    try { 
                        mcpClients = getOrCreateMcpClients(cfg); 
                        cflog(text="[S4] MCP clients count: #arrayLen(mcpClients)#", type="info", file="mcp-debug");
                        cflog(text="[S4] MCP clients initialized: #serializeJSON(mcpClients)#", type="info", file="mcp-debug");
                    } catch (any e) {
                        cflog(text="[S4] MCP init error: #e.message#", type="error", file="mcp-debug");
                    }
                    var toolsConfig = buildToolsConfig(cfg, mcpClients);

                    cfg.systemPrompt &= fetchMcpPrompt(mcpClients, "logistics_shipment_status");

                    var sessionAgent = agent({
                        CHATMODEL:        model,
                        STREAMINGHANDLER: STREAMER_CFC,
                        CHATMEMORY:       memoryConfig,
                        TOOLS:            toolsConfig
                    });

                    sessionAgent.systemMessage(cfg.systemPrompt, arguments.userId);

                    application.s4Agents[arguments.sessionId] = {
                        "cfg":       cfg,
                        "model":     model,
                        "agent":     sessionAgent,
                        "userId":    arguments.userId,
                        "createdAt": now()
                    };
                }
            }
        }
        return application.s4Agents[arguments.sessionId];
    }

    public void function evict(required string sessionId) {
        if (structKeyExists(application, "s4Agents") && structKeyExists(application.s4Agents, arguments.sessionId)) {
            structDelete(application.s4Agents, arguments.sessionId);
        }
    }

    public struct function loadConfig() {
        // Pick the side-specific properties — ref/AgentService reads
        // ai.ref.properties so cfg.tools points at ref/tools/, and
        // lab/AgentService reads ai.lab.properties so its agent runs
        // lab/tools/. Without this split lab would silently load ref tools.
        var here = getCurrentTemplatePath();
        var side = ( findNoCase("/lab/", here) || findNoCase("\\lab\\", here) ) ? "lab" : "ref";
        var configDir = createObject("java", "java.io.File").init(
            getDirectoryFromPath(here) & "../config/"
        ).getCanonicalPath() & "/";
        var props = getPropertyFile(configDir & "ai." & side & ".properties");

        var cfg = {
            provider:    props["provider"] ?: "ollama",
            baseUrl:     props["baseUrl"] ?: "",
            modelName:   props["modelName"] ?: "llama3.1:8b",
            apiKey:      props["apiKey"] ?: "",
            temperature: val(props["temperature"] ?: 0.5),
            topP:        val(props["topP"] ?: 0.9),
            topK:        val(props["topK"] ?: 40),
            maxTokens:   val(props["maxTokens"] ?: 1200),
            chatMemory: {
                type:            props["chatMemory.type"] ?: "messageWindowChatMemory",
                maxMessages:     val(props["chatMemory.maxMessages"] ?: 20),
                perUser:         (props["chatMemory.perUser"] ?: "true") == "true",
                persistentStore: props["chatMemory.persistentStore"] ?: ""
            },
            mcpConfigFile: props["mcpConfigFile"] ?: "mcp-servers.json",
            weatherMode:   props["weatherMode"] ?: "mock"
        };

        var toolsList = props["tools"] ?: "";
        cfg.tools = [];
        for (var t in listToArray(toolsList)) {
            arrayAppend(cfg.tools, {cfc: trim(t)});
        }

        var promptName = props["systemPromptFile"] ?: "system-prompt.txt";
        cfg.systemPrompt = fileRead(configDir & promptName);

        var extList = props["promptExtensions"] ?: "";
        for (var ext in listToArray(extList)) {
            var extPath = configDir & trim(ext);
            if (fileExists(extPath)) {
                cfg.systemPrompt &= "

" & fileRead(extPath);
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
            TEMPERATURE: arguments.cfg.temperature,
            TOPP:        arguments.cfg.topP,
            TOPK:        arguments.cfg.topK,
            MAXTOKENS:   arguments.cfg.maxTokens
        };
        if (len(trim(arguments.cfg.baseUrl))) modelArgs.BASEURL = arguments.cfg.baseUrl;
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

    private string function fetchMcpPrompt(required array mcpClients, required string promptName) {
        for (var client in arguments.mcpClients) {
            try {
                if (!client.isPromptsSupported()) continue;
                var promptResponse = client.getPrompt({ name: arguments.promptName });
                //cflog(text="[S4] getPrompt '#arguments.promptName#', text: '#promptResponse.messages[1].content.text#'", type="debug", file="prompts-debug");
                cflog(text="[S4] promptResponse: #serializeJSON(promptResponse)#", type="debug", file="prompts-debug");
                if (structKeyExists(promptResponse, "messages") && arrayLen(promptResponse.messages)) {
                    return chr(10) & chr(10) & promptResponse.messages[1].content.text;
                }
            } catch (any e) {
                cflog(text="[S4] fetchMcpPrompt('#arguments.promptName#') failed: #e.message#", type="warning", file="prompts-debug");
            }
        }
        return "";
    }

    public array function getOrCreateMcpClients(required struct cfg) {
        if (structKeyExists(application, "s4McpClients") && isArray(application.s4McpClients) && arrayLen(application.s4McpClients)) {
            return application.s4McpClients;
        }
        lock name="s4-mcp-init" type="exclusive" timeout="10" {
            if (!structKeyExists(application, "s4McpClients") || !isArray(application.s4McpClients) || arrayIsEmpty(application.s4McpClients)) {
                try {
                    var mcpConfigPath = resolveMcpConfig(arguments.cfg._configDir);
                    application.s4McpClients = MCPClient({
                                    configFile: mcpConfigPath, //BulkLoad MCP Servers from json.
                                    initializationTimeout: 40,
                                    requestTimeout: 20
                                }); 
                    sleep(2000);
                    if (!isArray(application.s4McpClients)) application.s4McpClients = [application.s4McpClients];
                    cflog(text="[S4] MCP clients initialized: #arrayLen(application.s4McpClients)#", type="info", file="mcp-debug");
                } catch (any e) {
                    application.s4McpClients = [];
                    cflog(text="[S4] MCP init failed (non-fatal): #e.message#", type="warning", file="mcp-debug");
                }
            }
        }
        return application.s4McpClients;
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
        var javaBin = findNoCase("windows", server.os.name) ? "java.exe" : "java";
        content = replace(content, "{{PORT}}", port, "all");
        content = replace(content, "{{WEBROOT}}", webroot, "all");
        content = replace(content, "{{JAVA_HOME}}", jreDir, "all");
        content = replace(content, "{{JAVA_BIN}}", javaBin, "all");
        fileWrite(outputPath, content);
        return outputPath;
    }
}
