<cfscript>
variables.currentStep = "step1";
variables.pmtTabs = "LLMs";

// Handle AJAX POST actions
if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        question = len(trim(form.question ?: "")) ? trim(form.question) : "What are the best practices for newborn sleep safety? Explain in 2-3 sentences.";
        result = { success: true };

        if (action == "chat_openai" || action == "chat_all") {
            t = getTickCount();
            try {
                cm = ChatModel({
                    PROVIDER:  "openAi",
                    APIKEY:    application.openaiKey,
                    MODELNAME: application.openaiModel
                });
                resp = cm.chat(question);
                result.openai = {
                    provider:  "OpenAI",
                    model:     application.openaiModel,
                    response:  resp.message ?: resp,
                    duration:  getTickCount() - t
                };
            } catch (any pe) {
                result.openai = { provider: "OpenAI", model: application.openaiModel, error: pe.message, duration: getTickCount() - t };
            }
        }

        if (action == "chat_anthropic" || action == "chat_all") {
            t = getTickCount();
            try {
                cm2 = ChatModel({
                    PROVIDER:  "anthropic",
                    APIKEY:    application.anthropicKey,
                    MODELNAME: application.anthropicModel
                });
                resp2 = cm2.chat(question);
                result.anthropic = {
                    provider: "Anthropic",
                    model:    application.anthropicModel,
                    response: resp2.message ?: resp2,
                    duration: getTickCount() - t
                };
            } catch (any pe) {
                result.anthropic = { provider: "Anthropic", model: application.anthropicModel, error: pe.message, duration: getTickCount() - t };
            }
        }

        if (action == "chat_mistral" || action == "chat_all") {
            t = getTickCount();
            try {
                cm3 = ChatModel({
                    PROVIDER:  "mistral",
                    APIKEY:    application.mistralkey,
                    MODELNAME: application.mistralModel
                });
                resp3 = cm3.chat(question);
                result.mistral = {
                    provider: "Mistral",
                    model:    application.mistralModel,
                    response: resp3.message ?: resp3,
                    duration: getTickCount() - t
                };
            } catch (any pe) {
                result.mistral = { provider: "Mistral", model: application.mistralModel, error: pe.message, duration: getTickCount() - t };
            }
        }

        if (action == "chat_azure" || action == "chat_all") {
            t = getTickCount();
            try {
                cm4 = ChatModel({
                    PROVIDER:  "azureopenAi",
                    APIKEY:    application.azureopenaikey,
                    BASEURL:   application.azureopenaiEndpoint,
                    MODELNAME: application.azureModelName
                });
                resp4 = cm4.chat(question);
                result.azure = {
                    provider: "Azure OpenAI",
                    model:    application.azureModelName,
                    response: resp4.message ?: resp4,
                    duration: getTickCount() - t
                };
            } catch (any pe) {
                result.azure = { provider: "Azure OpenAI", model: application.azureModelName, error: pe.message, duration: getTickCount() - t };
            }
        }

        if (action == "chat_ollama" || action == "chat_all") {
            t = getTickCount();
            try {
                cm5 = ChatModel({
                    PROVIDER:  "ollama",
                    BASEURL:   application.ollamaurl,
                    MODELNAME: application.ollamaModel
                });
                resp5 = cm5.chat(question);
                result.ollama = {
                    provider: "Ollama (Local)",
                    model:    application.ollamaModel,
                    response: resp5.message ?: resp5,
                    duration: getTickCount() - t
                };
            } catch (any pe) {
                result.ollama = { provider: "Ollama (Local)", model: application.ollamaModel, error: pe.message, duration: getTickCount() - t };
            }
        }

        result.totalDuration = getTickCount() - startMs;
        writeOutput(serializeJSON(result));

    } catch (any e) {
        writeOutput(serializeJSON({
            success: false,
            error:   e.message,
            detail:  e.detail ?: ""
        }));
    }
    abort;
}
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Step 1: LLM Basics — Mintu's Baby Care Assistant</title>
<cfinclude template="_styles.cfm">
<style>
.chat-input-bar {
    display: flex;
    gap: 8px;
    align-items: center;
    padding: 12px 16px;
    border-top: 1px solid #2d3748;
    background: #151d2e;
    border-radius: 0 0 12px 12px;
    flex-wrap: wrap;
}
.chat-input-bar select {
    background: #1a2035;
    color: #e2e8f0;
    border: 1px solid #2d3748;
    border-radius: 8px;
    padding: 8px 12px;
    font-size: 13px;
    cursor: pointer;
    flex-shrink: 0;
}
.chat-input-bar select:focus { outline: none; border-color: #4299e1; }
.chat-input-bar input[type=text] {
    flex: 1;
    min-width: 200px;
    background: #1a2035;
    color: #e2e8f0;
    border: 1px solid #2d3748;
    border-radius: 8px;
    padding: 8px 14px;
    font-size: 13px;
}
.chat-input-bar input[type=text]:focus { outline: none; border-color: #4299e1; }
.chat-input-bar input[type=text]::placeholder { color: #4a5568; }
.provider-icon { display:inline-block; width:28px; height:28px; border-radius:50%; line-height:28px; text-align:center; font-size:14px; flex-shrink:0; }
.pi-openai    { background:#10a37f22; }
.pi-anthropic { background:#d97b3222; }
.pi-mistral   { background:#6c3df022; }
.pi-azure     { background:#0078d422; }
.pi-ollama    { background:#22863a22; }
</style>
</head>
<body>
<cfset variables.currentStep = "step1">
<cfset variables.pmtTabs = "LLMs">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 1 &nbsp;|&nbsp; ChatModel</div>
        <h2>LLM Basics — All 5 Providers</h2>
        <p>Select a provider from the dropdown and send a question, or click <strong>Run All Providers</strong> to query all 5 sequentially. Each call populates the PMT LLMs tab in real time.</p>
    </div>

    <div class="page-content">
        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                LLMs tab &rsaquo; <span class="pmt-tab-ref">Provider Distribution</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Model Distribution</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Token Usage</span> &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Avg Response Time</span> — each message updates in real time
            </div>
        </div>

        <div class="section">
            <div class="chat-window" style="border-radius:12px;">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu's Baby Care Assistant — 5 Providers</span>
                    <span style="margin-left:auto;font-size:11px;color:#90cdf4;display:flex;gap:6px;align-items:center;">
                        <span class="provider-icon pi-openai">🤖</span>
                        <span class="provider-icon pi-anthropic">🧠</span>
                        <span class="provider-icon pi-mistral">✨</span>
                        <span class="provider-icon pi-azure">☁️</span>
                        <span class="provider-icon pi-ollama">💻</span>
                    </span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">
                        Select a provider and type a baby care question, or click <strong>Run All Providers</strong> to see them side-by-side.
                    </div>
                </div>
                <div class="chat-input-bar">
                    <select id="providerSelect">
                        <option value="openai">🤖 OpenAI — gpt-4o-mini</option>
                        <option value="anthropic">🧠 Anthropic — claude-sonnet-4-5</option>
                        <option value="mistral">✨ Mistral — mistral-large-latest</option>
                        <option value="azure">☁️ Azure OpenAI — gpt-5.3-chat</option>
                        <option value="ollama">💻 Ollama — llama3.2 (Local)</option>
                    </select>
                    <input type="text" id="questionInput"
                           value="What are the best practices for newborn sleep safety? Explain in 2-3 sentences."
                           placeholder="Ask a baby care question…"
                           onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();sendOne();}">
                    <button class="btn btn-primary" onclick="sendOne()" id="sendBtn">&#9658; Send</button>
                    <button class="btn btn-run-all" id="runAllBtn" onclick="runAll()">&#9654;&#9654; Run All Providers</button>
                </div>
            </div>
        </div>

        <!-- Nav buttons -->
        <div style="margin-top:24px;display:flex;gap:12px;">
            <a href="index.cfm" class="btn btn-secondary">&#8592; Home</a>
            <a href="step2_agent.cfm" class="btn btn-primary">Next: Agent &#8594;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
const PROVIDERS = ['openai','anthropic','mistral','azure','ollama'];
const PROVIDER_META = {
    openai:    { label:'OpenAI',       model:'gpt-4o-mini',          action:'chat_openai',    icon:'🤖', cls:'pi-openai' },
    anthropic: { label:'Anthropic',    model:'claude-sonnet-4-5',    action:'chat_anthropic', icon:'🧠', cls:'pi-anthropic' },
    mistral:   { label:'Mistral',      model:'mistral-large-latest', action:'chat_mistral',   icon:'✨', cls:'pi-mistral' },
    azure:     { label:'Azure OpenAI', model:'gpt-5.3-chat',         action:'chat_azure',     icon:'☁️', cls:'pi-azure' },
    ollama:    { label:'Ollama',       model:'llama3.2 (Local)',      action:'chat_ollama',    icon:'💻', cls:'pi-ollama' }
};

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showToast(msg, type) {
    const t=document.getElementById('toast'); t.textContent=msg;
    t.className='show toast-'+(type||'success');
    setTimeout(()=>{t.className='';}, 3500);
}
function scrollChat() { const c=document.getElementById('chatMsgs'); c.scrollTop=c.scrollHeight; }
function clearPlaceholder() {
    const ph=document.getElementById('chatMsgs').querySelector('div[style*="padding:30px"]');
    if (ph) ph.remove();
}

function addUserBubble(text, providerKey) {
    clearPlaceholder();
    const m=PROVIDER_META[providerKey]||{};
    const label=m.label ? '→ '+m.label : '→ All Providers';
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row user';
    row.innerHTML=`<div>
        <div class="chat-bbl user">${escHtml(text)}</div>
        <div class="chat-bbl-meta">${label} &nbsp;·&nbsp; ${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}</div>
    </div><div class="chat-av user">👤</div>`;
    c.appendChild(row); scrollChat();
}

function addTypingRow(id, label) {
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row bot'; row.id=id;
    row.innerHTML=`<div class="chat-av bot">${label||'⏳'}</div>
        <div class="chat-bbl bot">
          <div class="typing-dots"><span></span><span></span><span></span></div>
          <div style="font-size:11px;color:#718096;margin-top:4px">Calling LLM…</div>
        </div>`;
    c.appendChild(row); scrollChat();
}
function removeTyping(id) { document.getElementById(id)?.remove(); }

function addBotBubble(providerKey, response, model, duration, isError) {
    const meta=PROVIDER_META[providerKey]||{icon:'🤖',label:providerKey,model:model||'',cls:''};
    const row=document.createElement('div'); row.className='chat-row bot';
    if (isError) {
        row.innerHTML=`<div class="chat-av bot ${meta.cls}">${meta.icon}</div>
            <div>
              <div class="chat-bbl-badges"><span class="metric-badge model">${escHtml(meta.label)}</span></div>
              <div class="chat-bbl bot errored">❌ ${escHtml(response)}</div>
            </div>`;
    } else {
        row.innerHTML=`<div class="chat-av bot ${meta.cls}">${meta.icon}</div>
            <div>
              <div class="chat-bbl-badges">
                <span class="metric-badge model">${escHtml(meta.label)}</span>
                <span class="metric-badge score">⚡ ${escHtml(model||meta.model)}</span>
              </div>
              <div class="chat-bbl bot">${escHtml(response)}</div>
              <div class="chat-bbl-badges" style="margin-top:4px">
                <span class="metric-badge time">⏱ ${duration}ms</span>
              </div>
            </div>`;
    }
    document.getElementById('chatMsgs').appendChild(row); scrollChat();
}

function addSystemBubble(html) {
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div');
    row.style.cssText='text-align:center;padding:8px 0;';
    row.innerHTML=`<span style="background:#1a2035;color:#90cdf4;border-radius:20px;padding:4px 16px;font-size:11px;">${html}</span>`;
    c.appendChild(row); scrollChat();
}

async function callProvider(providerKey, question) {
    const meta=PROVIDER_META[providerKey];
    const body=new URLSearchParams({action: meta.action, question: question});
    const data=cfNorm(await fetch(location.pathname,{
        method:'POST',
        headers:{'Content-Type':'application/x-www-form-urlencoded'},
        body: body.toString()
    }).then(r=>r.json()));
    if (!data.success) throw new Error(data.error||'Request failed');
    const pd=data[providerKey];
    if (!pd) throw new Error('No response data for '+providerKey);
    return pd;
}

async function sendOne() {
    const pk=document.getElementById('providerSelect').value;
    const q=document.getElementById('questionInput').value.trim();
    if (!q) { showToast('Please enter a question','error'); return; }
    const sendBtn=document.getElementById('sendBtn');
    sendBtn.disabled=true;
    const typingId='_typing_'+pk+'_'+Date.now();
    addUserBubble(q, pk);
    addTypingRow(typingId, PROVIDER_META[pk].icon);
    try {
        const pd=await callProvider(pk, q);
        removeTyping(typingId);
        if (pd.error) {
            addBotBubble(pk, pd.error, pd.model, pd.duration, true);
            showToast('Error from '+PROVIDER_META[pk].label+': '+pd.error, 'error');
        } else {
            addBotBubble(pk, pd.response, pd.model, pd.duration, false);
            showToast(PROVIDER_META[pk].label+' responded in '+pd.duration+'ms.');
        }
    } catch(e) {
        removeTyping(typingId);
        addBotBubble(pk, e.message, '', 0, true);
        showToast('Error: '+e.message, 'error');
    }
    sendBtn.disabled=false;
}

async function runAll() {
    const q=document.getElementById('questionInput').value.trim()||'What are the best practices for newborn sleep safety? Explain in 2-3 sentences.';
    const btn=document.getElementById('runAllBtn');
    const sendBtn=document.getElementById('sendBtn');
    btn.disabled=true; sendBtn.disabled=true;
    btn.textContent='⏳ Running all…';

    // Single user bubble for the batch
    clearPlaceholder();
    const c=document.getElementById('chatMsgs');
    const userRow=document.createElement('div'); userRow.className='chat-row user';
    userRow.innerHTML=`<div>
        <div class="chat-bbl user">${escHtml(q)}</div>
        <div class="chat-bbl-meta">→ All 5 Providers &nbsp;·&nbsp; ${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}</div>
    </div><div class="chat-av user">👤</div>`;
    c.appendChild(userRow); scrollChat();

    addSystemBubble('Querying all 5 providers sequentially…');

    let successCount=0;
    for (const pk of PROVIDERS) {
        const meta=PROVIDER_META[pk];
        const typingId='_typing_all_'+pk;
        addTypingRow(typingId, meta.icon);
        try {
            const pd=await callProvider(pk, q);
            removeTyping(typingId);
            if (pd.error) {
                addBotBubble(pk, pd.error, pd.model, pd.duration, true);
            } else {
                addBotBubble(pk, pd.response, pd.model, pd.duration, false);
                successCount++;
            }
        } catch(e) {
            removeTyping(typingId);
            addBotBubble(pk, e.message, '', 0, true);
        }
    }
    addSystemBubble(`✓ ${successCount}/5 providers responded.`);
    btn.disabled=false; sendBtn.disabled=false;
    btn.innerHTML='&#9654;&#9654; Run All Providers';
    showToast(successCount+'/5 providers complete.', successCount>0?'success':'error');
}
</script>
</body>
</html>
