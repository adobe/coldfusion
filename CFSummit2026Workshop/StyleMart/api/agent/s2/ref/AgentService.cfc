component {

    STREAMER_CFC = "api.agent.s2.ref.Streamer";

    public struct function getOrCreateAgent(required string sessionId, required string userId) {
        if (!structKeyExists(application, "s2Agents")) application.s2Agents = {};

        if (!structKeyExists(application.s2Agents, arguments.sessionId)) {
            lock name="s2-agent-init-#arguments.sessionId#" type="exclusive" timeout="5" {
                if (!structKeyExists(application.s2Agents, arguments.sessionId)) {
                    var cfg = loadConfig();
                    var model = buildModel(cfg);
                    var memoryConfig = buildMemoryConfig(cfg);

                    var sessionAgent = agent({
                        CHATMODEL:        model,
                        STREAMINGHANDLER: STREAMER_CFC,
                        CHATMEMORY:       memoryConfig
                    });

                    sessionAgent.systemMessage(cfg.systemPrompt, arguments.userId);

                    application.s2Agents[arguments.sessionId] = {
                        "cfg":       cfg,
                        "model":     model,
                        "agent":     sessionAgent,
                        "userId":    arguments.userId,
                        "createdAt": now()
                    };
                }
            }
        }
        return application.s2Agents[arguments.sessionId];
    }

    public void function evict(required string sessionId) {
        if (structKeyExists(application, "s2Agents") && structKeyExists(application.s2Agents, arguments.sessionId)) {
            structDelete(application.s2Agents, arguments.sessionId);
        }
    }

    public struct function loadConfig() {
        var configDir = createObject("java", "java.io.File").init(
            getDirectoryFromPath(getCurrentTemplatePath()) & "../config/"
        ).getCanonicalPath() & "/";
        var props = getPropertyFile(configDir & "ai.properties");

        var cfg = {
            provider:    props["provider"],
            baseUrl:     props["baseUrl"],
            modelName:   props["modelName"],
            temperature: val(props["temperature"]),
            topP:        val(props["topP"]),
            topK:        val(props["topK"]),
            maxTokens:   val(props["maxTokens"]),
            chatMemory: {
                type:        props["chatMemory.type"],
                maxMessages: val(props["chatMemory.maxMessages"]),
                perUser:     (props["chatMemory.perUser"] ?: "true") == "true"
            }
        };

        var promptName = props["systemPromptFile"];
        cfg.systemPrompt = fileRead(configDir & promptName);

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
        return {
            TYPE:        arguments.cfg.chatMemory.type,
            MAXMESSAGES: arguments.cfg.chatMemory.maxMessages,
            PERUSER:     arguments.cfg.chatMemory.perUser
        };
    }
}
