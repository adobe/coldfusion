<cfsetting showdebugoutput="false">
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Dashboard</title>
    <link rel="stylesheet" href="assets/cairoi.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>CAIROI Dashboard</h1>
            <p>AI usage, cost, latency, and trace visibility for ColdFusion demo apps.</p>
        </div>
        <nav class="nav">
            <a href="../admin/setup.cfm">Setup</a>
            <a href="../admin/prices.cfm">Prices</a>
            <button class="danger" id="archiveButton" type="button">Archive + Reset</button>
            <button id="refreshButton" type="button">Refresh</button>
        </nav>
    </div>
    <div id="dashboardStatus"></div>

    <section class="grid" id="metricGrid">
        <div class="metric"><span>Total Cost</span><strong id="metricCost">$0.000000</strong></div>
        <div class="metric"><span>Total Tokens</span><strong id="metricTokens">0</strong></div>
        <div class="metric"><span>Input / Output</span><strong id="metricInputOutput">0 / 0</strong></div>
        <div class="metric"><span>Traces / Spans</span><strong id="metricTraceSpan">0 / 0</strong></div>
        <div class="metric"><span>Avg Latency</span><strong id="metricLatency">0 ms</strong></div>
    </section>

    <section class="chart-grid">
        <div class="panel">
            <h2>Cost Over Time</h2>
            <canvas id="costChart" height="160"></canvas>
        </div>
        <div class="panel">
            <h2>Tokens Over Time</h2>
            <canvas id="tokenChart" height="160"></canvas>
        </div>
    </section>

    <section class="chart-grid">
        <div class="panel">
            <h2>Cost By Application</h2>
            <div class="table-wrap"><table id="appBreakdown"></table></div>
        </div>
        <div class="panel">
            <h2>Cost By Model</h2>
            <div class="table-wrap"><table id="modelBreakdown"></table></div>
        </div>
        <div class="panel">
            <h2>Cost By Workflow</h2>
            <div class="table-wrap"><table id="workflowBreakdown"></table></div>
        </div>
        <div class="panel">
            <h2>Cost By Operation</h2>
            <div class="table-wrap"><table id="operationBreakdown"></table></div>
        </div>
    </section>

    <section class="panel">
        <h2>Recent Traces</h2>
        <div class="table-wrap"><table id="expensiveTraces"></table></div>
    </section>
</main>

<script>
const money = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 6 });
const integer = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });
let costChart;
let tokenChart;

function cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, char => ({
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        '"': "&quot;",
        "'": "&#39;"
    }[char]));
}

function read(obj, ...keys) {
    if (!obj) return undefined;
    for (const key of keys) {
        if (Object.prototype.hasOwnProperty.call(obj, key)) return obj[key];
        const found = Object.keys(obj).find(candidate => candidate.toLowerCase() === key.toLowerCase());
        if (found) return obj[found];
    }
    return undefined;
}

async function getJson(url) {
    const response = await fetch(url, { headers: { "Accept": "application/json" } });
    const payload = await response.json();
    if (!response.ok || read(payload, "ok") === false) {
        throw new Error(read(payload, "message") || `Request failed with status ${response.status}`);
    }
    return payload;
}

async function postJson(url, payload = {}) {
    const response = await fetch(url, {
        method: "POST",
        headers: { "Accept": "application/json", "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    });
    const data = await response.json();
    if (!response.ok || read(data, "ok") === false) {
        throw new Error(read(data, "message") || `Request failed with status ${response.status}`);
    }
    return data;
}

function showStatus(message, type = "ok") {
    document.getElementById("dashboardStatus").innerHTML = message
        ? `<div class="status ${type}">${esc(message)}</div>`
        : "";
}

function renderBreakdown(tableId, rows) {
    const table = document.getElementById(tableId);
    if (!rows.length) {
        table.innerHTML = "<tbody><tr><td class=\"muted\">No data yet.</td></tr></tbody>";
        return;
    }
    table.innerHTML = `
        <thead><tr><th>Label</th><th>Cost</th><th>Tokens</th><th>Spans</th><th>Avg Latency</th></tr></thead>
        <tbody>
            ${rows.map(row => `
                <tr>
                    <td>${esc(read(row, "label"))}</td>
                    <td>${money.format(Number(read(row, "estimated_cost") || 0))}</td>
                    <td>${integer.format(Number(read(row, "total_tokens") || 0))}</td>
                    <td>${integer.format(Number(read(row, "span_count") || 0))}</td>
                    <td>${integer.format(Number(read(row, "avg_duration_ms") || 0))} ms</td>
                </tr>
            `).join("")}
        </tbody>`;
}

function renderTraceTable(tableId, rows) {
    const table = document.getElementById(tableId);
    if (!rows.length) {
        table.innerHTML = "<tbody><tr><td class=\"muted\">No traces yet.</td></tr></tbody>";
        return;
    }
    table.innerHTML = `
        <thead><tr><th>Trace</th><th>App</th><th>Workflow</th><th>Status</th><th>Tokens</th><th>Cost</th><th>Duration</th></tr></thead>
        <tbody>
            ${rows.map(row => `
                <tr>
                    <td><a href="trace.cfm?traceId=${encodeURIComponent(read(row, "trace_id"))}">${esc(read(row, "trace_id"))}</a></td>
                    <td>${esc(read(row, "app_id"))}</td>
                    <td>${esc(read(row, "workflow_name"))}</td>
                    <td><span class="pill ${read(row, "status") === "error" ? "error" : ""}">${esc(read(row, "status"))}</span></td>
                    <td>${integer.format(Number(read(row, "total_tokens") || 0))}</td>
                    <td>${money.format(Number(read(row, "estimated_cost") || 0))}</td>
                    <td>${integer.format(Number(read(row, "duration_ms") || 0))} ms</td>
                </tr>
            `).join("")}
        </tbody>`;
}

function updateCharts(rows) {
    const labels = rows.map(row => String(read(row, "bucket_start") || ""));
    const costs = rows.map(row => Number(read(row, "estimated_cost") || 0));
    const tokens = rows.map(row => Number(read(row, "total_tokens") || 0));
    const axisColor = cssVar("--muted");
    const gridColor = cssVar("--line");

    if (costChart) costChart.destroy();
    if (tokenChart) tokenChart.destroy();

    costChart = new Chart(document.getElementById("costChart"), {
        type: "line",
        data: { labels, datasets: [{ label: "Estimated cost", data: costs, borderColor: cssVar("--accent"), backgroundColor: "rgba(96, 165, 250, .16)", tension: .25, fill: true }] },
        options: {
            plugins: { legend: { display: false } },
            scales: {
                x: { ticks: { color: axisColor }, grid: { color: gridColor } },
                y: { beginAtZero: true, ticks: { color: axisColor }, grid: { color: gridColor } }
            }
        }
    });

    tokenChart = new Chart(document.getElementById("tokenChart"), {
        type: "bar",
        data: { labels, datasets: [{ label: "Tokens", data: tokens, backgroundColor: cssVar("--good") }] },
        options: {
            plugins: { legend: { display: false } },
            scales: {
                x: { ticks: { color: axisColor }, grid: { color: gridColor } },
                y: { beginAtZero: true, ticks: { color: axisColor }, grid: { color: gridColor } }
            }
        }
    });
}

async function refresh() {
    const [summary, series, app, model, workflow, operation, recent] = await Promise.all([
        getJson("../api/dashboard.cfm?action=summary"),
        getJson("../api/dashboard.cfm?action=timeseries&bucket=hour"),
        getJson("../api/dashboard.cfm?action=breakdown&by=app"),
        getJson("../api/dashboard.cfm?action=breakdown&by=model"),
        getJson("../api/dashboard.cfm?action=breakdown&by=workflow"),
        getJson("../api/dashboard.cfm?action=breakdown&by=operation_type"),
        getJson("../api/dashboard.cfm?action=recent")
    ]);

    const s = read(summary, "summary") || {};
    document.getElementById("metricCost").textContent = money.format(Number(read(s, "totalEstimatedCost") || 0));
    document.getElementById("metricTokens").textContent = integer.format(Number(read(s, "totalTokens") || 0));
    document.getElementById("metricInputOutput").textContent = `${integer.format(Number(read(s, "totalInputTokens") || 0))} / ${integer.format(Number(read(s, "totalOutputTokens") || 0))}`;
    document.getElementById("metricTraceSpan").textContent = `${integer.format(Number(read(s, "traceCount") || 0))} / ${integer.format(Number(read(s, "spanCount") || 0))}`;
    document.getElementById("metricLatency").textContent = `${integer.format(Number(read(s, "averageLatencyMs") || 0))} ms`;

    updateCharts(read(series, "rows") || []);
    renderBreakdown("appBreakdown", read(app, "rows") || []);
    renderBreakdown("modelBreakdown", read(model, "rows") || []);
    renderBreakdown("workflowBreakdown", read(workflow, "rows") || []);
    renderBreakdown("operationBreakdown", read(operation, "rows") || []);
    renderTraceTable("expensiveTraces", read(recent, "expensive") || []);
}

document.getElementById("refreshButton").addEventListener("click", refresh);
document.getElementById("archiveButton").addEventListener("click", async () => {
    const ok = confirm("Archive current trace/span data to data/archives and reset the live dashboard?");
    if (!ok) return;

    const button = document.getElementById("archiveButton");
    button.disabled = true;
    showStatus("Archiving telemetry and resetting the live dashboard...", "warn");
    try {
        const result = await postJson("../api/archive.cfm");
        showStatus(`${read(result, "message")} Archive file: ${read(result, "archiveFile")}`, "ok");
        await refresh();
    } catch (e) {
        showStatus(e.message, "error");
    } finally {
        button.disabled = false;
    }
});
refresh().catch(error => {
    showStatus(`Dashboard failed to load: ${error.message}`, "error");
});
setInterval(() => refresh().catch(() => {}), 10000);
</script>
</body>
</html>
