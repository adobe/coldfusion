<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");

    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        rawBody = toString(getHTTPRequestData().content);
        data    = deserializeJSON(rawBody);

        action      = data.action      ?: "chat"; // "chat" or "clear"
        userMessage = data.message     ?: "";
        memoryType  = data.memoryType  ?: "messageWindowChatMemory";
        maxMessages = javacast("int", val(data.maxMessages ?: 10));
        maxTokens   = val(data.maxTokens   ?: 2000);
        perUser     = data.perUser     ?: false;
        userId      = data.userId      ?: "user_1";
        provider    = data.provider    ?: "anthropic";

        // Build AIService key for application scope storage
        svcKey = "demoMemSvc_" & hash(memoryType & maxMessages & maxTokens & perUser & provider);

        // Handle clear action
        if (action == "clear") {
            if (structKeyExists(application, svcKey)) {
                structDelete(application, svcKey);
            }
            writeOutput(serializeJSON({ success: true, cleared: true }));
            return;
        }

        // Get or create AIService
        if (!structKeyExists(application, svcKey)) {
            switch (provider) {
                case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
                case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
                default:          apiKey = application.openaiKey;    modelName = application.openaiModel;
            }

            chatModel = ChatModel({
                PROVIDER:  provider,
                APIKEY:    apiKey,
                MODELNAME: modelName,
                maxTokens: 300
            });

            memConfig = { TYPE: memoryType };
            if (memoryType == "tokenWindowChatMemory") {
                memConfig["MAXTOKENS"] = maxTokens;
            } else {
                memConfig["MAXMESSAGES"] = maxMessages;
            }
            if (perUser) {
                memConfig["PERUSER"] = true;
            }

            aiSvc = agent({ CHATMODEL: chatModel, CHATMEMORY: memConfig });
            application[svcKey] = aiSvc;
        } else {
            aiSvc = application[svcKey];
        }

        // Chat
        t0 = getTickCount();
        if (perUser) {
            response = aiSvc.chat(userMessage, userId);
        } else {
            response = aiSvc.chat(userMessage);
        }
        elapsed = getTickCount() - t0;

        result = {
            success:    true,
            message:    response.message ?: "",
            elapsed:    elapsed,
            memoryType: memoryType,
            perUser:    perUser,
            userId:     (perUser ? userId : ""),
            serviceKey: svcKey
        };

    } catch (any e) {
        //writedump(e)
        result = { success: false, error: e.message ?: e.type ?: "Unknown server error", detail: e.detail ?: "" };
    }

    writeOutput(serializeJSON(result));
</cfscript>
