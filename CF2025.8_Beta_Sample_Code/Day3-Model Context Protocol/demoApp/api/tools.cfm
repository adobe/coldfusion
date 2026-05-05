<cfsetting requestTimeOut="30" showDebugOutput="false">
<cfcontent type="application/json"><!------>
<cfscript>
    param name="url.action"   default="listTools";
    param name="url.server"   default="ts";
    param name="url.toolName" default="";
    param name="url.toolArgs" default="{}";

    serverUrl = (url.server == "cf") ? application.SERVERS.CF_TOOLS : application.SERVERS.TS_TOOLS
    result = {}
    mcpClient = ""

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-tools-client", version: "1.0.0" },
            initializationTimeout: 15,
            requestTimeout: 15
        })

        if (url.action == "listTools") {
            toolsResp = mcpClient.listTools()
            result = { success: true, serverUrl: serverUrl, tools: toolsResp.tools }
        }
        else if (url.action == "callTool" && len(url.toolName)) {
            args = isJSON(url.toolArgs) ? deserializeJSON(url.toolArgs) : {}
            toolResp = mcpClient.callTool({ name: url.toolName, arguments: args })
            result = { success: true, toolName: url.toolName, response: toolResp }
        }
        else {
            result = { success: false, error: "Invalid action or missing toolName" }
        }

        mcpClient.close()
    }
    catch (any e) {
        result = { success: false, error: e.message }
        if (isObject(mcpClient)) mcpClient.close()
    }
    //cfdump(var=#toolsResp#, label="result")
    writeOutput(serializeJSON(result))
</cfscript>
