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
    var path = replace(cgi.script_name, "/examples/rag-demo.cfm", "/api/telemetry.cfm", "one");
    return scheme & "://" & cgi.http_host & path;
}

function currentSessionId() {
    if (structKeyExists(session, "sessionId")) {
        return session.sessionId;
    }
    if (structKeyExists(session, "cfid") && structKeyExists(session, "cftoken")) {
        return session.cfid & "-" & session.cftoken;
    }
    return "";
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
            workflowName = "mock_rag_question",
            userId = "rag-demo-user",
            sessionId = currentSessionId(),
            metadata = { route: cgi.script_name, demo: "rag-demo" }
        );

        rag = cairoi.createRAG({ collectionName: "demo-rag-collection" });
        rag.recordRetrieve(trace, {
            collectionName: "demo-rag-collection",
            topK: 5,
            minScore: 0.15,
            resultCount: 3
        });

        vectorSpan = trace.startSpan("vector.search", "Mock vector search", "", {
            collectionName: "demo-rag-collection",
            topK: 5,
            minScore: 0.15,
            resultCount: 3,
            queryHash: cairoi.getHashUtil().hashNullable("What donuts are safe for robots?"),
            queryChars: len("What donuts are safe for robots?")
        });
        sleep(90);
        vectorSpan.finish({ status: "success", responseBytes: 768 });

        rag.recordContextAssembly(trace, {
            sourceCount: 3,
            contextChars: 1200,
            chunkTextStored: false
        });

        rag.recordGeneration(
            trace = trace,
            prompt = "Question plus private RAG context placeholder",
            response = "Mock grounded answer placeholder",
            provider = "openai",
            modelName = "gpt-4o-mini",
            metadata = { answerMode: "mocked" }
        );

        trace.finish(status = "success");
        traceId = trace.getTraceId();
        message = "Mock RAG trace recorded.";
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
    <title>CAIROI RAG Demo</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>RAG Trace Demo</h1>
            <p>Records a privacy-safe mocked RAG workflow shape.</p>
        </div>
        <nav class="nav">
            <a href="../dashboard/index.cfm">Dashboard</a>
            <a href="mcp-demo.cfm">MCP Demo</a>
        </nav>
    </div>

    <cfif len(message)><div class="status ok"><cfoutput>#h(message)#</cfoutput></div></cfif>
    <cfif len(errorMessage)><div class="status error"><cfoutput>#h(errorMessage)#</cfoutput></div></cfif>

    <section class="panel">
        <h2>Run Mock RAG Workflow</h2>
        <p class="muted">Creates spans for retrieval, vector search, context assembly, and generation. No source chunk text is stored.</p>
        <form method="post">
            <button class="primary" name="runDemo" value="1" type="submit">Record RAG Trace</button>
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
