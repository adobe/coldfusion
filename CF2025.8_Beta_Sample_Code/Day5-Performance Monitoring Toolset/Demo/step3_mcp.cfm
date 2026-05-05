<cfscript>
variables.currentStep = "step3";
variables.pmtTabs = "MCP Clients,MCP Servers";

mcpFastUrl = "http://localhost:8500/mintu_baby/mcp/babySuppliesMcpServer.cfm";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        mcpClient = MCPClient({
            TRANSPORT: { TYPE: "http", URL: mcpFastUrl }
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
            mcpUrl:   mcpFastUrl
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
<title>MCP Tools — Mintu Baby Care</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step3">
<cfset variables.pmtTabs = "MCP Clients,MCP Servers">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 3 &nbsp;|&nbsp; MCP — How It Works</div>
        <h2>MCP — Remote Tool Server</h2>
        <p>Agent calls remote baby supplies tools via MCP. PMT MCP Servers and MCP Clients tabs track each tool call, execution time, and latency.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128268;</span>
            <div>
                <strong>MCP Server Configuration</strong>
                MCP Server: <code>babySuppliesMcpServer.cfm</code> backed by <code>BabySuppliesService.cfc</code>
                <br><code>searchProducts</code>: ~150ms &nbsp; <code>checkInventory</code>: ~100ms &nbsp; <code>getOrderStatus</code>: ~200ms &nbsp; <code>caching: ENABLED</code>
            </div>
        </div>

        <div class="config-box">
            <span style="color:#666">// MCP Client Config — pointing to Baby Supplies server</span><br>
            <span class="cfg-key">MCPClient</span>({ TRANSPORT: { TYPE: <span class="cfg-key">"http"</span>, URL: <span class="cfg-good">"...babySuppliesMcpServer.cfm"</span> } })<br><br>
            <span style="color:#666">// BabySuppliesService.cfc methods (with caching):</span><br>
            <span class="cfg-good">searchProducts</span>: sleep(150) + cache &nbsp;&nbsp;<span style="color:#666">// indexed search + result cache</span><br>
            <span class="cfg-good">checkInventory</span>: sleep(100) + cache &nbsp;&nbsp;<span style="color:#666">// cached warehouse API</span><br>
            <span class="cfg-good">getOrderStatus</span>: sleep(200) + cache &nbsp;&nbsp;<span style="color:#666">// cached order lookup</span>
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                MCP Clients tab &rsaquo; <span class="pmt-tab-ref">Avg Response Time Per Server</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">MCP Client Calls</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Trace Viewer</span>
            </div>
        </div>

        <div class="section">
            <div class="section-title">Query the MCP Baby Supplies Server</div>

            <div class="preset-action-bar">
                <button class="btn btn-success" onclick="sendPreset('search','Find all newborn diapers available in our baby supplies store.')">🔍 Search Baby Supplies</button>
                <button class="btn btn-success" onclick="sendPreset('inventory','Is product DIAP-001 currently in stock? How many packs do we have?')">📦 Check Inventory</button>
                <button class="btn btn-success" onclick="sendPreset('order','What is the current status of order ORD-BABY-1234?')">📋 Track Order</button>
                <button class="btn btn-run-all" id="runAllBtn" onclick="runAll()">&#9654;&#9654; Run All</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu's Baby Supplies Bot</span>
                    <span style="margin-left:auto;color:#90cdf4;font-size:11px;">MintuBabySuppliesServer</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click a query above or <strong>Run All</strong> for a full conversation.</div>
                </div>
            </div>
        </div>


        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step2a_agent_problem.cfm" class="btn btn-secondary">&#8592; Agent</a>
            <a href="step3a_mcp_problem.cfm" class="btn btn-primary">Next: MCP — The Problem &#8594;</a>
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
    setTimeout(()=>{t.className='';}, 4000);
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
function addTypingRow() {
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row bot'; row.id='_typing';
    row.innerHTML=`<div class="chat-av bot">🤖</div><div class="chat-bbl bot"><div class="typing-dots"><span></span><span></span><span></span></div></div>`;
    c.appendChild(row); scrollChat(); return row;
}
function removeTyping() { document.getElementById('_typing')?.remove(); }

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
    addTypingRow();
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
                  <div class="chat-bbl bot">${escHtml(data.response)}</div>
                  <div class="chat-bbl-badges">
                    <span class="metric-badge time">⏱ ${data.duration}ms</span>
                  </div>
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
