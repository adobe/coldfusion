<cfscript>
/**
 * Embedding Model & Vector Store Failure Scenarios
 * Standalone repro — not wired into the demo navigation.
 * Run directly: http://localhost:8500/mintu_baby/test_failures.cfm
 */

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();

    try {

        // ──────────────────────────────────────────────
        // SCENARIO A: Embedding model unreachable
        //   Ollama URL points to a dead port → connection refused
        // ──────────────────────────────────────────────
        if (action == "embed_unreachable") {
            dataDir = application.dataDir;
            vsClient = vectorStore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider:  "ollama",
                    modelName: "all-minilm",
                    baseUrl:   "http://localhost:99999"   // dead port
                }
            });
            chatModel = ChatModel({
                PROVIDER:  "openAi",
                APIKEY:    application.openaiKey,
                MODELNAME: application.openaiModel
            });
            ragSvc = simpleRAG(dataDir, chatModel, {
                vectorStore: vsClient,
                chunkSize:   300,
                chunkOverlap: 75
            });
            result = ragSvc.ingest();   // should fail on embedding call
            writeOutput(serializeJSON({
                success: true,
                message: "Ingest unexpectedly succeeded",
                result: result,
                duration: getTickCount() - startMs
            }));
            abort;
        }

        // ──────────────────────────────────────────────
        // SCENARIO B: Wrong / non-existent embedding model name
        //   Ollama is running but model doesn't exist
        // ──────────────────────────────────────────────
        if (action == "embed_bad_model") {
            dataDir = application.dataDir;
            vsClient = vectorStore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider:  "ollama",
                    modelName: "nonexistent-model-xyz-404",
                    baseUrl:   application.ollamaurl
                }
            });
            chatModel = ChatModel({
                PROVIDER:  "openAi",
                APIKEY:    application.openaiKey,
                MODELNAME: application.openaiModel
            });
            ragSvc = simpleRAG(dataDir, chatModel, {
                vectorStore: vsClient,
                chunkSize:   300,
                chunkOverlap: 75
            });
            result = ragSvc.ingest();
            writeOutput(serializeJSON({
                success: true,
                message: "Ingest unexpectedly succeeded",
                result: result,
                duration: getTickCount() - startMs
            }));
            abort;
        }

        // ──────────────────────────────────────────────
        // SCENARIO C: minScore too high (silent failure)
        //   Ingest works, but query returns 0 results above threshold
        //   Agent hallucinates without any RAG context
        // ──────────────────────────────────────────────
        if (action == "minscore_too_high") {
            dataDir = application.dataDir;
            if (!directoryExists(dataDir) || arrayLen(directoryList(dataDir, false, "array", "*.txt")) == 0) {
                writeOutput(serializeJSON({ success: false, error: "No documents found. Run step 5 Create Documents first." }));
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
            // minScore 0.99 — almost impossible to match
            ragSvc = simpleRAG(dataDir, chatModel, {
                vectorStore:  vsClient,
                chunkSize:    300,
                chunkOverlap: 75,
                minScore:     0.99
            });
            ragSvc.ingest();
            answer = ragSvc.chat("What is the safest sleep position for a newborn?");
            respText = isStruct(answer) ? (answer.message ?: serializeJSON(answer)) : answer;
            writeOutput(serializeJSON({
                success:  true,
                message:  "Query completed — but likely hallucinated (no chunks passed minScore:0.99)",
                response: respText,
                config:   "minScore=0.99 (normal=0.6)",
                duration: getTickCount() - startMs
            }));
            abort;
        }

        // ──────────────────────────────────────────────
        // SCENARIO D: Query with embedding model down
        //   Ingest with working Ollama, then query with dead URL
        //   Shows: ingest OK but retrieval fails
        // ──────────────────────────────────────────────
        if (action == "query_embed_down") {
            dataDir = application.dataDir;
            if (!directoryExists(dataDir) || arrayLen(directoryList(dataDir, false, "array", "*.txt")) == 0) {
                writeOutput(serializeJSON({ success: false, error: "No documents found. Run step 5 Create Documents first." }));
                abort;
            }
            // Step 1: ingest with working embedding model
            vsGood = vectorStore({
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
                MODELNAME: application.openaiModel
            });
            ragGood = simpleRAG(dataDir, chatModel, {
                vectorStore: vsGood,
                chunkSize:   300,
                chunkOverlap: 75,
                minScore:    0.5
            });
            ragGood.ingest(); // this succeeds

            // Step 2: build a new RAG service with dead embedding URL for query
            vsBad = vectorStore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider:  "ollama",
                    modelName: application.ollamaEmbedModel,
                    baseUrl:   "http://localhost:99999"    // dead
                }
            });
            ragBad = simpleRAG(dataDir, chatModel, {
                vectorStore: vsBad,
                chunkSize:   300,
                chunkOverlap: 75,
                minScore:    0.5
            });
            // Query will fail — can't embed the query vector
            answer = ragBad.chat("How often should I feed my newborn?");
            respText = isStruct(answer) ? (answer.message ?: serializeJSON(answer)) : answer;
            writeOutput(serializeJSON({
                success:  true,
                message:  "Query unexpectedly succeeded",
                response: respText,
                duration: getTickCount() - startMs
            }));
            abort;
        }

        // ──────────────────────────────────────────────
        // SCENARIO E: Corrupt / empty document in batch
        //   Mix valid docs with an empty file → partial ingestion failure
        // ──────────────────────────────────────────────
        if (action == "partial_ingest_fail") {
            tempDir = application.dataDir & "failure_test/";
            if (directoryExists(tempDir)) directoryDelete(tempDir, true);
            directoryCreate(tempDir);

            // Good doc
            fileWrite(tempDir & "valid_doc.txt",
                "Baby Sleep Guide: Always place baby on their back to sleep. Use a firm mattress. Keep room temperature 68-72F. Swaddle until baby shows signs of rolling.");

            // Empty file — may cause splitting/embedding issues
            fileWrite(tempDir & "empty_doc.txt", "");

            // Minimal content — too short to chunk meaningfully
            fileWrite(tempDir & "tiny_doc.txt", "Hi");

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
                MODELNAME: application.openaiModel
            });
            ragSvc = simpleRAG(tempDir, chatModel, {
                vectorStore: vsClient,
                chunkSize:   300,
                chunkOverlap: 75
            });
            result = ragSvc.ingest();
            writeOutput(serializeJSON({
                success:  true,
                message:  "Partial ingest completed — check PMT for PARTIAL_FAILURE phases",
                result:   result,
                docs:     "valid_doc.txt (good), empty_doc.txt (empty), tiny_doc.txt (1 word)",
                duration: getTickCount() - startMs
            }));
            abort;
        }

        // ──────────────────────────────────────────────
        // SCENARIO F: Bad API key for OpenAI embedding
        //   Use OpenAI as embedding provider with invalid key
        // ──────────────────────────────────────────────
        if (action == "embed_bad_apikey") {
            dataDir = application.dataDir;
            vsClient = vectorStore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider:  "openAi",
                    apiKey:    "sk-invalid-key-00000000000000000000",
                    modelName: "text-embedding-3-small"
                }
            });
            chatModel = ChatModel({
                PROVIDER:  "openAi",
                APIKEY:    application.openaiKey,
                MODELNAME: application.openaiModel
            });
            ragSvc = simpleRAG(dataDir, chatModel, {
                vectorStore: vsClient,
                chunkSize:   300,
                chunkOverlap: 75
            });
            result = ragSvc.ingest();
            writeOutput(serializeJSON({
                success: true,
                message: "Ingest unexpectedly succeeded",
                result: result,
                duration: getTickCount() - startMs
            }));
            abort;
        }

        writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));

    } catch (any e) {
        writeOutput(serializeJSON({
            success:   false,
            error:     e.message,
            type:      e.type ?: "",
            detail:    e.detail ?: "",
            duration:  getTickCount() - startMs
        }));
    }
    abort;
}
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Failure Scenarios — Embedding &amp; Vector Store</title>
<cfinclude template="_styles.cfm">
</head>
<body style="display:block;background:#1a1215;">

<div style="max-width:960px;margin:0 auto;padding:40px;">

    <div style="margin-bottom:32px;">
        <div style="font-size:12px;text-transform:uppercase;letter-spacing:.08em;color:#b89a8f;margin-bottom:8px;">Test Harness — Not Part of Demo</div>
        <h1 style="margin:0 0 10px;font-size:28px;color:#fff;">Embedding &amp; Vector Store Failure Scenarios</h1>
        <p style="margin:0;color:#c0a898;font-size:15px;line-height:1.6;">Each button triggers a different failure mode. Check PMT after each one to see how errors surface in the dashboard.</p>
    </div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:18px;margin-bottom:28px;">

        <div class="action-card">
            <div class="card-title">A — Embedding Model Unreachable</div>
            <div class="card-desc">Ollama URL points to a dead port. Ingest fails at the embedding step.<br>
            <strong>PMT:</strong> EmbeddingCallStat=ERROR, RagPhase=SegmentIngestionError</div>
            <button class="btn btn-danger" onclick="run('embed_unreachable',this)">Run: Dead Embedding Server</button>
            <div class="result-area" id="r-embed_unreachable"></div>
        </div>

        <div class="action-card">
            <div class="card-title">B — Wrong Embedding Model Name</div>
            <div class="card-desc">Ollama is running but model "nonexistent-model-xyz-404" doesn't exist.<br>
            <strong>PMT:</strong> EmbeddingCallStat=ERROR, model not found</div>
            <button class="btn btn-danger" onclick="run('embed_bad_model',this)">Run: Bad Model Name</button>
            <div class="result-area" id="r-embed_bad_model"></div>
        </div>

        <div class="action-card">
            <div class="card-title">C — minScore Too High (Silent Failure)</div>
            <div class="card-desc">minScore=0.99 — everything works but 0 chunks pass the threshold. Agent hallucinates.<br>
            <strong>PMT:</strong> All green, but RAG retrieval scores show 0 matches above 0.99</div>
            <button class="btn btn-warning" onclick="run('minscore_too_high',this)">Run: minScore 0.99</button>
            <div class="result-area" id="r-minscore_too_high"></div>
        </div>

        <div class="action-card">
            <div class="card-title">D — Query with Embedding Down</div>
            <div class="card-desc">Ingest succeeds, then query embedding URL goes dead. Retrieval fails.<br>
            <strong>PMT:</strong> Ingest spans OK, then RetrievalError on query</div>
            <button class="btn btn-danger" onclick="run('query_embed_down',this)">Run: Embed Down at Query Time</button>
            <div class="result-area" id="r-query_embed_down"></div>
        </div>

        <div class="action-card">
            <div class="card-title">E — Corrupt / Empty Docs (Partial Failure)</div>
            <div class="card-desc">Mix valid + empty + tiny docs. Some ingest, some fail.<br>
            <strong>PMT:</strong> RagPhase=PARTIAL_FAILURE, errorCount + errorSamples</div>
            <button class="btn btn-warning" onclick="run('partial_ingest_fail',this)">Run: Partial Ingest</button>
            <div class="result-area" id="r-partial_ingest_fail"></div>
        </div>

        <div class="action-card">
            <div class="card-title">F — Bad API Key (OpenAI Embedding)</div>
            <div class="card-desc">Uses OpenAI as embedding provider with an invalid API key.<br>
            <strong>PMT:</strong> EmbeddingCallStat=AUTH_FAILURE (401)</div>
            <button class="btn btn-danger" onclick="run('embed_bad_apikey',this)">Run: Invalid API Key</button>
            <div class="result-area" id="r-embed_bad_apikey"></div>
        </div>

    </div>

    <a href="index.cfm" class="btn btn-secondary">&larr; Back to Demo</a>
</div>

<div id="toast"></div>

<script>
function escHtml(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');}
function showToast(msg,type){const t=document.getElementById('toast');t.textContent=msg;t.className='show toast-'+(type||'success');setTimeout(()=>{t.className='';},5000);}

async function run(action, btn) {
    btn.disabled = true;
    const el = document.getElementById('r-'+action);
    el.innerHTML = '<div class="loading-row"><div class="spinner"></div><span>Running failure scenario...</span></div>';
    try {
        const res = await fetch(location.pathname, {
            method:'POST',
            headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action='+action
        });
        const data = cfNorm(await res.json());
        if (data.success) {
            let extra = `<span class="metric-badge time">\u23F1 ${data.duration}ms</span>`;
            if (data.config) extra += `<span class="metric-badge alert">${escHtml(data.config)}</span>`;
            el.innerHTML = `<div class="result-card warning">
                <div class="result-text">${escHtml(data.message)}</div>
                ${data.response ? '<div style="margin-top:8px;padding:8px;background:rgba(255,255,255,0.05);border-radius:6px;font-size:13px;color:#c0a898;">'+escHtml(data.response).substring(0,300)+'...</div>' : ''}
                <div class="metrics-row">${extra}</div>
            </div>`;
            showToast('Scenario completed — check PMT','success');
        } else {
            el.innerHTML = `<div class="result-card error">
                <strong style="color:#ff8a80;">\u2717 ${escHtml(data.type || 'Error')}</strong>
                <div class="result-text" style="margin-top:6px;">${escHtml(data.error)}</div>
                ${data.detail ? '<div style="margin-top:4px;font-size:12px;color:#8a7068;">'+escHtml(data.detail).substring(0,200)+'</div>' : ''}
                <div class="metrics-row"><span class="metric-badge time">\u23F1 ${data.duration}ms</span></div>
            </div>`;
            showToast('Error captured — check PMT for monitoring data','error');
        }
    } catch(e) {
        el.innerHTML = `<div class="result-card error">${escHtml(e.message)}</div>`;
    }
    btn.disabled = false;
}
</script>
</body>
</html>
