<cfsetting showdebugoutput="false" requesttimeout="60">
<cfinclude template="_request.cfm">
<cfscript>
cairoiHandleOptions("GET,POST,OPTIONS");

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

try {
    if (compareNoCase(cgi.request_method, "GET") == 0) {
        q = runSql(
            "SELECT price_id, provider, model_name, input_cost_per_1m, output_cost_per_1m, currency,
                effective_start, effective_end, is_active, created_at
            FROM cairoi_model_prices
            ORDER BY provider, model_name, effective_start DESC"
        );
        sendJson({ ok: true, prices: queryToRows(q) });
    }

    payload = {};
    requestData = getHttpRequestData();
    if (len(trim(requestData.content)) && isJSON(requestData.content)) {
        payload = deserializeJSON(requestData.content);
    } else {
        payload = form;
    }

    provider = lcase(cleanString(payload.provider ?: "", 100));
    modelName = cleanString(payload.modelName ?: payload.model_name ?: "", 200);
    if (!len(provider) || !len(modelName)) {
        sendJson({ ok: false, error: "validation", message: "provider and modelName are required." }, 400);
    }

    runSql(
        "INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency, is_active)
        VALUES (:provider, :modelName, :inputCost, :outputCost, :currency, 1)",
        {
            provider: { value: provider, cfsqltype: "cf_sql_varchar" },
            modelName: { value: modelName, cfsqltype: "cf_sql_varchar" },
            inputCost: { value: val(payload.inputCostPer1M ?: payload.input_cost_per_1m ?: 0), cfsqltype: "cf_sql_decimal", scale: 8 },
            outputCost: { value: val(payload.outputCostPer1M ?: payload.output_cost_per_1m ?: 0), cfsqltype: "cf_sql_decimal", scale: 8 },
            currency: { value: ucase(cleanString(payload.currency ?: "USD", 10)), cfsqltype: "cf_sql_varchar" }
        }
    );

    sendJson({ ok: true });
} catch (any e) {
    sendJson({ ok: false, error: "prices_error", message: e.message, detail: e.detail ?: "" }, 500);
}
</cfscript>
