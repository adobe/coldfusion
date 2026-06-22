<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>InventoryAI MCP - ColdFusion Demo</title>
    <link rel="stylesheet" href="assets/app.css">
    <link rel="stylesheet" href="../assets/demo-window.css">
</head>
<body class="demo-windowed-workspace">
    <div class="demo-windowbar">
        <a class="demo-windowbar-back" href="/CFSummit2026/demos/" aria-label="Back to demo home">Back to home</a>
        <span class="demo-windowbar-title">CF2025 AI Demo</span>
        <span class="demo-windowbar-name">Inventory AI</span>
    </div>
    <header class="topbar">
        <div class="logo">
            <span class="logo-icon">iAI</span>
            <span>InventoryAI</span>
        </div>
        <div class="warehouse-tabs" id="warehouseTabs">
            <button class="wh-tab active" data-warehouse="">ALL</button>
            <button class="wh-tab" data-warehouse="Munich">MUNICH</button>
            <button class="wh-tab" data-warehouse="Berlin">BERLIN</button>
            <button class="wh-tab" data-warehouse="Vienna">VIENNA</button>
        </div>
        <div class="topbar-right">
            <div class="stat-chip">items <span class="stat-val" id="statItems">--</span></div>
            <div class="stat-chip">low <span class="stat-val" id="statLow">--</span></div>
            <label class="model-picker">
                <span>model</span>
                <select id="modelSelect" aria-label="AI model selection"></select>
            </label>
            <div class="provider-chip"><span class="pchip-dot"></span><span id="providerLabel">MCP + ChatGPT</span></div>
        </div>
    </header>

    <main class="main">
        <aside class="chat-sidebar">
            <div class="chat-messages" id="chatMessages">
                <div class="message">
                    <div class="msg-agent">
                        <div class="msg-ai-avatar">iAI</div>
                        <div class="msg-agent-body">
                            <div class="msg-agent-bubble">Ask about inventory, low stock, reorder recommendations, or a SKU. I will call the inventory MCP tools and summarize the result.</div>
                            <div class="msg-meta"><span class="msg-tag tag-tool">MCP READY</span><span>cf-inventory-database-mcp</span></div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="chat-input-area">
                <div class="quick-queries">
                    <button class="qq-btn">What items are low stock in Munich warehouse?</button>
                    <button class="qq-btn">Recommend reorders for Vienna warehouse.</button>
                    <button class="qq-btn">Show me electronics that need attention.</button>
                    <button class="qq-btn">What is the status of MUC-EL-001?</button>
                </div>
                <form class="input-row" id="chatForm">
                    <input class="chat-input" id="chatInput" placeholder="Ask inventory..." autocomplete="off">
                    <button class="send-btn" type="submit">→</button>
                </form>
            </div>
            <div class="chat-busy-overlay" id="chatBusyOverlay" aria-live="polite" aria-hidden="true">
                <div class="mcp-spinner" aria-hidden="true"></div>
                <div class="busy-title">Calling MCP tools</div>
                <div class="busy-copy">InventoryAI is waiting for the selected model and MCP server.</div>
            </div>
        </aside>

        <section class="table-area">
            <div class="table-toolbar">
                <div class="toolbar-title">Inventory database</div>
                <div class="active-filters" id="activeFilters"></div>
                <button class="toolbar-btn" id="seedBtn" type="button">Refresh DB</button>
                <div class="row-count"><span class="rc-num" id="rowCount">0</span> rows</div>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>SKU</th>
                            <th>Product</th>
                            <th>Warehouse</th>
                            <th>Stock</th>
                            <th>Reorder</th>
                            <th>Supplier</th>
                            <th>Lead</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody id="inventoryRows">
                        <tr><td colspan="8" class="empty-cell">Loading inventory...</td></tr>
                    </tbody>
                </table>
            </div>
        </section>

        <aside class="right-panel">
            <div class="rpanel-tabs">
                <button class="rtab active" data-tab="debug">DEBUG</button>
                <button class="rtab" data-tab="sql">SQL QUERY</button>
            </div>
            <div class="rpanel-body">
                <section class="rsection active" id="debugPanel">
                    <div class="debug-block">
                        <div class="db-header"><span class="db-type dbt-tool">MCP</span><span>Waiting for tool call</span></div>
                        <div class="db-body">Ask a question to see the selected MCP tool, arguments, and result summary.</div>
                    </div>
                </section>
                <section class="rsection" id="sqlPanel">
                    <div class="debug-block">
                        <div class="db-header"><span class="db-type dbt-result">SQL</span><span>Waiting for MCP query</span></div>
                        <div class="db-body">Run an inventory question to see the parameterized SQL and bound values used by the MCP tool.</div>
                    </div>
                </section>
            </div>
        </aside>
    </main>

    <script src="assets/app.js"></script>
</body>
</html>
