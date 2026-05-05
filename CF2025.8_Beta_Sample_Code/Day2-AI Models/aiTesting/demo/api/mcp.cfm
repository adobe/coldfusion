<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        data       = deserializeJSON(toString(getHTTPRequestData().content));
        action     = data.action     ?: "aiChat";
        serverType = data.serverType ?: "custom";
        chatPrompt = data.chatPrompt ?: "Search for ColdFusion software under $500 and tell me what you find.";
        provider   = data.provider   ?: "anthropic";

        switch (provider) {
            case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
            case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
            default:          apiKey = application.openaiKey;    modelName = application.openaiModel;
        }

        baseUrl    = "http://#cgi.SERVER_NAME#:#cgi.SERVER_PORT#";
        scriptDir  = getDirectoryFromPath(cgi.SCRIPT_NAME);
        appDir     = reReplace(scriptDir, "api/$", "");
        customUrl  = baseUrl & appDir & "mcp/server.cfm";

        if (serverType == "wiki") {
            wikiHttpUrl = "http://localhost:3001/mcp";
            mcpKey = "mcpClient_wiki";
            if (!structKeyExists(application, mcpKey)) {
                application[mcpKey] = McpClient({
                    transport:             { type:"HTTP", URL:wikiHttpUrl },
                    clientInfo:            { name:"demo-wiki-client", version:"1.0.0" },
                    initializationTimeout: 30,
                    requestTimeout:        30
                });
            }
        } else {
            mcpKey = "mcpClient_custom";
            application[mcpKey] = McpClient({
                transport:             { type:"HTTP", URL:customUrl },
                clientInfo:            { name:"cf-demo-client", version:"1.0.0" },
                initializationTimeout: 30,
                requestTimeout:        30
            });
        }
        mcpClient = application[mcpKey];

        t0 = getTickCount();

        switch (action) {

            case "aiChat":
                chatModel = ChatModel({ PROVIDER:provider, APIKEY:apiKey, MODELNAME:modelName });
                // MCPCLIENT takes an array of MCP client objects
                aiService = agent({
                    CHATMODEL:  chatModel,
                    TOOLS:      [{ MCPCLIENT: [mcpClient] }],
                    CHATMEMORY: { MAXMESSAGES: javacast("int", 6) }
                });
                resp    = aiService.chat(chatPrompt);
                elapsed = getTickCount() - t0;
                result  = {
                    success:      true,
                    action:       "aiChat",
                    serverType:   serverType,
                    prompt:       chatPrompt,
                    message:      resp.message ?: "",
                    toolRequests: resp.toolExecutionRequests ?: [],
                    elapsed:      elapsed
                };
                break;

            case "listTools":
                toolsRaw  = mcpClient.listTools();
                toolsList = (isStruct(toolsRaw) && structKeyExists(toolsRaw, "tools")) ? toolsRaw.tools : toolsRaw;
                elapsed   = getTickCount() - t0;
                result    = { success:true, action:"listTools", serverType:serverType, tools:toolsList, elapsed:elapsed };
                break;

            case "listPrompts":
                promptsRaw = mcpClient.listPrompts();
                result = { success:true, action:"listPrompts", prompts:(isStruct(promptsRaw) && structKeyExists(promptsRaw,"prompts") ? promptsRaw.prompts : promptsRaw), elapsed:getTickCount()-t0 };
                break;

            case "listResources":
                resourcesRaw = mcpClient.listResources();
                result = { success:true, action:"listResources", resources:(isStruct(resourcesRaw) && structKeyExists(resourcesRaw,"resources") ? resourcesRaw.resources : resourcesRaw), elapsed:getTickCount()-t0 };
                break;

            default:
                result = { success:false, error:"Unknown action: #action#. Use: aiChat|listTools|listPrompts|listResources" };
        }

    } catch (any e) {
        if (structKeyExists(application, "mcpClient_#serverType#")) {
            structDelete(application, "mcpClient_#serverType#");
        }
        result = { success:false, error:e.message ?: e.type ?: "Unknown server error", detail:e.detail ?: "" };
    }
    writeOutput(serializeJSON(result));
</cfscript>
