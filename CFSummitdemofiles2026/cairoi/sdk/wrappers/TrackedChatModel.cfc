component output=false {
    variables.cairoi = "";
    variables.chatConfig = {};
    variables.chatModel = "";

    public TrackedChatModel function init(required struct config) {
        variables.cairoi = config.cairoi;
        variables.chatConfig = duplicate(config.chatConfig);
        variables.chatModel = ChatModel(variables.chatConfig);
        return this;
    }

    public any function chat(required string prompt, any trace = "", struct metadata = {}) {
        var span = "";
        var response = "";
        var responseText = "";
        var provider = readKey(variables.chatConfig, "provider", readKey(variables.cairoi.getConfig(), "defaultProvider", ""));
        var modelName = readKey(variables.chatConfig, "modelName", readKey(variables.cairoi.getConfig(), "defaultModelName", ""));
        var spanMetadata = mergeStructs(configMetadata(), arguments.metadata);

        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan("llm.chat", "ChatModel.chat", "", spanMetadata);
        }

        try {
            response = variables.chatModel.chat(arguments.prompt);
            responseText = variables.cairoi.extractResponseText(response);
            finishAiSpan(
                span = span,
                status = "success",
                provider = provider,
                modelName = modelName,
                promptText = arguments.prompt,
                responseText = responseText,
                response = response,
                metadata = {}
            );
            return response;
        } catch (any e) {
            if (isObject(span)) {
                span.finish({
                    status: "error",
                    provider: provider,
                    modelName: modelName,
                    promptText: arguments.prompt,
                    errorType: e.type ?: "ColdFusion.AI.ChatModel",
                    errorMessage: e.message
                });
            }
            rethrow;
        }
    }

    public any function getNative() {
        return variables.chatModel;
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

        var usage = variables.cairoi.getTokenExtractor().extractFromResponse(
            response = arguments.response,
            promptText = arguments.promptText,
            responseText = arguments.responseText
        );
        var cost = variables.cairoi.getCostCalculator().calculate(
            provider = arguments.provider,
            modelName = arguments.modelName,
            inputTokens = usage.inputTokens,
            outputTokens = usage.outputTokens
        );
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
        for (var key in ["temperature", "maxTokens", "maxOutputTokens", "maxCompletionTokens", "topP", "topK", "timeout", "responseFormat"]) {
            var value = readKey(variables.chatConfig, key, "__CAIROI_MISSING__");
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
