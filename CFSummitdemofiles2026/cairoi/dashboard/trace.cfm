<cfsetting showdebugoutput="false">
<cfscript>
traceId = trim(url.traceId ?: "");
function h(any value = "") {
    return encodeForHTML(toString(arguments.value));
}
</cfscript>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>CAIROI Trace Detail</title>
    <link rel="stylesheet" href="assets/cairoi.css">
</head>
<body>
<main class="shell">
    <div class="topbar">
        <div class="brand">
            <h1>Trace Detail</h1>
            <p><cfoutput>#len(traceId) ? h(traceId) : 'No trace selected'#</cfoutput></p>
        </div>
        <nav class="nav">
            <a href="index.cfm">Dashboard</a>
            <a href="../admin/setup.cfm">Setup</a>
        </nav>
    </div>

    <cfif !len(traceId)>
        <div class="status error">A traceId query parameter is required.</div>
    <cfelse>
        <section class="grid" id="traceMetrics"></section>
        <section class="panel">
            <h2>Trace Metadata</h2>
            <pre id="traceMetadata">{}</pre>
        </section>
        <section class="panel">
            <h2>Spans</h2>
            <div class="table-wrap"><table id="spanTable"></table></div>
        </section>
    </cfif>
</main>

<cfif len(traceId)>
<script>
const traceId = <cfoutput>#serializeJSON(traceId)#</cfoutput>;
const money = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", minimumFractionDigits: 6 });
const integer = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });

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

function renderMetrics(trace) {
    document.getElementById("traceMetrics").innerHTML = `
        <div class="metric"><span>App</span><strong>${esc(read(trace, "app_id"))}</strong></div>
        <div class="metric"><span>Environment</span><strong>${esc(read(trace, "environment"))}</strong></div>
        <div class="metric"><span>Workflow</span><strong>${esc(read(trace, "workflow_name"))}</strong></div>
        <div class="metric"><span>Status</span><strong>${esc(read(trace, "status"))}</strong></div>
        <div class="metric"><span>Duration</span><strong>${integer.format(Number(read(trace, "duration_ms") || 0))} ms</strong></div>
        <div class="metric"><span>Total Tokens</span><strong>${integer.format(Number(read(trace, "total_tokens") || 0))}</strong></div>
        <div class="metric"><span>Estimated Cost</span><strong>${money.format(Number(read(trace, "estimated_cost") || 0))}</strong></div>
    `;
    document.getElementById("traceMetadata").textContent = JSON.stringify(read(trace, "metadata") || {}, null, 2);
}

function renderSpans(spans) {
    const table = document.getElementById("spanTable");
    if (!spans.length) {
        table.innerHTML = "<tbody><tr><td class=\"muted\">No spans recorded.</td></tr></tbody>";
        return;
    }
    table.innerHTML = `
        <thead>
            <tr><th>Operation</th><th>Name</th><th>Provider / Model</th><th>Duration</th><th>Tokens</th><th>Cost</th><th>Status</th></tr>
        </thead>
        <tbody>
            ${spans.map(span => `
                <tr>
                    <td>${esc(read(span, "operation_type"))}</td>
                    <td>${esc(read(span, "operation_name"))}</td>
                    <td>${esc([read(span, "provider"), read(span, "model_name")].filter(Boolean).join(" / "))}</td>
                    <td>${integer.format(Number(read(span, "duration_ms") || 0))} ms</td>
                    <td>${integer.format(Number(read(span, "total_tokens") || 0))}</td>
                    <td>${money.format(Number(read(span, "estimated_cost") || 0))}</td>
                    <td><span class="pill ${read(span, "status") === "error" ? "error" : ""}">${esc(read(span, "status"))}</span></td>
                </tr>
                <tr>
                    <td colspan="7"><pre>${esc(JSON.stringify(read(span, "metadata") || {}, null, 2))}</pre></td>
                </tr>
            `).join("")}
        </tbody>
    `;
}

fetch(`../api/traces.cfm?traceId=${encodeURIComponent(traceId)}`)
    .then(response => response.json())
    .then(payload => {
        if (!read(payload, "ok")) throw new Error(read(payload, "message") || "Trace failed to load.");
        renderMetrics(read(payload, "trace"));
        renderSpans(read(payload, "spans") || []);
    })
    .catch(error => {
        document.querySelector(".shell").insertAdjacentHTML("beforeend", `<div class="status error">${esc(error.message)}</div>`);
    });
</script>
</cfif>
</body>
</html>
