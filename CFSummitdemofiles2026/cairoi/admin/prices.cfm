<cfsetting showdebugoutput="false">
<cfscript>
message = "";
errorMessage = "";

function h(any value = "") {
    return encodeForHTML(toString(arguments.value));
}

function runSql(required string sql, struct params = {}) {
    return application.cairoiDb.execute(arguments.sql, arguments.params);
}

try {
    if (structKeyExists(form, "savePrice")) {
        priceId = val(form.priceId ?: 0);
        provider = lcase(trim(form.provider ?: ""));
        modelName = trim(form.modelName ?: "");
        inputCost = val(form.inputCost ?: 0);
        outputCost = val(form.outputCost ?: 0);
        currency = ucase(trim(form.currency ?: "USD"));
        isActive = structKeyExists(form, "isActive") ? 1 : 0;

        if (!len(provider) || !len(modelName)) {
            throw(type = "CAIROI.Validation", message = "Provider and model name are required.");
        }

        if (priceId > 0) {
            runSql(
                "UPDATE cairoi_model_prices
                SET provider = :provider,
                    model_name = :modelName,
                    input_cost_per_1m = :inputCost,
                    output_cost_per_1m = :outputCost,
                    currency = :currency,
                    is_active = :isActive
                WHERE price_id = :priceId",
                {
                    priceId: { value: priceId, cfsqltype: "cf_sql_integer" },
                    provider: { value: provider, cfsqltype: "cf_sql_varchar" },
                    modelName: { value: modelName, cfsqltype: "cf_sql_varchar" },
                    inputCost: { value: inputCost, cfsqltype: "cf_sql_decimal", scale: 8 },
                    outputCost: { value: outputCost, cfsqltype: "cf_sql_decimal", scale: 8 },
                    currency: { value: currency, cfsqltype: "cf_sql_varchar" },
                    isActive: { value: isActive, cfsqltype: "cf_sql_integer" }
                }
            );
        } else {
            runSql(
                "INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency, is_active)
                VALUES (:provider, :modelName, :inputCost, :outputCost, :currency, :isActive)",
                {
                    provider: { value: provider, cfsqltype: "cf_sql_varchar" },
                    modelName: { value: modelName, cfsqltype: "cf_sql_varchar" },
                    inputCost: { value: inputCost, cfsqltype: "cf_sql_decimal", scale: 8 },
                    outputCost: { value: outputCost, cfsqltype: "cf_sql_decimal", scale: 8 },
                    currency: { value: currency, cfsqltype: "cf_sql_varchar" },
                    isActive: { value: isActive, cfsqltype: "cf_sql_integer" }
                }
            );
        }
        message = "Price saved.";
    }

    prices = runSql("SELECT price_id, provider, model_name, input_cost_per_1m, output_cost_per_1m, currency, is_active, effective_start, effective_end FROM cairoi_model_prices ORDER BY provider, model_name, effective_start DESC");
} catch (any e) {
    prices = queryNew("price_id,provider,model_name,input_cost_per_1m,output_cost_per_1m,currency,is_active,effective_start,effective_end");
    errorMessage = e.message;
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Prices</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>Model Prices</h1>
            <p>Edit local model prices used by CAIROI cost estimates.</p>
        </div>
        <nav class="nav">
            <a href="index.cfm">Admin</a>
            <a href="setup.cfm">Setup</a>
            <a href="../dashboard/index.cfm">Dashboard</a>
        </nav>
    </div>

    <cfif len(message)><div class="status ok"><cfoutput>#h(message)#</cfoutput></div></cfif>
    <cfif len(errorMessage)><div class="status error"><cfoutput>#h(errorMessage)#</cfoutput> <a href="setup.cfm">Run setup</a>.</div></cfif>

    <section class="panel">
        <h2>Add Price</h2>
        <form method="post">
            <input type="hidden" name="priceId" value="0">
            <div class="form-grid">
                <div><label for="provider">Provider</label><input id="provider" name="provider" required placeholder="openai"></div>
                <div><label for="modelName">Model</label><input id="modelName" name="modelName" required placeholder="gpt-5-nano"></div>
                <div><label for="inputCost">Input $ / 1M</label><input id="inputCost" name="inputCost" type="number" step="0.00000001" value="0"></div>
                <div><label for="outputCost">Output $ / 1M</label><input id="outputCost" name="outputCost" type="number" step="0.00000001" value="0"></div>
                <div><label for="currency">Currency</label><input id="currency" name="currency" value="USD"></div>
                <div><label><input name="isActive" type="checkbox" checked style="width:auto"> Active</label></div>
            </div>
            <p><button class="primary" name="savePrice" value="1" type="submit">Add Price</button></p>
        </form>
    </section>

    <section class="panel">
        <h2>Current Prices</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Provider</th><th>Model</th><th>Input</th><th>Output</th><th>Currency</th><th>Active</th><th>Save</th></tr></thead>
                <tbody>
                    <cfoutput query="prices">
                        <tr>
                            <form method="post">
                                <td>#price_id#<input type="hidden" name="priceId" value="#price_id#"></td>
                                <td><input name="provider" value="#h(provider)#"></td>
                                <td><input name="modelName" value="#h(model_name)#"></td>
                                <td><input name="inputCost" type="number" step="0.00000001" value="#numberFormat(input_cost_per_1m, '0.00000000')#"></td>
                                <td><input name="outputCost" type="number" step="0.00000001" value="#numberFormat(output_cost_per_1m, '0.00000000')#"></td>
                                <td><input name="currency" value="#h(currency)#"></td>
                                <td><input name="isActive" type="checkbox" #is_active ? 'checked' : ''#></td>
                                <td><button name="savePrice" value="1" type="submit">Save</button></td>
                            </form>
                        </tr>
                    </cfoutput>
                </tbody>
            </table>
        </div>
    </section>
</main>
</body>
</html>
