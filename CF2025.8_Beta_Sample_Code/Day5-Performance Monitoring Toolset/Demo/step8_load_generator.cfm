<cfscript>
variables.currentStep = "step8";
variables.pmtTabs = "LLMs,RAG,Agents,MCP Clients,MCP Servers,Vector Stores";

mcpFastUrl = "http://localhost:8500/mintu_baby/mcp/babySuppliesMcpServer.cfm";

// Helper: run a named sub-action and capture result
function runSubAction(name, callback) {
    var t = getTickCount();
    try {
        var r = callback();
        return { name: name, success: true, duration: getTickCount()-t, result: r };
    } catch (any e) {
        return { name: name, success: false, duration: getTickCount()-t, error: e.message };
    }
}

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    results = [];
    errors  = [];

    try {
        // ---- LLM calls ----
        if (action == "gen_llm" || action == "gen_all") {
            llmQuestions = [
                "What is the best room temperature for a baby nursery?",
                "How does breastfeeding benefit a newborn?",
                "Explain baby sleep regression in 2 sentences.",
                "What is tummy time and why is it important?",
                "When should a baby start solid foods?"
            ];
            llmProviders = [
                { PROVIDER: "openAi",     APIKEY: application.openaiKey,    MODELNAME: application.openaiModel },
                { PROVIDER: "anthropic",  APIKEY: application.anthropicKey, MODELNAME: application.anthropicModel },
                { PROVIDER: "mistral",    APIKEY: application.mistralkey,   MODELNAME: application.mistralModel },
                { PROVIDER: "openAi",     APIKEY: application.openaiKey,    MODELNAME: application.openaiModel },
                { PROVIDER: "openAi",     APIKEY: application.openaiKey,    MODELNAME: application.openaiModel }
            ];
            for (i = 1; i <= 5; i++) {
                q = llmQuestions[i];
                p = llmProviders[i];
                arrayAppend(results, runSubAction("llm_" & i, function() {
                    var cm = ChatModel(p);
                    return cm.chat(q);
                }));
            }
        }

        // ---- RAG queries ----
        if (action == "gen_rag" || action == "gen_all") {
            if (isObject(session.ragService)) {
                ragQueries = [
                    "How do I establish a bedtime routine?",
                    "What is the vaccination schedule for newborns?",
                    "How do I treat diaper rash?",
                    "When should I start tummy time?",
                    "What are signs my baby is getting enough milk?"
                ];
                for (rq in ragQueries) {
                    capturedRq = rq;
                    arrayAppend(results, runSubAction("rag_query", function() {
                        return session.ragService.chat(capturedRq);
                    }));
                }
            } else {
                arrayAppend(errors, "RAG service not initialized — run Step 5 first to ingest documents.");
            }
        }

        // ---- Agent calls ----
        if (action == "gen_agent" || action == "gen_all") {
            agentPrompts = [
                "Look up baby BABY-001 and tell me their weight.",
                "Check the status of the Feeding routine.",
                "Create a P4 care task: general wellness check reminder.",
                "Look up family member PARENT-001 and check the Sleep routine status.",
                "Check Diaper and Bath routine status."
            ];
            genAgentInst = Agent({
                CHATMODEL: ChatModel({
                    PROVIDER: "openAi", APIKEY: application.openaiKey,
                    MODELNAME: application.openaiModel, TEMPERATURE: 0.3, MAXTOKENS: 200
                }),
                TOOLS: [{
                    cfc: "mintu_baby.helpers.BabyCareDesk",
                    methods: [
                        { method: "lookupFamilyMember",  description: "Look up family member details by ID." },
                        { method: "checkRoutineStatus",  description: "Check baby care routine status." },
                        { method: "createCareTask",      description: "Create a baby care task." }
                    ]
                }]
            });
            for (ap in agentPrompts) {
                capturedAp = ap;
                arrayAppend(results, runSubAction("agent_call", function() {
                    var r = genAgentInst.chat(capturedAp);
                    return r.message ?: r;
                }));
            }
        }

        // ---- MCP calls ----
        if (action == "gen_mcp" || action == "gen_all") {
            mcpPrompts = [
                "Search for baby bottles in the store.",
                "Check if SWAD-001 swaddle is in stock.",
                "What is the status of order ORD-BABY-1235?",
                "Find all feeding products available.",
                "Check inventory for THER-001 thermometer."
            ];
            mcpAgent = Agent({
                CHATMODEL: ChatModel({
                    PROVIDER: "openAi", APIKEY: application.openaiKey,
                    MODELNAME: application.openaiModel, TEMPERATURE: 0.3, MAXTOKENS: 200
                }),
                TOOLS: [{ MCPCLIENT: [MCPClient({ TRANSPORT: { TYPE: "http", URL: mcpFastUrl } })] }]
            });
            for (mp in mcpPrompts) {
                capturedMp = mp;
                arrayAppend(results, runSubAction("mcp_call", function() {
                    var r = mcpAgent.chat(capturedMp);
                    return r.message ?: r;
                }));
            }
        }

        // ---- Error/edge cases ----
        if (action == "gen_errors" || action == "gen_all") {
            // 1. Input guardrail block
            guardrailBlockFn = function() {
                var ga = Agent({
                    CHATMODEL: ChatModel({ PROVIDER:"openAi", APIKEY:application.openaiKey, MODELNAME:application.openaiModel, MAXTOKENS:100 }),
                    INPUTGUARDRAILS: [expandPath("/mintu_baby/helpers/InputSafetyGuardrail.cfc")]
                });
                try { return ga.chat("Should I give honey to my newborn?"); } catch (any e) { return "Blocked: " & e.message; }
            };
            arrayAppend(results, runSubAction("guardrail_block", guardrailBlockFn));

            // 2. Empty query (edge case)
            emptyQueryFn = function() {
                if (isObject(session.ragService)) {
                    return session.ragService.chat("...");
                }
                return "RAG not available";
            };
            arrayAppend(results, runSubAction("empty_query_rag", emptyQueryFn));

            // 3. PII output guardrail
            piiRedactFn = function() {
                var gb = Agent({
                    CHATMODEL: ChatModel({ PROVIDER:"openAi", APIKEY:application.openaiKey, MODELNAME:application.openaiModel, MAXTOKENS:150 }),
                    TOOLS: [{ cfc:"mintu_baby.helpers.BabyCareDesk", methods:[{ method:"lookupFamilyMember", description:"Look up family member details by ID." }] }],
                    OUTPUTGUARDRAILS: [expandPath("/mintu_baby/helpers/PIIProtectionGuardrail.cfc")]
                });
                var rawR = gb.chat("What is family member PARENT-002's email?");
                return rawR.message ?: rawR;
            };
            arrayAppend(results, runSubAction("pii_redaction", piiRedactFn));
        }

        successCount = arrayFilter(results, function(r){ return r.success; }).len();
        errorCount   = arrayFilter(results, function(r){ return !r.success; }).len();

        writeOutput(serializeJSON({
            success:      true,
            action:       action,
            totalCalls:   arrayLen(results),
            successCount: successCount,
            errorCount:   errorCount,
            results:      results,
            errors:       errors,
            duration:     getTickCount() - startMs
        }));

    } catch (any e) {
        writeOutput(serializeJSON({ success: false, error: e.message, detail: e.detail ?: "" }));
    }
    abort;
}
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Step 8: Load Generator — Mintu Baby Care AI</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step8">
<cfset variables.pmtTabs = "LLMs,RAG,Agents,MCP Clients,MCP Servers,Vector Stores">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 8 &nbsp;|&nbsp; Load Generator</div>
        <h2>Load Generator — Populate All PMT Dashboard Charts</h2>
        <p>Generate a volume of varied AI calls across all categories to fully populate PMT's charts, time-series graphs, grids, and KPI cards for a complete baby care dashboard showcase.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128200;</span>
            <div>
                <strong>Goal:</strong> After running all generators, the PMT AI Services dashboard will have rich data across all 6 tabs — enough to show time-series charts, provider distribution pies, score histograms, and data grids with multiple entries.
            </div>
        </div>

        <!-- Progress overview -->
        <div class="section" id="progressSection" style="display:none">
            <div class="section-title">Overall Progress</div>
            <div style="display:flex;align-items:center;gap:16px;flex-wrap:wrap;margin-bottom:8px">
                <span id="progressLabel" style="font-size:14px;color:#63b3ed;font-weight:600">0 / 23 calls completed</span>
                <span id="progressStatus" style="font-size:12px;color:#718096"></span>
            </div>
            <div class="progress-bar-wrap" style="height:10px">
                <div class="progress-bar-fill" id="progressBar" style="width:0%"></div>
            </div>
        </div>

        <!-- Category generators -->
        <div class="section">
            <div class="section-title">Generate by Category</div>
            <div class="action-grid">

                <div class="action-card">
                    <div class="card-title">&#x1F4AC; 5 LLM Calls</div>
                    <div class="card-desc">5 varied baby care questions across OpenAI, Anthropic, and Mistral. Populates: LLMs tab provider distribution, token usage, avg response time.</div>
                    <button class="btn btn-primary" onclick="generate('gen_llm', this)">Generate LLM Calls (5)</button>
                    <div class="result-area" id="result-gen_llm"></div>
                </div>

                <div class="action-card">
                    <div class="card-title">&#128229; 5 RAG Queries</div>
                    <div class="card-desc">5 baby care queries via the optimized RAG service. Requires Step 5 knowledge base. Populates: RAG tab retrieval scores, query grid.</div>
                    <button class="btn btn-primary" onclick="generate('gen_rag', this)">Generate RAG Queries (5)</button>
                    <div class="result-area" id="result-gen_rag"></div>
                </div>

                <div class="action-card">
                    <div class="card-title">&#129302; 5 Agent Calls</div>
                    <div class="card-desc">5 baby care agent interactions using family member lookup, routine checks, and care task creation. Populates: Agents tab, LLMs tab tool-call metrics.</div>
                    <button class="btn btn-primary" onclick="generate('gen_agent', this)">Generate Agent Calls (5)</button>
                    <div class="result-area" id="result-gen_agent"></div>
                </div>

                <div class="action-card">
                    <div class="card-title">&#128268; 5 MCP Calls</div>
                    <div class="card-desc">5 baby supply queries via the optimized MCP server. Populates: MCP Clients tab, MCP Servers tab tool call metrics.</div>
                    <button class="btn btn-primary" onclick="generate('gen_mcp', this)">Generate MCP Calls (5)</button>
                    <div class="result-area" id="result-gen_mcp"></div>
                </div>

                <div class="action-card">
                    <div class="card-title">&#9889; 3 Edge Cases</div>
                    <div class="card-desc">Guardrail block, empty query, PII redaction. Creates variety in the trace viewer and error metrics. Populates: guardrail spans, Trace Viewer entries.</div>
                    <button class="btn btn-warning" onclick="generate('gen_errors', this)">Generate Error Cases (3)</button>
                    <div class="result-area" id="result-gen_errors"></div>
                </div>

            </div>
        </div>

        <!-- Run All -->
        <div class="section">
            <div style="display:flex;align-items:center;gap:16px;flex-wrap:wrap;">
                <button class="btn btn-run-all" id="runAllBtn" onclick="runAll()" style="padding:12px 28px;font-size:14px">
                    &#9654;&#9654; Run All (23 Calls)
                </button>
                <div>
                    <div style="font-size:13px;color:#e2e8f0;font-weight:600">Full Dashboard Populate</div>
                    <div style="font-size:12px;color:#718096">Runs all 5 categories sequentially. After completion, do a full PMT dashboard tour.</div>
                </div>
            </div>
        </div>

        <!-- PMT Tour hints -->
        <div class="section">
            <div class="section-title">PMT Dashboard Tour (after running all generators)</div>
            <div class="action-grid">
                <div class="action-card" style="border-color:#4299e1">
                    <div class="card-title" style="color:#63b3ed">LLMs Tab</div>
                    <div class="card-desc">Provider distribution pie, token usage by model, avg response time line chart, slow LLM calls grid with 5+ entries.</div>
                </div>
                <div class="action-card" style="border-color:#4299e1">
                    <div class="card-title" style="color:#63b3ed">RAG Tab</div>
                    <div class="card-desc">Retrieval score histogram (optimized config scores 0.6+), completed ingest operations grid, query performance metrics.</div>
                </div>
                <div class="action-card" style="border-color:#4299e1">
                    <div class="card-title" style="color:#63b3ed">Agents Tab</div>
                    <div class="card-desc">Agent call timeline, tool usage breakdown, slow agent requests, multi-turn conversation metrics.</div>
                </div>
                <div class="action-card" style="border-color:#4299e1">
                    <div class="card-title" style="color:#63b3ed">MCP Clients / Servers Tab</div>
                    <div class="card-desc">Tool call latency per server, avg response time comparison (slow vs fast server still visible from Steps 5a/5b).</div>
                </div>
                <div class="action-card" style="border-color:#4299e1">
                    <div class="card-title" style="color:#63b3ed">Trace Viewer</div>
                    <div class="card-desc">Multiple complete traces including the full agent trace from Step 7. Flamegraphs show every span type.</div>
                </div>
            </div>
        </div>

        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step7_full_agent.cfm" class="btn btn-secondary">&#8592; Full Agent</a>
            <a href="index.cfm" class="btn btn-primary">&#127968; Back to Home</a>
            <a href="http://localhost:9101/ai-services/home" target="_blank" class="btn btn-success">&#128200; Open PMT Dashboard &nearr;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
const totalCalls = 23;
let completedCalls = 0;

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showToast(msg, type) {
    const t = document.getElementById('toast'); t.textContent = msg;
    t.className = 'show toast-' + (type || 'success');
    setTimeout(() => { t.className = ''; }, 5000);
}

function updateProgress(count, total, status) {
    document.getElementById('progressSection').style.display = 'block';
    document.getElementById('progressLabel').textContent = count + ' / ' + total + ' calls completed';
    document.getElementById('progressStatus').textContent = status || '';
    const pct = Math.round((count / total) * 100);
    document.getElementById('progressBar').style.width = pct + '%';
}

function renderBatchResult(containerId, data) {
    const el = document.getElementById(containerId);
    if (!data.success) {
        el.innerHTML = `<div class="result-card error">${escHtml(data.error)}</div>`;
        return;
    }
    const rows = data.results.map(r => `
        <tr>
            <td style="color:#a0aec0;font-size:11px">${escHtml(r.name)}</td>
            <td>${r.success ? '<span style="color:#68d391">&#10003;</span>' : '<span style="color:#fc8181">&#10007;</span>'}</td>
            <td style="font-size:11px">${r.duration}ms</td>
        </tr>`).join('');
    const errMsg = data.errors && data.errors.length > 0 ? `<div style="margin-top:8px;padding:6px;background:#2d1515;border-radius:4px;font-size:11px;color:#fc8181">${data.errors.map(e => escHtml(e)).join('<br>')}</div>` : '';
    el.innerHTML = `<div class="result-card success">
        <div class="metrics-row" style="margin-bottom:8px">
            <span class="metric-badge score">&#10003; ${data.successcount} succeeded</span>
            ${data.errorcount > 0 ? `<span class="metric-badge alert">&#10007; ${data.errorcount} errors</span>` : ''}
            <span class="metric-badge time">&#9201; ${data.duration}ms total</span>
        </div>
        <table style="width:100%;font-size:11px;border-collapse:collapse">
            <thead><tr><th style="text-align:left;color:#718096;padding:4px 0">Call</th><th>Status</th><th>Duration</th></tr></thead>
            <tbody>${rows}</tbody>
        </table>
        ${errMsg}
    </div>`;
}

async function generate(action, btn) {
    if (btn) btn.disabled = true;
    const id = 'result-' + action;
    document.getElementById(id).innerHTML = '<div class="loading-row"><div class="spinner"></div><span>Generating ' + action.replace('gen_','') + ' calls...</span></div>';
    try {
        const res  = await fetch(window.location.pathname, {
            method:  'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body:    'action=' + action
        });
        const data = cfNorm(await res.json());
        renderBatchResult(id, data);
        if (data.success) {
            completedCalls += data.totalcalls || 0;
            showToast(action + ': ' + (data.successcount || 0) + ' calls done in ' + data.duration + 'ms', 'success');
        } else {
            showToast('Error in ' + action + ': ' + data.error, 'error');
        }
    } catch(e) {
        document.getElementById(id).innerHTML = `<div class="result-card error">${escHtml(e.message)}</div>`;
    } finally {
        if (btn) btn.disabled = false;
    }
}

async function runAll() {
    const btn = document.getElementById('runAllBtn');
    btn.disabled = true;
    btn.textContent = '⏳ Running all generators...';
    completedCalls = 0;
    updateProgress(0, totalCalls, 'Starting...');

    const categories = [
        { action: 'gen_llm',    label: 'LLM calls',    count: 5,  btnId: null },
        { action: 'gen_rag',    label: 'RAG queries',  count: 5,  btnId: null },
        { action: 'gen_agent',  label: 'Agent calls',  count: 5,  btnId: null },
        { action: 'gen_mcp',    label: 'MCP calls',    count: 5,  btnId: null },
        { action: 'gen_errors', label: 'Error cases',  count: 3,  btnId: null }
    ];

    let done = 0;
    for (const cat of categories) {
        updateProgress(done, totalCalls, 'Running ' + cat.label + '...');
        const id = 'result-' + cat.action;
        document.getElementById(id).innerHTML = '<div class="loading-row"><div class="spinner"></div><span>Generating ' + cat.label + '...</span></div>';
        try {
            const res  = await fetch(window.location.pathname, {
                method:  'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body:    'action=' + cat.action
            });
            const data = cfNorm(await res.json());
            renderBatchResult(id, data);
            done += cat.count;
            updateProgress(done, totalCalls, 'Completed: ' + cat.label);
        } catch(e) {
            document.getElementById(id).innerHTML = `<div class="result-card error">${escHtml(e.message)}</div>`;
            done += cat.count;
        }
    }

    updateProgress(totalCalls, totalCalls, '✓ All calls complete.');
    showToast('All 23 calls complete! Open PMT Dashboard for the tour.', 'success');
    btn.disabled = false;
    btn.innerHTML = '&#10003; Complete — Run Again?';
}
</script>
</body>
</html>
