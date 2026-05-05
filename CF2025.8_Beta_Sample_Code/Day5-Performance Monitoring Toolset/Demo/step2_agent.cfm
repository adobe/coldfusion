<cfscript>
variables.currentStep = "step2";
variables.pmtTabs = "Agents,LLMs";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        // Concise, focused system prompt (~80 words)
        conciseSystemPrompt = "You are Mintu's Baby Care Assistant. Help parents with baby care questions concisely. Available tools: family member lookup, routine status checks, care task creation. Always: 1) identify the specific concern, 2) check relevant routines, 3) provide clear guidance or create a care task. Be direct and caring. Limit responses to essential information only.";

        // Direct, specific user prompts
        prompts = {
            interact1: "Baby Mintu (BABY-001) seems fussy after feeding. Check the feeding routine status and create a P3 care task.",
            interact2: "Check if Mintu's sleep routine is on track and get the status of care task CARE-DEMO-001.",
            interact3: "Who is the primary caregiver for evenings? Create a P4 task for updating the baby's milestone tracker."
        };

        if (!structKeyExists(prompts, action)) {
            writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));
            abort;
        }

        // Optimized agent: maxTokens=300, low temperature, concise system prompt
        if (!isObject(session.agentAfter)) {
            session.agentAfter = Agent({
                CHATMODEL: ChatModel({
                    PROVIDER:    "openAi",
                    APIKEY:      application.openaiKey,
                    MODELNAME:   application.openaiModel,
                    TEMPERATURE: 0.3,
                    MAXTOKENS:   300
                }),
                TOOLS: [{
                    cfc: "mintu_baby.helpers.BabyCareDesk",
                    methods: [
                        { method: "lookupFamilyMember",  description: "Look up a family member or caregiver's details by member ID." },
                        { method: "checkRoutineStatus",  description: "Check the current status of a baby care routine (feeding, sleep, diaper, etc.)." },
                        { method: "createCareTask",      description: "Create a new baby care task with priority and description." },
                        { method: "getTaskStatus",       description: "Get the current status of an existing care task by task ID." }
                    ]
                }]
            });
        }

        rawResp   = session.agentAfter.chat(prompts[action]);
        respText  = rawResp.message ?: rawResp;
        duration  = getTickCount() - startMs;
        tokenEst  = int(len(conciseSystemPrompt & prompts[action] & respText) / 4);

        writeOutput(serializeJSON({
            success:       true,
            action:        action,
            response:      respText,
            duration:      duration,
            tokenEst:      tokenEst,
            promptLen:     len(prompts[action]),
            sysPromptLen:  len(conciseSystemPrompt)
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
<title>Agent — Mintu's Baby Care</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step2">
<cfset variables.pmtTabs = "Agents,LLMs">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 2 &nbsp;|&nbsp; Agent — How It Works</div>
        <h2>Agent — Mintu's Baby Care with Tools &amp; Memory</h2>
        <p>Agent with a concise system prompt, direct user queries, maxTokens=300, and temperature=0.3. Chat with the agent and watch PMT Agents + LLMs tabs populate.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128268;</span>
            <div>
                <strong>Agent Configuration</strong>
                <code>temperature: 0.3</code> &nbsp; <code>maxTokens: 300</code> &nbsp; <code>systemPrompt: ~80 words</code>
                <br>Direct, actionable prompts produce focused responses. Token count drops from 1500+ to 300–500. Response time drops from 5–8s to 1–2s.
            </div>
        </div>

        <div class="config-box">
            <span style="color:#666">// Agent Config</span><br>
            <span class="cfg-key">Agent</span>({<br>
            &nbsp;&nbsp;<span class="cfg-key">CHATMODEL</span>: <span class="cfg-key">ChatModel</span>({<br>
            &nbsp;&nbsp;&nbsp;&nbsp;<span class="cfg-key">TEMPERATURE</span>: <span class="cfg-good">0.3</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">//  focused, deterministic</span><br>
            &nbsp;&nbsp;&nbsp;&nbsp;<span class="cfg-key">MAXTOKENS</span>: <span class="cfg-good">300</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">//  constrains response length</span><br>
            &nbsp;&nbsp;&nbsp;&nbsp;<span class="cfg-key">SYSTEMPROMPT</span>: <span class="cfg-good">"[80-word concise prompt]"</span><br>
            &nbsp;&nbsp;}),<br>
            &nbsp;&nbsp;<span class="cfg-key">TOOLS</span>: [{ cfc: <span class="cfg-key">"BabyCareDesk.cfc"</span>, methods: [...] }]<br>
            });
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                LLMs tab &rsaquo; <span class="pmt-tab-ref">LLM Calls</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Avg Response Time</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Token Usage</span> &nbsp;&middot;&nbsp; Agents tab &rsaquo; <span class="pmt-tab-ref">Agent Requests</span>
            </div>
        </div>

        <div class="section">
            <div class="section-title">Chat with the Agent</div>

            <div class="preset-action-bar">
                <button class="btn btn-success" onclick="sendPreset('interact1',&quot;Baby Mintu (BABY-001) seems fussy after feeding. Check the feeding routine status and create a P3 care task.&quot;)">1 — Feeding Concern</button>
                <button class="btn btn-success" onclick="sendPreset('interact2','Check if Mintu\'s sleep routine is on track and get the status of care task CARE-DEMO-001.')">2 — Sleep &amp; Task Check</button>
                <button class="btn btn-success" onclick="sendPreset('interact3','Who is the primary caregiver for evenings? Create a P4 task for updating the baby\'s milestone tracker.')">3 — Caregiver &amp; Milestone</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu's Baby Care Agent</span>
                    <span style="margin-left:auto;color:#68d391;font-size:11px;">temperature:0.3 · maxTokens:300 · ~80-word prompt</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click a button above to chat with the Agent.</div>
                </div>
            </div>
        </div>


        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step1_chatmodel.cfm" class="btn btn-secondary">&#8592; ChatModel</a>
            <a href="step2a_agent_problem.cfm" class="btn btn-primary">Next: Agent — The Problem &#8594;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
let isWaiting = false;

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showToast(msg, type) {
    const t = document.getElementById('toast'); t.textContent = msg;
    t.className = 'show toast-'+(type||'success');
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

async function sendPreset(action, displayPrompt) {
    if (isWaiting) return;
    isWaiting = true;
    addUserBubble(displayPrompt);
    addTypingRow();
    try {
        const data = cfNorm(await fetch(location.pathname, {
            method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
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
                    <span class="metric-badge tokens">~${data.tokenest} tokens</span>
                  </div>
                </div>`;
            document.getElementById('chatMsgs').appendChild(row);
            showToast(`${data.duration}ms · ~${data.tokenest} tokens — much better than 2A!`);
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
