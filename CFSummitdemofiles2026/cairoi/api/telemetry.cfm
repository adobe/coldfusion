<cfsetting showdebugoutput="false" requesttimeout="60">
<cfinclude template="_request.cfm">
<cfscript>
cairoiHandleOptions("POST,OPTIONS");
allowedOperations = "llm.chat,agent.chat,agent.tool_request,agent.tool_result,rag.ingest,rag.retrieve,rag.context_assembly,rag.generate,embedding.embed,embedding.embed_batch,vector.add,vector.add_batch,vector.search,vector.delete,mcp.list_tools,mcp.call_tool,mcp.read_resource,mcp.get_prompt,guardrail.input,guardrail.output,custom";

function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function runSql(required string sql, struct params = {}) {
    return application.cairoiDb.execute(arguments.sql, arguments.params);
}

function readKey(any value = "", required string key, any fallback = "") {
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

function readHeader(required struct headers, required string key, string fallback = "") {
    return readKey(arguments.headers, arguments.key, arguments.fallback);
}

function parseRequestBody() {
    var requestData = getHttpRequestData();
    if (!len(trim(requestData.content))) {
        sendJson({ ok: false, error: "empty_payload", message: "Telemetry payload is required." }, 400);
    }
    if (len(requestData.content) > cairoiMaxTelemetryBytes()) {
        sendJson({ ok: false, error: "payload_too_large", message: "Telemetry payload exceeds the configured request-size limit." }, 413);
    }
    if (!isJSON(requestData.content)) {
        sendJson({ ok: false, error: "invalid_json", message: "Telemetry payload must be JSON." }, 400);
    }
    return deserializeJSON(requestData.content);
}

function cleanString(any value = "", numeric maxLength = 4000) {
    if (isNull(arguments.value)) {
        return "";
    }
    var text = isSimpleValue(arguments.value) ? toString(arguments.value) : serializeJSON(arguments.value);
    text = reReplace(text, "(?i)(bearer\s+)[A-Za-z0-9._\-]+", "\1[redacted]", "all");
    text = reReplace(text, "(?i)(api[_-]?key\s*[:=]\s*)[A-Za-z0-9._\-]+", "\1[redacted]", "all");
    text = reReplace(text, "(?i)(password\s*[:=]\s*)\S+", "\1[redacted]", "all");
    return left(text, arguments.maxLength);
}

function sanitizeMetadata(any metadata = {}) {
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
            clean[key] = cleanString(value, 1000);
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

function isSensitiveKey(required string key) {
    var lowered = lcase(arguments.key);
    for (var pattern in ["password", "secret", "token", "apikey", "api_key", "authorization", "bearer", "prompt", "response", "content", "document", "chunk", "sourceText"]) {
        if (find(pattern, lowered)) {
            return true;
        }
    }
    return false;
}

function metadataJson(any metadata = {}) {
    var clean = sanitizeMetadata(arguments.metadata);
    return structIsEmpty(clean) ? "" : serializeJSON(clean);
}

function parseIncomingDate(any value = "") {
    if (isDate(arguments.value)) {
        return arguments.value;
    }
    var text = trim(toString(arguments.value));
    if (!len(text)) {
        return now();
    }
    text = replace(text, "T", " ", "one");
    text = replace(text, "Z", "", "one");
    if (find(".", text)) {
        text = listFirst(text, ".");
    }
    try {
        return parseDateTime(text);
    } catch (any ignored) {
        return now();
    }
}

function normalizeOperationType(required string operationType) {
    return listFindNoCase(allowedOperations, arguments.operationType) ? lcase(arguments.operationType) : "custom";
}

function decimalParam(any value = 0) {
    var parsed = 0;
    try {
        parsed = createObject("java", "java.lang.Double").parseDouble(trim(toString(arguments.value)));
    } catch (any ignored) {
        parsed = val(arguments.value);
    }
    return { value: parsed, cfsqltype: "cf_sql_float" };
}

function requireTables() {
    for (var tableName in ["cairoi_applications", "cairoi_api_keys", "cairoi_traces", "cairoi_spans"]) {
        if (!application.cairoiDb.tableExists(tableName)) {
            sendJson({ ok: false, error: "setup_required", message: "CAIROI tables are missing. Run /CAIROI/admin/setup.cfm first." }, 503);
        }
    }
}

function normalizedProvider(required string provider) {
    return compareNoCase(arguments.provider, "openAi") == 0 ? "openai" : lcase(arguments.provider);
}

function normalizePayloadProvider(required struct spanPayload) {
    var provider = cleanString(readKey(arguments.spanPayload, "provider", ""), 100);
    if (len(provider)) {
        arguments.spanPayload.provider = normalizedProvider(provider);
    }
}

function normalizeTracePayload(required struct tracePayload) {
    var metadata = readKey(arguments.tracePayload, "metadata", {});
    if (isStruct(metadata) && structKeyExists(metadata, "provider")) {
        metadata.provider = normalizedProvider(metadata.provider);
        arguments.tracePayload.metadata = metadata;
    }
}

function updateTraceTotals(required string traceId) {
    var totals = runSql(
        "SELECT
            SUM(input_tokens) AS total_input_tokens,
            SUM(output_tokens) AS total_output_tokens,
            SUM(total_tokens) AS total_tokens,
            SUM(estimated_cost) AS estimated_cost,
            SUM(CASE WHEN status = 'error' THEN 1 ELSE 0 END) AS error_count
        FROM cairoi_spans
        WHERE trace_id = :traceId",
        { traceId: { value: arguments.traceId, cfsqltype: "cf_sql_varchar" } }
    );

    runSql(
        "UPDATE cairoi_traces
        SET total_input_tokens = :totalInputTokens,
            total_output_tokens = :totalOutputTokens,
            total_tokens = :totalTokens,
            estimated_cost = :estimatedCost,
            status = CASE WHEN :errorCount > 0 THEN 'error' ELSE status END
        WHERE trace_id = :traceId",
        {
            traceId: { value: arguments.traceId, cfsqltype: "cf_sql_varchar" },
            totalInputTokens: { value: val(totals.total_input_tokens[1]), cfsqltype: "cf_sql_integer" },
            totalOutputTokens: { value: val(totals.total_output_tokens[1]), cfsqltype: "cf_sql_integer" },
            totalTokens: { value: val(totals.total_tokens[1]), cfsqltype: "cf_sql_integer" },
            estimatedCost: decimalParam(totals.estimated_cost[1]),
            errorCount: { value: val(totals.error_count[1]), cfsqltype: "cf_sql_integer" }
        }
    );
}

function authenticate(required struct headers, required struct payload) {
    var apiKey = cairoiTelemetryApiKey();
    if (!len(apiKey)) {
        sendJson({ ok: false, error: "missing_api_key", message: "X-CAIROI-API-Key or Authorization: Bearer is required." }, 401);
    }

    var apiKeyHash = lcase(hash(apiKey, "SHA-256", "UTF-8"));
    var keyQuery = runSql(
        "SELECT k.api_key_id, k.app_id, a.app_name, a.environment
        FROM cairoi_api_keys k
        INNER JOIN cairoi_applications a ON a.app_id = k.app_id
        WHERE k.api_key_hash = :apiKeyHash
            AND k.is_active = 1
            AND a.is_active = 1",
        { apiKeyHash: { value: apiKeyHash, cfsqltype: "cf_sql_varchar" } }
    );

    if (!keyQuery.recordCount) {
        sendJson({ ok: false, error: "invalid_api_key", message: "Telemetry API key is invalid or inactive." }, 401);
    }

    runSql(
        "UPDATE cairoi_api_keys SET last_used_at = CURRENT_TIMESTAMP WHERE api_key_id = :apiKeyId",
        { apiKeyId: { value: keyQuery.api_key_id[1], cfsqltype: "cf_sql_integer" } }
    );

    return {
        apiKeyId: keyQuery.api_key_id[1],
        appId: keyQuery.app_id[1],
        appName: keyQuery.app_name[1],
        environment: keyQuery.environment[1]
    };
}

function ensureTrace(required struct tracePayload, required struct authContext) {
    normalizeTracePayload(arguments.tracePayload);
    var traceId = cleanString(readKey(arguments.tracePayload, "traceId", ""), 80);
    if (!len(traceId)) {
        sendJson({ ok: false, error: "missing_trace_id", message: "trace.traceId is required." }, 400);
    }

    var appId = cleanString(readKey(arguments.tracePayload, "appId", arguments.authContext.appId), 100);
    if (compareNoCase(appId, arguments.authContext.appId) != 0) {
        sendJson({ ok: false, error: "app_key_mismatch", message: "API key is not active for appId " & appId & "." }, 403);
    }

    var existsQuery = runSql(
        "SELECT COUNT(*) AS trace_count FROM cairoi_traces WHERE trace_id = :traceId",
        { traceId: { value: traceId, cfsqltype: "cf_sql_varchar" } }
    );

    var params = {
        traceId: { value: traceId, cfsqltype: "cf_sql_varchar" },
        appId: { value: appId, cfsqltype: "cf_sql_varchar" },
        environment: { value: cleanString(readKey(arguments.tracePayload, "environment", arguments.authContext.environment), 50), cfsqltype: "cf_sql_varchar" },
        workflowName: { value: cleanString(readKey(arguments.tracePayload, "workflowName", "ai_workflow"), 200), cfsqltype: "cf_sql_varchar" },
        userHash: { value: cleanString(readKey(arguments.tracePayload, "userHash", ""), 80), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.tracePayload, "userHash", ""), 80)) },
        sessionHash: { value: cleanString(readKey(arguments.tracePayload, "sessionHash", ""), 80), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.tracePayload, "sessionHash", ""), 80)) },
        requestId: { value: cleanString(readKey(arguments.tracePayload, "requestId", ""), 120), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.tracePayload, "requestId", ""), 120)) },
        startedAt: { value: parseIncomingDate(readKey(arguments.tracePayload, "startedAt", "")), cfsqltype: "cf_sql_timestamp" },
        endedAt: { value: parseIncomingDate(readKey(arguments.tracePayload, "endedAt", "")), cfsqltype: "cf_sql_timestamp", null: !len(cleanString(readKey(arguments.tracePayload, "endedAt", ""), 40)) },
        durationMs: { value: val(readKey(arguments.tracePayload, "durationMs", 0)), cfsqltype: "cf_sql_integer" },
        status: { value: cleanString(readKey(arguments.tracePayload, "status", "success"), 40), cfsqltype: "cf_sql_varchar" },
        totalInputTokens: { value: val(readKey(arguments.tracePayload, "totalInputTokens", 0)), cfsqltype: "cf_sql_integer" },
        totalOutputTokens: { value: val(readKey(arguments.tracePayload, "totalOutputTokens", 0)), cfsqltype: "cf_sql_integer" },
        totalTokens: { value: val(readKey(arguments.tracePayload, "totalTokens", 0)), cfsqltype: "cf_sql_integer" },
        estimatedCost: decimalParam(readKey(arguments.tracePayload, "estimatedCost", 0)),
        metadataJson: { value: metadataJson(readKey(arguments.tracePayload, "metadata", {})), cfsqltype: "cf_sql_longvarchar", null: !len(metadataJson(readKey(arguments.tracePayload, "metadata", {}))) }
    };

    if (existsQuery.trace_count[1]) {
        runSql(
            "UPDATE cairoi_traces
            SET ended_at = :endedAt,
                duration_ms = :durationMs,
                status = :status,
                total_input_tokens = :totalInputTokens,
                total_output_tokens = :totalOutputTokens,
                total_tokens = :totalTokens,
                estimated_cost = :estimatedCost,
                metadata_json = :metadataJson
            WHERE trace_id = :traceId",
            params
        );
    } else {
        runSql(
            "INSERT INTO cairoi_traces (
                trace_id, app_id, environment, workflow_name, user_hash, session_hash, request_id,
                started_at, ended_at, duration_ms, status, total_input_tokens, total_output_tokens,
                total_tokens, estimated_cost, metadata_json
            )
            VALUES (
                :traceId, :appId, :environment, :workflowName, :userHash, :sessionHash, :requestId,
                :startedAt, :endedAt, :durationMs, :status, :totalInputTokens, :totalOutputTokens,
                :totalTokens, :estimatedCost, :metadataJson
            )",
            params
        );
    }

    return traceId;
}

function ensureMinimalTrace(required struct spanPayload, required struct authContext) {
    var traceId = cleanString(readKey(arguments.spanPayload, "traceId", ""), 80);
    if (!len(traceId)) {
        sendJson({ ok: false, error: "missing_trace_id", message: "span.traceId is required for standalone spans." }, 400);
    }

    var appId = cleanString(readKey(arguments.spanPayload, "appId", arguments.authContext.appId), 100);
    var workflowName = cleanString(readKey(arguments.spanPayload, "workflowName", "standalone_span"), 200);
    ensureTrace({
        traceId: traceId,
        appId: appId,
        environment: readKey(arguments.spanPayload, "environment", arguments.authContext.environment),
        workflowName: workflowName,
        startedAt: readKey(arguments.spanPayload, "startedAt", ""),
        status: readKey(arguments.spanPayload, "status", "success")
    }, arguments.authContext);
    return traceId;
}

function insertSpan(required struct spanPayload, required struct authContext) {
    normalizePayloadProvider(arguments.spanPayload);
    var spanId = cleanString(readKey(arguments.spanPayload, "spanId", ""), 80);
    if (!len(spanId)) {
        sendJson({ ok: false, error: "missing_span_id", message: "span.spanId is required." }, 400);
    }

    var existsQuery = runSql(
        "SELECT COUNT(*) AS span_count FROM cairoi_spans WHERE span_id = :spanId",
        { spanId: { value: spanId, cfsqltype: "cf_sql_varchar" } }
    );
    if (existsQuery.span_count[1]) {
        return false;
    }

    var appId = cleanString(readKey(arguments.spanPayload, "appId", arguments.authContext.appId), 100);
    if (compareNoCase(appId, arguments.authContext.appId) != 0) {
        sendJson({ ok: false, error: "app_key_mismatch", message: "API key is not active for span appId " & appId & "." }, 403);
    }

    var requestedOperationType = cleanString(readKey(arguments.spanPayload, "operationType", "custom"), 80);
    var operationType = normalizeOperationType(requestedOperationType);
    var metadata = readKey(arguments.spanPayload, "metadata", {});
    if (operationType == "custom" && compareNoCase(requestedOperationType, "custom") != 0) {
        if (!isStruct(metadata)) {
            metadata = {};
        }
        metadata.originalOperationType = requestedOperationType;
    }

    runSql(
        "INSERT INTO cairoi_spans (
            span_id, trace_id, parent_span_id, app_id, environment, workflow_name,
            operation_type, operation_name, provider, model_name, started_at, ended_at,
            duration_ms, status, input_tokens, output_tokens, total_tokens,
            input_token_source, output_token_source, total_token_source, estimated_cost, cost_source,
            prompt_hash, response_hash, prompt_chars, response_chars, request_bytes, response_bytes,
            error_type, error_message, metadata_json
        )
        VALUES (
            :spanId, :traceId, :parentSpanId, :appId, :environment, :workflowName,
            :operationType, :operationName, :provider, :modelName, :startedAt, :endedAt,
            :durationMs, :status, :inputTokens, :outputTokens, :totalTokens,
            :inputTokenSource, :outputTokenSource, :totalTokenSource, :estimatedCost, :costSource,
            :promptHash, :responseHash, :promptChars, :responseChars, :requestBytes, :responseBytes,
            :errorType, :errorMessage, :metadataJson
        )",
        {
            spanId: { value: spanId, cfsqltype: "cf_sql_varchar" },
            traceId: { value: cleanString(readKey(arguments.spanPayload, "traceId", ""), 80), cfsqltype: "cf_sql_varchar" },
            parentSpanId: { value: cleanString(readKey(arguments.spanPayload, "parentSpanId", ""), 80), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "parentSpanId", ""), 80)) },
            appId: { value: appId, cfsqltype: "cf_sql_varchar" },
            environment: { value: cleanString(readKey(arguments.spanPayload, "environment", arguments.authContext.environment), 50), cfsqltype: "cf_sql_varchar" },
            workflowName: { value: cleanString(readKey(arguments.spanPayload, "workflowName", "ai_workflow"), 200), cfsqltype: "cf_sql_varchar" },
            operationType: { value: operationType, cfsqltype: "cf_sql_varchar" },
            operationName: { value: cleanString(readKey(arguments.spanPayload, "operationName", ""), 200), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "operationName", ""), 200)) },
            provider: { value: cleanString(readKey(arguments.spanPayload, "provider", ""), 100), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "provider", ""), 100)) },
            modelName: { value: cleanString(readKey(arguments.spanPayload, "modelName", ""), 200), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "modelName", ""), 200)) },
            startedAt: { value: parseIncomingDate(readKey(arguments.spanPayload, "startedAt", "")), cfsqltype: "cf_sql_timestamp" },
            endedAt: { value: parseIncomingDate(readKey(arguments.spanPayload, "endedAt", "")), cfsqltype: "cf_sql_timestamp", null: !len(cleanString(readKey(arguments.spanPayload, "endedAt", ""), 40)) },
            durationMs: { value: val(readKey(arguments.spanPayload, "durationMs", 0)), cfsqltype: "cf_sql_integer" },
            status: { value: cleanString(readKey(arguments.spanPayload, "status", "success"), 40), cfsqltype: "cf_sql_varchar" },
            inputTokens: { value: val(readKey(arguments.spanPayload, "inputTokens", 0)), cfsqltype: "cf_sql_integer" },
            outputTokens: { value: val(readKey(arguments.spanPayload, "outputTokens", 0)), cfsqltype: "cf_sql_integer" },
            totalTokens: { value: val(readKey(arguments.spanPayload, "totalTokens", 0)), cfsqltype: "cf_sql_integer" },
            inputTokenSource: { value: cleanString(readKey(arguments.spanPayload, "inputTokenSource", "missing"), 40), cfsqltype: "cf_sql_varchar" },
            outputTokenSource: { value: cleanString(readKey(arguments.spanPayload, "outputTokenSource", "missing"), 40), cfsqltype: "cf_sql_varchar" },
            totalTokenSource: { value: cleanString(readKey(arguments.spanPayload, "totalTokenSource", "missing"), 40), cfsqltype: "cf_sql_varchar" },
            estimatedCost: decimalParam(readKey(arguments.spanPayload, "estimatedCost", 0)),
            costSource: { value: cleanString(readKey(arguments.spanPayload, "costSource", ""), 80), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "costSource", ""), 80)) },
            promptHash: { value: cleanString(readKey(arguments.spanPayload, "promptHash", ""), 80), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "promptHash", ""), 80)) },
            responseHash: { value: cleanString(readKey(arguments.spanPayload, "responseHash", ""), 80), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "responseHash", ""), 80)) },
            promptChars: { value: val(readKey(arguments.spanPayload, "promptChars", 0)), cfsqltype: "cf_sql_integer" },
            responseChars: { value: val(readKey(arguments.spanPayload, "responseChars", 0)), cfsqltype: "cf_sql_integer" },
            requestBytes: { value: val(readKey(arguments.spanPayload, "requestBytes", 0)), cfsqltype: "cf_sql_integer" },
            responseBytes: { value: val(readKey(arguments.spanPayload, "responseBytes", 0)), cfsqltype: "cf_sql_integer" },
            errorType: { value: cleanString(readKey(arguments.spanPayload, "errorType", ""), 200), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "errorType", ""), 200)) },
            errorMessage: { value: cleanString(readKey(arguments.spanPayload, "errorMessage", ""), 2000), cfsqltype: "cf_sql_varchar", null: !len(cleanString(readKey(arguments.spanPayload, "errorMessage", ""), 2000)) },
            metadataJson: { value: metadataJson(metadata), cfsqltype: "cf_sql_longvarchar", null: !len(metadataJson(metadata)) }
        }
    );

    return true;
}

try {
    if (compareNoCase(cgi.request_method, "POST") != 0) {
        sendJson({ ok: false, error: "method_not_allowed", message: "Use POST." }, 405);
    }

    requireTables();
    requestData = getHttpRequestData();
    payload = parseRequestBody();
    authContext = authenticate(requestData.headers, payload);
    spansInserted = 0;
    traceId = "";

    transaction {
        if (structKeyExists(payload, "trace") && isStruct(payload.trace)) {
            traceId = ensureTrace(payload.trace, authContext);
            spans = readKey(payload, "spans", []);
            if (isArray(spans)) {
                for (spanPayload in spans) {
                    if (!isStruct(spanPayload)) {
                        continue;
                    }
                    if (!len(readKey(spanPayload, "traceId", ""))) {
                        spanPayload.traceId = traceId;
                    }
                    if (insertSpan(spanPayload, authContext)) {
                        spansInserted++;
                    }
                }
            }
            updateTraceTotals(traceId);
        } else if (structKeyExists(payload, "span") && isStruct(payload.span)) {
            traceId = ensureMinimalTrace(payload.span, authContext);
            if (insertSpan(payload.span, authContext)) {
                spansInserted++;
            }
            updateTraceTotals(traceId);
        } else {
            sendJson({ ok: false, error: "invalid_payload", message: "Payload must contain trace/spans or span." }, 400);
        }
    }

    sendJson({
        ok: true,
        traceId: traceId,
        spansInserted: spansInserted,
        dashboardUrl: cairoiDashboardUrl(),
        traceUrl: cairoiTraceUrl(traceId)
    });
} catch (any e) {
    sendJson({
        ok: false,
        error: "telemetry_error",
        message: cleanString(e.message, 500),
        detail: structKeyExists(e, "detail") ? cleanString(e.detail, 1000) : ""
    }, structKeyExists(e, "errorCode") && isNumeric(e.errorCode) ? val(e.errorCode) : 500);
}
</cfscript>
