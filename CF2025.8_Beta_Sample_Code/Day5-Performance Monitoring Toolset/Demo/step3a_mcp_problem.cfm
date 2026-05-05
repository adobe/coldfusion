<cfscript>
variables.currentStep = "step3a";
variables.pmtTabs = "MCP Clients,MCP Servers";

mcpSlowUrl = "http://localhost:8500/mintu_baby/mcp/babySuppliesMcpServerSlow.cfm";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        mcpClient = MCPClient({
            TRANSPORT: { TYPE: "http", URL: mcpSlowUrl }
        });
        agentInst = Agent({
            CHATMODEL: ChatModel({
                PROVIDER:    "openAi",
                APIKEY:      application.openaiKey,
                MODELNAME:   application.openaiModel,
                TEMPERATURE: 0.3,
                MAXTOKENS:   600
            }),
            TOOLS: [{ MCPCLIENT: [mcpClient] }]
        });

        prompts = {
            search:    "Find all newborn diapers available in our baby supplies store.",
            inventory: "Is product DIAP-001 currently in stock? How many packs do we have?",
            order:     "What is the current status of order ORD-BABY-1234?"
        };

        if (!structKeyExists(prompts, action)) {
            writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));
            abort;
        }

        rawResp  = agentInst.chat(prompts[action]);
        duration = getTickCount() - startMs;

        writeOutput(serializeJSON({
            success:  true,
            action:   action,
            response: rawResp.message ?: rawResp,
            duration: duration,
            mcpUrl:   mcpSlowUrl
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
<title>MCP — Slow Server Problem — Mintu Baby Care</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step3a">
<cfset variables.pmtTabs = "MCP Clients,MCP Servers">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 3 &nbsp;|&nbsp; MCP — The Problem</div>
        <h2>MCP Tool Calls — Slow Legacy Server</h2>
        <p>An agent backed by a slow MCP server with 2–4 second response times per tool call and no caching. PMT will show these calls flagged in the Slow MCP Client Calls grid.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-bottleneck">
            <span class="banner-icon">&#9888;</span>
            <div>
                <strong>Slow MCP Tool Calls — Legacy Server</strong>
                MCP Server: <code>MintuBabySuppliesServer-Legacy</code> (<code>babySuppliesMcpServerSlow.cfm</code>)
                <br><code>searchProducts</code>: 3000ms &nbsp; <code>checkInventory</code>: 2000ms &nbsp; <code>getOrderStatus</code>: 4000ms &nbsp; <code>caching: NONE</code>
            </div>
        </div>

        <div class="config-box">
            <span style="color:#666">// MCP Client Config — pointing to SLOW server</span><br>
            <span class="cfg-key">MCPClient</span>({ TRANSPORT: { TYPE: <span class="cfg-key">"http"</span>, URL: <span class="cfg-bad">"...babySuppliesMcpServerSlow.cfm"</span> } })<br><br>
            <span style="color:#666">// BabySuppliesServiceSlow.cfc methods:</span><br>
            <span class="cfg-bad">searchProducts</span>: sleep(3000) &nbsp;&nbsp;<span style="color:#666">// full table scan, no index</span><br>
            <span class="cfg-bad">checkInventory</span>: sleep(2000) &nbsp;&nbsp;<span style="color:#666">// uncached ERP call</span><br>
            <span class="cfg-bad">getOrderStatus</span>: sleep(4000) &nbsp;&nbsp;<span style="color:#666">// chained cross-system APIs</span>
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                MCP Clients tab &rsaquo; <span class="pmt-tab-ref">Slow MCP Client Calls</span> (2000–4000ms) &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Avg Response Time Per Server</span> &nbsp;&middot;&nbsp; Trace Viewer: MCP spans dominating flamegraph
            </div>
        </div>

        <div class="section">
            <div class="section-title">MCP Queries (Slow Server)</div>

            <div class="preset-action-bar">
                <button class="btn btn-danger" onclick="sendPreset('search','Find all newborn diapers available in our baby supplies store.')">🔍 Search Baby Supplies</button>
                <button class="btn btn-danger" onclick="sendPreset('inventory','Is product DIAP-001 currently in stock? How many packs do we have?')">📦 Check Inventory</button>
                <button class="btn btn-danger" onclick="sendPreset('order','What is the current status of order ORD-BABY-1234?')">📋 Track Order</button>
                <button class="btn btn-run-all" id="runAllBtn" onclick="runAll()">&#9654;&#9654; Run All</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot" style="background:#c53030"></div>
                    <span>Mintu's Baby Supplies Bot — Legacy Server</span>
                    <span style="margin-left:auto;color:#fc8181;font-size:11px;">MintuBabySuppliesServer-Legacy</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click a query above or <strong>Run All</strong> for a full conversation.</div>
                </div>
            </div>
        </div>


        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step3_mcp.cfm" class="btn btn-secondary">&#8592; MCP</a>
            <a href="step4_guardrails.cfm" class="btn btn-primary">Next: Guardrails &#8594;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
let isWaiting = false;

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showToast(msg, type) {
    const t=document.getElementById('toast'); t.textContent=msg;
    t.className='show toast-'+(type||'success');
    setTimeout(()=>{t.className='';}, 5000);
}
function scrollChat() { const c=document.getElementById('chatMsgs'); c.scrollTop=c.scrollHeight; }
function addUserBubble(text) {
    const c=document.getElementById('chatMsgs');
    const ph=c.querySelector('div[style*="padding:30px"]'); if(ph) ph.remove();
    const row=document.createElement('div'); row.className='chat-row user';
    row.innerHTML=`<div><div class="chat-bbl user">${escHtml(text)}</div>
        <div class="chat-bbl-meta">${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}</div></div>
        <div class="chat-av user">👤</div>`;
    c.appendChild(row); scrollChat();
}
function addTimedTypingRow() {
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row bot'; row.id='_typing';
    row.innerHTML=`<div class="chat-av bot">🤖</div>
        <div class="chat-bbl bot"><div class="typing-dots"><span></span><span></span><span></span></div>
        &nbsp;<span id="_elapsed" style="font-size:11px;color:#4a5568;">0s</span></div>`;
    c.appendChild(row); scrollChat();
    let s=0;
    const ti=setInterval(()=>{ s++; const el=document.getElementById('_elapsed'); if(el) el.textContent=s+'s'; }, 1000);
    row._ti = ti;
    return row;
}
function removeTyping() {
    const el=document.getElementById('_typing');
    if(el) { if(el._ti) clearInterval(el._ti); el.remove(); }
}

async function runAll() {
    const btn=document.getElementById('runAllBtn');
    btn.disabled=true; btn.textContent='⏳ Running…';
    const turns=[
        {action:'search',   prompt:'Find all newborn diapers available in our baby supplies store.'},
        {action:'inventory', prompt:'Is product DIAP-001 currently in stock? How many packs do we have?'},
        {action:'order',     prompt:'What is the current status of order ORD-BABY-1234?'}
    ];
    for (const t of turns) {
        await sendPreset(t.action, t.prompt);
    }
    btn.disabled=false; btn.innerHTML='&#9654;&#9654; Run All';
}

async function sendPreset(action, displayPrompt) {
    if (isWaiting) return;
    isWaiting = true;
    addUserBubble(displayPrompt);
    addTimedTypingRow();
    try {
        const data=cfNorm(await fetch(location.pathname,{
            method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action='+action
        }).then(r=>r.json()));
        removeTyping();
        if (!data.success) {
            const row=document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">🤖</div><div class="chat-bbl bot errored">${escHtml(data.error)}</div>`;
            document.getElementById('chatMsgs').appendChild(row);
        } else {
            const row=document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">🤖</div>
                <div>
                  <div class="chat-bbl bot warn">${escHtml(data.response)}</div>
                  <div class="chat-bbl-badges">
                    <span class="metric-badge alert">⚠ ${data.duration}ms total</span>
                    <span class="metric-badge time">🔌 Slow MCP server</span>
                  </div>
                  <div class="chat-bbl-meta problem-indicator" style="margin-top:6px;">Slow MCP calls dominated total time.</div>
                </div>`;
            document.getElementById('chatMsgs').appendChild(row);
            showToast('Completed in '+data.duration+'ms.');
        }
    } catch(e) {
        removeTyping();
        const row=document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">🤖</div><div class="chat-bbl bot errored">${escHtml(e.message)}</div>`;
        document.getElementById('chatMsgs').appendChild(row);
    }
    scrollChat();
    isWaiting = false;
}
</script>
</body>
</html>
