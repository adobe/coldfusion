component {

    STREAMER_CFC = "api.agent.s2.lab.Streamer";

    public struct function getOrCreateAgent(required string sessionId, required string userId) {
        if (!structKeyExists(application, "s2Agents")) application.s2Agents = {};

        if (!structKeyExists(application.s2Agents, arguments.sessionId)) {
            lock name="s2-agent-init-#arguments.sessionId#" type="exclusive" timeout="5" {
                if (!structKeyExists(application.s2Agents, arguments.sessionId)) {
                    var cfg = loadConfig();

                    /* ===== ATTENDEE TODO ZONE (Build CHATMEMORY + ChatModel + agent) ====== */

                    /*
                     TODO-S2-1: Build the CHATMEMORY config struct so multi-turn coherence works.
                       Read cfg.chatMemory and produce the uppercase-keyed shape CF expects:
                         - TYPE (always)
                         - MAXMESSAGES (when type == messageWindowChatMemory)
                         - MAXTOKENS    (when type == tokenWindowChatMemory; structDelete MAXMESSAGES)
                         - PERUSER (always; defaults true)
                         - PERSISTENTSTORE (only when len(cfg.chatMemory.persistentStore) > 0)
                       Hint:
                         var memoryConfig = {
                           TYPE:        cfg.chatMemory.type,
                           MAXMESSAGES: cfg.chatMemory.maxMessages ?: 20,
                           PERUSER:     cfg.chatMemory.perUser ?: true
                         };
                         if ( cfg.chatMemory.type == "tokenWindowChatMemory" ) {
                           memoryConfig.MAXTOKENS = cfg.chatMemory.maxTokens;
                           structDelete( memoryConfig, "MAXMESSAGES" );
                         }
                         if ( len( cfg.chatMemory.persistentStore ?: "" ) ) {
                           memoryConfig.PERSISTENTSTORE = cfg.chatMemory.persistentStore;
                         }
                    */
                    var memoryConfig = "" /* TODO-S2-1 */;

                    /*
                     TODO-S2-2: Build the ChatModel from cfg (same pattern as s1).
                       Hint:
                         var modelArgs = {
                           PROVIDER: cfg.provider, APIKEY: application.OPENAI_API_KEY,
                           MODELNAME: cfg.modelName, TEMPERATURE: cfg.temperature,
                           TOPP: cfg.topP, TOPK: cfg.topK, MAXTOKENS: cfg.maxTokens
                         };
                         if ( len(trim(cfg.baseUrl)) ) modelArgs.BASEURL = cfg.baseUrl;
                         var model = ChatModel( modelArgs );
                    */
                    var model = "" /* TODO-S2-2 */;

                    /*
                     TODO-S2-3: Wrap with the streaming agent + chat memory, and set the system prompt ONCE.
                       Note: build agent into its own variable first (CFML parser quirk).
                       Note: systemMessage is called ONCE at agent creation — calling it per-turn stacks
                             N copies of the prompt in role-tagged memory and produces hybrid outputs.
                       Hint:
                         var sessionAgent = agent( {
                           CHATMODEL:        model,
                           STREAMINGHANDLER: STREAMER_CFC,
                           CHATMEMORY:       memoryConfig
                         } );
                         sessionAgent.systemMessage( cfg.systemPrompt, arguments.userId );
                    */
                    var sessionAgent = "" /* TODO-S2-3 */;

                    /* ===== END ATTENDEE TODO ZONE ========================================= */

                    application.s2Agents[arguments.sessionId] = {
                        "cfg":       cfg,
                        "model":     model,
                        "memoryCfg": memoryConfig,
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
}
