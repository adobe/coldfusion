<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        data      = deserializeJSON(toString(getHTTPRequestData().content));
        provider  = data.provider  ?: "anthropic";
        systemMsg = data.systemMsg ?: "You are a helpful assistant.";
        prompt    = data.prompt    ?: "Tell me about yourself.";

        switch (provider) {
            case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
            case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
            default:          apiKey = application.openaiKey;    modelName = application.openaiModel; provider = "openai";
        }

        chatModel = ChatModel({ PROVIDER:provider, APIKEY:apiKey, MODELNAME:modelName });
        aiService = agent({ CHATMODEL: chatModel, CHATMEMORY:{ MAXMESSAGES: javacast("int", 10) } });

        // Set the system message — shapes every response from this agent
        aiService.systemMessage(systemMsg);

        t0       = getTickCount();
        response = aiService.chat(prompt);
        elapsed  = getTickCount() - t0;

        result = {
            success:   true,
            provider:  provider,
            model:     modelName,
            systemMsg: systemMsg,
            prompt:    prompt,
            message:   response.message ?: "",
            elapsed:   elapsed
        };

    } catch (any e) {
        result = { success:false, error:e.message ?: e.type ?: "Unknown server error", detail:e.detail ?: "" };
    }
    writeOutput(serializeJSON(result));
</cfscript>
