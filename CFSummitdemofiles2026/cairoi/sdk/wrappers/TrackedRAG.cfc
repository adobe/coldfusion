component output=false {
    variables.cairoi = "";
    variables.ragConfig = {};

    public TrackedRAG function init(required struct config) {
        variables.cairoi = config.cairoi;
        variables.ragConfig = duplicate(config.ragConfig);
        return this;
    }

    public any function recordIngest(required any trace, any callbackOrMetadata = {}, struct metadata = {}) {
        return recordOperation("rag.ingest", "RAG ingest", arguments.trace, arguments.callbackOrMetadata, arguments.metadata);
    }

    public any function recordRetrieve(required any trace, any callbackOrMetadata = {}, struct metadata = {}) {
        return recordOperation("rag.retrieve", "RAG retrieve", arguments.trace, arguments.callbackOrMetadata, arguments.metadata);
    }

    public any function recordContextAssembly(required any trace, struct metadata = {}) {
        var span = arguments.trace.startSpan("rag.context_assembly", "RAG context assembly", "", mergeStructs(variables.ragConfig, arguments.metadata));
        span.finish({ status: "success" });
        return span;
    }

    public any function recordGeneration(
        required any trace,
        required string prompt,
        required string response,
        string provider = "",
        string modelName = "",
        struct metadata = {}
    ) {
        var span = arguments.trace.startSpan("rag.generate", "RAG generation", "", mergeStructs(variables.ragConfig, arguments.metadata));
        var usage = variables.cairoi.getTokenExtractor().extractFromResponse({}, arguments.prompt, arguments.response);
        var cost = variables.cairoi.getCostCalculator().calculate(arguments.provider, arguments.modelName, usage.inputTokens, usage.outputTokens);
        var costSource = cost.costSource == "calculated" ? "calculated_from_estimated_tokens" : cost.costSource;
        span.finish({
            status: "success",
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
            promptText: arguments.prompt,
            responseText: arguments.response
        });
        return span;
    }

    public any function startSpan(required any trace, required string operationType, string operationName = "", struct metadata = {}) {
        return arguments.trace.startSpan(arguments.operationType, arguments.operationName, "", mergeStructs(variables.ragConfig, arguments.metadata));
    }

    public any function finishSpan(required any span, struct data = {}) {
        return arguments.span.finish(arguments.data);
    }

    private any function recordOperation(
        required string operationType,
        required string operationName,
        required any trace,
        any callbackOrMetadata = {},
        struct metadata = {}
    ) {
        var callMetadata = mergeStructs(variables.ragConfig, arguments.metadata);
        if (isStruct(arguments.callbackOrMetadata)) {
            callMetadata = mergeStructs(callMetadata, arguments.callbackOrMetadata);
        }

        var span = arguments.trace.startSpan(arguments.operationType, arguments.operationName, "", callMetadata);

        if (!isCallback(arguments.callbackOrMetadata)) {
            span.finish({ status: "success" });
            return span;
        }

        try {
            var result = arguments.callbackOrMetadata();
            span.finish({
                status: "success",
                responseBytes: isSimpleValue(result) ? len(toString(result)) : len(serializeJSON(result))
            });
            return result;
        } catch (any e) {
            span.finish({
                status: "error",
                errorType: e.type ?: "CAIROI.RAG",
                errorMessage: e.message
            });
            rethrow;
        }
    }

    private boolean function isCallback(any value = "") {
        try {
            return isCustomFunction(arguments.value) || isClosure(arguments.value);
        } catch (any ignored) {
            return isCustomFunction(arguments.value);
        }
    }

    private struct function mergeStructs(required struct leftStruct, required struct rightStruct) {
        var merged = duplicate(arguments.leftStruct);
        for (var key in structKeyArray(arguments.rightStruct)) {
            merged[key] = arguments.rightStruct[key];
        }
        return merged;
    }
}
