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

function h(any value = "") {
    return encodeForHTML(toString(arguments.value));
}

function cleanString(any value = "", numeric maxLength = 200) {
    if (isNull(arguments.value)) {
        return "";
    }
    return left(trim(toString(arguments.value)), arguments.maxLength);
}

function dateOrNull(any value = "") {
    var text = cleanString(arguments.value, 40);
    if (!len(text)) {
        return "";
    }
    try {
        text = replace(text, "T", " ", "one");
        text = replace(text, "Z", "", "one");
        if (find(".", text)) {
            text = listFirst(text, ".");
        }
        return parseDateTime(text);
    } catch (any ignored) {
        return "";
    }
}

function buildFilters() {
    var filters = [];
    var params = {};
    var mapping = {
        appId: "app_id",
        environment: "environment",
        workflowName: "workflow_name",
        provider: "provider",
        modelName: "model_name"
    };

    for (var key in structKeyArray(mapping)) {
        var value = cleanString(structKeyExists(url, key) ? url[key] : "", 200);
        if (len(value)) {
            arrayAppend(filters, mapping[key] & " = :" & key);
            params[key] = { value: value, cfsqltype: "cf_sql_varchar" };
        }
    }

    var fromDate = dateOrNull(url.from ?: "");
    if (isDate(fromDate)) {
        arrayAppend(filters, "started_at >= :fromDate");
        params.fromDate = { value: fromDate, cfsqltype: "cf_sql_timestamp" };
    }

    var toDate = dateOrNull(url.to ?: "");
    if (isDate(toDate)) {
        arrayAppend(filters, "started_at <= :toDate");
        params.toDate = { value: toDate, cfsqltype: "cf_sql_timestamp" };
    }

    return {
        sql: arrayLen(filters) ? " WHERE " & arrayToList(filters, " AND ") : "",
        params: params
    };
}

function queryToRows(required query q) {
    var rows = [];
    var columns = q.columnList;
    for (var i = 1; i <= q.recordCount; i++) {
        var row = {};
        for (var column in listToArray(columns)) {
            row[column] = q[column][i];
        }
        arrayAppend(rows, row);
    }
    return rows;
}

function bucketDate(any value = "", string bucket = "hour") {
    var dateValue = isDate(arguments.value) ? arguments.value : parseDateTime(toString(arguments.value));
    if (compareNoCase(arguments.bucket, "day") == 0) {
        return dateTimeFormat(dateValue, "yyyy-mm-dd 00:00:00");
    }
    return dateTimeFormat(dateValue, "yyyy-mm-dd HH:00:00");
}

function numericValue(any value = 0) {
    if (isNull(arguments.value)) {
        return 0;
    }
    try {
        return createObject("java", "java.lang.Double").parseDouble(trim(toString(arguments.value)));
    } catch (any ignored) {
        return val(arguments.value);
    }
}

function summary() {
    var filters = buildFilters();
    var q = runSql(
        "SELECT
            COUNT(*) AS span_count,
            COUNT(DISTINCT trace_id) AS trace_count,
            SUM(input_tokens) AS total_input_tokens,
            SUM(output_tokens) AS total_output_tokens,
            SUM(total_tokens) AS total_tokens,
            SUM(estimated_cost) AS total_estimated_cost,
            AVG(CAST(duration_ms AS DOUBLE)) AS avg_duration_ms
        FROM cairoi_spans" & filters.sql,
        filters.params
    );

    var spanCount = val(q.span_count[1]);
    return {
        ok: true,
        summary: {
            spanCount: spanCount,
            traceCount: val(q.trace_count[1]),
            totalInputTokens: val(q.total_input_tokens[1]),
            totalOutputTokens: val(q.total_output_tokens[1]),
            totalTokens: val(q.total_tokens[1]),
            totalEstimatedCost: numericValue(q.total_estimated_cost[1]),
            averageLatencyMs: val(q.avg_duration_ms[1]),
            from: cleanString(url.from ?: ""),
            to: cleanString(url.to ?: "")
        }
    };
}

function timeseries() {
    var bucket = lcase(cleanString(url.bucket ?: "hour", 20));
    var filters = buildFilters();
    var q = runSql(
        "SELECT
            started_at,
            total_tokens,
            input_tokens,
            output_tokens,
            estimated_cost,
            duration_ms
        FROM cairoi_spans" & filters.sql & "
        ORDER BY started_at",
        filters.params
    );

    var buckets = {};
    for (var i = 1; i <= q.recordCount; i++) {
        var bucketStart = bucketDate(q.started_at[i], bucket);
        if (!structKeyExists(buckets, bucketStart)) {
            buckets[bucketStart] = {
                bucket_start: bucketStart,
                total_tokens: 0,
                input_tokens: 0,
                output_tokens: 0,
                estimated_cost: 0,
                span_count: 0,
                duration_total: 0
            };
        }
        buckets[bucketStart].total_tokens += val(q.total_tokens[i]);
        buckets[bucketStart].input_tokens += val(q.input_tokens[i]);
        buckets[bucketStart].output_tokens += val(q.output_tokens[i]);
        buckets[bucketStart].estimated_cost += numericValue(q.estimated_cost[i]);
        buckets[bucketStart].span_count++;
        buckets[bucketStart].duration_total += val(q.duration_ms[i]);
    }

    var keys = structKeyArray(buckets);
    arraySort(keys, "textnocase");
    var rows = [];
    for (var key in keys) {
        var row = buckets[key];
        row.avg_duration_ms = row.span_count ? row.duration_total / row.span_count : 0;
        structDelete(row, "duration_total");
        arrayAppend(rows, row);
    }

    return { ok: true, bucket: bucket, rows: rows };
}

function breakdown() {
    var by = lcase(cleanString(url.by ?: "model", 40));
    var columns = {
        app: "app_id",
        workflow: "workflow_name",
        provider: "provider",
        model: "model_name",
        operation_type: "operation_type",
        environment: "environment"
    };
    if (!structKeyExists(columns, by)) {
        by = "model";
    }

    var columnName = columns[by];
    var filters = buildFilters();
    var q = runSql(
        "SELECT
            COALESCE(NULLIF(" & columnName & ", ''), '(none)') AS label,
            SUM(total_tokens) AS total_tokens,
            SUM(estimated_cost) AS estimated_cost,
            COUNT(*) AS span_count,
            AVG(CAST(duration_ms AS DOUBLE)) AS avg_duration_ms
        FROM cairoi_spans" & filters.sql & "
        GROUP BY COALESCE(NULLIF(" & columnName & ", ''), '(none)')
        ORDER BY estimated_cost DESC, total_tokens DESC, span_count DESC
        FETCH FIRST 25 ROWS ONLY",
        filters.params
    );

    return { ok: true, by: by, rows: queryToRows(q) };
}

function recent() {
    var q = runSql(
        "SELECT
            t.trace_id,
            t.app_id,
            t.environment,
            t.workflow_name,
            t.status,
            t.started_at,
            t.duration_ms,
            t.total_tokens,
            t.estimated_cost,
            (SELECT COUNT(*) FROM cairoi_spans s WHERE s.trace_id = t.trace_id) AS span_count
        FROM cairoi_traces t
        ORDER BY t.started_at DESC
        FETCH FIRST 20 ROWS ONLY"
    );

    var expensive = runSql(
        "SELECT
            trace_id,
            app_id,
            environment,
            workflow_name,
            status,
            started_at,
            duration_ms,
            total_tokens,
            estimated_cost
        FROM cairoi_traces
        ORDER BY estimated_cost DESC, started_at DESC
        FETCH FIRST 20 ROWS ONLY"
    );

    return { ok: true, traces: queryToRows(q), expensive: queryToRows(expensive) };
}

try {
    action = lcase(cleanString(url.action ?: "summary", 40));
    switch (action) {
        case "summary":
            sendJson(summary());
            break;
        case "timeseries":
            sendJson(timeseries());
            break;
        case "breakdown":
            sendJson(breakdown());
            break;
        case "recent":
            sendJson(recent());
            break;
        default:
            sendJson({ ok: false, error: "unknown_action", message: "Unsupported dashboard action." }, 400);
    }
} catch (any e) {
    sendJson({ ok: false, error: "dashboard_error", message: e.message, detail: e.detail ?: "" }, 500);
}
</cfscript>
