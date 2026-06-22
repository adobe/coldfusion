component output=false {
    public DemoTelemetry function init() {
        return this;
    }

    public boolean function isEnabled() {
        return structKeyExists(application, "cairoiConfig") &&
            isStruct(application.cairoiConfig) &&
            len(trim(readKey(application.cairoiConfig, "collectorUrl", ""))) &&
            len(trim(readKey(application.cairoiConfig, "apiKey", "")));
    }

    public any function startTrace(
        required string workflowName,
        string userId = "",
        string sessionId = "",
        string requestId = "",
        struct metadata = {}
    ) {
        if (!isEnabled()) {
            return "";
        }

        try {
            var client = sdkComponent("sdk.Cairoi").init(application.cairoiConfig);
            return client.startTrace(
                workflowName = arguments.workflowName,
                userId = arguments.userId,
                sessionId = arguments.sessionId,
                requestId = len(arguments.requestId) ? arguments.requestId : makeRequestId(),
                metadata = arguments.metadata
            );
        } catch (any ignored) {
            return "";
        }
    }

    public any function currentTrace() {
        return structKeyExists(request, "cairoiTrace") && isObject(request.cairoiTrace)
            ? request.cairoiTrace
            : "";
    }

    public any function startSpan(
        any trace = "",
        required string operationType,
        string operationName = "",
        struct metadata = {}
    ) {
        if (!isObject(arguments.trace)) {
            return "";
        }

        try {
            return arguments.trace.startSpan(
                operationType = arguments.operationType,
                operationName = arguments.operationName,
                metadata = arguments.metadata
            );
        } catch (any ignored) {
            return "";
        }
    }

    public void function finishSpan(any span = "", struct data = {}) {
        if (!isObject(arguments.span)) {
            return;
        }

        try {
            var payload = duplicate(arguments.data);
            var provider = normalizeProvider(readKey(payload, "provider", ""));
            var modelName = readKey(payload, "modelName", "");
            var inputTokens = val(readKey(payload, "inputTokens", 0));
            var outputTokens = val(readKey(payload, "outputTokens", 0));
            var totalTokens = val(readKey(payload, "totalTokens", inputTokens + outputTokens));

            if (!structKeyExists(payload, "totalTokens")) {
                payload.totalTokens = totalTokens;
            }
            if (!structKeyExists(payload, "inputTokenSource")) {
                payload.inputTokenSource = "estimated";
            }
            if (!structKeyExists(payload, "outputTokenSource")) {
                payload.outputTokenSource = "estimated";
            }
            if (!structKeyExists(payload, "totalTokenSource")) {
                payload.totalTokenSource = "estimated";
            }
            if (!structKeyExists(payload, "estimatedCost") || !structKeyExists(payload, "costSource")) {
                var cost = calculateCost(provider, modelName, inputTokens, outputTokens);
                payload.estimatedCost = cost.estimatedCost;
                payload.costSource = cost.costSource;
            }
            if (len(provider)) {
                payload.provider = provider;
            }

            arguments.span.finish(payload);
        } catch (any ignored) {
        }
    }

    public struct function finishTrace(any trace = "", string status = "success", struct metadata = {}) {
        if (!isObject(arguments.trace)) {
            return { ok: false, message: "No CAIROI trace." };
        }

        try {
            return arguments.trace.finish(arguments.status, arguments.metadata);
        } catch (any e) {
            return { ok: false, message: e.message };
        }
    }

    public struct function traceLinks(any trace = "") {
        if (!isObject(arguments.trace)) {
            return {};
        }

        var traceId = "";
        try {
            traceId = arguments.trace.getTraceId();
        } catch (any ignored) {
            return {};
        }

        var traceBase = structKeyExists(application, "cairoiTraceUrl") ? application.cairoiTraceUrl : "";
        var dashboardUrl = structKeyExists(application, "cairoiDashboardUrl") ? application.cairoiDashboardUrl : "";
        return {
            traceId: traceId,
            traceUrl: len(traceBase) ? traceBase & "?traceId=" & urlEncodedFormat(traceId) : "",
            dashboardUrl: dashboardUrl
        };
    }

    public numeric function estimateTokens(string text = "") {
        return max(1, ceiling(len(arguments.text) / 4));
    }

    public numeric function estimateBytes(string text = "") {
        return len(arguments.text);
    }

    public struct function calculateCost(
        string provider = "",
        string modelName = "",
        numeric inputTokens = 0,
        numeric outputTokens = 0
    ) {
        var normalizedProvider = normalizeProvider(arguments.provider);
        if (isLocalProvider(normalizedProvider, arguments.modelName)) {
            return {
                estimatedCost: 0,
                costSource: "local_model_zero_cost",
                price: {
                    found: true,
                    provider: normalizedProvider,
                    modelName: arguments.modelName,
                    inputCostPer1M: 0,
                    outputCostPer1M: 0,
                    currency: "USD"
                }
            };
        }

        try {
            var calc = sdkComponent("sdk.CostCalculator").init("embedded-derby");
            return calc.calculate(normalizedProvider, arguments.modelName, arguments.inputTokens, arguments.outputTokens);
        } catch (any ignored) {
            return {
                estimatedCost: 0,
                costSource: "missing_price",
                price: {
                    found: false,
                    provider: normalizedProvider,
                    modelName: arguments.modelName,
                    inputCostPer1M: 0,
                    outputCostPer1M: 0,
                    currency: "USD"
                }
            };
        }
    }

    public boolean function isLocalProvider(string provider = "", string modelName = "") {
        var normalizedProvider = normalizeProvider(arguments.provider);
        if (listFindNoCase("ollama,local", normalizedProvider)) {
            return true;
        }

        var normalizedModel = lcase(trim(arguments.modelName));
        return find("llama", normalizedModel) || find("nomic-embed", normalizedModel);
    }

    public string function normalizeProvider(string provider = "") {
        var normalized = lcase(trim(arguments.provider));
        return compareNoCase(arguments.provider, "openAi") == 0 ? "openai" : normalized;
    }

    public string function makeRequestId() {
        var method = structKeyExists(cgi, "request_method") ? cgi.request_method : "REQ";
        return lcase(method) & "_" & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all"));
    }

    private any function sdkComponent(required string suffix) {
        try {
            return createObject("component", "cairoiLive." & arguments.suffix);
        } catch (any ignored) {
            return createObject("component", "cairoi." & arguments.suffix);
        }
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
