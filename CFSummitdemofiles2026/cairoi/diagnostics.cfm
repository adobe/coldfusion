<cfsetting showdebugoutput="false" requesttimeout="60">
<cfscript>
diagnosticToken = "cairoi-diagnostics-2026";
showDetails = structKeyExists(url, "token") && url.token == diagnosticToken;
pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
appRoot = getDirectoryFromPath(getCurrentTemplatePath());
dataRoot = appRoot & "data" & pathSep;
dbParentPath = dataRoot & "derby" & pathSep;
databasePath = dbParentPath & "cairoi";
results = [];

function addResult(required string name, required boolean ok, string message = "", any details = "") {
    arrayAppend(results, {
        name: arguments.name,
        ok: arguments.ok,
        message: sanitizeDiagText(arguments.message, 1000),
        details: arguments.details
    });
}

function exceptionDetails(required any e) {
    var detail = {
        type: structKeyExists(arguments.e, "type") ? sanitizeDiagText(arguments.e.type, 500) : "",
        message: structKeyExists(arguments.e, "message") ? sanitizeDiagText(arguments.e.message, 1000) : "",
        detail: structKeyExists(arguments.e, "detail") ? sanitizeDiagText(arguments.e.detail, 2000) : "",
        tagContext: []
    };

    if (structKeyExists(arguments.e, "tagContext") && isArray(arguments.e.tagContext)) {
        for (var item in arguments.e.tagContext) {
            arrayAppend(detail.tagContext, {
                template: structKeyExists(item, "template") ? sanitizeDiagText(item.template, 500) : "",
                line: structKeyExists(item, "line") ? item.line : "",
                column: structKeyExists(item, "column") ? item.column : ""
            });
            if (arrayLen(detail.tagContext) >= 10) {
                break;
            }
        }
    }

    return detail;
}

function sanitizeDiagText(required string value, numeric maxLength = 1000) {
    var text = replace(arguments.value, chr(13), " ", "all");
    text = replace(text, chr(10), " ", "all");
    text = rereplace(text, "(?i)(authorization|api[-_ ]?key|bearer|token|password|secret)([=: ]+)[^&\s<,}]+", "\1\2[redacted]", "all");
    if (len(text) > arguments.maxLength) {
        text = left(text, arguments.maxLength) & "...";
    }
    return text;
}

function escapeDiagHtml(required string value) {
    var text = replace(arguments.value, "&", "&amp;", "all");
    text = replace(text, "<", "&lt;", "all");
    text = replace(text, ">", "&gt;", "all");
    text = replace(text, chr(34), "&quot;", "all");
    text = replace(text, chr(39), "&##39;", "all");
    return text;
}

function runStep(required string name, required any callback) {
    try {
        var data = arguments.callback();
        addResult(arguments.name, true, "OK", isNull(data) ? "" : data);
    } catch (any e) {
        addResult(arguments.name, false, e.message, exceptionDetails(e));
    }
}

runStep("Request reached diagnostics.cfm", function() {
    return {
        scriptName: cgi.script_name,
        requestMethod: cgi.request_method,
        httpHost: structKeyExists(cgi, "http_host") ? cgi.http_host : "",
        currentTemplatePath: getCurrentTemplatePath()
    };
});

runStep("Application paths", function() {
    return {
        appRoot: appRoot,
        dataRoot: dataRoot,
        dbParentPath: dbParentPath,
        databasePath: databasePath,
        appRootExists: directoryExists(appRoot),
        dataRootExists: directoryExists(dataRoot),
        dbParentPathExists: directoryExists(dbParentPath)
    };
});

runStep("Create data directories", function() {
    if (!directoryExists(dataRoot)) {
        directoryCreate(dataRoot, true, true);
    }
    if (!directoryExists(dbParentPath)) {
        directoryCreate(dbParentPath, true, true);
    }
    return {
        dataRootExists: directoryExists(dataRoot),
        dbParentPathExists: directoryExists(dbParentPath)
    };
});

runStep("Write permission", function() {
    var filePath = dataRoot & "diagnostic-write-test-" & replace(createUUID(), "-", "", "all") & ".txt";
    fileWrite(filePath, "CAIROI diagnostic write test " & now(), "utf-8");
    var readBack = fileRead(filePath, "utf-8");
    try {
        fileDelete(filePath);
    } catch (any cleanupError) {
    }
    return {
        testFile: filePath,
        bytesWritten: len(readBack)
    };
});

runStep("ColdFusion server info", function() {
    return {
        productName: structKeyExists(server, "coldfusion") && structKeyExists(server.coldfusion, "productName") ? server.coldfusion.productName : "",
        productVersion: structKeyExists(server, "coldfusion") && structKeyExists(server.coldfusion, "productVersion") ? server.coldfusion.productVersion : "",
        osName: structKeyExists(server, "os") && structKeyExists(server.os, "name") ? server.os.name : "",
        javaVersion: createObject("java", "java.lang.System").getProperty("java.version")
    };
});

runStep("Derby driver available", function() {
    createObject("java", "org.apache.derby.jdbc.EmbeddedDriver");
    return { driver: "org.apache.derby.jdbc.EmbeddedDriver" };
});

runStep("CAIROI component mapping", function() {
    var store = new cairoi.db.DerbyStore({
        appRoot: appRoot,
        dataRoot: dataRoot,
        dbParentPath: dbParentPath,
        databasePath: databasePath
    });
    return store.getConfig();
});

runStep("Derby bootstrap", function() {
    var store = new cairoi.db.DerbyStore({
        appRoot: appRoot,
        dataRoot: dataRoot,
        dbParentPath: dbParentPath,
        databasePath: databasePath
    });
    return store.bootstrap();
});

runStep("Derby query", function() {
    var store = new cairoi.db.DerbyStore({
        appRoot: appRoot,
        dataRoot: dataRoot,
        dbParentPath: dbParentPath,
        databasePath: databasePath
    });
    var q = store.execute("SELECT COUNT(*) AS item_count FROM cairoi_applications");
    return {
        applicationCount: q.recordCount ? q.item_count[1] : 0
    };
});

payload = {
    ok: arrayEvery(results, function(item) { return item.ok; }),
    generatedAt: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
    diagnosticsVisible: showDetails,
    detailUrl: cgi.script_name & "?token=" & diagnosticToken,
    results: results
};

if (structKeyExists(url, "format") && lcase(url.format) == "json") {
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(showDetails ? payload : {
        ok: payload.ok,
        generatedAt: payload.generatedAt,
        diagnosticsVisible: false,
        detailUrl: payload.detailUrl,
        message: "Add the diagnostic token to view details."
    }));
    abort;
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>CAIROI Diagnostics</title>
    <style>
        body { color: #18212f; font-family: Arial, sans-serif; line-height: 1.4; margin: 32px; }
        h1 { margin-bottom: 4px; }
        table { border-collapse: collapse; margin-top: 20px; width: 100%; }
        th, td { border: 1px solid #d7dde5; padding: 10px; text-align: left; vertical-align: top; }
        th { background: #f4f6f8; }
        .ok { color: #137333; font-weight: 700; }
        .fail { color: #b3261e; font-weight: 700; }
        code, pre { background: #f4f6f8; border: 1px solid #d7dde5; border-radius: 6px; display: block; padding: 12px; white-space: pre-wrap; }
        .muted { color: #5f6b7a; }
    </style>
</head>
<body>
    <h1>CAIROI Diagnostics</h1>
    <p class="muted">Temporary diagnostic helper. Remove or protect this file after troubleshooting.</p>

    <cfif !showDetails>
        <p>Add the diagnostic token to show details:</p>
        <code><cfoutput>#escapeDiagHtml(cgi.script_name)#?token=#escapeDiagHtml(diagnosticToken)#</cfoutput></code>
    <cfelse>
        <table>
            <thead>
                <tr>
                    <th>Check</th>
                    <th>Status</th>
                    <th>Message</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput>
                <cfloop array="#results#" index="item">
                    <tr>
                        <td>#escapeDiagHtml(item.name)#</td>
                        <td><span class="#item.ok ? 'ok' : 'fail'#">#item.ok ? 'OK' : 'FAIL'#</span></td>
                        <td>#escapeDiagHtml(item.message)#</td>
                        <td><pre>#escapeDiagHtml(serializeJSON(item.details))#</pre></td>
                    </tr>
                </cfloop>
                </cfoutput>
            </tbody>
        </table>

        <h2>Raw JSON</h2>
        <pre><cfoutput>#escapeDiagHtml(serializeJSON(payload))#</cfoutput></pre>
    </cfif>
</body>
</html>
