<cfscript>
variables.currentStep = "step2a";
variables.pmtTabs = "Agents,LLMs";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        // Deliberately verbose system prompt (~500 words equivalent)
        verboseSystemPrompt = "You are an incredibly comprehensive, thorough, and detail-oriented baby care specialist assistant working for Mintu's Baby Care, a family-oriented baby wellness service that helps parents, grandparents, nannies, and all types of caregivers with every conceivable aspect of caring for babies and young children. Your role is to provide extremely detailed assistance to anyone who may have questions about a very wide range of different types of baby care topics including but not limited to feeding schedules, sleep training, diaper changes, milestone tracking, teething, bath time routines, tummy time, vaccinations, growth charts, and any other type of baby-related concern that might be affecting a caregiver's ability to provide the best possible care for their little one. When someone comes to you with a concern, no matter how simple or complex it may appear at first glance, you should always provide an extremely thorough, comprehensive, and complete response that covers every possible aspect and consideration related to their baby care question. Make sure to always explain things in great detail and depth, covering all possible causes, all possible remedies, all possible routines to try, and all possible escalation paths to pediatricians. You should also proactively provide lots of additional related baby care information that might be useful even if not directly asked for, because it is always better to provide more information rather than less when it comes to the wellbeing of a precious baby. Always organize your responses with multiple numbered steps, sub-steps, bullet points, headers, and detailed explanations about every possible baby care scenario. Never give a short answer when a long one is possible. Always err on the side of providing too much information about baby care. Remember to consider all edge cases, all possible developmental stages, and all possible environmental factors. Be very thorough in your baby care guidance.";

        // VERBOSE/VAGUE user prompts
        prompts = {
            interact1: "I think there might be something going on with the baby or maybe not I'm not really sure but I was wondering if you could maybe look into this because the baby has been acting a little bit different than usual or maybe it's normal I can't really tell and I think it might have something to do with feeding or maybe sleeping or possibly something else entirely and I'm not sure what the exact issue is but things just seem a little off compared to how they were before whatever this is started happening.",
            interact2: "Can you maybe also check some other things that could potentially be related to what we were just talking about with the baby because I feel like there might be additional factors involved like maybe the routine needs adjusting or maybe there's a developmental thing happening and I think it would be really helpful if you could provide some more comprehensive information about all the different things that could potentially be causing these types of baby behaviors in a household like ours.",
            interact3: "Also I was wondering if you could maybe help with some other baby stuff too like maybe providing some general guidance about best practices for baby care and routines and things like that because I think our family could really benefit from having some more comprehensive information about how to handle all these different baby situations going forward in the future when they come up again which they probably will since babies change so much."
        };

        if (!structKeyExists(prompts, action)) {
            writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));
            abort;
        }

        // Deliberately inefficient agent: no maxTokens, high temperature, verbose system prompt
        if (!isObject(session.agentBefore)) {
            session.agentBefore = Agent({
                CHATMODEL: ChatModel({
                    PROVIDER:    "openAi",
                    APIKEY:      application.openaiKey,
                    MODELNAME:   application.openaiModel,
                    TEMPERATURE: 1.0
                }),
                TOOLS: [{
                    cfc: "mintu_baby.helpers.BabyCareDesk",
                    methods: [
                        { method: "lookupFamilyMember",  description: "Look up a family member or caregiver's details by member ID." },
                        { method: "checkRoutineStatus",  description: "Check the current status of a baby care routine (feeding, sleep, diaper, etc.)." },
                        { method: "createCareTask",      description: "Create a new baby care task with priority and description." }
                    ]
                }]
            });
        }

        rawResp   = session.agentBefore.chat(prompts[action]);
        respText  = rawResp.message ?: rawResp;
        duration  = getTickCount() - startMs;
        tokenEst  = int(len(verboseSystemPrompt & prompts[action] & respText) / 4);

        writeOutput(serializeJSON({
            success:    true,
            action:     action,
            response:   respText,
            duration:   duration,
            tokenEst:   tokenEst,
            promptLen:  len(prompts[action]),
            sysPromptLen: len(verboseSystemPrompt)
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
<title>Agent — Verbose Baby Care Prompts Problem</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step2a">
<cfset variables.pmtTabs = "Agents,LLMs">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 2 &nbsp;|&nbsp; Agent — The Problem</div>
        <h2>Agent — Verbose Baby Care Prompts &amp; Token Waste</h2>
        <p>A poorly configured agent with a 500-word system prompt, vague baby care queries, no token limit, and high temperature. PMT will show 1500+ tokens per call and 5–8 second response times.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-bottleneck">
            <span class="banner-icon">&#9888;</span>
            <div>
                <strong>BOTTLENECK SCENARIO B — Verbose Prompts / Token Waste</strong>
                <code>temperature: 1.0</code> &nbsp; <code>maxTokens: unlimited</code> &nbsp; <code>systemPrompt: ~500 words</code>
                <br>Vague user prompts + verbose system prompt = 1500+ tokens per call. LLM generates rambling responses, driving up latency and cost.
            </div>
        </div>

        <div class="config-box">
            <span style="color:#666">// BAD Agent Config</span><br>
            <span class="cfg-key">Agent</span>({<br>
            &nbsp;&nbsp;<span class="cfg-key">CHATMODEL</span>: <span class="cfg-key">ChatModel</span>({<br>
            &nbsp;&nbsp;&nbsp;&nbsp;<span class="cfg-key">TEMPERATURE</span>: <span class="cfg-bad">1.0</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// BAD: high randomness, verbose output</span><br>
            &nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// MAXTOKENS: not set — unlimited output</span><br>
            &nbsp;&nbsp;&nbsp;&nbsp;<span class="cfg-key">SYSTEMPROMPT</span>: <span class="cfg-bad">"[500-word verbose prompt...]"</span><br>
            &nbsp;&nbsp;}),<br>
            &nbsp;&nbsp;<span class="cfg-key">TOOLS</span>: [{ cfc: <span class="cfg-key">"BabyCareDesk.cfc"</span>, methods: [...] }]<br>
            });
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                LLMs tab &rsaquo; <span class="pmt-tab-ref">Slow LLM Calls</span> (5–8s) &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Token Usage by Provider</span> (large slices) &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Avg Response Time</span> &nbsp;&middot;&nbsp; Agents tab &rsaquo; <span class="pmt-tab-ref">Slow Agent Requests</span>
            </div>
        </div>

        <div class="section">
            <div class="section-title">Interactions (Bad Config)</div>

            <div class="preset-action-bar">
                <button class="btn btn-danger" onclick="sendPreset('interact1','I think there might be something going on with the baby or maybe not I\u2019m not really sure but I was wondering if you could maybe look into this because the baby has been acting a little bit different than usual...')">1 — Vague Baby Concern</button>
                <button class="btn btn-danger" onclick="sendPreset('interact2','Can you maybe also check some other things that could potentially be related to what we were just talking about with the baby because I feel like there might be additional factors involved...')">2 — Vague Follow-up</button>
                <button class="btn btn-danger" onclick="sendPreset('interact3','Also I was wondering if you could maybe help with some other baby stuff too like maybe providing some general guidance about best practices for baby care and routines...')">3 — General Baby Guidance Ask</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu's Baby Care Agent (Bad Config)</span>
                    <span style="margin-left:auto;color:#fc8181;font-size:11px;">temperature:1.0 · no maxTokens · ~500-word prompt</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click a button above to send a vague query and observe the bloated response in PMT.</div>
                </div>
            </div>
        </div>


        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step2_agent.cfm" class="btn btn-secondary">&#8592; Agent</a>
            <a href="step3_mcp.cfm" class="btn btn-primary">Next: MCP &#8594;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
let isWaiting = false;

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function showToast(msg, type) {
    const t = document.getElementById('toast'); t.textContent = msg;
    t.className = 'show toast-' + (type||'success');
    setTimeout(() => { t.className=''; }, 4000);
}
function scrollChat() {
    const c = document.getElementById('chatMsgs'); c.scrollTop = c.scrollHeight;
}
function addUserBubble(text) {
    const c = document.getElementById('chatMsgs');
    const row = document.createElement('div'); row.className = 'chat-row user';
    row.innerHTML = `<div><div class="chat-bbl user">${escHtml(text)}</div>
        <div class="chat-bbl-meta">${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}</div></div>
        <div class="chat-av user">👤</div>`;
    c.appendChild(row); scrollChat(); return row;
}
function addTypingRow() {
    const c = document.getElementById('chatMsgs');
    const row = document.createElement('div'); row.className = 'chat-row bot'; row.id = '_typing';
    row.innerHTML = `<div class="chat-av bot">🤖</div>
        <div class="chat-bbl bot"><div class="typing-dots"><span></span><span></span><span></span></div></div>`;
    c.appendChild(row); scrollChat(); return row;
}
function removeTyping() { document.getElementById('_typing')?.remove(); }

async function sendPreset(action, displayPrompt) {
    if (isWaiting) return;
    isWaiting = true;
    // Clear placeholder on first use
    const ph = document.querySelector('#chatMsgs div[style*="padding:30px"]');
    if (ph) ph.remove();

    addUserBubble(displayPrompt);
    addTypingRow();
    try {
        const data = cfNorm(await fetch(location.pathname, {
            method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action='+action
        }).then(r=>r.json()));
        removeTyping();
        if (!data.success) {
            const row = document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">🤖</div><div class="chat-bbl bot errored">${escHtml(data.error)}</div>`;
            document.getElementById('chatMsgs').appendChild(row);
        } else {
            const row = document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">🤖</div>
                <div>
                  <div class="chat-bbl bot warn">${escHtml(data.response)}</div>
                  <div class="chat-bbl-badges">
                    <span class="metric-badge time">⏱ ${data.duration}ms</span>
                    <span class="metric-badge alert">⚠ ~${data.tokenest} tokens</span>
                  </div>
                  <div class="chat-bbl-meta problem-indicator" style="margin-top:6px;">High token count and slow response time.</div>
                </div>`;
            document.getElementById('chatMsgs').appendChild(row);
            showToast(`${data.duration}ms · ~${data.tokenest} tokens.`);
        }
    } catch(e) {
        removeTyping();
        const row = document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">🤖</div><div class="chat-bbl bot errored">${escHtml(e.message)}</div>`;
        document.getElementById('chatMsgs').appendChild(row);
    }
    scrollChat();
    isWaiting = false;
}
</script>
</body>
</html>
