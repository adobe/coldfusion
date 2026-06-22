<cfsetting showdebugoutput="false" requesttimeout="120">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
}

function getRequestJson() {
    var requestData = getHttpRequestData();
    if (!len(trim(requestData.content))) {
        return {};
    }
    return deserializeJSON(requestData.content);
}

function readKey(required any value, required string key, any fallback = "") {
    if (isStruct(arguments.value)) {
        for (var candidate in structKeyArray(arguments.value)) {
            if (compareNoCase(candidate, arguments.key) == 0) {
                return arguments.value[candidate];
            }
        }
    }
    return arguments.fallback;
}

function currentSessionId() {
    if (structKeyExists(session, "sessionId")) {
        return session.sessionId;
    }
    if (structKeyExists(session, "cfid") && structKeyExists(session, "cftoken")) {
        return session.cfid & "-" & session.cftoken;
    }
    return "";
}

function detectWarehouse(required string text) {
    var lowerText = lcase(arguments.text);
    if (find("munich", lowerText)) return "Munich";
    if (find("berlin", lowerText)) return "Berlin";
    if (find("vienna", lowerText)) return "Vienna";
    return "";
}

function detectCategory(required string text) {
    var lowerText = lcase(arguments.text);
    for (var category in ["electronics", "hardware", "consumables", "safety"]) {
        if (find(category, lowerText)) {
            return ucase(left(category, 1)) & mid(category, 2, len(category));
        }
    }
    return "";
}

function detectSku(required string text) {
    var match = reFindNoCase("[A-Z]{3}-[A-Z]{2}-[0-9]{3}|INV-[0-9]{4}", arguments.text, 1, true);
    if (match.len[1] > 0) {
        return mid(arguments.text, match.pos[1], match.len[1]);
    }
    return "";
}

function chooseTool(required string message) {
    var lowerMessage = lcase(arguments.message);
    var sku = detectSku(arguments.message);
    var toolName = "findItems";
    var args = {
        query: "",
        warehouse: detectWarehouse(arguments.message),
        category: detectCategory(arguments.message),
        stockStatus: ""
    };

    if (len(sku)) {
        toolName = "getItemBySku";
        args = { sku: sku };
    } else if (find("reorder", lowerMessage) || find("order", lowerMessage)) {
        toolName = find("create", lowerMessage) && len(sku) ? "createReorderRequest" : "recommendReorders";
        args = { warehouse: detectWarehouse(arguments.message) };
    } else if (find("low", lowerMessage) || find("critical", lowerMessage) || find("out of stock", lowerMessage)) {
        toolName = "getLowStockItems";
        args = { warehouse: detectWarehouse(arguments.message), threshold: -1 };
    } else {
        args.query = trim(arguments.message);
    }

    if (find("critical", lowerMessage) && toolName == "findItems") {
        args.stockStatus = "critical";
    }

    return { name: toolName, arguments: args };
}

function callMcpTool(required any cairoi, required any trace, required string toolName, required struct toolArguments) {
    var configData = {
        transport: { type: "http", url: application.mcpEndpoint },
        clientInfo: { name: "inventory-ai-demo", version: "1.0.0" },
        initializationTimeout: 10,
        requestTimeout: 30
    };
    var traceId = "";
    try {
        if (isObject(arguments.trace)) {
            traceId = arguments.trace.getTraceId();
        }
    } catch (any ignored) {
    }
    var mcpClient = arguments.cairoi.createMCPClient(configData);
    var resolvedToolName = resolveToolName(mcpClient, arguments.toolName, arguments.trace);
    var nativeResult = mcpClient.callTool(
        request = {
            name: resolvedToolName,
            arguments: arguments.toolArguments
        },
        trace = arguments.trace,
        metadata = {
            serverName: "cf-inventory-database-mcp",
            workflowStep: "inventory_tool_call",
            toolName: resolvedToolName
        }
    );

    return {
        ok: true,
        transportMode: len(traceId) ? "CAIROI TrackedMCPClient" : "ColdFusion MCPClient",
        toolName: resolvedToolName,
        toolResult: normalizeMcpToolResult(nativeResult),
        rawResult: nativeResult
    };
}

function resolveToolName(required any mcpClient, required string desiredName, required any trace) {
    var toolsResponse = arguments.mcpClient.listTools(
        trace = arguments.trace,
        metadata = {
            serverName: "cf-inventory-database-mcp",
            workflowStep: "tool_name_resolution"
        }
    );
    var tools = readKey(toolsResponse, "tools", isArray(toolsResponse) ? toolsResponse : []);
    var desired = lcase(arguments.desiredName);

    for (var toolDef in tools) {
        var candidate = readKey(toolDef, "name", "");
        if (compareNoCase(candidate, arguments.desiredName) == 0 || listLast(lcase(candidate), ".") == desired) {
            return candidate;
        }
    }

    return arguments.desiredName;
}

function getMcpTools(required any cairoi, required any trace) {
    var configData = {
        transport: { type: "http", url: application.mcpEndpoint },
        clientInfo: { name: "inventory-ai-demo-tool-discovery", version: "1.0.0" },
        initializationTimeout: 10,
        requestTimeout: 30
    };
    var mcpClient = arguments.cairoi.createMCPClient(configData);
    var toolsResponse = mcpClient.listTools(
        trace = arguments.trace,
        metadata = {
            serverName: "cf-inventory-database-mcp",
            workflowStep: "tool_discovery"
        }
    );
    return readKey(toolsResponse, "tools", isArray(toolsResponse) ? toolsResponse : []);
}

function resolveSelectedModelKey(string requestedKey = "") {
    var selectedKey = len(trim(arguments.requestedKey))
        ? trim(arguments.requestedKey)
        : (structKeyExists(session, "selectedAiModelKey") ? session.selectedAiModelKey : application.selectedAiModelKey);

    if (!structKeyExists(application.aiModelOptions, selectedKey)) {
        selectedKey = "openai-nano";
    }

    if (!application.aiModelOptions[selectedKey].available) {
        throw(type = "MissingAIKey", message = application.aiModelOptions[selectedKey].label & " is not configured with an API key yet.");
    }

    session.selectedAiModelKey = selectedKey;
    return selectedKey;
}

function selectedModelInfo(required string selectedKey) {
    var option = application.aiModelOptions[arguments.selectedKey];
    return {
        key: option.key,
        label: option.label,
        providerLabel: option.providerLabel,
        modelName: option.chatConfig.modelName,
        modelLabel: option.modelLabel
    };
}

function makeAgent(required any cairoi, string selectedKey = "") {
    var modelKey = resolveSelectedModelKey(arguments.selectedKey);
    var option = application.aiModelOptions[modelKey];

    if (!len(trim(option.chatConfig.apiKey))) {
        throw(type = "MissingAIKey", message = option.label & " is not configured with an API key yet.");
    }

    var chatConfig = duplicate(option.chatConfig);
    return arguments.cairoi.createAgent({ chatConfig: chatConfig });
}

function extractJsonObject(required string text) {
    var startPos = find("{", arguments.text);
    var endPos = 0;

    for (var i = len(arguments.text); i >= 1; i--) {
        if (mid(arguments.text, i, 1) == "}") {
            endPos = i;
            break;
        }
    }

    if (!startPos || !endPos || endPos <= startPos) {
        throw(type = "ToolSelectionParseError", message = "The LLM did not return a JSON tool selection.", detail = left(arguments.text, 1000));
    }

    var jsonText = mid(arguments.text, startPos, endPos - startPos + 1);
    if (!isJSON(jsonText)) {
        throw(type = "ToolSelectionParseError", message = "The LLM returned invalid JSON for tool selection.", detail = jsonText);
    }

    return deserializeJSON(jsonText);
}

function chooseToolWithLlm(
    required any cairoi,
    required any trace,
    required string message,
    required array tools,
    required string selectedModelKey
) {
    var agent = makeAgent(arguments.cairoi, arguments.selectedModelKey);
    var toolNames = [];
    for (var toolDef in arguments.tools) {
        arrayAppend(toolNames, readKey(toolDef, "name", ""));
    }
    var toolPrompt = "You are an inventory MCP tool router. Choose exactly one tool for the user's request." & chr(10) &
        "Return exactly one JSON object and no other text." & chr(10) &
        "The JSON schema is: {""toolName"":""one of the available tool names"",""arguments"":{}}" & chr(10) &
        "Available tool names: " & arrayToList(toolNames, ", ") & chr(10) &
        "Tool definitions: " & serializeJSON(arguments.tools) & chr(10) &
        "Examples:" & chr(10) &
        "User: What items are low stock in Munich warehouse?" & chr(10) &
        "Output: {""toolName"":""getLowStockItems"",""arguments"":{""warehouse"":""Munich"",""threshold"":-1}}" & chr(10) &
        "User: What is about to ruin my week?" & chr(10) &
        "Output: {""toolName"":""recommendReorders"",""arguments"":{""warehouse"":""""}}" & chr(10) &
        "User: What is our stock on noise cancelling headphones?" & chr(10) &
        "Output: {""toolName"":""findItems"",""arguments"":{""query"":""noise cancelling headphones"",""warehouse"":"""",""category"":"""",""stockStatus"":""""}}" & chr(10) &
        "User: Show me electronics that need attention." & chr(10) &
        "Output: {""toolName"":""findItems"",""arguments"":{""query"":""electronics need attention"",""warehouse"":"""",""category"":""Electronics"",""stockStatus"":""low""}}" & chr(10) &
        "User: What is the status of MUC-EL-001?" & chr(10) &
        "Output: {""toolName"":""getItemBySku"",""arguments"":{""sku"":""MUC-EL-001""}}" & chr(10) &
        "User request: " & arguments.message;
    var selectionResponse = agent.chat(
        message = toolPrompt,
        userId = "inventory-tool-router",
        trace = arguments.trace,
        metadata = {
            workflowStep: "tool_router",
            selectedModelKey: arguments.selectedModelKey,
            availableToolCount: arrayLen(arguments.tools),
            userMessageChars: len(arguments.message)
        }
    );
    var toolRequestSelection = extractToolExecutionRequest(selectionResponse);
    if (!structIsEmpty(toolRequestSelection)) {
        return validateToolSelection(toolRequestSelection, arguments.tools);
    }

    var selectionText = responseText(selectionResponse);
    try {
        var selection = extractJsonObject(selectionText);
        return validateToolSelection(selection, arguments.tools);
    } catch (any parseError) {
        var repairPrompt = "Your previous inventory tool-router response was invalid because it was not JSON." & chr(10) &
            "Convert it into exactly one JSON object and no prose." & chr(10) &
            "Schema: {""toolName"":""one of: " & arrayToList(toolNames, ", ") & """,""arguments"":{}}" & chr(10) &
            "Available tools: " & serializeJSON(arguments.tools) & chr(10) &
            "User request: " & arguments.message & chr(10) &
            "Invalid response: " & selectionText & chr(10) &
            "Return only the JSON object.";
        var repairResponse = agent.chat(
            message = repairPrompt,
            userId = "inventory-tool-router-repair",
            trace = arguments.trace,
            metadata = {
                workflowStep: "tool_router_repair",
                selectedModelKey: arguments.selectedModelKey,
                availableToolCount: arrayLen(arguments.tools),
                userMessageChars: len(arguments.message)
            }
        );
        var repairToolRequest = extractToolExecutionRequest(repairResponse);
        if (!structIsEmpty(repairToolRequest)) {
            return validateToolSelection(repairToolRequest, arguments.tools);
        }

        var repairSelection = extractJsonObject(responseText(repairResponse));
        return validateToolSelection(repairSelection, arguments.tools);
    }
}

function extractToolExecutionRequest(required any selectionResponse) {
    var aiMessage = readKey(arguments.selectionResponse, "aiMessage", {});
    var requests = readKey(aiMessage, "toolExecutionRequests", []);

    if (!isArray(requests) || !arrayLen(requests)) {
        return {};
    }

    var request = requests[1];
    var requestArguments = readKey(request, "arguments", {});

    if (isSimpleValue(requestArguments) && len(trim(requestArguments)) && isJSON(requestArguments)) {
        requestArguments = deserializeJSON(requestArguments);
    }

    return {
        toolName: readKey(request, "name", ""),
        arguments: isStruct(requestArguments) ? requestArguments : {}
    };
}

function validateToolSelection(required struct selection, required array tools) {
    var nestedToolRequest = extractToolExecutionRequest(arguments.selection);
    if (!structIsEmpty(nestedToolRequest)) {
        arguments.selection = nestedToolRequest;
    }

    var selectedName = readKey(selection, "toolName", readKey(selection, "name", ""));
    var selectedArguments = readKey(selection, "arguments", {});

    if (!len(selectedName) || !isStruct(selectedArguments)) {
        throw(type = "ToolSelectionError", message = "The LLM did not select a valid MCP tool.");
    }

    for (var toolDef in arguments.tools) {
        var availableName = readKey(toolDef, "name", "");
        if (compareNoCase(availableName, selectedName) == 0) {
            return { name: availableName, arguments: selectedArguments };
        }
    }

    throw(type = "ToolSelectionError", message = "The LLM selected an unavailable MCP tool: " & selectedName);
}

function normalizeMcpToolResult(required any nativeResult) {
    if (isStruct(arguments.nativeResult)) {
        var structuredContent = readKey(arguments.nativeResult, "structuredContent", {});
        if (isStruct(structuredContent) && !structIsEmpty(structuredContent)) {
            return structuredContent;
        }

        var content = readKey(arguments.nativeResult, "content", []);
        if (isArray(content) && arrayLen(content)) {
            var firstText = readKey(content[1], "text", "");
            if (len(firstText) && isJSON(firstText)) {
                return deserializeJSON(firstText);
            }
        }
    }

    return isStruct(arguments.nativeResult) ? arguments.nativeResult : { value: arguments.nativeResult };
}

function responseText(required any response) {
    if (isSimpleValue(arguments.response)) {
        return arguments.response;
    }

    for (var key in ["message", "content", "text", "answer", "response"]) {
        var possible = readKey(arguments.response, key, "");
        if (isSimpleValue(possible) && len(trim(possible))) {
            return possible;
        }
    }

    return serializeJSON(arguments.response);
}

function llmSummary(
    required any cairoi,
    required any trace,
    required string question,
    required string toolName,
    required struct toolArguments,
    required struct toolResult,
    required string selectedModelKey
) {
    var option = application.aiModelOptions[arguments.selectedModelKey];
    var chatModel = arguments.cairoi.createChatModel(duplicate(option.chatConfig));
    var systemPrompt = "You are InventoryAI, a concise operations assistant. You answer only from the supplied MCP tool result. Mention SKUs, warehouses, quantities, status, suppliers, and lead time when relevant. If the result is empty, say no matching inventory records were found.";
    var prompt = systemPrompt & chr(10) & chr(10) &
        "User question: " & arguments.question & chr(10) & chr(10) &
        "MCP tool called: " & arguments.toolName & chr(10) &
        "Tool arguments: " & serializeJSON(arguments.toolArguments) & chr(10) &
        "Tool result: " & serializeJSON(arguments.toolResult);
    var response = chatModel.chat(
        prompt = prompt,
        trace = arguments.trace,
        metadata = {
            workflowStep: "answer_synthesis",
            selectedModelKey: arguments.selectedModelKey,
            toolName: arguments.toolName,
            toolArgumentCount: structCount(arguments.toolArguments),
            toolResultBytes: len(serializeJSON(arguments.toolResult))
        }
    );

    return responseText(response);
}

trace = "";
traceId = "";
currentStage = "request_validation";
requestedModelKey = "";
selectedModelKey = "";

try {
    startedAt = getTickCount();
    payload = getRequestJson();
    message = trim(readKey(payload, "message", ""));
    requestedModelKey = trim(readKey(payload, "modelKey", ""));

    if (!len(message)) {
        sendJson({ ok: false, message: "Message is required." }, 400);
    }

    selectedModelKey = resolveSelectedModelKey(requestedModelKey);
    modelInfo = selectedModelInfo(selectedModelKey);
    cairoiComponentName = "cairoiLive" & ".sdk.Cairoi";
    cairoi = createObject("component", cairoiComponentName).init(application.cairoiConfig);
    trace = cairoi.startTrace(
        workflowName = "inventory_mcp_chat",
        userId = "inventory-demo-user",
        sessionId = currentSessionId(),
        requestId = "req_" & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")),
        metadata = {
            route: cgi.script_name,
            feature: "inventory-mcp-assistant",
            selectedModelKey: selectedModelKey,
            provider: modelInfo.providerLabel,
            modelName: modelInfo.modelName,
            questionChars: len(message)
        }
    );
    traceId = trace.getTraceId();

    currentStage = "mcp_tool_discovery";
    availableTools = getMcpTools(cairoi, trace);
    currentStage = "agent_tool_routing";
    toolCall = chooseToolWithLlm(cairoi, trace, message, availableTools, selectedModelKey);
    currentStage = "mcp_tool_call";
    mcpResponse = callMcpTool(cairoi, trace, toolCall.name, toolCall.arguments);
    toolResult = readKey(mcpResponse, "toolResult", readKey(readKey(mcpResponse, "result", {}), "structuredContent", {}));
    currentStage = "llm_answer_synthesis";
    answer = llmSummary(cairoi, trace, message, toolCall.name, toolCall.arguments, toolResult, selectedModelKey);
    elapsedMs = getTickCount() - startedAt;
    trace.finish(
        status = "success",
        metadata = {
            toolName: toolCall.name,
            selectedModelKey: selectedModelKey,
            elapsedMs: elapsedMs
        }
    );

    responsePayload = {
        ok: true,
        answer: answer,
        toolCall: {
            name: toolCall.name,
            arguments: toolCall.arguments
        },
        toolResult: toolResult,
        mcp: {
            endpoint: application.mcpEndpoint,
            mode: readKey(mcpResponse, "transportMode", application.mcpTransportMode),
            rawStatus: readKey(mcpResponse, "ok", true)
        },
        model: modelInfo,
        modelName: modelInfo.modelName,
        elapsedMs: elapsedMs
    };
    if (len(traceId)) {
        responsePayload.cairoi = {
            traceId: traceId,
            traceUrl: application.cairoiTraceUrl & "?traceId=" & urlEncodedFormat(traceId),
            dashboardUrl: application.cairoiDashboardUrl
        };
    }
    sendJson(responsePayload);
} catch (any error) {
    try {
        if (isObject(trace)) {
            trace.finish(
                status = "error",
                metadata = {
                    failureStage: currentStage,
                    requestedModelKey: requestedModelKey,
                    selectedModelKey: selectedModelKey
                }
            );
            traceId = trace.getTraceId();
        }
    } catch (any ignored) {
    }

    errorPayload = {
        ok: false,
        message: "Chat failed: " & error.message,
        detail: error.detail ?: ""
    };
    if (len(traceId)) {
        errorPayload.cairoi = {
            traceId: traceId,
            traceUrl: application.cairoiTraceUrl & "?traceId=" & urlEncodedFormat(traceId),
            dashboardUrl: application.cairoiDashboardUrl
        };
    }
    sendJson(errorPayload, 500);
}
</cfscript>
