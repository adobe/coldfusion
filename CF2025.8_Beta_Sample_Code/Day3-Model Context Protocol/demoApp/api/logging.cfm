<cfsetting requestTimeOut="30" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.action" default="callLoggingTool";

    serverUrl = application.SERVERS.TS_LOGGING
    result    = {}
    mcpClient = ""
    capturedLogs = []

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-logging-client", version: "1.0.0" },
            initializationTimeout: 15,
            requestTimeout: 15,
            loggingConsumer: function(message) {
                arrayAppend(capturedLogs, {
                    level: message.level ?: "unknown",
                    data:  message.data  ?: ""
                })
            }
        })

        writeOutput("")  // flush
        isSupported = mcpClient.isLoggingSupported()

        // Call the test_logging tool which triggers server-side log emissions
        toolResp = mcpClient.callTool({ name: "test_logging", arguments: {} })
        sleep(1000)  // allow log messages to arrive

        mcpClient.close()

        result = {
            success:            true,
            serverUrl:          serverUrl,
            isLoggingSupported: isSupported,
            toolResponse:       toolResp,
            capturedLogs:       capturedLogs
        }
    }
    catch (any e) {
        result = { success: false, error: e.message }
        if (isObject(mcpClient)) mcpClient.close()
    }

    writeOutput(serializeJSON(result))
</cfscript>
