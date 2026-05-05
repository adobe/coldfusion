<cfscript>
variables.currentStep = "step6a";
variables.pmtTabs = "RAG,Vector Stores";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        // Allow flushing the cached RAG service (e.g. after config changes)
        if (action == "reset_session") {
            session.ragServiceBad = "";
            writeOutput(serializeJSON({ success: true, message: "Session reset. Next query will reinitialize the RAG service." }));
            abort;
        }

        // Initialize the RAG service with DELIBERATELY BAD config (once per session)
        if (!isObject(session.ragServiceBad)) {
            dataDir = application.dataDir;
            if (!directoryExists(dataDir) || arrayLen(directoryList(dataDir, false, "array", "*.txt")) == 0) {
                writeOutput(serializeJSON({ success: false, error: "No documents found in " & dataDir & ". Please run Step 2 first to create and ingest the knowledge base." }));
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
            chatModel = ChatModel({
                PROVIDER:  "openAi",
                APIKEY:    application.openaiKey,
                MODELNAME: application.openaiModel,
                TEMPERATURE: 0.9
            });
            // BAD CONFIG: huge chunks, no overlap, very low minScore, no compression
            session.ragServiceBad = simpleRAG(dataDir, chatModel, {
                vectorStore:  vsClient,
                chunkSize:    2000,
                chunkOverlap: 0,
                minScore:     0.1
            });
            session.ragServiceBad.ingest();
        }

        // IDENTICAL queries to step3b — only the RAG config differs.
        // With chunkSize:2000 the embedding for each chunk blends many topics
        // (sleep + feeding + diapers + milestones all in one vector), so cosine similarity
        // to a specific query is diluted, producing lower retrieval scores.
        queries = {
            query1: "What is the safest sleep position for a newborn baby?",
            query2: "How often should I feed my newborn and what are hunger cues?",
            query3: "How many wet diapers should a newborn have per day?",
            query4: "What are the developmental milestones for a 1-month old baby?",
            query5: "What are the essential items I need for a newborn baby?"
        };

        queryKey = action;
        runAll = (action == "query_all");
        results = [];

        toRun = runAll ? structKeyArray(queries) : [queryKey];

        for (qk in toRun) {
            if (!structKeyExists(queries, qk)) continue;
            qStart = getTickCount();
            qText  = queries[qk];
            rawAnswer = session.ragServiceBad.chat(qText);
            answer    = isStruct(rawAnswer) ? (rawAnswer.message ?: "") : rawAnswer;
            qDuration = getTickCount() - qStart;
            arrayAppend(results, {
                queryKey:  lCase(qk),
                question:  qText,
                answer:    answer,
                duration:  qDuration,
                config:    "chunkSize=2000, chunkOverlap=0, minScore=0.1, compression=OFF"
            });
        }

        writeOutput(serializeJSON({
            success:  true,
            results:  results,
            duration: getTickCount() - startMs
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
<title>RAG Retrieval — Poor Configuration</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step6a">
<cfset variables.pmtTabs = "RAG,Vector Stores">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 6 &nbsp;|&nbsp; RAG Retrieval — The Problem</div>
        <h2>RAG Retrieval — Poor Configuration</h2>
        <p>The <strong>exact same queries</strong> as Step 3B — but with a poor RAG config. Large chunks dilute embeddings, low minScore accepts weak matches. PMT will show retrieval scores in the 0.3–0.5 range.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-bottleneck">
            <span class="banner-icon">&#9888;</span>
            <div>
                <strong>Same Queries, Poor Config = Low Retrieval Scores</strong>
                <code>chunkSize: 2000</code> &nbsp; <code>chunkOverlap: 0</code> &nbsp; <code>minScore: 0.1</code> &nbsp; <code>queryCompression: OFF</code>
                <br>These are <em>the exact same queries</em> used in Step 3B. The difference is config only: 2000-char chunks blend sleep safety + feeding + diapers + milestones into one embedding vector, diluting cosine similarity. Scores land in the <strong>0.3–0.5</strong> range. minScore:0.1 means those weak matches still reach the LLM — producing incomplete or generic answers.
            </div>
        </div>

        <div class="config-box">
            <span class="cfg-key">simpleRAG</span>(dataDir, chatModel, {<br>
            &nbsp;&nbsp;<span class="cfg-key">chunkSize</span>: <span class="cfg-bad">2000</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// BAD: huge chunk mixes sleep + feeding + diapers into one blended vector</span><br>
            &nbsp;&nbsp;<span class="cfg-key">chunkOverlap</span>: <span class="cfg-bad">0</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// BAD: no overlap — context lost at boundaries</span><br>
            &nbsp;&nbsp;<span class="cfg-key">minScore</span>: <span class="cfg-bad">0.1</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// BAD: weak matches (score 0.3–0.5) still sent to LLM</span><br>
            &nbsp;&nbsp;<span style="color:#666">// queryTransformer: none — no query compression or rewriting</span><br>
            });
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                RAG tab &rsaquo; <span class="pmt-tab-ref">Retrieval Score Distribution</span> (histogram clusters 0.3–0.5) &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Low Relevance Queries</span> grid &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Slow Retrieval Operations</span> (large chunks take longer). Compare directly with Step 3B — same queries, scores jump to 0.65–0.85.
            </div>
        </div>

        <div class="section">
            <div class="section-title">Run Baby Care Queries (Bad Config) — Identical Queries to Step 3B</div>

            <div class="preset-action-bar">
                <button class="btn btn-danger" onclick="sendQuery('query1','What is the safest sleep position for a newborn baby?')">1 — Sleep Safety</button>
                <button class="btn btn-danger" onclick="sendQuery('query2','How often should I feed my newborn and what are hunger cues?')">2 — Feeding Guide</button>
                <button class="btn btn-danger" onclick="sendQuery('query3','How many wet diapers should a newborn have per day?')">3 — Diaper Tracking</button>
                <button class="btn btn-danger" onclick="sendQuery('query4','What are the developmental milestones for a 1-month old baby?')">4 — Milestones</button>
                <button class="btn btn-danger" onclick="sendQuery('query5','What are the essential items I need for a newborn baby?')">5 — Baby Essentials</button>
                <button class="btn btn-run-all" id="runAllBtn" onclick="runAllQueries()">&#9654;&#9654; Run All</button>
                <button class="btn btn-secondary" id="resetBtn" onclick="resetSession()" style="font-size:12px;padding:6px 12px;">&#8635; Reset</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot" style="background:#c53030"></div>
                    <span>Mintu Baby Care — RAG (Poor Config)</span>
                    <span style="margin-left:auto;color:#fc8181;font-size:11px;">chunkSize:2000 · overlap:0 · minScore:0.1 · no compression</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click any query — same questions as Step 3B, watch PMT RAG tab show lower retrieval scores due to poor config.</div>
                </div>
            </div>
        </div>


        <!-- Nav buttons -->
        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step6_rag_retrieval.cfm" class="btn btn-secondary">&#8592; RAG Retrieval</a>
            <a href="step7_full_agent.cfm" class="btn btn-primary">Next: Full Agent &#8594;</a>
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
    setTimeout(()=>{t.className='';}, 3500);
}
function scrollChat() { const c=document.getElementById('chatMsgs'); c.scrollTop=c.scrollHeight; }

function addUserBubble(text) {
    const c=document.getElementById('chatMsgs');
    const ph=c.querySelector('div[style*="padding:30px"]'); if(ph) ph.remove();
    const row=document.createElement('div'); row.className='chat-row user';
    row.innerHTML=`<div><div class="chat-bbl user">${escHtml(text)}</div>
        <div class="chat-bbl-meta">${new Date().toLocaleTimeString([],{hour:'2-digit',minute:'2-digit'})}</div></div>
        <div class="chat-av user">&#128100;</div>`;
    c.appendChild(row); scrollChat(); return row;
}
function addTypingRow() {
    const c=document.getElementById('chatMsgs');
    const row=document.createElement('div'); row.className='chat-row bot'; row.id='_typing';
    row.innerHTML=`<div class="chat-av bot">&#129302;</div><div class="chat-bbl bot"><div class="typing-dots"><span></span><span></span><span></span></div></div>`;
    c.appendChild(row); scrollChat(); return row;
}
function removeTyping() { document.getElementById('_typing')?.remove(); }

function appendBotResult(result) {
    const row=document.createElement('div'); row.className='chat-row bot';
    row.innerHTML=`<div class="chat-av bot">&#129302;</div>
        <div>
          <div class="chat-bbl bot warn">${escHtml(result.answer||'(no answer)')}</div>
          <div class="chat-bbl-badges">
            <span class="metric-badge alert">&#9888; Low retrieval quality</span>
            <span class="metric-badge time">&#9201; ${result.duration}ms</span>
          </div>
          <div class="chat-bbl-meta problem-indicator" style="margin-top:5px;">2000-char chunk embedding is diluted — low similarity score despite a precise query.</div>
        </div>`;
    document.getElementById('chatMsgs').appendChild(row); scrollChat();
}

async function sendQuery(queryKey, displayPrompt) {
    if (isWaiting) return;
    isWaiting = true;
    addUserBubble(displayPrompt);
    addTypingRow();
    try {
        const data=cfNorm(await fetch(location.pathname,{
            method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action='+queryKey
        }).then(r=>r.json()));
        removeTyping();
        if (!data.success) {
            const row=document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">&#129302;</div><div class="chat-bbl bot errored">${escHtml(data.error)}</div>`;
            document.getElementById('chatMsgs').appendChild(row);
        } else if (data.results && data.results.length > 0) {
            appendBotResult(data.results[0]);
            showToast('Query complete.');
        }
    } catch(e) {
        removeTyping();
        const row=document.createElement('div'); row.className='chat-row bot';
        row.innerHTML=`<div class="chat-av bot">&#129302;</div><div class="chat-bbl bot errored">${escHtml(e.message)}</div>`;
        document.getElementById('chatMsgs').appendChild(row);
    }
    scrollChat(); isWaiting=false;
}

async function runAllQueries() {
    if (isWaiting) return;
    const btn=document.getElementById('runAllBtn');
    btn.disabled=true; btn.textContent='&#9203; Running all...';
    const queries=[
        {key:'query1',prompt:'What is the safest sleep position for a newborn baby?'},
        {key:'query2',prompt:'How often should I feed my newborn and what are hunger cues?'},
        {key:'query3',prompt:'How many wet diapers should a newborn have per day?'},
        {key:'query4',prompt:'What are the developmental milestones for a 1-month old baby?'},
        {key:'query5',prompt:'What are the essential items I need for a newborn baby?'}
    ];
    for (const q of queries) {
        addUserBubble(q.prompt);
        addTypingRow();
        try {
            const data=cfNorm(await fetch(location.pathname,{
                method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
                body:'action='+q.key
            }).then(r=>r.json()));
            removeTyping();
            if (!data.success) {
                const row=document.createElement('div'); row.className='chat-row bot';
                row.innerHTML=`<div class="chat-av bot">&#129302;</div><div class="chat-bbl bot errored">${escHtml(data.error)}</div>`;
                document.getElementById('chatMsgs').appendChild(row);
            } else if (data.results && data.results.length>0) {
                appendBotResult(data.results[0]);
            }
        } catch(e) {
            removeTyping();
            const row=document.createElement('div'); row.className='chat-row bot';
            row.innerHTML=`<div class="chat-av bot">&#129302;</div><div class="chat-bbl bot errored">${escHtml(e.message)}</div>`;
            document.getElementById('chatMsgs').appendChild(row);
        }
    }
    scrollChat();
    btn.disabled=false; btn.innerHTML='&#9654;&#9654; Run All';
    showToast('All 5 queries complete.');
}

async function resetSession() {
    const btn=document.getElementById('resetBtn');
    btn.disabled=true; btn.textContent='&#9203;...';
    try {
        const data=cfNorm(await fetch(location.pathname,{
            method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action=reset_session'
        }).then(r=>r.json()));
        document.getElementById('chatMsgs').innerHTML='<div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Session reset — RAG service will reinitialise on next query.</div>';
        showToast(data.message||'Session reset');
    } catch(e) { showToast('Reset failed: '+e.message,'error'); }
    btn.disabled=false; btn.innerHTML='&#8635; Reset';
}
</script>
</body>
</html>
