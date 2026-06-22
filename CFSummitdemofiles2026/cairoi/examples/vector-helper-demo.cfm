<cfsetting showdebugoutput="false" requesttimeout="60">
<cfscript>
message = "";
errorMessage = "";
traceId = "";

function h(any value = "") {
    return encodeForHTML(toString(arguments.value));
}

function collectorUrl() {
    var scheme = structKeyExists(cgi, "https") && compareNoCase(cgi.https, "on") == 0 ? "https" : "http";
    var path = replace(cgi.script_name, "/examples/vector-helper-demo.cfm", "/api/telemetry.cfm", "one");
    return scheme & "://" & cgi.http_host & path;
}

if (structKeyExists(form, "runDemo")) {
    try {
        cairoi = new cairoi.sdk.Cairoi({
            appId: "demo-app",
            environment: "dev",
            collectorUrl: collectorUrl(),
            apiKey: application.cairoiDevApiKey,
            failSilently: true
        });

        trace = cairoi.startTrace(
            workflowName = "mock_vector_workflow",
            metadata = { route: cgi.script_name, demo: "vector-helper-demo" }
        );

        addSpan = trace.startSpan("vector.add_batch", "Mock vector addAll", "", {
            collectionName: "demo-vector-collection",
            itemCount: 12,
            sourceDocumentCount: 2,
            rawDocumentsStored: false
        });
        sleep(90);
        addSpan.finish({ status: "success", requestBytes: 2048, responseBytes: 128 });

        searchSpan = trace.startSpan("vector.search", "Mock vector search", "", {
            collectionName: "demo-vector-collection",
            topK: 5,
            minScore: 0.2,
            hasMetadataFilter: true,
            resultCount: 4,
            queryHash: cairoi.getHashUtil().hashNullable("demo vector query"),
            queryChars: len("demo vector query")
        });
        sleep(65);
        searchSpan.finish({ status: "success", requestBytes: 72, responseBytes: 900 });

        trace.finish(status = "success");
        traceId = trace.getTraceId();
        message = "Mock vector trace recorded.";
    } catch (any e) {
        errorMessage = e.message & (structKeyExists(e, "detail") && len(e.detail) ? " " & e.detail : "");
    }
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Vector Helper Demo</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>Vector Helper Demo</h1>
            <p>Records vector add/search telemetry shape without a live vector store.</p>
        </div>
        <nav class="nav">
            <a href="../dashboard/index.cfm">Dashboard</a>
            <a href="rag-demo.cfm">RAG Demo</a>
        </nav>
    </div>

    <cfif len(message)><div class="status ok"><cfoutput>#h(message)#</cfoutput></div></cfif>
    <cfif len(errorMessage)><div class="status error"><cfoutput>#h(errorMessage)#</cfoutput></div></cfif>

    <section class="panel">
        <h2>Run Mock Vector Workflow</h2>
        <form method="post">
            <button class="primary" name="runDemo" value="1" type="submit">Record Vector Trace</button>
        </form>
    </section>

    <cfif len(traceId)>
        <section class="panel">
            <h2>Trace</h2>
            <p><a class="button primary" href="../dashboard/trace.cfm?traceId=<cfoutput>#urlEncodedFormat(traceId)#</cfoutput>">Open Trace Detail</a></p>
        </section>
    </cfif>
</main>
</body>
</html>
