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
    if (structKeyExists(form, "saveApp")) {
        appId = trim(form.appId ?: "");
        appName = trim(form.appName ?: "");
        ownerName = trim(form.ownerName ?: "");
        environment = trim(form.environment ?: "dev");

        if (!len(appId) || !len(appName)) {
            throw(type = "CAIROI.Validation", message = "App ID and app name are required.");
        }

        existing = runSql(
            "SELECT COUNT(*) AS item_count FROM cairoi_applications WHERE app_id = :appId",
            { appId: { value: appId, cfsqltype: "cf_sql_varchar" } }
        );
        if (val(existing.item_count[1])) {
            runSql(
                "UPDATE cairoi_applications
                SET app_name = :appName, owner_name = :ownerName, environment = :environment, is_active = 1
                WHERE app_id = :appId",
                {
                    appId: { value: appId, cfsqltype: "cf_sql_varchar" },
                    appName: { value: appName, cfsqltype: "cf_sql_varchar" },
                    ownerName: { value: ownerName, cfsqltype: "cf_sql_varchar" },
                    environment: { value: environment, cfsqltype: "cf_sql_varchar" }
                }
            );
        } else {
            runSql(
                "INSERT INTO cairoi_applications (app_id, app_name, owner_name, environment, is_active)
                VALUES (:appId, :appName, :ownerName, :environment, 1)",
                {
                    appId: { value: appId, cfsqltype: "cf_sql_varchar" },
                    appName: { value: appName, cfsqltype: "cf_sql_varchar" },
                    ownerName: { value: ownerName, cfsqltype: "cf_sql_varchar" },
                    environment: { value: environment, cfsqltype: "cf_sql_varchar" }
                }
            );
        }
        message = "Application saved.";
    }

    if (structKeyExists(form, "toggleApp")) {
        runSql(
            "UPDATE cairoi_applications SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END WHERE app_id = :appId",
            { appId: { value: trim(form.appId ?: ""), cfsqltype: "cf_sql_varchar" } }
        );
        message = "Application status updated.";
    }

    apps = runSql("SELECT app_id, app_name, owner_name, environment, is_active, created_at FROM cairoi_applications ORDER BY app_id");
} catch (any e) {
    apps = queryNew("app_id,app_name,owner_name,environment,is_active,created_at");
    errorMessage = e.message;
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Applications</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>Applications</h1>
            <p>Register apps that submit CAIROI telemetry.</p>
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
        <h2>Add Or Update Application</h2>
        <form method="post">
            <div class="form-grid">
                <div><label for="appId">App ID</label><input id="appId" name="appId" required placeholder="donut-demo"></div>
                <div><label for="appName">App Name</label><input id="appName" name="appName" required placeholder="Donut RAG Demo"></div>
                <div><label for="ownerName">Owner</label><input id="ownerName" name="ownerName" placeholder="Team or person"></div>
                <div><label for="environment">Environment</label><input id="environment" name="environment" value="dev"></div>
            </div>
            <p><button class="primary" name="saveApp" value="1" type="submit">Save Application</button></p>
        </form>
    </section>

    <section class="panel">
        <h2>Registered Applications</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>App ID</th><th>Name</th><th>Owner</th><th>Environment</th><th>Active</th><th></th></tr></thead>
                <tbody>
                    <cfoutput query="apps">
                        <tr>
                            <td>#h(app_id)#</td>
                            <td>#h(app_name)#</td>
                            <td>#h(owner_name)#</td>
                            <td>#h(environment)#</td>
                            <td><span class="pill#is_active ? '' : ' error'#">#is_active ? 'active' : 'inactive'#</span></td>
                            <td>
                                <form method="post">
                                    <input type="hidden" name="appId" value="#h(app_id)#">
                                    <button name="toggleApp" value="1" type="submit">Toggle</button>
                                </form>
                            </td>
                        </tr>
                    </cfoutput>
                </tbody>
            </table>
        </div>
    </section>
</main>
</body>
</html>
