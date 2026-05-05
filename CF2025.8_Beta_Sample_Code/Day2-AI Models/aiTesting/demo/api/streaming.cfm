<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        data     = deserializeJSON(toString(getHTTPRequestData().content));
        provider = data.provider ?: "anthropic";
        prompt   = data.prompt   ?: "Tell me a fun fact about ColdFusion in 3-4 sentences.";

        switch (provider) {
            case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
            case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
            default:          apiKey = application.openaiKey;    modelName = application.openaiModel; provider = "openai";
        }

        // Write a START marker to the log. DemoStreamHandler writes CHUNK/DONE
        // to the same log. stream_poll.cfm reads entries after this marker.
        // NEVER delete the log file — CF's internal logger loses its handle.
        streamId = createUUID();
        application.streamId    = streamId;
        application.streamStart = getTickCount();
        writeLog(text="START:" & streamId, type="information", file="demo-stream2");

        chatModel = ChatModel({ PROVIDER: provider, APIKEY: apiKey, MODELNAME: modelName });
        aiService = agent({
            CHATMODEL:        chatModel,
            STREAMINGHANDLER: "aiTesting.demo.StreamHandler2"
        });

        response = aiService.chat(prompt);

        writeOutput(serializeJSON({ success: true, provider: provider, model: modelName, streamId: streamId }));

    } catch (any e) {
        writeOutput(serializeJSON({ success: false, error: e.message ?: e.type ?: "Unknown server error", detail: e.detail ?: "" }));
    }
</cfscript>
