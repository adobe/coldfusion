<cfsetting showdebugoutput="false" requesttimeout="180">
<cfscript>
messages = [];
errors = [];
requiredTables = [
    "cairoi_applications",
    "cairoi_api_keys",
    "cairoi_traces",
    "cairoi_spans",
    "cairoi_model_prices"
];

function h(any value = "") {
    return encodeForHTML(toString(arguments.value));
}

function runSql(required string sql, struct params = {}) {
    return application.cairoiDb.execute(arguments.sql, arguments.params);
}

function tableExists(required string tableName) {
    return application.cairoiDb.tableExists(arguments.tableName);
}

function collectStatus() {
    var status = [];
    for (var tableName in requiredTables) {
        arrayAppend(status, { name: tableName, exists: tableExists(tableName) });
    }
    return status;
}

function createTables() {
    return application.cairoiDb.bootstrap();
}

function seedData() {
    var exists = runSql(
        "SELECT COUNT(*) AS item_count FROM cairoi_applications WHERE app_id = :appId",
        { appId: { value: "demo-app", cfsqltype: "cf_sql_varchar" } }
    );
    if (!val(exists.item_count[1])) {
        runSql(
            "INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
            VALUES (:appId, :appName, :ownerName, :environment, 1)",
            {
                appId: { value: "demo-app", cfsqltype: "cf_sql_varchar" },
                appName: { value: "CAIROI Demo App", cfsqltype: "cf_sql_varchar" },
                ownerName: { value: "Local Developer", cfsqltype: "cf_sql_varchar" },
                environment: { value: "dev", cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    exists = runSql(
        "SELECT COUNT(*) AS item_count FROM cairoi_api_keys WHERE api_key_hash = :apiKeyHash",
        { apiKeyHash: { value: application.cairoiDevApiKeyHash, cfsqltype: "cf_sql_varchar" } }
    );
    if (!val(exists.item_count[1])) {
        runSql(
            "INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
            VALUES (:appId, :apiKeyHash, :apiKeyPreview, 1)",
            {
                appId: { value: "demo-app", cfsqltype: "cf_sql_varchar" },
                apiKeyHash: { value: application.cairoiDevApiKeyHash, cfsqltype: "cf_sql_varchar" },
                apiKeyPreview: { value: "cairoi-dev...", cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    exists = runSql(
        "SELECT COUNT(*) AS item_count FROM cairoi_applications WHERE app_id = :appId",
        { appId: { value: "inventory-ai", cfsqltype: "cf_sql_varchar" } }
    );
    if (!val(exists.item_count[1])) {
        runSql(
            "INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
            VALUES (:appId, :appName, :ownerName, :environment, 1)",
            {
                appId: { value: "inventory-ai", cfsqltype: "cf_sql_varchar" },
                appName: { value: "InventoryAI MCP Demo", cfsqltype: "cf_sql_varchar" },
                ownerName: { value: "CFSummit 2026 Demos", cfsqltype: "cf_sql_varchar" },
                environment: { value: "dev", cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    exists = runSql(
        "SELECT COUNT(*) AS item_count FROM cairoi_api_keys WHERE api_key_hash = :apiKeyHash",
        { apiKeyHash: { value: application.cairoiInventoryDevApiKeyHash, cfsqltype: "cf_sql_varchar" } }
    );
    if (!val(exists.item_count[1])) {
        runSql(
            "INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
            VALUES (:appId, :apiKeyHash, :apiKeyPreview, 1)",
            {
                appId: { value: "inventory-ai", cfsqltype: "cf_sql_varchar" },
                apiKeyHash: { value: application.cairoiInventoryDevApiKeyHash, cfsqltype: "cf_sql_varchar" },
                apiKeyPreview: { value: "cairoi-inventory...", cfsqltype: "cf_sql_varchar" }
            }
        );
    }

    var conferenceDemos = [
        {
            appId: "cfcase",
            appName: "CF Cases Mystery Demo",
            ownerName: "CFSummit 2026 Demos",
            environment: "conference",
            apiKey: "cairoi-cfcase-dev-key",
            apiKeyPreview: "cairoi-cfcase..."
        },
        {
            appId: "onboardiq",
            appName: "OnboardIQ RAG Guardrail Demo",
            ownerName: "CFSummit 2026 Demos",
            environment: "conference",
            apiKey: "cairoi-onboardiq-dev-key",
            apiKeyPreview: "cairoi-onboardiq..."
        },
        {
            appId: "donut-rag",
            appName: "Glaze Against The Machine Donut RAG Demo",
            ownerName: "CFSummit 2026 Demos",
            environment: "conference",
            apiKey: "cairoi-donut-rag-dev-key",
            apiKeyPreview: "cairoi-donut-rag..."
        },
        {
            appId: "code-review-local",
            appName: "CodeReview.cf Local Review Demo",
            ownerName: "CFSummit 2026 Demos",
            environment: "conference",
            apiKey: "cairoi-code-review-dev-key",
            apiKeyPreview: "cairoi-code-review..."
        }
    ];

    for (var demo in conferenceDemos) {
        exists = runSql(
            "SELECT COUNT(*) AS item_count FROM cairoi_applications WHERE app_id = :appId",
            { appId: { value: demo.appId, cfsqltype: "cf_sql_varchar" } }
        );
        if (!val(exists.item_count[1])) {
            runSql(
                "INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
                VALUES (:appId, :appName, :ownerName, :environment, 1)",
                {
                    appId: { value: demo.appId, cfsqltype: "cf_sql_varchar" },
                    appName: { value: demo.appName, cfsqltype: "cf_sql_varchar" },
                    ownerName: { value: demo.ownerName, cfsqltype: "cf_sql_varchar" },
                    environment: { value: demo.environment, cfsqltype: "cf_sql_varchar" }
                }
            );
        }

        exists = runSql(
            "SELECT COUNT(*) AS item_count FROM cairoi_api_keys WHERE api_key_hash = :apiKeyHash",
            { apiKeyHash: { value: lcase(hash(demo.apiKey, "SHA-256", "UTF-8")), cfsqltype: "cf_sql_varchar" } }
        );
        if (!val(exists.item_count[1])) {
            runSql(
                "INSERT INTO cairoi_api_keys (app_id, api_key_hash, api_key_preview, is_active)
                VALUES (:appId, :apiKeyHash, :apiKeyPreview, 1)",
                {
                    appId: { value: demo.appId, cfsqltype: "cf_sql_varchar" },
                    apiKeyHash: { value: lcase(hash(demo.apiKey, "SHA-256", "UTF-8")), cfsqltype: "cf_sql_varchar" },
                    apiKeyPreview: { value: demo.apiKeyPreview, cfsqltype: "cf_sql_varchar" }
                }
            );
        }
    }

    var prices = [
        { provider: "openai", model: "gpt-5-nano", input: 0.05, output: 0.40 },
        { provider: "openai", model: "gpt-5-mini", input: 0.25, output: 2.00 },
        { provider: "openai", model: "gpt-4o-mini", input: 0.15, output: 0.60 },
        { provider: "openai", model: "text-embedding-3-small", input: 0.02, output: 0.00 },
        { provider: "anthropic", model: "claude-haiku-4-5-20251001", input: 1.00, output: 5.00 },
        { provider: "ollama", model: "llama3.2", input: 0.00, output: 0.00 },
        { provider: "ollama", model: "nomic-embed-text", input: 0.00, output: 0.00 }
    ];

    runSql(
        "DELETE FROM cairoi_model_prices WHERE provider = :provider AND model_name = :modelName",
        {
            provider: { value: "mock", cfsqltype: "cf_sql_varchar" },
            modelName: { value: "manual-demo", cfsqltype: "cf_sql_varchar" }
        }
    );

    for (var price in prices) {
        exists = runSql(
            "SELECT COUNT(*) AS item_count FROM cairoi_model_prices WHERE provider = :provider AND model_name = :modelName",
            {
                provider: { value: price.provider, cfsqltype: "cf_sql_varchar" },
                modelName: { value: price.model, cfsqltype: "cf_sql_varchar" }
            }
        );
        if (!val(exists.item_count[1])) {
            runSql(
                "INSERT INTO cairoi_model_prices (provider, model_name, input_cost_per_1m, output_cost_per_1m, currency)
                VALUES (:provider, :modelName, :inputCost, :outputCost, 'USD')",
                {
                    provider: { value: price.provider, cfsqltype: "cf_sql_varchar" },
                    modelName: { value: price.model, cfsqltype: "cf_sql_varchar" },
                    inputCost: { value: price.input, cfsqltype: "cf_sql_decimal", scale: 8 },
                    outputCost: { value: price.output, cfsqltype: "cf_sql_decimal", scale: 8 }
                }
            );
        }
    }
}

try {
    dbStatus = application.cairoiDb.bootstrap();

    if (structKeyExists(form, "runSetup")) {
        createTables();
        seedData();
        arrayAppend(messages, "Embedded Derby schema and seed data were checked.");
    }

    tableStatus = collectStatus();
    appCount = tableExists("cairoi_applications") ? runSql("SELECT COUNT(*) AS item_count FROM cairoi_applications").item_count[1] : 0;
    keyCount = tableExists("cairoi_api_keys") ? runSql("SELECT COUNT(*) AS item_count FROM cairoi_api_keys").item_count[1] : 0;
    priceCount = tableExists("cairoi_model_prices") ? runSql("SELECT COUNT(*) AS item_count FROM cairoi_model_prices").item_count[1] : 0;
} catch (any e) {
    tableStatus = [];
    appCount = 0;
    keyCount = 0;
    priceCount = 0;
    arrayAppend(errors, e.message & (structKeyExists(e, "detail") && len(e.detail) ? " " & e.detail : ""));
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Setup</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>CAIROI Setup</h1>
            <p>Initialize the self-contained CAIROI embedded Derby database.</p>
        </div>
        <nav class="nav">
            <a href="index.cfm">Admin</a>
            <a href="../dashboard/index.cfm">Dashboard</a>
        </nav>
    </div>

    <cfloop array="#messages#" index="message">
        <div class="status ok"><cfoutput>#h(message)#</cfoutput></div>
    </cfloop>
    <cfloop array="#errors#" index="errorMessage">
        <div class="status error"><cfoutput>#h(errorMessage)#</cfoutput></div>
    </cfloop>

    <section class="panel">
        <h2>Deployment URLs</h2>
        <p class="muted">Use these URLs after copying the CAIROI folder to the conference collector server.</p>
        <pre><cfoutput>Collector: #h(application.cairoiTelemetryUrl)#
Dashboard: #h(application.cairoiDashboardUrl)#
Health: #h(application.cairoiPublicBaseUrl & "/api/health.cfm")#</cfoutput></pre>
    </section>

    <section class="panel">
        <h2>Setup Status</h2>
        <p class="muted">This page creates missing tables and seeds local development app/key hashes for the conference demos plus starter prices.</p>
        <form method="post">
            <button class="primary" name="runSetup" value="1" type="submit">Run Setup</button>
        </form>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr><th>Table</th><th>Status</th></tr>
                </thead>
                <tbody>
                    <cfoutput>
                    <cfloop array="#tableStatus#" index="row">
                        <tr>
                            <td>#h(row.name)#</td>
                            <td><span class="pill#row.exists ? '' : ' error'#">#row.exists ? 'exists' : 'missing'#</span></td>
                        </tr>
                    </cfloop>
                    </cfoutput>
                </tbody>
            </table>
        </div>
    </section>

    <section class="grid">
        <div class="metric"><span>Applications</span><strong><cfoutput>#appCount#</cfoutput></strong></div>
        <div class="metric"><span>API Keys</span><strong><cfoutput>#keyCount#</cfoutput></strong></div>
        <div class="metric"><span>Model Prices</span><strong><cfoutput>#priceCount#</cfoutput></strong></div>
    </section>

    <section class="panel">
        <h2>Local Development Keys</h2>
        <p>The seeded keys are for local MVP demos only:</p>
        <pre>demo-app: cairoi-dev-key
inventory-ai: cairoi-inventory-dev-key
cfcase: cairoi-cfcase-dev-key
onboardiq: cairoi-onboardiq-dev-key
donut-rag: cairoi-donut-rag-dev-key
code-review-local: cairoi-code-review-dev-key</pre>
        <p class="muted">Only SHA-256 hashes are stored in the database. Replace this approach before production use.</p>
    </section>
</main>
</body>
</html>
