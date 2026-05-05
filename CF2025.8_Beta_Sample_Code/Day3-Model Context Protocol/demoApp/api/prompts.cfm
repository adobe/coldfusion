<cfsetting requestTimeOut="30" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.action"     default="listPrompts";
    param name="url.server"     default="ts";
    param name="url.promptName" default="";
    param name="url.promptArgs" default="{}";

    serverUrl = (url.server == "cf") ? application.SERVERS.CF_PROMPTS : application.SERVERS.TS_PROMPTS
    result    = {}
    mcpClient = ""

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-prompts-client", version: "1.0.0" },
            initializationTimeout: 15,
            requestTimeout: 15
        })

        if (url.action == "listPrompts") {
            promptsResp = mcpClient.listPrompts()
            result = { success: true, serverUrl: serverUrl, prompts: promptsResp.prompts }
        }
        else if (url.action == "getPrompt" && len(url.promptName)) {
            args = isJSON(url.promptArgs) ? deserializeJSON(url.promptArgs) : {}
            promptResp = mcpClient.getPrompt({ name: url.promptName, arguments: args })
            result = { success: true, promptName: url.promptName, prompt: promptResp }
        }
        else {
            result = { success: false, error: "Invalid action or missing promptName" }
        }

        mcpClient.close()
    }
    catch (any e) {
        result = { success: false, error: e.message }
        if (isObject(mcpClient)) mcpClient.close()
    }

    writeOutput(serializeJSON(result))
</cfscript>
