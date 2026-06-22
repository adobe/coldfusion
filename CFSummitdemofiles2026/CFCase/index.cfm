<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CF Cases</title>
    <link rel="stylesheet" href="assets/css/game.css?v=critical-hints-1">
    <link rel="stylesheet" href="../assets/demo-window.css">
</head>
<body class="demo-windowed-case">
    <div class="demo-windowbar">
        <a class="demo-windowbar-back" href="/CFSummit2026/demos/" aria-label="Back to demo home">Back to home</a>
        <span class="demo-windowbar-title">CF2025 AI Demo</span>
        <span class="demo-windowbar-name">CF Cases</span>
    </div>
    <main class="app-shell" data-debug="<cfoutput>#encodeForHtmlAttribute(structKeyExists(url, "debug") && url.debug == "1" ? "1" : "0")#</cfoutput>">
        <section class="scenario-screen" id="scenarioScreen">
            <div class="scenario-topbar">
                <div>
                    <p class="eyebrow">ColdFusion AI Mystery Engine</p>
                    <h1>CF Cases</h1>
                </div>
            </div>
            <div class="selection-layout">
                <div class="scenario-list-pane">
                    <div class="scenario-grid" id="scenarioGrid"></div>
                    <p class="empty-state" id="scenarioEmpty" hidden>No case files found.</p>
                    <button class="refresh-button" id="refreshScenarios" type="button">Refresh cases</button>
                </div>
                <aside class="selection-panel" aria-live="polite">
                    <button class="start-button" id="startMystery" type="button" disabled>Start Adventure</button>
                    <div class="selection-details">
                        <img class="selected-image" id="selectedImage" alt="">
                        <h2 id="selectedTitle">Choose a case</h2>
                        <p id="selectedSubtitle">Select a mystery file, then start the investigation.</p>
                        <p class="selected-intro" id="selectedIntro"></p>
                        <dl class="selected-meta" id="selectedMeta"></dl>
                    </div>
                </aside>
            </div>
        </section>

        <section class="game-screen" id="gameScreen" hidden>
            <div class="room-stage">
                <img id="roomImage" class="room-image" alt="">
                <div class="rain-layer" aria-hidden="true"></div>
                <div class="room-title-band">
                    <p class="eyebrow" id="caseTitle">Case</p>
                    <h1 id="roomName">Room</h1>
                    <p id="roomDescription"></p>
                </div>
            </div>

            <section class="command-panel">
                <div class="log" id="narrativeLog" aria-live="polite"></div>
                <div class="quick-actions" id="quickActions"></div>
                <form class="command-form" id="commandForm">
                    <input id="commandInput" name="command" autocomplete="off" placeholder="Type a command..." aria-label="Command">
                    <button type="submit">Send</button>
                </form>
            </section>

            <aside class="side-panel">
                <div class="panel exits-panel">
                    <div class="panel-heading">
                        <h2>Exits</h2>
                        <span class="panel-legend"><span class="legend-swatch visited"></span>Visited</span>
                    </div>
                    <div class="chip-list" id="exitList"></div>
                </div>

                <div class="panel visible-panel">
                    <div class="panel-heading">
                        <h2>Visible</h2>
                        <span class="panel-legend-group">
                            <span class="panel-legend"><span class="legend-swatch examined"></span>Examined</span>
                            <span class="panel-legend"><span class="legend-swatch portable"></span>Carryable</span>
                        </span>
                    </div>
                    <div class="chip-list" id="objectList"></div>
                </div>

                <div class="panel inventory-panel">
                    <h2>Inventory</h2>
                    <div class="item-list" id="inventoryList"></div>
                </div>

                <div class="panel clues-panel">
                    <div class="panel-heading">
                        <h2>Clues</h2>
                        <span class="clue-progress" id="clueProgress">0 / 0 found</span>
                    </div>
                    <div class="item-list" id="clueList"></div>
                </div>

                <div class="panel">
                    <h2>Suspects</h2>
                    <div class="item-list" id="suspectList"></div>
                </div>
            </aside>
        </section>
    </main>

    <div class="solved-modal" id="solvedModal" hidden>
        <div class="solved-dialog" role="dialog" aria-modal="true" aria-labelledby="solvedTitle" aria-describedby="solvedText">
            <p class="eyebrow">Case closed</p>
            <h2 id="solvedTitle">You've solved the case!</h2>
            <p id="solvedText">You won the investigation. IRIS has enough evidence to close the file.</p>
            <button class="start-button" id="returnToCases" type="button">Back to case files</button>
        </div>
    </div>

    <script type="module" src="assets/js/game.js?v=critical-hints-1"></script>
</body>
</html>
