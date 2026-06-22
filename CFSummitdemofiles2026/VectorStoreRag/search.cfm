<cfscript>
ready = len(trim(application.openAiApiKey)) > 0 && application.ingestStatus.ready;
currentSource = application.ingestStatus.sourceName;
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Ask The Bot - Glaze Against The Machine</title>
    <link rel="stylesheet" href="assets/app.css">
    <link rel="stylesheet" href="../assets/demo-window.css">
</head>
<body class="demo-windowed-scroll">
    <div class="demo-windowbar">
        <a class="demo-windowbar-back" href="/CFSummit2026/demos/" aria-label="Back to demo home">Back to home</a>
        <span class="demo-windowbar-title">CF2025 AI Demo</span>
        <span class="demo-windowbar-name">Glaze Against The Machine</span>
    </div>
    <header class="header">
        <div class="header-top">
            <a class="logo logo-image-lockup" href="index.cfm" aria-label="Glaze Against The Machine home">
                <img class="header-logo-image" src="img/gatm_rect_logo.png" alt="">
                <span class="logo-badge">CF AI</span>
            </a>
            <nav class="nav" aria-label="Main navigation">
                <a href="index.cfm">Home</a>
                <a href="bootstrap.cfm">Stock The Case</a>
                <a class="active" href="search.cfm">Ask The Bot</a>
            </nav>
        </div>
    </header>

    <main class="shell panel-stack">
        <section class="card">
            <p class="eyebrow">Step 2</p>
            <h1>Chat with the glaze case.</h1>
            <p>
                Each question is embedded, matched against the in-memory vector store, and sent to ChatGPT
                with the retrieved menu chunks as grounding context.
            </p>
            <cfoutput>
                <p class="menu-banner">
                    Current vector menu: <strong>#encodeForHTML(currentSource)#</strong>
                </p>
            </cfoutput>
            <form id="searchForm" class="search-box">
                <input
                    id="questionInput"
                    class="search-input"
                    name="question"
                    type="search"
                    placeholder="Try: What would you recommend for someone who likes chocolate?"
                    autocomplete="off"
                    <cfif !ready>disabled</cfif>
                >
                <button class="button" type="submit" <cfif !ready>disabled</cfif>>Ask</button>
            </form>
            <cfif !ready>
                <p class="muted" style="margin-top: 14px;">
                    Ask The Bot is not ready yet. Add the API key to the keystore as <code>openaiapi_donuts</code>,
                    <a href="search.cfm?reloadApp=1">reload application state</a>, then Stock The Case.
                </p>
            </cfif>
            <div class="actions">
                <button class="button secondary quick-question" type="button">Which options are vegan?</button>
                <button class="button secondary quick-question" type="button">What would pair well with coffee?</button>
                <button class="button secondary quick-question" type="button">Which options contain tree nuts?</button>
                <button class="button secondary quick-question" type="button">What would you recommend for someone who likes chocolate?</button>
            </div>
        </section>

        <section class="hero">
            <div class="card">
                <p class="eyebrow">Answer</p>
                <div id="answer" class="answer muted">Ask a question to see a grounded answer.</div>
            </div>

            <aside class="card">
                <p class="eyebrow">Retrieved chunks</p>
                <div id="sources" class="source-list">
                    <div class="source-card">
                        <div class="source-text muted">Top vector matches will appear here with score and metadata.</div>
                    </div>
                </div>
            </aside>
        </section>
    </main>

    <script src="assets/app.js"></script>
</body>
</html>
