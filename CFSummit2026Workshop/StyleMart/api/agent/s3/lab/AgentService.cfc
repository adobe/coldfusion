component {

    STREAMER_CFC = "api.agent.s3.lab.Streamer";

    public struct function getOrCreateAgent(required string sessionId, required string userId) {
        if (!structKeyExists(application, "s3Agents")) application.s3Agents = {};

        if (!structKeyExists(application.s3Agents, arguments.sessionId)) {
            lock name="s3-agent-init-#arguments.sessionId#" type="exclusive" timeout="10" {
                if (!structKeyExists(application.s3Agents, arguments.sessionId)) {
                    var cfg = loadConfig();
                    var model = buildModel(cfg);
                    var memoryConfig = buildMemoryConfig(cfg);

                    /* ===== ATTENDEE TODO ZONE (Wire tools into the agent) ================= */

                    /*
                     TODO-S3-1: Build the TOOLS array from cfg.tools.
                       ai.lab.properties declares tool CFC paths as a comma-separated list.
                       loadConfig() already parses them into cfg.tools as [{cfc:"..."},...].
                       When CF wires the agent it instantiates each CFC and binds its public
                       methods as tools the LLM can call.
                       Hint: var toolsConfig = cfg.tools ?: [];
                    */
                    var toolsConfig = [] /* TODO-S3-1 */;

                    /*
                     TODO-S3-2: Add TOOLS to the agent assembly, then set the system
                       prompt ONCE. CHATMODEL, STREAMINGHANDLER, and CHATMEMORY are
                       unchanged from s2 — only the TOOLS slot is new in s3.
                       Note: systemMessage() appends; calling it per-turn stacks N
                             copies of the prompt — so set it ONCE here.
                       Hint:
                         var sessionAgent = agent( {
                           CHATMODEL:        model,
                           STREAMINGHANDLER: STREAMER_CFC,
                           CHATMEMORY:       memoryConfig,
                           TOOLS:            toolsConfig
                         } );
                         sessionAgent.systemMessage( cfg.systemPrompt, arguments.userId );
                    */
                    var sessionAgent = "" /* TODO-S3-2 */;

                    /* ===== END ATTENDEE TODO ZONE ========================================= */

                    application.s3Agents[arguments.sessionId] = {
                        "cfg":       cfg,
                        "model":     model,
                        "agent":     sessionAgent,
                        "userId":    arguments.userId,
                        "createdAt": now()
                    };
                }
            }
        }
        return application.s3Agents[arguments.sessionId];
    }

    public void function evict(required string sessionId) {
        if (structKeyExists(application, "s3Agents") && structKeyExists(application.s3Agents, arguments.sessionId)) {
            structDelete(application.s3Agents, arguments.sessionId);
        }
    }

    public struct function loadConfig() {
        var here = getCurrentTemplatePath();
        var side = (findNoCase("/lab/", here) || findNoCase("\lab\", here)) ? "lab" : "ref";
        var configDir = createObject("java", "java.io.File").init(
            getDirectoryFromPath(here) & "../config/"
        ).getCanonicalPath() & "/";
        var props = getPropertyFile(configDir & "ai." & side & ".properties");

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

        var toolsList = props["tools"] ?: "";
        cfg.tools = [];
        for (var t in listToArray(toolsList)) {
            arrayAppend(cfg.tools, {cfc: trim(t)});
        }

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

    private array function buildToolsConfig(required struct cfg) {
        var toolsConfig = [];
        for (var t in (arguments.cfg.tools ?: [])) {
            arrayAppend(toolsConfig, t);
        }
        return toolsConfig;
    }
}
