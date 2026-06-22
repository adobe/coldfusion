<cfscript>
function getDataFiles() {
    var dataQuery = directoryList(expandPath("./data"), false, "query", "*.txt*");
    var files = [];

    for (var row in dataQuery) {
        arrayAppend(files, row.name);
    }

    arraySort(files, "textnocase");
    return files;
}

apiKeyReady = len(trim(application.openAiApiKey)) > 0;
dataFiles = getDataFiles();
ingestReady = application.ingestStatus.ready;
selectedSource = structKeyExists(url, "source") ? url.source : "";

if (!arrayFindNoCase(dataFiles, selectedSource) && arrayLen(dataFiles)) {
    selectedSource = ingestReady && arrayFindNoCase(dataFiles, application.ingestStatus.sourceName)
        ? application.ingestStatus.sourceName
        : dataFiles[1];
}

selectedDataFile = expandPath("./data/" & selectedSource);
dataExists = len(selectedSource) && fileExists(selectedDataFile);
ingestedMenuLabel = ingestReady ? application.ingestStatus.sourceName : "No menu ingested";
preview = "";

if (dataExists) {
    preview = fileRead(selectedDataFile, "utf-8");
    preview = left(preview, 1600);
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Stock The Case - Glaze Against The Machine</title>
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
                <a class="active" href="bootstrap.cfm">Stock The Case</a>
                <a href="search.cfm">Ask The Bot</a>
            </nav>
        </div>
    </header>

    <main class="shell panel-stack">
        <section class="card">
            <p class="eyebrow">Step 1: choose the menu</p>
            <h1>Stock the glaze case.</h1>
            <p>
                Choose which donut menu should be loaded into ColdFusion's in-memory vector store.
                Swap between the regular shop catalog and the circuit-safe AI menu to see how RAG changes the bot's answers.
            </p>
            <form class="source-picker" method="get" action="bootstrap.cfm">
                <label for="sourceSelect">Menu data file</label>
                <select id="sourceSelect" name="source">
                    <cfloop array="#dataFiles#" index="dataFileName">
                        <cfoutput>
                            <option value="#encodeForHTMLAttribute(dataFileName)#" <cfif compareNoCase(dataFileName, selectedSource) == 0>selected</cfif>>
                                #encodeForHTML(dataFileName)#
                            </option>
                        </cfoutput>
                    </cfloop>
                </select>
                <button class="button secondary" type="submit">Preview Menu</button>
            </form>
            <cfif !apiKeyReady>
                <p class="muted">
                    Add your API key to the keystore as <code>openaiapi_donuts</code>, then
                    <a href="bootstrap.cfm?reloadApp=1">reload application state</a> before ingesting.
                </p>
            </cfif>
            <div class="actions">
                <button id="ingestBtn" class="button" type="button" data-source="<cfoutput>#encodeForHTMLAttribute(selectedSource)#</cfoutput>" <cfif !apiKeyReady || !dataExists>disabled</cfif>>
                    Ingest Selected Menu
                </button>
                <button id="resetBtn" class="button secondary danger" type="button">
                    Reset All
                </button>
                <a class="button secondary" href="search.cfm">Ask The Bot</a>
            </div>
        </section>

        <section class="hero">
            <div class="card">
                <p class="eyebrow">Current status</p>
                <div class="status-grid" id="statusGrid">
                    <div class="status-row">
                        <span class="status-label">API key</span>
                        <cfoutput><span class="chip #apiKeyReady ? 'ok' : 'bad'#">#apiKeyReady ? 'configured' : 'missing in keystore'#</span></cfoutput>
                    </div>
                    <div class="status-row">
                        <span class="status-label">Ingested</span>
                        <cfoutput><span class="chip #ingestReady ? 'ok' : 'warn'#">#ingestReady ? application.ingestStatus.addedCount & ' chunks' : 'not yet'#</span></cfoutput>
                    </div>
                    <div class="status-row">
                        <span class="status-label">Ingested menu</span>
                        <cfoutput><span class="chip #ingestReady ? 'ok' : 'warn'#">#encodeForHTML(ingestedMenuLabel)#</span></cfoutput>
                    </div>
                    <cfif structKeyExists(application.ingestStatus, "collectionName") && len(application.ingestStatus.collectionName)>
                        <div class="status-row">
                            <span class="status-label">Collection</span>
                            <cfoutput><span class="muted">#encodeForHTML(application.ingestStatus.collectionName)#</span></cfoutput>
                        </div>
                    </cfif>
                    <div class="status-row">
                        <span class="status-label">Last message</span>
                        <cfoutput><span class="muted">#encodeForHTML(application.ingestStatus.message)#</span></cfoutput>
                    </div>
                </div>
            </div>

            <div class="card">
                <p class="eyebrow">Source preview</p>
                <cfif dataExists>
                    <cfoutput><h3>#encodeForHTML(selectedSource)#</h3></cfoutput>
                    <cfoutput><div class="mono-box">#encodeForHTML(preview)#</div></cfoutput>
                <cfelse>
                    <div class="mono-box error">The configured data file was not found.</div>
                </cfif>
            </div>
        </section>
    </main>

    <script src="assets/app.js"></script>
</body>
</html>
