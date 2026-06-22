component output=false {
    public DemoTelemetry function init() {
        return this;
    }

    public boolean function isEnabled() {
        return false;
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
        return isObject(arguments.trace)
            ? arguments.trace.startSpan(arguments.operationType, arguments.operationName, "", arguments.metadata)
            : "";
    }

    public void function finishSpan(any span = "", struct data = {}) {
        if (isObject(arguments.span)) {
            try {
                arguments.span.finish(arguments.data);
            } catch (any ignored) {
            }
        }
    }

    public struct function finishTrace(any trace = "", string status = "success", struct metadata = {}) {
        if (isObject(arguments.trace)) {
            try {
                return arguments.trace.finish(arguments.status, arguments.metadata);
            } catch (any ignored) {
            }
        }
        return { ok: false, disabled: true };
    }

    public struct function traceLinks(any trace = "") {
        if (!isObject(arguments.trace)) {
            return {};
        }

        try {
            var traceId = arguments.trace.getTraceId();
            if (!len(traceId)) {
                return {};
            }
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
        return {
            estimatedCost: 0,
            costSource: "cairoi_sdk_unavailable",
            price: {
                found: false,
                provider: normalizeProvider(arguments.provider),
                modelName: arguments.modelName,
                inputCostPer1M: 0,
                outputCostPer1M: 0,
                currency: "USD"
            }
        };
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
        return compareNoCase(arguments.provider, "openAi") == 0 ? "openai" : lcase(trim(arguments.provider));
    }

    public string function makeRequestId() {
        var method = structKeyExists(cgi, "request_method") ? cgi.request_method : "REQ";
        return lcase(method) & "_" & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all"));
    }
}
