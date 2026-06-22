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
    var path = replace(cgi.script_name, "/examples/mcp-demo.cfm", "/api/telemetry.cfm", "one");
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
            workflowName = "mock_mcp_tool_workflow",
            userId = "mcp-demo-user",
            sessionId = currentSessionId(),
            metadata = { route: cgi.script_name, demo: "mcp-demo" }
        );

        agentSpan = trace.startSpan("agent.chat", "Mock agent tool routing", "", {
            persona: "inventory_assistant",
            toolChoiceVisible: true
        });
        sleep(70);
        agentSpan.finish({
            status: "success",
            provider: "openai",
            modelName: "gpt-4o-mini",
            inputTokens: 250,
            outputTokens: 45,
            totalTokens: 295,
            inputTokenSource: "estimated",
            outputTokenSource: "estimated",
            totalTokenSource: "estimated",
            costSource: "calculated_from_estimated_tokens",
            estimatedCost: cairoi.getCostCalculator().calculate("openai", "gpt-4o-mini", 250, 45).estimatedCost,
            promptText: "mock MCP routing prompt",
            responseText: "mock MCP routing response"
        });

        mcpSpan = trace.startSpan("mcp.call_tool", "Mock MCP callTool", agentSpan.getSpanId(), {
            serverName: "inventory-demo",
            toolName: "getLowStockItems",
            argumentCount: 2,
            argumentKeys: "warehouse,threshold",
            argumentBytes: 42,
            rawArgumentsStored: false
        });
        sleep(80);
        mcpSpan.finish({
            status: "success",
            requestBytes: 42,
            responseBytes: 640
        });

        summarySpan = trace.startSpan("llm.chat", "Mock answer synthesis", agentSpan.getSpanId(), {
            feature: "mcp-summary"
        });
        sleep(60);
        summarySpan.finish({
            status: "success",
            provider: "openai",
            modelName: "gpt-4o-mini",
            inputTokens: 340,
            outputTokens: 85,
            totalTokens: 425,
            inputTokenSource: "estimated",
            outputTokenSource: "estimated",
            totalTokenSource: "estimated",
            costSource: "calculated_from_estimated_tokens",
            estimatedCost: cairoi.getCostCalculator().calculate("openai", "gpt-4o-mini", 340, 85).estimatedCost,
            promptText: "mock MCP summary prompt",
            responseText: "mock MCP summary response"
        });

        trace.finish(status = "success");
        traceId = trace.getTraceId();
        message = "Mock MCP trace recorded.";
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
    <title>CAIROI MCP Demo</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>MCP Trace Demo</h1>
            <p>Records a mocked agent plus MCP tool workflow without storing tool argument values.</p>
        </div>
        <nav class="nav">
            <a href="../dashboard/index.cfm">Dashboard</a>
            <a href="rag-demo.cfm">RAG Demo</a>
        </nav>
    </div>

    <cfif len(message)><div class="status ok"><cfoutput>#h(message)#</cfoutput></div></cfif>
    <cfif len(errorMessage)><div class="status error"><cfoutput>#h(errorMessage)#</cfoutput></div></cfif>

    <section class="panel">
        <h2>Run Mock MCP Workflow</h2>
        <p class="muted">Creates spans for agent routing, MCP tool call, and final LLM synthesis.</p>
        <form method="post">
            <button class="primary" name="runDemo" value="1" type="submit">Record MCP Trace</button>
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
