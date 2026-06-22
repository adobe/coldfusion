component output=false {
    variables.mcpConfig = {};
    variables.mcpClient = "";

    public TrackedMCPClient function init(required struct config) {
        variables.mcpConfig = duplicate(config.mcpConfig);
        variables.mcpClient = MCPClient(variables.mcpConfig);
        return this;
    }

    public any function listTools(any trace = "", struct metadata = {}) {
        return trackedCall("mcp.list_tools", "MCPClient.listTools", {}, arguments.trace, arguments.metadata, function() {
            return variables.mcpClient.listTools();
        });
    }

    public any function callTool(any request = "", struct toolArguments = {}, any trace = "", struct metadata = {}) {
        var nativeRequest = {};
        if (isStruct(arguments.request)) {
            nativeRequest = duplicate(arguments.request);
        } else {
            nativeRequest = {
                name: toString(arguments.request),
                arguments: arguments.toolArguments
            };
        }

        return trackedCall("mcp.call_tool", "MCPClient.callTool", nativeRequest, arguments.trace, arguments.metadata, function() {
            return variables.mcpClient.callTool(nativeRequest);
        });
    }

    public any function readResource(any request = "", any trace = "", struct metadata = {}) {
        return trackedCall("mcp.read_resource", "MCPClient.readResource", arguments.request, arguments.trace, arguments.metadata, function() {
            return variables.mcpClient.readResource(arguments.request);
        });
    }

    public any function getPrompt(any request = "", any trace = "", struct metadata = {}) {
        return trackedCall("mcp.get_prompt", "MCPClient.getPrompt", arguments.request, arguments.trace, arguments.metadata, function() {
            return variables.mcpClient.getPrompt(arguments.request);
        });
    }

    public any function getNative() {
        return variables.mcpClient;
    }

    private any function trackedCall(
        required string operationType,
        required string operationName,
        any requestPayload = "",
        any trace = "",
        struct metadata = {},
        required any callback
    ) {
        var span = "";
        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan(arguments.operationType, arguments.operationName, "", arguments.metadata);
        }

        try {
            var response = arguments.callback();
            finishSpan(span, "success");
            return response;
        } catch (any e) {
            finishSpan(span, "error", e);
            rethrow;
        }
    }

    private void function finishSpan(required any span, required string status, any error = "") {
        if (!isObject(arguments.span)) {
            return;
        }

        var payload = { status: arguments.status };
        if (isStruct(arguments.error)) {
            payload.errorType = arguments.error.type ?: "ColdFusion.AI.MCPClient";
            payload.errorMessage = arguments.error.message ?: "";
        }
        arguments.span.finish(payload);
    }
}
