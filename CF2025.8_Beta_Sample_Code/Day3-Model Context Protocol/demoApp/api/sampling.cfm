<cfsetting requestTimeOut="60" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.text"      default="The Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to Large Language Models. It supports tools, resources, prompts, sampling, and logging over JSON-RPC 2.0.";
    param name="url.maxTokens" default="150";

    serverUrl      = application.SERVERS.TS_SAMPLING
    result         = {}
    mcpClient      = ""
    samplingRequest = {}

    // The samplingConsumer callback — invoked when the server sends a sampling/createMessage
    // request back to the client. In real usage this would call an LLM; here we return a
    // mock summary so the demo works without an API key on the client side.
    summarizedText = "MCP is an open protocol that standardizes how applications provide context to LLMs, enabling better AI responses through flexible, extensible communication using JSON-RPC 2.0."

    function buildSamplingConsumer() {
        return function(req) {
            samplingRequest = req
            return {
                "role":       "assistant",
                "content":    { "type": "text", "text": summarizedText },
                "model":      "cf-mock-summarizer-v1",
                "stopReason": "endTurn"
            }
        }
    }

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-sampling-client", version: "1.0.0" },
            capabilities: { sampling: true },
            initializationTimeout: 15,
            requestTimeout:        40,
            samplingConsumer: buildSamplingConsumer(),
            loggingConsumer:  function(msg) { /* discard */ }
        })

        // Call tool — server will fire a sampling/createMessage back to our consumer
        toolResp = mcpClient.callTool({
            "name": "send_sampling_request_for_summarizer",
            "arguments": {
                "text":      url.text,
                "maxTokens": val(url.maxTokens)
            }
        })

        mcpClient.close()

        // Parse the tool response content
        responseData = {}
        if (isStruct(toolResp) && structKeyExists(toolResp, "content") && arrayLen(toolResp.content)) {
            try { responseData = deserializeJSON(toolResp.content[1].text) } catch (any e) {}
        }

        result = {
            success:         true,
            serverUrl:       serverUrl,
            inputText:       url.text,
            maxTokens:       val(url.maxTokens),
            samplingRequest: samplingRequest,
            toolResponse:    toolResp,
            summary:         responseData.summary    ?: "",
            model:           responseData.model      ?: "",
            stopReason:      responseData.stopReason ?: "",
            role:            responseData.role       ?: ""
        }
    }
    catch (any e) {
        if (isObject(mcpClient)) try { mcpClient.close() } catch (any ignore) {}
        result = { success: false, error: e.message, serverUrl: serverUrl }
    }

    writeOutput(serializeJSON(result))
</cfscript>
