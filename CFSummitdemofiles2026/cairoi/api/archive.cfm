<cfsetting showdebugoutput="false" requesttimeout="180">
<cfinclude template="_request.cfm">
<cfscript>
cairoiHandleOptions("POST,OPTIONS");

function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function runSql(required string sql, struct params = {}) {
    return application.cairoiDb.execute(arguments.sql, arguments.params);
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

try {
    if (compareNoCase(cgi.request_method, "POST") != 0) {
        sendJson({ ok: false, message: "POST required." }, 405);
    }

    traceQuery = runSql(
        "SELECT trace_id, app_id, environment, workflow_name, user_hash, session_hash, request_id,
            started_at, ended_at, duration_ms, status, total_input_tokens, total_output_tokens,
            total_tokens, estimated_cost, metadata_json, created_at
        FROM cairoi_traces
        ORDER BY started_at, trace_id"
    );
    spanQuery = runSql(
        "SELECT span_id, trace_id, parent_span_id, app_id, environment, workflow_name,
            operation_type, operation_name, provider, model_name, started_at, ended_at,
            duration_ms, status, input_tokens, output_tokens, total_tokens,
            input_token_source, output_token_source, total_token_source, estimated_cost,
            cost_source, prompt_hash, response_hash, prompt_chars, response_chars,
            request_bytes, response_bytes, error_type, error_message, metadata_json, created_at
        FROM cairoi_spans
        ORDER BY started_at, span_id"
    );

    traceRows = queryToRows(traceQuery);
    spanRows = queryToRows(spanQuery);
    archiveDir = application.cairoiDataRoot & "archives" & (findNoCase("windows", server.OS.name) ? "\" : "/");
    if (!directoryExists(archiveDir)) {
        directoryCreate(archiveDir, true, true);
    }

    archiveId = "cairoi-archive-" & dateTimeFormat(now(), "yyyymmdd-HHnnss") & "-" & left(lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")), 8);
    archiveFile = archiveDir & archiveId & ".json";
    archivePayload = {
        archiveId: archiveId,
        archivedAt: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
        databasePath: application.cairoiDb.getConfig().databasePath,
        traceCount: arrayLen(traceRows),
        spanCount: arrayLen(spanRows),
        traces: traceRows,
        spans: spanRows
    };

    fileWrite(archiveFile, serializeJSON(archivePayload), "utf-8");

    runSql("DELETE FROM cairoi_spans");
    runSql("DELETE FROM cairoi_traces");
    runSql(
        "DELETE FROM cairoi_model_prices WHERE provider = :provider AND model_name = :modelName",
        {
            provider: { value: "mock", cfsqltype: "cf_sql_varchar" },
            modelName: { value: "manual-demo", cfsqltype: "cf_sql_varchar" }
        }
    );

    sendJson({
        ok: true,
        archiveId: archiveId,
        archiveFile: archiveFile,
        traceCount: arrayLen(traceRows),
        spanCount: arrayLen(spanRows),
        message: "Archived " & arrayLen(traceRows) & " traces and " & arrayLen(spanRows) & " spans, then reset live telemetry."
    });
} catch (any e) {
    sendJson({
        ok: false,
        message: "Archive reset failed: " & e.message,
        detail: structKeyExists(e, "detail") ? e.detail : ""
    }, 500);
}
</cfscript>
