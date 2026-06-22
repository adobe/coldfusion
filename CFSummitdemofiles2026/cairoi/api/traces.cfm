<cfsetting showdebugoutput="false" requesttimeout="60">
<cfinclude template="_request.cfm">
<cfscript>
cairoiHandleOptions("GET,OPTIONS");

function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function runSql(required string sql, struct params = {}) {
    return application.cairoiDb.execute(arguments.sql, arguments.params);
}

function cleanString(any value = "", numeric maxLength = 200) {
    if (isNull(arguments.value)) {
        return "";
    }
    return left(trim(toString(arguments.value)), arguments.maxLength);
}

function queryToRows(required query q) {
    var rows = [];
    for (var i = 1; i <= q.recordCount; i++) {
        var row = {};
        for (var column in listToArray(q.columnList)) {
            row[column] = q[column][i];
        }
        arrayAppend(rows, row);
    }
    return rows;
}

function parseJsonStruct(any value = "") {
    var text = cleanString(arguments.value, 200000);
    if (len(text) && isJSON(text)) {
        var parsed = deserializeJSON(text);
        return isStruct(parsed) ? parsed : {};
    }
    return {};
}

try {
    traceId = cleanString(url.traceId ?: "", 80);
    if (!len(traceId)) {
        q = runSql(
            "SELECT trace_id, app_id, environment, workflow_name, status, started_at, duration_ms, total_tokens, estimated_cost
            FROM cairoi_traces
            ORDER BY started_at DESC
            FETCH FIRST 50 ROWS ONLY"
        );
        sendJson({ ok: true, traces: queryToRows(q) });
    }

    traceQuery = runSql(
        "SELECT trace_id, app_id, environment, workflow_name, user_hash, session_hash, request_id,
            started_at, ended_at, duration_ms, status, total_input_tokens, total_output_tokens,
            total_tokens, estimated_cost, metadata_json
        FROM cairoi_traces
        WHERE trace_id = :traceId",
        { traceId: { value: traceId, cfsqltype: "cf_sql_varchar" } }
    );

    if (!traceQuery.recordCount) {
        sendJson({ ok: false, error: "not_found", message: "Trace not found." }, 404);
    }

    spanQuery = runSql(
        "SELECT span_id, trace_id, parent_span_id, app_id, environment, workflow_name,
            operation_type, operation_name, provider, model_name, started_at, ended_at,
            duration_ms, status, input_tokens, output_tokens, total_tokens,
            input_token_source, output_token_source, total_token_source, estimated_cost,
            cost_source, prompt_hash, response_hash, prompt_chars, response_chars,
            request_bytes, response_bytes, error_type, error_message, metadata_json
        FROM cairoi_spans
        WHERE trace_id = :traceId
        ORDER BY started_at, span_id",
        { traceId: { value: traceId, cfsqltype: "cf_sql_varchar" } }
    );

    traceRows = queryToRows(traceQuery);
    trace = traceRows[1];
    trace.metadata = parseJsonStruct(trace.metadata_json);
    structDelete(trace, "metadata_json");

    spans = queryToRows(spanQuery);
    for (span in spans) {
        span.metadata = parseJsonStruct(span.metadata_json);
        structDelete(span, "metadata_json");
    }

    sendJson({ ok: true, trace: trace, spans: spans });
} catch (any e) {
    sendJson({ ok: false, error: "trace_error", message: e.message, detail: e.detail ?: "" }, 500);
}
</cfscript>
