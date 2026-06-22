component output=false {
    variables.traceId = "";
    variables.appId = "";
    variables.environment = "dev";
    variables.workflowName = "";
    variables.userHash = "";
    variables.sessionHash = "";
    variables.requestId = "";
    variables.startedAt = now();
    variables.startedTick = getTickCount();
    variables.endedAt = "";
    variables.durationMs = 0;
    variables.status = "running";
    variables.metadata = {};
    variables.spans = [];
    variables.spanIds = {};
    variables.telemetryClient = "";
    variables.hashUtil = "";
    variables.sendResult = {};

    public TraceContext function init(required struct config) {
        variables.traceId = readKey(arguments.config, "traceId", "trc_" & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")));
        variables.appId = readKey(arguments.config, "appId", "");
        variables.environment = readKey(arguments.config, "environment", "dev");
        variables.workflowName = readKey(arguments.config, "workflowName", "ai_workflow");
        variables.requestId = readKey(arguments.config, "requestId", "");
        variables.telemetryClient = readKey(arguments.config, "telemetryClient", "");
        variables.hashUtil = readKey(arguments.config, "hashUtil", "");
        variables.metadata = sanitizeMetadata(readKey(arguments.config, "metadata", {}));

        var userId = readKey(arguments.config, "userId", "");
        var sessionId = readKey(arguments.config, "sessionId", "");
        variables.userHash = len(userId) && isObject(variables.hashUtil) ? variables.hashUtil.hashNullable(userId) : "";
        variables.sessionHash = len(sessionId) && isObject(variables.hashUtil) ? variables.hashUtil.hashNullable(sessionId) : "";
        return this;
    }

    public any function startSpan(
        required string operationType,
        string operationName = "",
        string parentSpanId = "",
        struct metadata = {}
    ) {
        return sdkComponent("sdk.SpanContext").init({
            trace: this,
            hashUtil: variables.hashUtil,
            traceId: variables.traceId,
            parentSpanId: arguments.parentSpanId,
            appId: variables.appId,
            environment: variables.environment,
            workflowName: variables.workflowName,
            operationType: arguments.operationType,
            operationName: arguments.operationName,
            metadata: arguments.metadata
        });
    }

    public struct function finish(string status = "success", struct metadata = {}) {
        if (len(variables.endedAt)) {
            return variables.sendResult;
        }

        variables.endedAt = now();
        variables.durationMs = getTickCount() - variables.startedTick;
        variables.status = arguments.status;
        variables.metadata = mergeStructs(variables.metadata, sanitizeMetadata(arguments.metadata));

        var spanStructs = getSpans();
        variables.sendResult = isObject(variables.telemetryClient)
            ? variables.telemetryClient.sendTrace(toStruct(), spanStructs)
            : { ok: false, message: "No telemetry client configured." };

        return variables.sendResult;
    }

    public void function addSpan(required any span) {
        var spanStruct = isObject(arguments.span) ? arguments.span.toStruct() : arguments.span;
        var spanId = readKey(spanStruct, "spanId", "");
        if (!len(spanId) || structKeyExists(variables.spanIds, spanId)) {
            return;
        }
        variables.spanIds[spanId] = true;
        arrayAppend(variables.spans, arguments.span);
    }

    public struct function toStruct() {
        var totals = calculateTotals();
        return {
            traceId: variables.traceId,
            appId: variables.appId,
            environment: variables.environment,
            workflowName: variables.workflowName,
            userHash: variables.userHash,
            sessionHash: variables.sessionHash,
            requestId: variables.requestId,
            startedAt: formatDate(variables.startedAt),
            endedAt: len(variables.endedAt) ? formatDate(variables.endedAt) : "",
            durationMs: variables.durationMs,
            status: variables.status,
            totalInputTokens: totals.inputTokens,
            totalOutputTokens: totals.outputTokens,
            totalTokens: totals.totalTokens,
            estimatedCost: totals.estimatedCost,
            metadata: duplicate(variables.metadata)
        };
    }

    public string function getTraceId() {
        return variables.traceId;
    }

    private any function sdkComponent(required string suffix) {
        try {
            return createObject("component", "cairoiLive." & arguments.suffix);
        } catch (any ignored) {
            return createObject("component", "cairoi." & arguments.suffix);
        }
    }

    public array function getSpans() {
        var result = [];
        for (var span in variables.spans) {
            arrayAppend(result, isObject(span) ? span.toStruct() : span);
        }
        return result;
    }

    private struct function calculateTotals() {
        var totals = { inputTokens: 0, outputTokens: 0, totalTokens: 0, estimatedCost: 0 };
        for (var span in getSpans()) {
            totals.inputTokens += val(readKey(span, "inputTokens", 0));
            totals.outputTokens += val(readKey(span, "outputTokens", 0));
            totals.totalTokens += val(readKey(span, "totalTokens", 0));
            totals.estimatedCost += numericValue(readKey(span, "estimatedCost", 0));
        }
        return totals;
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

    private struct function sanitizeMetadata(any metadata = {}) {
        var clean = {};
        if (!isStruct(arguments.metadata)) {
            return clean;
        }
        for (var key in structKeyArray(arguments.metadata)) {
            if (isSensitiveKey(key)) {
                continue;
            }
            var value = arguments.metadata[key];
            if (isNull(value)) {
                clean[key] = "";
            } else if (isSimpleValue(value)) {
                clean[key] = left(toString(value), 1000);
            } else if (isArray(value)) {
                clean[key] = "array(" & arrayLen(value) & ")";
            } else if (isStruct(value)) {
                clean[key] = sanitizeMetadata(value);
            } else {
                clean[key] = "complex";
            }
        }
        return clean;
    }

    private boolean function isSensitiveKey(required string key) {
        var lowered = lcase(arguments.key);
        for (var pattern in ["password", "secret", "token", "apikey", "api_key", "authorization", "bearer", "prompt", "response", "content", "document", "chunk", "sourceText"]) {
            if (find(pattern, lowered)) {
                return true;
            }
        }
        return false;
    }

    private numeric function numericValue(any value = 0) {
        if (isNull(arguments.value)) {
            return 0;
        }
        try {
            return createObject("java", "java.lang.Double").parseDouble(trim(toString(arguments.value)));
        } catch (any ignored) {
            return val(arguments.value);
        }
    }

    private string function formatDate(required date value) {
        return dateTimeFormat(arguments.value, "yyyy-mm-dd HH:nn:ss");
    }
}
