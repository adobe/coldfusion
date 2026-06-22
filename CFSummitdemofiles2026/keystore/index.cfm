<cfsetting showdebugoutput="false">
<cfscript>
service = new keystore.KeystoreService(application.keystoreConfig);
status = service.bootstrap();
storedKeys = service.listKeys();
basePath = replace(getDirectoryFromPath(cgi.script_name), "\", "/", "all");
lookupTemplate = basePath & "api/key.cfm?id={keyId}";
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CFSummit API Keystore</title>
    <meta name="lookup-template" content="<cfoutput>#encodeForHTMLAttribute(lookupTemplate)#</cfoutput>">
    <link rel="stylesheet" href="assets/app.css">
    <link rel="stylesheet" href="../assets/demo-window.css">
</head>
<body class="demo-windowed-scroll">
    <div class="demo-windowbar" role="banner">
        <a class="demo-windowbar-back" href="/CFSummit2026/demos/">Back to home</a>
        <span class="demo-windowbar-title">CF2025 AI Demo</span>
        <span class="demo-windowbar-name">API Keystore</span>
    </div>

    <header class="topbar">
        <div>
            <p class="eyebrow">CFSummit 2026</p>
            <h1>API Keystore</h1>
        </div>
        <div class="status-strip" aria-label="Storage status">
            <span class="status-pill good">Derby</span>
            <span class="status-pill" id="headerKeyCount"><cfoutput>#arrayLen(storedKeys)#</cfoutput> keys</span>
            <a class="status-link" href="?reloadApp=1">Reload</a>
        </div>
    </header>

    <main class="shell">
        <section class="workspace">
            <form id="keyForm" class="panel entry-panel" autocomplete="off">
                <div class="panel-heading">
                    <h2>Add Key</h2>
                    <button class="secondary" type="button" id="clearBtn">Clear</button>
                </div>

                <label class="field">
                    <span>Name</span>
                    <input id="name" name="name" type="text" maxlength="180" required>
                </label>

                <label class="field">
                    <span>Unique ID</span>
                    <input id="keyId" name="keyId" type="text" maxlength="80" required pattern="[A-Za-z0-9_.-]+">
                </label>

                <label class="field">
                    <span>API Key</span>
                    <textarea id="apiKey" name="apiKey" rows="5" required spellcheck="false"></textarea>
                </label>

                <label class="field">
                    <span>Notes</span>
                    <input id="notes" name="notes" type="text" maxlength="4000">
                </label>

                <button class="primary" type="submit">Save Key</button>
                <p id="formMessage" class="message" role="status"></p>
            </form>

            <section class="panel storage-panel">
                <div class="panel-heading">
                    <h2>Storage</h2>
                    <button class="secondary" type="button" id="refreshBtn">Refresh</button>
                </div>
                <dl class="storage-list">
                    <div>
                        <dt>Database</dt>
                        <dd><cfoutput>#encodeForHTML(status.databasePath)#</cfoutput></dd>
                    </div>
                    <div>
                        <dt>Master Key</dt>
                        <dd><cfoutput>#encodeForHTML(status.masterKeyPath)#</cfoutput></dd>
                    </div>
                    <div>
                        <dt>Lookup URL</dt>
                        <dd><code><cfoutput>#encodeForHTML(lookupTemplate)#</cfoutput></code></dd>
                    </div>
                </dl>
            </section>
        </section>

        <section class="panel table-panel">
            <div class="panel-heading">
                <h2>Stored Keys</h2>
                <span id="keyCount" class="count"><cfoutput>#arrayLen(storedKeys)#</cfoutput></span>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>Unique ID</th>
                            <th>Stored Value</th>
                            <th>Fingerprint</th>
                            <th>Last Read</th>
                            <th>Retrievals</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="keysBody">
                        <cfoutput>
                            <cfloop array="#storedKeys#" index="keyRecord">
                                <tr data-key-id="#encodeForHTMLAttribute(keyRecord.keyId)#">
                                    <td>
                                        <strong>#encodeForHTML(keyRecord.name)#</strong>
                                        <cfif len(keyRecord.notes)><small>#encodeForHTML(keyRecord.notes)#</small></cfif>
                                    </td>
                                    <td><code>#encodeForHTML(keyRecord.keyId)#</code></td>
                                    <td>#encodeForHTML(keyRecord.hint)#</td>
                                    <td><code>#encodeForHTML(left(keyRecord.fingerprint, 12))#</code></td>
                                    <td>#encodeForHTML(len(keyRecord.lastRetrievedAt) ? keyRecord.lastRetrievedAt : "Never")#</td>
                                    <td>#encodeForHTML(keyRecord.retrievalCount)#</td>
                                    <td class="actions">
                                        <button class="secondary small" type="button" data-action="copy" data-id="#encodeForHTMLAttribute(keyRecord.keyId)#">Copy ID</button>
                                        <button class="danger small" type="button" data-action="delete" data-id="#encodeForHTMLAttribute(keyRecord.keyId)#">Delete</button>
                                    </td>
                                </tr>
                            </cfloop>
                        </cfoutput>
                    </tbody>
                </table>
            </div>
            <p id="emptyState" class="empty <cfif arrayLen(storedKeys)>hidden</cfif>">No keys saved yet.</p>
        </section>
    </main>

    <script src="assets/app.js"></script>
</body>
</html>
