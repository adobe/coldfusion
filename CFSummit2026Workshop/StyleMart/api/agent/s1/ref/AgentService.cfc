component {

    STREAMER_CFC = "api.agent.s1.ref.Streamer";

    public any function getOrCreateAgent(required string sessionId, boolean streaming = true) {
        if (!structKeyExists(application, "s1Agents")) application.s1Agents = {};

        var cfg = loadConfig();

        // Cache key fingerprints every parameter that affects agent behavior.
        // If ANY of these change in ai.properties, the fingerprint changes and we
        // build a fresh agent (and drop any previously-cached entries for this
        // session so the cache doesn't grow unbounded as attendees tweak config).
        var fingerprint = hash(
            arguments.sessionId
            & "|" & (arguments.streaming ? "stream" : "sync")
            & "|" & cfg.provider
            & "|" & cfg.modelName
            & "|" & cfg.temperature
            & "|" & cfg.topP
            & "|" & cfg.topK
            & "|" & cfg.maxTokens
        );
        var sessionPrefix = arguments.sessionId & "::";
        var cacheKey      = sessionPrefix & fingerprint;

        if (!structKeyExists(application.s1Agents, cacheKey)) {
            // Drop any older entries for this same sessionId — a config change
            // just invalidated them.
            for (var k in structKeyArray(application.s1Agents)) {
                if (left(k, len(sessionPrefix)) == sessionPrefix && k != cacheKey) {
                    structDelete(application.s1Agents, k);
                }
            }

            var agentConfig = {
                CHATMODEL: ChatModel({
                    PROVIDER:    cfg.provider,
                    MODELNAME:   cfg.modelName,
                    APIKEY:      application.OPENAI_API_KEY,
                    TEMPERATURE: cfg.temperature,
                    TOPP:        cfg.topP,
                    TOPK:        cfg.topK,
                    MAXTOKENS:   cfg.maxTokens
                })
            };
            if (arguments.streaming) {
                agentConfig.STREAMINGHANDLER = STREAMER_CFC;
            }
            application.s1Agents[cacheKey] = agent(agentConfig);
        }
        return application.s1Agents[cacheKey];
    }


    public void function evict(required string sessionId) {
        if (!structKeyExists(application, "s1Agents")) return;
        var sessionPrefix = arguments.sessionId & "::";
        for (var k in structKeyArray(application.s1Agents)) {
            if (left(k, len(sessionPrefix)) == sessionPrefix) {
                structDelete(application.s1Agents, k);
            }
        }
    }

    public struct function loadConfig() {
        var configDir = getDirectoryFromPath(getCurrentTemplatePath()) & "../config/";
        var props = getPropertyFile(configDir & "ai.properties");

        var cfg = {
            provider:    props["provider"] ?: "openai",
            baseUrl:     props["baseUrl"] ?: "",
            modelName:   props["modelName"] ?: "gpt-4o-mini",
            temperature: val(props["temperature"] ?: 0.7),
            topP:        val(props["topP"] ?: 0.9),
            topK:        val(props["topK"] ?: 40),
            maxTokens:   val(props["maxTokens"] ?: 800)
        };

        var promptName = props["systemPromptFile"] ?: "system-prompt.txt";
        cfg.systemPrompt = fileRead(configDir & promptName);
        cfg._configDir = configDir;
        return cfg;
    }
}
