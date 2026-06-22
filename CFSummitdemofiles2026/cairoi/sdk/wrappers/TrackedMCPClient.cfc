component output=false {
    variables.cairoi = "";
    variables.mcpConfig = {};
    variables.mcpClient = "";

    public TrackedMCPClient function init(required struct config) {
        variables.cairoi = config.cairoi;
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
        var toolName = "";

        if (isStruct(arguments.request)) {
            nativeRequest = duplicate(arguments.request);
            toolName = readKey(nativeRequest, "name", readKey(nativeRequest, "toolName", ""));
        } else {
            toolName = toString(arguments.request);
            nativeRequest = { name: toolName, arguments: arguments.toolArguments };
        }

        var safeMetadata = mergeStructs(metadataForTool(toolName, readKey(nativeRequest, "arguments", {})), arguments.metadata);
        return trackedCall("mcp.call_tool", "MCPClient.callTool", nativeRequest, arguments.trace, safeMetadata, function() {
            return variables.mcpClient.callTool(nativeRequest);
        });
    }

    public any function readResource(any request = "", any trace = "", struct metadata = {}) {
        var nativeRequest = arguments.request;
        var safeMetadata = mergeStructs({ resource: summarizeRequest(arguments.request) }, arguments.metadata);
        return trackedCall("mcp.read_resource", "MCPClient.readResource", arguments.request, arguments.trace, safeMetadata, function() {
            return variables.mcpClient.readResource(nativeRequest);
        });
    }

    public any function getPrompt(any request = "", any trace = "", struct metadata = {}) {
        var nativeRequest = arguments.request;
        var safeMetadata = mergeStructs({ prompt: summarizeRequest(arguments.request) }, arguments.metadata);
        return trackedCall("mcp.get_prompt", "MCPClient.getPrompt", arguments.request, arguments.trace, safeMetadata, function() {
            return variables.mcpClient.getPrompt(nativeRequest);
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
        var response = "";
        var requestBytes = isSimpleValue(arguments.requestPayload) ? len(toString(arguments.requestPayload)) : len(serializeJSON(arguments.requestPayload));

        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan(arguments.operationType, arguments.operationName, "", arguments.metadata);
        }

        try {
            response = arguments.callback();
            if (isObject(span)) {
                span.finish({
                    status: "success",
                    requestBytes: requestBytes,
                    responseBytes: isSimpleValue(response) ? len(toString(response)) : len(serializeJSON(response))
                });
            }
            return response;
        } catch (any e) {
            if (isObject(span)) {
                span.finish({
                    status: "error",
                    requestBytes: requestBytes,
                    errorType: e.type ?: "ColdFusion.AI.MCPClient",
                    errorMessage: e.message
                });
            }
            rethrow;
        }
    }

    private struct function metadataForTool(required string toolName, any toolArgs = {}) {
        var result = {
            toolName: arguments.toolName,
            argumentCount: isStruct(arguments.toolArgs) ? structCount(arguments.toolArgs) : 0,
            argumentKeys: isStruct(arguments.toolArgs) ? arrayToList(structKeyArray(arguments.toolArgs), ",") : "",
            argumentBytes: isSimpleValue(arguments.toolArgs) ? len(toString(arguments.toolArgs)) : len(serializeJSON(arguments.toolArgs))
        };
        return result;
    }

    private string function summarizeRequest(any request = "") {
        if (isSimpleValue(arguments.request)) {
            return left(toString(arguments.request), 200);
        }
        if (isStruct(arguments.request)) {
            return arrayToList(structKeyArray(arguments.request), ",");
        }
        return "complex";
    }

    private struct function mergeStructs(required struct leftStruct, required struct rightStruct) {
        var merged = duplicate(arguments.leftStruct);
        for (var key in structKeyArray(arguments.rightStruct)) {
            merged[key] = arguments.rightStruct[key];
        }
        return merged;
    }

    private any function readKey(any value = "", required string key, any fallback = "") {
        if (!isStruct(arguments.value)) {
            return arguments.fallback;
        }
        for (var candidate in structKeyArray(arguments.value)) {
            if (compareNoCase(candidate, arguments.key) == 0) {
                return arguments.value[candidate];
            }
        }
        return arguments.fallback;
    }
}
