<cfscript>
variables.currentStep = "step7";
variables.pmtTabs = "Agents,LLMs,RAG,Vector Stores,MCP Clients,Trace Viewer";

mcpFastUrl = "http://localhost:8500/mintu_baby/mcp/babySuppliesMcpServer.cfm";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {

        if (action == "setup") {
            // AbstractCfcGuardrail caches the UDFMethod at construction time via
            // CfcIntrospector.getTemplateProxy() (static cache). Clear the cache first so
            // any source changes to InputSafetyGuardrail.cfc are compiled fresh.
            try {
                createObject("java", "coldfusion.ai.mcp.server.tools.CfcIntrospector")
                    .clearCache("InputSafetyGuardrail");
            } catch (any ignore) {}

            // Reset the session agent so a new instance (with fresh cached UDFMethod) is built.
            session.fullAgent = "";
            session.chatHistory = [];

            // Initialize the full-stack agent (stored in session for multi-turn memory)
            dataDir = application.dataDir;
            if (!directoryExists(dataDir) || arrayLen(directoryList(dataDir, false, "array", "*.txt")) == 0) {
                writeOutput(serializeJSON({ success: false, error: "Please run Step 2 first to create the knowledge base documents." }));
                abort;
            }

            vsClient = vectorStore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider:  "ollama",
                    modelName: application.ollamaEmbedModel,
                    baseUrl:   application.ollamaurl
                }
            });
            mcpClient = MCPClient({
                TRANSPORT: { TYPE: "http", URL: mcpFastUrl }
            });

            session.fullAgent = Agent({
                CHATMODEL: ChatModel({
                    PROVIDER:    "openAi",
                    APIKEY:      application.openaiKey,
                    MODELNAME:   application.openaiModel,
                    TEMPERATURE: 0.4,
                    MAXTOKENS:   500
                }),
                TOOLS: [
                    {
                        cfc: "mintu_baby.helpers.BabyCareDesk",
                        methods: [
                            { method: "lookupFamilyMember",  description: "Look up a family member or baby profile by their ID." },
                            { method: "checkRoutineStatus",  description: "Check the current status of a baby care routine (feeding, sleep, etc.)." },
                            { method: "createCareTask",      description: "Create a new baby care task with priority and description." },
                            { method: "getTaskStatus",       description: "Get the current status of an existing care task by task ID." }
                        ]
                    },
                    { MCPCLIENT: [mcpClient] }
                ],
                INPUTGUARDRAILS: [expandPath("/mintu_baby/helpers/InputSafetyGuardrail.cfc")],
                ingestion: {
                    source:           dataDir,
                    documentSplitter: { chunkSize: 300, chunkOverlap: 75 },
                    vectorStoreIngestor: { vectorStore: vsClient, minScore: 0.55 }
                },
                retrievalAugmentor: {
                    contentRetriever: { vectorStore: vsClient, minScore: 0.55 }
                }
            });

            // Ingest knowledge base into this agent's vector store
            ingestResult = session.fullAgent.ingest();
            session.chatHistory = [];

            writeOutput(serializeJSON({
                success:    true,
                message:    "Full-stack baby care agent initialized successfully! Components active: RAG (5 baby care docs ingested) + Baby Care Tools (4 methods) + MCP Baby Supplies Client + Input Guardrail. Memory enabled for multi-turn conversation.",
                components: ["RAG Knowledge Base (5 baby care docs)", "Baby Care Desk Tools (lookupFamilyMember, checkRoutineStatus, createCareTask, getTaskStatus)", "MCP Baby Supplies Client (searchProducts, checkInventory, getOrderStatus)", "Input Safety Guardrail", "Multi-turn Memory"],
                ingested:   true
            }));
            abort;
        }

        // Ensure agent is initialized
        if (!isObject(session.fullAgent)) {
            writeOutput(serializeJSON({ success: false, error: "Agent not set up. Please click 'Setup Agent' first." }));
            abort;
        }

        turnPrompts = {
            turn1: "Hi, I'm a new parent and need help with safe sleep practices for baby Mintu. What should I know?",
            turn2: "Can you look up baby BABY-001's profile and check if the feeding routine is on schedule?",
            turn3: "We're running low on diapers. Can you check if newborn diapers (DIAP-001) are in stock at the baby store?",
            turn4: "Thanks for all the help! Can you create a P3 care task summarizing everything — sleep setup advice, feeding check, and diaper order for baby Mintu?"
        };

        if (!structKeyExists(turnPrompts, action)) {
            writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));
            abort;
        }

        rawResp   = session.fullAgent.chat(turnPrompts[action]);
        respText  = rawResp.message ?: rawResp;
        duration  = getTickCount() - startMs;
        tokenEst  = int(len(turnPrompts[action] & respText) / 4);

        arrayAppend(session.chatHistory, {
            turn:      action,
            user:      turnPrompts[action],
            assistant: respText,
            duration:  duration
        });

        writeOutput(serializeJSON({
            success:  true,
            action:   action,
            prompt:   turnPrompts[action],
            response: respText,
            duration: duration,
            tokenEst: tokenEst,
            history:  session.chatHistory
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
<title>Step 7: Full Stack Agent — Mintu's Baby Care Bot</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step7">
<cfset variables.pmtTabs = "Agents,LLMs,RAG,Vector Stores,MCP Clients,Trace Viewer">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 7 &nbsp;|&nbsp; Full Production Agent</div>
        <h2>Full Stack Agent — All 6 PMT Tabs</h2>
        <p>The "ultimate agent" combining RAG, baby care tools, MCP client, guardrails, and multi-turn memory. Each turn populates a different PMT tab. After all 4 turns, open Trace Viewer for the complete flamegraph.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128268;</span>
            <div>
                <strong>Agent Components (all active simultaneously)</strong>
                RAG Knowledge Base (baby care docs) &nbsp;|&nbsp; Baby Care Desk Tools &nbsp;|&nbsp; MCP Baby Supplies Client &nbsp;|&nbsp; Input Safety Guardrail &nbsp;|&nbsp; Multi-turn Memory
            </div>
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch — per Turn</span>
                Turn 1 &rsaquo; <span class="pmt-tab-ref">RAG</span> + <span class="pmt-tab-ref">LLMs</span> &nbsp;&middot;&nbsp;
                Turn 2 &rsaquo; <span class="pmt-tab-ref">Agents</span> + <span class="pmt-tab-ref">Tools</span> &nbsp;&middot;&nbsp;
                Turn 3 &rsaquo; <span class="pmt-tab-ref">MCP Clients</span> &nbsp;&middot;&nbsp;
                Turn 4 &rsaquo; All 6 tabs &nbsp;&middot;&nbsp;
                After all turns: <span class="pmt-tab-ref">Trace Viewer</span> → full flamegraph with every span type
            </div>
        </div>

        <!-- Setup + turns in one flow -->
        <div class="section">
            <div class="section-title">Setup &amp; Multi-turn Conversation</div>

            <div class="preset-action-bar">
                <button class="btn btn-primary" id="setupBtn" onclick="setupAgent()" title="Initialize agent + ingest KB">&#9881; Setup Agent</button>
                <span style="color:#4a5568;font-size:13px;padding:0 4px">|</span>
                <button class="btn btn-primary"  id="t1Btn" onclick="runTurn('turn1')" title="Sleep safety → RAG + LLM">Turn 1: Sleep Safety</button>
                <button class="btn btn-primary"  id="t2Btn" onclick="runTurn('turn2')" title="Baby profile + feeding check → Baby Care Tools">Turn 2: Baby Profile &amp; Feeding</button>
                <button class="btn btn-primary"  id="t3Btn" onclick="runTurn('turn3')" title="Diaper inventory → MCP">Turn 3: Diaper Stock</button>
                <button class="btn btn-primary"  id="t4Btn" onclick="runTurn('turn4')" title="Care task creation → Baby Care Tool + memory">Turn 4: Create Care Task</button>
                <button class="btn btn-run-all"  id="runAllBtn" onclick="runAll()" title="Setup then run all 4 turns sequentially">&#9654;&#9654; Run All Turns</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu's Care Bot</span>
                    <span style="margin-left:auto;font-size:11px;color:#90cdf4">RAG · Baby Care Tools · MCP · Guardrail · Memory</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click <strong>Setup Agent</strong> first (always re-setup after a server restart or guardrail change), then run turns individually or click <strong>Run All Turns</strong>.</div>
                </div>
            </div>
        </div>

        <div class="banner banner-info" id="traceViewerHint" style="display:none;margin-top:8px;">
            <span class="banner-icon">&#127909;</span>
            <div>
                <strong>All 4 turns complete — open PMT &gt; Trace Viewer.</strong>
                Find the most recent trace for this agent. The flamegraph will show spans for: guardrail check → RAG retrieval → LLM call → tool calls → MCP calls — the complete picture of AI execution in one view.
            </div>
        </div>

        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step6a_rag_problem.cfm" class="btn btn-secondary">&#8592; RAG</a>
            <a href="step8_load_generator.cfm" class="btn btn-primary">Next: Load Generator &#8594;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
let turnsCompleted = 0;
let agentReady = false;

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showToast(msg, type) {
    const t=document.getElementById('toast'); t.textContent=msg;
    t.className='show toast-'+(type||'success');
    setTimeout(()=>{t.className='';}, 4500);
}
function scrollChat() { const c=document.getElementById('chatMsgs'); c.scrollTop=c.scrollHeight; }

function clearPlaceholder() {
    const ph=document.getElementById('chatMsgs').querySelector('div[style*="padding:30px"]');
    if (ph) ph.remove();
}
function addSystemBubble(html) {
    clearPlaceholder();
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div');
    row.style.cssText='text-align:center;padding:10px 0;';
    row.innerHTML=`<span style="background:#1a2035;color:#90cdf4;border-radius:20px;padding:5px 16px;font-size:12px;">${html}</span>`;
    c.appendChild(row); scrollChat();
}
function addUserBubble(text) {
    clearPlaceholder();
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row user';
    row.innerHTML=`<div><div class="chat-bbl user">${escHtml(text)}</div>
        <div class="chat-bbl-meta">${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}</div></div>
        <div class="chat-av user">👤</div>`;
    c.appendChild(row); scrollChat();
}
function addTypingRow(label) {
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row bot'; row.id='_typing';
    row.innerHTML=`<div class="chat-av bot">🤖</div>
        <div class="chat-bbl bot">
          <div class="typing-dots"><span></span><span></span><span></span></div>
          <div style="font-size:11px;color:#718096;margin-top:4px">${label||'Care Bot is thinking...'}</div>
        </div>`;
    c.appendChild(row); scrollChat();
}
function removeTyping() { document.getElementById('_typing')?.remove(); }

const turnMeta = {
    turn1: { label: 'Retrieving sleep safety info from knowledge base...', pmt: 'PMT: RAG tab + LLMs tab',          icon: '📚' },
    turn2: { label: 'Looking up baby profile + checking feeding routine...', pmt: 'PMT: Agents tab + Tools',          icon: '🍼' },
    turn3: { label: 'Querying baby supplies MCP store...',               pmt: 'PMT: MCP Clients tab',             icon: '🛒' },
    turn4: { label: 'Creating care task (using memory)...',       pmt: 'PMT: All 6 tabs now populated',  icon: '📋' }
};
const turnPrompts = {
    turn1: "Hi, I'm a new parent and need help with safe sleep practices for baby Mintu. What should I know?",
    turn2: "Can you look up baby BABY-001's profile and check if the feeding routine is on schedule?",
    turn3: "We're running low on diapers. Can you check if newborn diapers (DIAP-001) are in stock at the baby store?",
    turn4: "Thanks for all the help! Can you create a P3 care task summarizing everything — sleep setup advice, feeding check, and diaper order for baby Mintu?"
};

async function setupAgent() {
    const btn=document.getElementById('setupBtn');
    btn.disabled=true; btn.textContent='⏳ Setting up...';
    addSystemBubble('⚙️ Initializing full-stack agent — ingesting baby care knowledge base…');
    addTypingRow('Setting up RAG + Baby Care Tools + MCP Client + Guardrail…');
    try {
        const data=cfNorm(await fetch(location.pathname,{
            method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action=setup'
        }).then(r=>r.json()));
        removeTyping();
        if (!data.success) {
            addSystemBubble('❌ Setup failed: '+escHtml(data.error));
            showToast('Setup error: '+data.error,'error');
            btn.disabled=false; btn.textContent='⚙ Setup Agent';
            return;
        }
        const row=document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">🤖</div>
            <div>
              <div class="chat-bbl bot">✅ <strong>Mintu's Care Bot is ready!</strong> All components active:<br>${(data.components||[]).map(c=>`<br>• ${escHtml(c)}`).join('')}</div>
              <div class="chat-bbl-badges">${(data.components||[]).map(c=>`<span class="metric-badge score">✓ ${escHtml(c.split(' ')[0])}</span>`).join('')}</div>
            </div>`;
        document.getElementById('chatMsgs').appendChild(row); scrollChat();
        agentReady=true;
        showToast('Full-stack baby care agent ready — all 5 components active!','success');
        btn.disabled=false; btn.innerHTML='&#9881; Re-Setup';
    } catch(e) {
        removeTyping();
        addSystemBubble('❌ '+escHtml(e.message));
        btn.disabled=false; btn.innerHTML='&#9881; Setup Agent';
    }
}

async function runTurn(action) {
    if (!agentReady) { showToast('Click "Setup Agent" first','error'); return; }
    const meta=turnMeta[action]||{label:'Agent processing…',pmt:'',icon:'🤖'};
    addUserBubble(turnPrompts[action]);
    addTypingRow(meta.label);
    const btnId={turn1:'t1Btn',turn2:'t2Btn',turn3:'t3Btn',turn4:'t4Btn'}[action];
    const btn=document.getElementById(btnId);
    if (btn) { btn.disabled=true; }
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
            showToast('Error on '+action+': '+data.error,'error');
        } else {
            const row=document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">${meta.icon}</div>
                <div>
                  <div class="chat-bbl bot">${escHtml(data.response)}</div>
                  <div class="chat-bbl-badges">
                    <span class="metric-badge time">⏱ ${data.duration}ms</span>
                    <span class="metric-badge tokens">~${data.tokenest} tokens</span>
                    <span class="metric-badge model">${escHtml(meta.pmt)}</span>
                  </div>
                </div>`;
            document.getElementById('chatMsgs').appendChild(row);
            turnsCompleted++;
            showToast('Turn '+action.slice(-1)+' done ('+data.duration+'ms) — '+meta.pmt,'success');
            if (turnsCompleted >= 4) {
                document.getElementById('traceViewerHint').style.display='flex';
                addSystemBubble('🎉 All 4 turns complete — open PMT &gt; Trace Viewer for the full flamegraph!');
            }
        }
        scrollChat();
    } catch(e) {
        removeTyping();
        const row=document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">🤖</div><div class="chat-bbl bot errored">${escHtml(e.message)}</div>`;
        document.getElementById('chatMsgs').appendChild(row);
    }
    if (btn) { btn.disabled=false; }
}

async function runAll() {
    const btn=document.getElementById('runAllBtn');
    btn.disabled=true; btn.textContent='⏳ Running…';
    // setup first if not already ready
    if (!agentReady) { await setupAgent(); }
    if (!agentReady) { btn.disabled=false; btn.innerHTML='&#9654;&#9654; Run All Turns'; return; }
    for (const t of ['turn1','turn2','turn3','turn4']) {
        await runTurn(t);
    }
    btn.disabled=false; btn.innerHTML='&#9654;&#9654; Run All Turns';
}
</script>
</body>
</html>
