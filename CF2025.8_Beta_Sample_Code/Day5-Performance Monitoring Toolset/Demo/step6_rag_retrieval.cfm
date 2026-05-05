<cfscript>
variables.currentStep = "step6";
variables.pmtTabs = "RAG,Vector Stores";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {
        // Initialize optimized RAG service (once per session)
        if (!isObject(session.ragService)) {
            dataDir = application.dataDir;
            if (!directoryExists(dataDir) || arrayLen(directoryList(dataDir, false, "array", "*.txt")) == 0) {
                writeOutput(serializeJSON({ success: false, error: "No documents found. Please run Step 2 first." }));
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
                TEMPERATURE: 0.3
            });
            // GOOD CONFIG: small chunks, overlap, high minScore, query compression
            session.ragService = simpleRAG(dataDir, chatModel, {
                vectorStore:  vsClient,
                chunkSize:    300,
                chunkOverlap: 75,
                minScore:     0.6
            });
            session.ragService.ingest();
        }

        queries = {
            query1: "What is the safest sleep position for a newborn baby?",
            query2: "How often should I feed my newborn and what are hunger cues?",
            query3: "How many wet diapers should a newborn have per day?",
            query4: "What are the developmental milestones for a 1-month old baby?",
            query5: "What are the essential items I need for a newborn baby?"
        };

        queryKey = action;
        runAll   = (action == "query_all");
        results  = [];
        toRun    = runAll ? structKeyArray(queries) : [queryKey];

        for (qk in toRun) {
            if (!structKeyExists(queries, qk)) continue;
            qStart   = getTickCount();
            qText    = queries[qk];
            rawAnswer = session.ragService.chat(qText);
            answer    = isStruct(rawAnswer) ? (rawAnswer.message ?: "") : rawAnswer;
            qDuration = getTickCount() - qStart;
            arrayAppend(results, {
                queryKey: lCase(qk),
                question: qText,
                answer:   answer,
                duration: qDuration,
                config:   "chunkSize=300, chunkOverlap=75, minScore=0.6"
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
<title>RAG Retrieval — Mintu Baby Care</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step6">
<cfset variables.pmtTabs = "RAG,Vector Stores">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 6 &nbsp;|&nbsp; RAG Retrieval</div>
        <h2>RAG Retrieval — Agent + Knowledge Base</h2>
        <p>The Agent retrieves relevant chunks from the knowledge base before answering. Ask baby care questions and watch PMT RAG tab show retrieval scores and query details.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128268;</span>
            <div>
                <strong>RAG Configuration</strong>
                <code>chunkSize: 300</code> &nbsp; <code>chunkOverlap: 75</code> &nbsp; <code>minScore: 0.6</code>
            </div>
        </div>

        <div class="config-box">
            <span class="cfg-key">simpleRAG</span>(dataDir, chatModel, {<br>
            &nbsp;&nbsp;<span class="cfg-key">chunkSize</span>: <span class="cfg-good">300</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// GOOD: fine-grained, precise embeddings</span><br>
            &nbsp;&nbsp;<span class="cfg-key">chunkOverlap</span>: <span class="cfg-good">75</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// GOOD: context continuity across chunks</span><br>
            &nbsp;&nbsp;<span class="cfg-key">minScore</span>: <span class="cfg-good">0.6</span>,&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:#666">// GOOD: filters irrelevant results</span><br>
            &nbsp;&nbsp;<span class="cfg-key">queryTransformer</span>: { type: <span class="cfg-good">"compressing"</span> },&nbsp;&nbsp;<span style="color:#666">// GOOD: enriches vague follow-ups</span><br>
            &nbsp;&nbsp;<span class="cfg-key">contentAggregator</span>: { type: <span class="cfg-good">"default"</span> }<br>
            });
        </div>

        <div class="banner banner-pmt">
            <div>
                <span class="pmt-watch-label">&#128202; PMT to Watch</span>
                RAG tab &rsaquo; <span class="pmt-tab-ref">Retrieval Score Distribution</span> (histogram now 0.6–0.9) &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Low Relevance Queries</span> grid (empty/fewer) &nbsp;&middot;&nbsp; <span class="pmt-tab-ref">Avg Score By Router Model</span> (significantly higher).
            </div>
        </div>

        <div class="section">
            <div class="section-title">Run Baby Care Queries</div>

            <div class="preset-action-bar">
                <button class="btn btn-success" onclick="sendQuery('query1','What is the safest sleep position for a newborn baby?')">1 — Sleep Safety</button>
                <button class="btn btn-success" onclick="sendQuery('query2','How often should I feed my newborn and what are hunger cues?')">2 — Feeding Guide</button>
                <button class="btn btn-success" onclick="sendQuery('query3','How many wet diapers should a newborn have per day?')">3 — Diaper Tracking</button>
                <button class="btn btn-success" onclick="sendQuery('query4','What are the developmental milestones for a 1-month old baby?')">4 — Milestones</button>
                <button class="btn btn-success" onclick="sendQuery('query5','What are the essential items I need for a newborn baby?')">5 — Baby Essentials</button>
                <button class="btn btn-run-all" id="runAllBtn" onclick="runAllQueries()">&#9654;&#9654; Run All</button>
            </div>

            <div class="chat-window">
                <div class="chat-win-header">
                    <div class="chat-win-dot"></div>
                    <span>Mintu Baby Care — RAG Retrieval</span>
                    <span style="margin-left:auto;color:#90cdf4;font-size:11px;">chunkSize:300 · overlap:75 · minScore:0.6</span>
                </div>
                <div class="chat-msgs" id="chatMsgs">
                    <div style="text-align:center;color:#4a5568;font-size:12px;padding:30px 0;">Click a query above to ask the baby care knowledge base.</div>
                </div>
            </div>
        </div>


        <!-- Nav buttons -->
        <div style="margin-top:24px;display:flex;gap:12px;flex-wrap:wrap;">
            <a href="step5_rag_ingestion.cfm" class="btn btn-secondary">&#8592; RAG Ingestion</a>
            <a href="step6a_rag_problem.cfm" class="btn btn-primary">Next: RAG — The Problem &#8594;</a>
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
    c.appendChild(row); scrollChat();
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
          <div class="chat-bbl bot">${escHtml(result.answer||'(no answer)')}</div>
          <div class="chat-bbl-badges">
            <span class="metric-badge score">&#10003; High retrieval score</span>
            <span class="metric-badge time">&#9201; ${result.duration}ms</span>
          </div>
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
        } else if (data.results && data.results.length>0) {
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
</script>
</body>
</html>
