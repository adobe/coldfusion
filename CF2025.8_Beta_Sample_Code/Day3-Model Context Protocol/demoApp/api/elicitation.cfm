<cfsetting requestTimeOut="60" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.username" default="Demo User";
    param name="url.email"    default="demo@example.com";

    serverUrl = application.SERVERS.TS_ELICITATION
    result    = {}
    mcpClient = ""
    elicitationRequests = []

    // Capture URL-scope values into variables scope before the MCPClient closure —
    // CF closures passed to MCPClient callbacks may not have access to request-scoped
    // url/form/cgi variables; a scope error causes MCPClient to send action=cancel.
    capturedUsername = url.username
    capturedEmail    = url.email

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-elicitation-client", version: "1.0.0" },
            capabilities: {
                sampling:    true,
                elicitation: true
            },
            initializationTimeout: 15,
            requestTimeout: 30,
            elicitationConsumer: function(elicitRequest) {
                arrayAppend(elicitationRequests, elicitRequest)
                // Quoted keys required — unquoted CF struct keys are uppercased and
                // fail the server's lowercase field validation (action, content, etc.)
                return {
                    "action":  "accept",
                    "content": {
                        "username":   capturedUsername,
                        "email":      capturedEmail,
                        "password":   "s3cureP@ss",
                        "newsletter": false
                    }
                }
            },
            samplingConsumer: function(samplingRequest) {
                return {
                    "role":       "assistant",
                    "content":    { "type": "text", "text": "Mock LLM response from demo." },
                    "model":      "demo-mock",
                    "stopReason": "endTurn"
                }
            },
            loggingConsumer: function(message) { /* discard */ }
        })

        // Call register_user tool which triggers elicitation from server
        toolResp = mcpClient.callTool({ name: "register_user", arguments: {} })

        mcpClient.close()

        result = {
            success:              true,
            serverUrl:            serverUrl,
            toolResponse:         toolResp,
            elicitationRequests:  elicitationRequests,
            providedUsername:     capturedUsername,
            providedEmail:        capturedEmail
        }
    }
    catch (any e) {
        result = { success: false, error: e.message }
        if (isObject(mcpClient)) mcpClient.close()
    }

    writeOutput(serializeJSON(result))
</cfscript>
