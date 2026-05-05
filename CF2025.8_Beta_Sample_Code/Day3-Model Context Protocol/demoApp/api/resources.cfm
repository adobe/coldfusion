<cfsetting requestTimeOut="30" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.action" default="listResources";
    param name="url.uri"    default="";

    serverUrl = application.SERVERS.CF_RESOURCES
    result    = {}
    mcpClient = ""

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-resources-client", version: "1.0.0" },
            initializationTimeout: 15,
            requestTimeout: 15
        })

        if (url.action == "listResources") {
            resResp = mcpClient.listResources()
            result = { success: true, serverUrl: serverUrl, resources: resResp.resources }
        }
        else if (url.action == "readResource" && len(url.uri)) {
            readResp = mcpClient.readResource(url.uri)
            result = { success: true, uri: url.uri, contents: readResp }
        }
        else {
            result = { success: false, error: "Invalid action or missing uri" }
        }

        mcpClient.close()
    }
    catch (any e) {
        result = { success: false, error: e.message }
        if (isObject(mcpClient)) mcpClient.close()
    }
    //cfdump(var=#result#, label="result")
    writeOutput(serializeJSON(result))
</cfscript>
