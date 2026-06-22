component output=false {
    variables.cairoi = "";
    variables.agentConfig = {};
    variables.chatConfig = {};
    variables.agent = "";

    public TrackedAgent function init(required struct config) {
        variables.cairoi = config.cairoi;
        variables.agentConfig = duplicate(config.agentConfig);
        variables.chatConfig = readKey(variables.agentConfig, "chatConfig", {});

        if (isStruct(variables.chatConfig) && !structIsEmpty(variables.chatConfig)) {
            var chatModel = ChatModel(variables.chatConfig);
            variables.agent = Agent({ chatModel: chatModel });
        } else {
            variables.agent = Agent(variables.agentConfig);
        }

        return this;
    }

    public any function chat(required any message, any userId = "", any trace = "", struct metadata = {}) {
        var span = "";
        var response = "";
        var responseText = "";
        var provider = readKey(variables.chatConfig, "provider", readKey(variables.cairoi.getConfig(), "defaultProvider", ""));
        var modelName = readKey(variables.chatConfig, "modelName", readKey(variables.cairoi.getConfig(), "defaultModelName", ""));
        var promptText = isSimpleValue(arguments.message) ? toString(arguments.message) : serializeJSON(arguments.message);
        var spanMetadata = mergeStructs(configMetadata(), arguments.metadata);

        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan("agent.chat", "Agent.chat", "", spanMetadata);
        }

        try {
            if (len(trim(toString(arguments.userId)))) {
                response = variables.agent.chat(arguments.message, arguments.userId);
            } else {
                response = variables.agent.chat(arguments.message);
            }

            responseText = variables.cairoi.extractResponseText(response);
            finishAiSpan(span, "success", provider, modelName, promptText, responseText, response, {});
            return response;
        } catch (any e) {
            if (isObject(span)) {
                span.finish({
                    status: "error",
                    provider: provider,
                    modelName: modelName,
                    promptText: promptText,
                    errorType: e.type ?: "ColdFusion.AI.Agent",
                    errorMessage: e.message
                });
            }
            rethrow;
        }
    }

    public any function systemMessage(required string message) {
        return variables.agent.systemMessage(arguments.message);
    }

    public any function getNative() {
        return variables.agent;
    }

    private void function finishAiSpan(
        required any span,
        required string status,
        required string provider,
        required string modelName,
        required string promptText,
        required string responseText,
        required any response,
        struct metadata = {}
    ) {
        if (!isObject(arguments.span)) {
            return;
        }

        var usage = variables.cairoi.getTokenExtractor().extractFromResponse(arguments.response, arguments.promptText, arguments.responseText);
        var cost = variables.cairoi.getCostCalculator().calculate(arguments.provider, arguments.modelName, usage.inputTokens, usage.outputTokens);
        var costSource = cost.costSource;
        if (costSource == "calculated") {
            costSource = usage.inputTokenSource == "provider" && usage.outputTokenSource == "provider"
                ? "calculated_from_provider_tokens"
                : "calculated_from_estimated_tokens";
        }

        arguments.span.finish({
            status: arguments.status,
            provider: arguments.provider,
            modelName: arguments.modelName,
            inputTokens: usage.inputTokens,
            outputTokens: usage.outputTokens,
            totalTokens: usage.totalTokens,
            inputTokenSource: usage.inputTokenSource,
            outputTokenSource: usage.outputTokenSource,
            totalTokenSource: usage.totalTokenSource,
            estimatedCost: cost.estimatedCost,
            costSource: costSource,
            promptText: arguments.promptText,
            responseText: arguments.responseText,
            responseBytes: len(serializeJSON(arguments.response)),
            metadata: arguments.metadata
        });
    }

    private struct function configMetadata() {
        var result = {};
        for (var key in ["temperature", "maxTokens", "maxOutputTokens", "maxCompletionTokens", "timeout", "description"]) {
            var value = readKey(variables.chatConfig, key, readKey(variables.agentConfig, key, "__CAIROI_MISSING__"));
            if (!(isSimpleValue(value) && value == "__CAIROI_MISSING__")) {
                result[key] = value;
            }
        }
        return result;
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
