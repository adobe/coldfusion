component output=false {
    variables.traceId = "";

    public TraceContext function init(struct config = {}) {
        variables.traceId = structKeyExists(arguments.config, "traceId")
            ? arguments.config.traceId
            : "";
        return this;
    }

    public any function startSpan(
        string operationType = "",
        string operationName = "",
        string parentSpanId = "",
        struct metadata = {}
    ) {
        return new cairoi.sdk.SpanContext();
    }

    public struct function finish(string status = "success", struct metadata = {}) {
        return {
            ok: false,
            disabled: true,
            status: arguments.status
        };
    }

    public string function getTraceId() {
        return variables.traceId;
    }
}
