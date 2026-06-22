<cfsetting showdebugoutput="false" requesttimeout="120">
<cfscript>
prompt = form.prompt ?: "Explain ColdFusion AI tracking in one sentence.";
provider = lcase(trim(form.provider ?: "openai"));
modelName = trim(form.modelName ?: "gpt-5-nano");
baseUrl = trim(form.baseUrl ?: "");
apiKey = trim(form.apiKey ?: "");
temperature = val(form.temperature ?: 0.2);
answer = "";
traceId = "";
message = "";
errorMessage = "";

function h(any value = "") {
    return encodeForHTML(toString(arguments.value));
}

function collectorUrl() {
    var scheme = structKeyExists(cgi, "https") && compareNoCase(cgi.https, "on") == 0 ? "https" : "http";
    var path = replace(cgi.script_name, "/examples/simple-chat.cfm", "/api/telemetry.cfm", "one");
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

function responseText(required any response) {
    if (isSimpleValue(arguments.response)) {
        return toString(arguments.response);
    }
    for (var key in ["message", "content", "text", "answer", "response"]) {
        if (isStruct(arguments.response)) {
            for (var candidate in structKeyArray(arguments.response)) {
                if (compareNoCase(candidate, key) == 0 && isSimpleValue(arguments.response[candidate])) {
                    return toString(arguments.response[candidate]);
                }
            }
        }
    }
    return serializeJSON(arguments.response);
}

if (structKeyExists(form, "runChat")) {
    try {
        if (provider != "ollama" && !len(apiKey)) {
            throw(type = "CAIROI.MissingProviderKey", message = "Enter a provider API key or switch provider to ollama with a local base URL.");
        }

        chatConfig = {
            provider: provider,
            modelName: modelName,
            temperature: temperature
        };
        if (len(apiKey)) {
            chatConfig.apiKey = apiKey;
        }
        if (len(baseUrl)) {
            chatConfig.baseUrl = baseUrl;
        }

        cairoi = new cairoi.sdk.Cairoi({
            appId: "demo-app",
            environment: "dev",
            collectorUrl: collectorUrl(),
            apiKey: application.cairoiDevApiKey,
            failSilently: true,
            debug: true,
            defaultProvider: provider,
            defaultModelName: modelName
        });

        trace = cairoi.startTrace(
            workflowName = "simple_chat",
            userId = "simple-chat-user",
            sessionId = currentSessionId(),
            metadata = { route: cgi.script_name, demo: "simple-chat" }
        );

        chat = cairoi.createChatModel(chatConfig);
        response = chat.chat(prompt = prompt, trace = trace, metadata = { feature: "simple-chat-form" });
        answer = responseText(response);
        trace.finish(status = "success");
        traceId = trace.getTraceId();
        message = "Chat completed and telemetry was submitted.";
    } catch (any e) {
        errorMessage = e.message & (structKeyExists(e, "detail") && len(e.detail) ? " " & e.detail : "");
        try {
            if (isDefined("trace") && isObject(trace)) {
                trace.finish(status = "error", metadata = { failure: "simple-chat" });
                traceId = trace.getTraceId();
            }
        } catch (any ignored) {
        }
    }
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Simple Chat Demo</title>
    <link rel="stylesheet" href="../dashboard/assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>Simple Chat Demo</h1>
            <p>Tracked `ChatModel().chat()` usage with privacy-safe telemetry.</p>
        </div>
        <nav class="nav">
            <a href="../admin/setup.cfm">Setup</a>
            <a href="../dashboard/index.cfm">Dashboard</a>
        </nav>
    </div>

    <cfif len(message)><div class="status ok"><cfoutput>#h(message)#</cfoutput></div></cfif>
    <cfif len(errorMessage)><div class="status error"><cfoutput>#h(errorMessage)#</cfoutput></div></cfif>

    <section class="panel">
        <h2>Provider Configuration</h2>
        <p class="muted">API keys entered here are used for this request only and are not stored by CAIROI.</p>
        <form method="post">
            <div class="form-grid">
                <div>
                    <label for="provider">Provider</label>
                    <select id="provider" name="provider">
                        <cfoutput>
                        <option value="openai" #provider == 'openai' ? 'selected' : ''#>OpenAI</option>
                        <option value="anthropic" #provider == 'anthropic' ? 'selected' : ''#>Anthropic</option>
                        <option value="mistral" #provider == 'mistral' ? 'selected' : ''#>Mistral</option>
                        <option value="gemini" #provider == 'gemini' ? 'selected' : ''#>Gemini</option>
                        <option value="ollama" #provider == 'ollama' ? 'selected' : ''#>Ollama</option>
                        </cfoutput>
                    </select>
                </div>
                <div><label for="modelName">Model Name</label><input id="modelName" name="modelName" value="<cfoutput>#h(modelName)#</cfoutput>"></div>
                <div><label for="apiKey">Provider API Key</label><input id="apiKey" name="apiKey" type="password" autocomplete="off" placeholder="Not stored"></div>
                <div><label for="baseUrl">Base URL</label><input id="baseUrl" name="baseUrl" value="<cfoutput>#h(baseUrl)#</cfoutput>" placeholder="Optional; useful for Ollama"></div>
                <div><label for="temperature">Temperature</label><input id="temperature" name="temperature" type="number" step="0.1" value="<cfoutput>#temperature#</cfoutput>"></div>
            </div>
            <p><label for="prompt">Prompt</label><textarea id="prompt" name="prompt"><cfoutput>#h(prompt)#</cfoutput></textarea></p>
            <button class="primary" name="runChat" value="1" type="submit">Send Tracked Chat</button>
        </form>
    </section>

    <cfif len(answer)>
        <section class="panel">
            <h2>Response</h2>
            <p><cfoutput>#h(answer)#</cfoutput></p>
        </section>
    </cfif>

    <cfif len(traceId)>
        <section class="panel">
            <h2>Trace</h2>
            <p><a class="button primary" href="../dashboard/trace.cfm?traceId=<cfoutput>#urlEncodedFormat(traceId)#</cfoutput>">Open Trace Detail</a></p>
        </section>
    </cfif>
</main>
</body>
</html>
