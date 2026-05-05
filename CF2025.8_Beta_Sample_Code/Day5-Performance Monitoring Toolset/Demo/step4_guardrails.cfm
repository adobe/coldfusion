<cfscript>
variables.currentStep = "step4";
variables.pmtTabs = "Agents,Trace Viewer";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        inputGuardrailPath  = expandPath("/mintu_baby/helpers/InputSafetyGuardrail.cfc");
        outputGuardrailPath = expandPath("/mintu_baby/helpers/PIIProtectionGuardrail.cfc");

        agentWithGuardrails = Agent({
            CHATMODEL: ChatModel({
                PROVIDER:    "openAi",
                APIKEY:      application.openaiKey,
                MODELNAME:   application.openaiModel,
                TEMPERATURE: 0.3,
                MAXTOKENS:   350
            }),
            TOOLS: [{
                cfc: "mintu_baby.helpers.BabyCareDesk",
                methods: [
                    { method: "lookupFamilyMember",    description: "Look up a family member's details by member ID for Mintu's Baby Care." },
                    { method: "checkRoutineStatus", description: "Check the current status of a named baby care routine (feeding, sleeping, diaper changes)." }
                ]
            }],
            INPUTGUARDRAILS:  [inputGuardrailPath],
            OUTPUTGUARDRAILS: [outputGuardrailPath]
        });

        prompts = {
            test_pass:  "What is the recommended room temperature for a newborn's nursery?",
            test_warn:  "My baby has a fever! I need help immediately!",
            test_block: "Should I give honey to my newborn baby?",
            test_pii:   "What is family member PARENT-001's phone number and email address?"
        };

        if (!structKeyExists(prompts, action)) {
            writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));
            abort;
        }

        response = "";
        guardrailTriggered = false;
        guardrailType = "";

        try {
            rawResp  = agentWithGuardrails.chat(prompts[action]);
            response = isStruct(rawResp) ? (rawResp.message ?: serializeJSON(rawResp)) : rawResp;
            // PIIProtectionGuardrail.cfc returns SUCCESSWITH, which causes LangChain4j to replace
            // aiMessage.text() with the sanitized text + a [Note:...] suffix. Detect that suffix to
            // know that the output guardrail fired and set the status fields accordingly.
            if (findNoCase("[Note: Sensitive information was automatically redacted", response)) {
                guardrailTriggered = true;
                guardrailType      = "OUTPUT_PII_REDACTED";
            }
        } catch (InputGuardrailException e) {
            guardrailTriggered = true;
            guardrailType      = "INPUT_BLOCKED";
            response           = "Request blocked by input safety guardrail: " & e.message;
        } catch (any e) {
            if (findNoCase("guardrail", e.message) || findNoCase("FATAL", e.message)) {
                guardrailTriggered = true;
                guardrailType      = "INPUT_BLOCKED";
                response           = "Request blocked: " & e.message;
            } else {
                rethrow;
            }
        }

        writeOutput(serializeJSON({
            success:            true,
            action:             action,
            prompt:             prompts[action],
            response:           response,
            duration:           getTickCount() - startMs,
            guardrailTriggered: guardrailTriggered,
            guardrailType:      guardrailType
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
<title>Step 4: Guardrails — Mintu's Baby Care AI Assistant</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step4">
<cfset variables.pmtTabs = "Agents,Trace Viewer">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 4 &nbsp;|&nbsp; Guardrails</div>
        <h2>Guardrails — Baby Safety &amp; Family Privacy Protection</h2>
        <p>Test all guardrail outcomes: clean pass, warning passthrough, fatal block, and PII redaction. View the guardrail spans in the PMT Trace Viewer flamegraph after each test.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128272;</span>
            <div>
                <strong>Guardrails Active on This Agent</strong>
                <strong>Input:</strong> <code>InputSafetyGuardrail.cfc</code> — blocks unsafe baby care advice, warns on urgency keywords &nbsp;|&nbsp;
                <strong>Output:</strong> <code>PIIProtectionGuardrail.cfc</code> — redacts phone, email, and personal family information from responses
            </div>
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                Agents tab &rsaquo; <span class="pmt-tab-ref">Guardrail Execution Spans</span> &nbsp;&middot;&nbsp; After "Blocked Query": Trace Viewer &rsaquo; find the trace &rsaquo; guardrail span shows <code>result=FATAL</code> — request stopped before reaching the LLM
            </div>
        </div>

        <div class="section">
            <div class="section-title">Guardrail Test Cases</div>

            <div class="preset-action-bar">
                <button class="btn btn-success"
                    onclick="sendPreset('test_pass','What is the recommended room temperature for a newborn\'s nursery?','pass')">
                    ✓ Normal Query (Pass)
                </button>
                <button class="btn btn-warning"
                    onclick="sendPreset('test_warn','My baby has a fever! I need help immediately!','warn')">
                    ⚠ Urgency Warning (SuccesWith)
                </button>
                <button class="btn btn-danger"
                    onclick="sendPreset('test_block','Should I give honey to my newborn baby?','block')">
                    ✗ Blocked Query (Fatal)
                </button>
                <button class="btn btn-primary" style="background:linear-gradient(135deg,#553c9a,#44337a);border-color:#9f7aea"
                    onclick="sendPreset('test_pii',&quot;What is family member PARENT-001's phone number and email address?&quot;,'pii')">
                    👁 PII Redaction Test
                </button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu's Baby Care — Guardrails Active</span>
                    <span style="margin-left:auto;color:#9f7aea;font-size:11px;">InputSafetyGuardrail · PIIProtectionGuardrail</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click a test case — watch the guardrail spans appear in PMT Trace Viewer after each one.</div>
                </div>
            </div>
        </div>


        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step3a_mcp_problem.cfm" class="btn btn-secondary">&#8592; MCP</a>
            <a href="step5_rag_ingestion.cfm" class="btn btn-primary">Next: RAG Ingestion &#8594;</a>
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
    row.innerHTML=`<div class="chat-av bot">🛡️</div><div class="chat-bbl bot"><div class="typing-dots"><span></span><span></span><span></span></div></div>`;
    c.appendChild(row); scrollChat(); return row;
}
function removeTyping() { document.getElementById('_typing')?.remove(); }

// testType: 'pass' | 'warn' | 'block' | 'pii'
async function sendPreset(action, displayPrompt, testType) {
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
            row.innerHTML=`<div class="chat-av bot">🛡️</div><div class="chat-bbl bot errored">${escHtml(data.error)}</div>`;
            document.getElementById('chatMsgs').appendChild(row); scrollChat();
            isWaiting=false; return;
        }

        // Choose bubble style and badge based on guardrail outcome
        const bblClass = testType==='block' ? 'blocked'
                       : testType==='warn'  ? 'warn'
                       : testType==='pii'   ? 'redacted'
                       : '';

        const badges = {
            pass:  `<span class="metric-badge score">✓ Guardrail: PASS</span><span class="metric-badge time">⏱ ${data.duration}ms</span>`,
            warn:  `<span class="metric-badge alert">⚠ Guardrail: SUCCESSWITH</span><span class="metric-badge time">⏱ ${data.duration}ms</span>`,
            block: `<span class="metric-badge alert">✗ Guardrail: FATAL (Blocked)</span><span class="metric-badge time">⏱ ${data.duration}ms</span>`,
            pii:   `<span class="metric-badge tokens">👁 Output PII Redacted</span><span class="metric-badge time">⏱ ${data.duration}ms</span>`
        };
        const notes = {
            pass:  `<div class="chat-bbl-meta" style="margin-top:5px;color:#68d391;">Clean pass — no triggers.</div>`,
            warn:  `<div class="chat-bbl-meta" style="margin-top:5px;color:#d69e2e;font-size:11px;">⚠ Request flagged but allowed through (SUCCESSWITH). Check Trace Viewer.</div>`,
            block: `<div class="chat-bbl-meta problem-indicator" style="margin-top:5px;">BLOCKED before reaching LLM. Check Trace Viewer — no LLM span.</div>`,
            pii:   `<div class="chat-bbl-meta" style="margin-top:5px;color:#9f7aea;font-size:11px;">🔒 PII redacted by PIIProtectionGuardrail.cfc. Check Trace Viewer for output guardrail span.</div>`
        };

        const row=document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">🛡️</div>
            <div>
              <div class="chat-bbl bot ${bblClass}">${escHtml(data.response)}</div>
              <div class="chat-bbl-badges">${badges[testType]||badges.pass}</div>
              ${notes[testType]||''}
            </div>`;
        document.getElementById('chatMsgs').appendChild(row);
        showToast(`${testType.toUpperCase()} test complete.`);
    } catch(e) {
        removeTyping();
        const row=document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">🛡️</div><div class="chat-bbl bot errored">${escHtml(e.message)}</div>`;
        document.getElementById('chatMsgs').appendChild(row);
    }
    scrollChat();
    isWaiting = false;
}
</script>
</body>
</html>
