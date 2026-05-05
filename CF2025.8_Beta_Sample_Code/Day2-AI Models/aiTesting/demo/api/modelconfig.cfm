<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");

    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        rawBody = toString(getHTTPRequestData().content);
        data    = deserializeJSON(rawBody);

        provider       = data.provider       ?: "anthropic";
        modelName      = data.model          ?: application.openaiModel;
        temperature    = val(data.temperature    ?: 0.7);
        maxTokens      = val(data.maxTokens      ?: 500);
        topP           = val(data.topP           ?: 1.0);
        responseFormat = data.responseFormat ?: "text";
        prompt         = data.prompt         ?: "Tell me a fun fact about space in 2-3 sentences.";

        switch (provider) {
            case "anthropic":    apiKey = application.anthropicKey;    break;
            case "mistral":      apiKey = application.mistralkey;       break;
            case "azureopenai":  apiKey = application.azureopenaikey;   break;
            default:             apiKey = application.openaiKey;
        }

        config = {
            PROVIDER:       provider,
            APIKEY:         apiKey,
            MODELNAME:      modelName,
            temperature:    temperature,
            maxTokens:      maxTokens,
            responseFormat: responseFormat
        };

        if (provider == "azureopenai") {
            config["ENDPOINT"] = application.azureopenaiEndpoint;
        }

        t0        = getTickCount();
        chatModel = ChatModel(config);
        response  = chatModel.chat(prompt);
        elapsed   = getTickCount() - t0;

        msg = response.message ?: "";

        // Strip markdown code fences for JSON format
        if (responseFormat == "JSON") {
            msg = reReplace(msg, "(?s)^```[a-z]*\s*", "", "ONE");
            msg = reReplace(msg, "(?s)\s*```$",         "", "ONE");
            msg = trim(msg);
        }

        result = {
            success: true,
            message: msg,
            elapsed: elapsed,
            config: {
                provider:       provider,
                model:          modelName,
                temperature:    temperature,
                maxTokens:      maxTokens,
                responseFormat: responseFormat
            }
        };

    } catch (any e) {
        result = { success: false, error: e.message ?: e.type ?: "Unknown server error", detail: e.detail ?: "" };
    }

    writeOutput(serializeJSON(result));
</cfscript>
