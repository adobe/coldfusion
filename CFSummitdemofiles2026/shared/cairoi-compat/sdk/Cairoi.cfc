component output=false {
    variables.config = {};

    public Cairoi function init(struct config = {}) {
        variables.config = duplicate(arguments.config);
        return this;
    }

    public any function startTrace(
        required string workflowName,
        string userId = "",
        string sessionId = "",
        string requestId = "",
        struct metadata = {}
    ) {
        return new cairoi.sdk.TraceContext({ traceId: "" });
    }

    public any function createChatModel(required struct chatConfig) {
        return new cairoi.sdk.wrappers.TrackedChatModel({
            chatConfig: arguments.chatConfig
        });
    }

    public any function createAgent(required struct agentConfig) {
        return new cairoi.sdk.wrappers.TrackedAgent({
            agentConfig: arguments.agentConfig
        });
    }

    public any function createMCPClient(required struct mcpConfig) {
        return new cairoi.sdk.wrappers.TrackedMCPClient({
            mcpConfig: arguments.mcpConfig
        });
    }

    public any function createVectorStore(struct vectorConfig = {}) {
        throw(type = "CAIROI.Compat.Unsupported", message = "Vector store telemetry is unavailable because the CAIROI SDK is not installed.");
    }

    public any function createRAG(struct ragConfig = {}) {
        throw(type = "CAIROI.Compat.Unsupported", message = "RAG telemetry is unavailable because the CAIROI SDK is not installed.");
    }

    public struct function recordSpan(required struct spanData) {
        return { ok: false, disabled: true };
    }

    public struct function flush() {
        return { ok: false, disabled: true };
    }

    public struct function getTelemetryQueueStatus() {
        return { ok: false, disabled: true };
    }

    public any function getHashUtil() {
        return this;
    }

    public any function getTokenExtractor() {
        return this;
    }

    public any function getCostCalculator() {
        return this;
    }

    public struct function getConfig() {
        return duplicate(variables.config);
    }

    public string function extractResponseText(any response = "") {
        if (isSimpleValue(arguments.response)) {
            return toString(arguments.response);
        }

        for (var key in ["message", "content", "text", "answer", "response"]) {
            var possible = readKey(arguments.response, key, "");
            if (isSimpleValue(possible) && len(trim(toString(possible)))) {
                return toString(possible);
            }
        }

        return isStruct(arguments.response) || isArray(arguments.response)
            ? serializeJSON(arguments.response)
            : "";
    }

    public struct function extractFromResponse(any response = "", string promptText = "", string responseText = "") {
        var inputTokens = estimateTokens(arguments.promptText);
        var outputText = len(arguments.responseText) ? arguments.responseText : extractResponseText(arguments.response);
        var outputTokens = estimateTokens(outputText);

        return {
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            totalTokens: inputTokens + outputTokens,
            inputTokenSource: "estimated",
            outputTokenSource: "estimated",
            totalTokenSource: "estimated"
        };
    }

    public struct function calculate(string provider = "", string modelName = "", numeric inputTokens = 0, numeric outputTokens = 0) {
        return {
            estimatedCost: 0,
            costSource: "cairoi_sdk_unavailable",
            price: {
                found: false,
                provider: arguments.provider,
                modelName: arguments.modelName,
                inputCostPer1M: 0,
                outputCostPer1M: 0,
                currency: "USD"
            }
        };
    }

    public string function hashNullable(any value = "") {
        if (isNull(arguments.value) || !len(trim(toString(arguments.value)))) {
            return "";
        }
        return lcase(hash(toString(arguments.value), "SHA-256", "UTF-8"));
    }

    private numeric function estimateTokens(string text = "") {
        return max(1, ceiling(len(arguments.text) / 4));
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
