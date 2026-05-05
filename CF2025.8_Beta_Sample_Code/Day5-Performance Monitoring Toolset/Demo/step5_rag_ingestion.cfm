<cfscript>
variables.currentStep = "step5";
variables.pmtTabs = "RAG,Vector Stores";

if (cgi.request_method == "POST") {
    cfheader(name="Content-Type", value="application/json");
    action = form.action ?: "";
    startMs = getTickCount();
    try {

        // ---- Create knowledge base documents ----
        if (action == "create_docs") {
            dataDir = application.dataDir;
            docs = {
                "newborn_sleep_guide.txt":        "Newborn Sleep Guide for New Parents\n\nThis guide covers safe sleep practices for your newborn baby. Always place your baby on their back to sleep — this is the single most important step to reduce the risk of SIDS (Sudden Infant Death Syndrome). Use a firm, flat mattress with a fitted sheet only. Never place blankets, pillows, stuffed animals, or bumper pads in the crib.\n\nRoom Sharing: The AAP recommends room sharing (but not bed sharing) for at least the first 6 months. Place the bassinet or crib within arm's reach of your bed.\n\nRoom Temperature: Keep the nursery between 68-72F (20-22C). Dress your baby in a sleep sack or wearable blanket instead of loose blankets. If baby's chest feels warm and dry, the temperature is right.\n\nSwaddling Tips: Swaddling can soothe newborns by mimicking the womb. Use a thin muslin or cotton blanket. Ensure the swaddle is snug around the arms but loose around the hips. Stop swaddling once baby shows signs of rolling (usually around 2-3 months).\n\nWake Windows for 0-3 Months: Newborns (0-4 weeks) can only stay awake 35-60 minutes. At 1-2 months, wake windows extend to 60-90 minutes. By 3 months, expect 75-120 minute wake windows. Watch for sleepy cues: yawning, eye rubbing, fussiness, and looking away.",
                "feeding_schedule.txt":        "Baby Feeding Schedule and Guide\n\nBreastfeeding newborns should feed on demand, typically every 2-3 hours (8-12 times per day) in the first weeks. Each feeding session may last 10-20 minutes per breast. As baby grows, feedings become more efficient and may space to every 3-4 hours.\n\nBottle-Feeding: If formula feeding, newborns typically take 1-2 oz per feeding in the first week, increasing to 2-3 oz by 2 weeks, and 4-5 oz by 2 months. Always prepare formula according to package instructions — never dilute or concentrate.\n\nGrowth Spurts: Expect cluster feeding during growth spurts at 2-3 weeks, 6 weeks, 3 months, and 6 months. Baby may want to feed every hour during these periods. This is normal and helps increase milk supply.\n\nBurping Techniques: Burp baby after every 2-3 oz (bottle) or when switching breasts. Methods include: over-the-shoulder, sitting upright on your lap, or face-down across your lap. Gently pat or rub baby's back.\n\nSigns of Hunger: Early cues include rooting (turning head side to side), lip smacking, sucking on hands. Crying is a late hunger cue. Try to feed before baby gets to the crying stage.\n\nTracking Feedings: In the first weeks, keep a log of feeding times, duration, and wet/dirty diapers. Most newborns should have 6+ wet diapers and 3-4 dirty diapers per day by day 5.",
                "diaper_care_guide.txt": "Diaper Care Guide for Newborns\n\nHow Many Diapers Per Day: Newborns go through 8-12 diapers per day in the first month. This decreases to 6-8 per day by 3-6 months. Always change the diaper as soon as it is soiled to prevent diaper rash.\n\nDiaper Rash Prevention: Apply a thin layer of barrier cream (zinc oxide or petroleum jelly) at every change. Keep the diaper area clean and dry. Allow diaper-free time daily (10-15 minutes) to let skin breathe. Avoid scented wipes in the first few weeks — use warm water and soft cloth or fragrance-free wipes.\n\nTypes of Diapers: Disposable diapers are convenient and highly absorbent. Cloth diapers are eco-friendly and cost-effective long term but require more frequent changes. Hybrid diapers combine a reusable cover with disposable inserts.\n\nWhen to Change: Change immediately after bowel movements. For wet-only diapers, change at least every 2-3 hours. Always change before and after sleep. At nighttime, change only if baby is soiled or the diaper is very saturated.\n\nWhat is Normal for Newborn Stool: Day 1-2: Black/dark green meconium (sticky, tar-like). Day 3-4: Transitional green-brown stool. Day 5+: Breastfed babies have yellow, seedy, loose stools. Formula-fed babies have tan/yellow, firmer stools. Contact your pediatrician if you see blood, white/gray stool, or no stool for 3+ days.",
                "baby_health_milestones.txt": "Baby Health and Developmental Milestones (0-6 Months)\n\n1 Month: Lifts head briefly during tummy time. Can focus on faces 8-12 inches away. Responds to sounds. Strong grasp reflex. First pediatrician visit at 2 weeks for weight check.\n\n2 Months: Begins to smile socially. Tracks objects with eyes. Makes cooing sounds. Can hold head up at 45 degrees during tummy time. Vaccinations: DTaP, IPV, Hib, HepB (dose 2), PCV13, Rotavirus.\n\n3 Months: Reaches for and bats at objects. Laughs and squeals. Opens and closes hands. Supports upper body on arms during tummy time.\n\n4 Months: Rolls from tummy to back. Grasps toys. Babbles with expression. Recognizes familiar people. Vaccinations: DTaP (dose 2), IPV (dose 2), Hib (dose 2), PCV13 (dose 2), Rotavirus (dose 2).\n\n5-6 Months: Rolls both directions. Sits with support. Transfers objects between hands. Responds to own name. May begin showing interest in food. Vaccinations at 6 months: DTaP (dose 3), IPV (dose 3), HepB (dose 3), PCV13 (dose 3), Rotavirus (dose 3), Flu vaccine.\n\nWhen to Call the Pediatrician: Fever over 100.4F in babies under 3 months (emergency). Not feeding well or refusing feeds. Fewer than 6 wet diapers in 24 hours. Persistent vomiting. Unusual lethargy or difficulty waking. Rash with fever.\n\nGrowth Tracking: Babies typically double their birth weight by 4-5 months and triple it by 12 months. Head circumference, weight, and length are tracked at every well-child visit.\n\nTummy Time: Start from day one, beginning with 1-2 minutes several times daily. Work up to 15-20 minutes total per day by 2 months. Tummy time builds neck, shoulder, and core strength needed for rolling and sitting.",
                "newborn_essentials_checklist.txt": "Newborn Essentials Checklist — Must-Have Items\n\nSleep: Crib or bassinet that meets current safety standards (firm mattress, no gaps). 2-3 fitted crib sheets. 2-3 sleep sacks or wearable blankets. Optional: white noise machine, blackout curtains.\n\nTravel: Rear-facing infant car seat (installed before baby arrives). Stroller compatible with car seat. Diaper bag with changing pad.\n\nDiapering: Newborn-size diapers (2-3 packs to start). Fragrance-free baby wipes. Diaper rash cream (zinc oxide based). Changing pad or mat. Diaper pail.\n\nFeeding — Breastfeeding: Nursing pillow. Breast pump (check insurance coverage). Milk storage bags. Nursing bras (2-3). Nipple cream (lanolin-based). Bottle set for pumped milk.\n\nFeeding — Formula: Formula (as recommended by pediatrician). 4-6 bottles with slow-flow newborn nipples. Bottle brush. Formula dispenser for on-the-go.\n\nClothing: 6-8 onesies (mix of short and long sleeve). 4-6 footed sleepers/pajamas. 2-3 swaddle blankets. Socks and mittens. Season-appropriate outerwear. Hat for sun or warmth.\n\nHealth and Safety: Digital rectal thermometer. Infant nail clippers or file. Bulb syringe or nasal aspirator. Baby-safe laundry detergent. Baby monitor (audio or video). First aid kit with infant pain reliever (as directed by pediatrician).\n\nBathing: Infant bathtub or bath seat. Soft washcloths. Gentle baby wash/shampoo. Hooded towels. Baby lotion (fragrance-free)."
            };
            for (filename in docs) {
                fileWrite(dataDir & filename, docs[filename]);
            }
            writeOutput(serializeJSON({
                success: true,
                message: "5 baby care knowledge base documents created in " & application.dataDir,
                files:   structKeyList(docs),
                duration: getTickCount() - startMs
            }));
            abort;
        }

        // ---- Sync Ingestion ----
        if (action == "sync_ingest") {
            dataDir = application.dataDir;
            if (!directoryExists(dataDir) || arrayLen(directoryList(dataDir, false, "array", "*.txt")) == 0) {
                writeOutput(serializeJSON({ success: false, error: "No documents found. Please click 'Create Documents' first." }));
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
                MODELNAME: application.openaiModel
            });
            ragService = simpleRAG(dataDir, chatModel, {
                vectorStore:   vsClient,
                chunkSize:     500,
                chunkOverlap:  50
            });
            session.ragService = ragService;
            ingestResult = ragService.ingest();
            writeOutput(serializeJSON({
                success:   true,
                message:   "Sync ingestion complete! Baby care knowledge base is ready for retrieval queries.",
                stats:     ingestResult,
                duration:  getTickCount() - startMs
            }));
            abort;
        }

        // ---- Start Async Ingestion (large dataset) ----
        if (action == "async_ingest_start") {
            dataDir = application.dataDir;
            // Create additional large documents for a longer-running ingestion
            largeDocDir = dataDir & "large_async/";
            if (!directoryExists(largeDocDir)) directoryCreate(largeDocDir);

            topics = ["infant_massage", "baby_bathing", "colic_management", "postpartum_care",
                      "baby_proofing", "breastfeeding_positions", "formula_preparation", "sleep_regression",
                      "teething_guide", "baby_first_aid", "tummy_time_exercises", "baby_skin_care",
                      "growth_spurts", "baby_travel_safety", "introducing_solids", "baby_language_development",
                      "nursery_setup", "sibling_preparation", "baby_clothing_guide", "infant_CPR_basics"];
            for (i = 1; i <= arrayLen(topics); i++) {
                topic = topics[i];
                content = "Baby & Parenting Guide: " & uCase(replace(topic, "_", " ", "ALL")) & Chr(10) & Chr(10)
                    & "This comprehensive guide covers the " & replace(topic, "_", " ", "ALL")
                    & " best practices for new parents. " & Chr(10)
                    & "Section 1: Overview and Importance. This guide is intended for all parents, caregivers, and family members involved in the care of infants and young children. Following these guidelines helps ensure baby's health, safety, and developmental progress."
                    & Chr(10) & "Section 2: Key Recommendations. Pediatricians and child development experts recommend the techniques and practices described here. Always consult your pediatrician before making changes to your baby's care routine." & Chr(10)
                    & "Section 3: Step-by-Step Instructions. Detailed instructions are provided with age-appropriate guidance. Each technique has been reviewed by certified pediatric specialists and lactation consultants." & Chr(10)
                    & "Section 4: Safety Considerations. Always supervise your baby during any activity. Watch for signs of discomfort, allergic reactions, or distress. When in doubt, stop and consult your pediatrician." & Chr(10)
                    & "Section 5: When to Seek Help. If you notice anything unusual or have concerns about your baby's health or development, do not hesitate to contact your pediatrician. For emergencies, call 911 immediately." & Chr(10)
                    & "Contact: pediatrics@babycarecentral.com | Parent Helpline: 1-800-BABY-HELP";
                fileWrite(largeDocDir & topic & ".txt", content);
            }

            vsClient2 = vectorStore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider:  "ollama",
                    modelName: application.ollamaEmbedModel,
                    baseUrl:   application.ollamaurl
                }
            });
            chatModel2 = ChatModel({
                PROVIDER:  "openAi",
                APIKEY:    application.openaiKey,
                MODELNAME: application.openaiModel
            });
            ragSvc2 = simpleRAG(largeDocDir, chatModel2, {
                vectorStore:   vsClient2,
                chunkSize:     400,
                chunkOverlap:  60
            });
            // Start async ingestion — returns a Future immediately
            future = ragSvc2.ingestAsync();
            session.asyncFuture = future;
            session.asyncStart  = getTickCount();
            session.asyncRagSvc = ragSvc2;

            writeOutput(serializeJSON({
                success: true,
                message: "Async ingestion started — processing 20 baby & parenting guide documents in the background.",
                docsCount: 20,
                started: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")
            }));
            abort;
        }

        // ---- Check Async Ingestion Status ----
        if (action == "async_ingest_check") {
            if (isSimpleValue(session.asyncFuture) && session.asyncFuture == "") {
                writeOutput(serializeJSON({ success: false, error: "No async ingestion in progress. Start one first." }));
                abort;
            }
            elapsed = round((getTickCount() - session.asyncStart) / 1000);
            if (!isSimpleValue(session.asyncFuture) && session.asyncFuture.isDone()) {
                finalResult = session.asyncFuture.get();
                session.asyncFuture = "";
                writeOutput(serializeJSON({
                    success:  true,
                    status:   "completed",
                    message:  "Async ingestion completed. All 20 documents processed.",
                    elapsed:  elapsed & "s",
                    stats:    finalResult
                }));
            } else {
                writeOutput(serializeJSON({
                    success:  true,
                    status:   "in_progress",
                    message:  "Ingestion still running... (" & elapsed & "s elapsed).",
                    elapsed:  elapsed & "s"
                }));
            }
            abort;
        }

        writeOutput(serializeJSON({ success: false, error: "Unknown action: " & action }));

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
<title>Step 5: RAG Ingestion — Mintu Baby Care Assistant</title>
<cfinclude template="_styles.cfm">
</head>
<body>
<cfset variables.currentStep = "step5">
<cfset variables.pmtTabs = "RAG,Vector Stores">
<cfinclude template="_nav.cfm">

<div id="main">
    <div class="page-header">
        <div class="step-label">Step 5 &nbsp;|&nbsp; RAG Ingestion</div>
        <h2>RAG Ingestion + Async Demo</h2>
        <p>Build the Mintu Baby Care knowledge base. First create documents, then ingest them synchronously. Then start a long-running async ingestion to demonstrate the PMT "In-Progress" KPI card.</p>
    </div>

    <div class="page-content">

        <div class="banner banner-info">
            <span class="banner-icon">&#128202;</span>
            <div>
                <strong>PMT Dashboard: RAG Tab</strong>
                After sync ingest: see <strong>Ingestion KPIs</strong>, <strong>Completed Ingest Operations</strong> grid, and <strong>Document Journey</strong>. During async ingest: see <strong>Async In Progress KPI = 1</strong> and the <strong>In-Progress Ingest Operations</strong> grid live.
            </div>
        </div>

        <!-- Section 1: Create Documents -->
        <div class="section">
            <div class="section-title">1. Create Knowledge Base Documents</div>
            <div class="action-grid" style="grid-template-columns:1fr 1fr">
                <div class="action-card">
                    <div class="card-title">&#128196; Create Baby Care Knowledge Base</div>
                    <div class="card-desc">Writes 5 baby care documentation files to the <code>mintu_baby/data/</code> directory: newborn sleep guide, feeding schedule, diaper care guide, baby health milestones, and newborn essentials checklist.</div>
                    <button class="btn btn-primary" onclick="runAction('create_docs', 'result-create')">Create Documents</button>
                    <div class="result-area" id="result-create"></div>
                </div>
            </div>
        </div>

        <!-- Section 2: Sync Ingest -->
        <div class="section">
            <div class="section-title">2. Synchronous Ingestion (SimpleRAG)</div>
            <div class="action-grid" style="grid-template-columns:1fr 1fr">
                <div class="action-card">
                    <div class="card-title">&#128229; Run Sync Ingestion</div>
                    <div class="card-desc">Ingests the 5 baby care documents using Ollama <code>all-minilm</code> for embeddings, stored in an in-memory vector store. Waits until fully complete and shows ingestion stats.</div>
                    <button class="btn btn-primary" onclick="runAction('sync_ingest', 'result-sync')">Run Sync Ingest</button>
                    <div class="result-area" id="result-sync"></div>
                </div>
            </div>
        </div>

        <!-- Section 3: Async Ingest -->
        <div class="section">
            <div class="section-title">3. Async Ingestion — Large Dataset (In-Progress KPI Demo)</div>
            <div class="action-grid" style="grid-template-columns:1fr 1fr">
                <div class="action-card">
                    <div class="card-title">&#9889; Start Large Async Ingestion</div>
                    <div class="card-desc">Creates 20 baby & parenting guide documents and calls <code>ingestAsync()</code> which returns a Future immediately while ingestion continues in the background.</div>
                    <button class="btn btn-warning" id="asyncStartBtn" onclick="startAsyncIngest()">Start Async Ingest (Large)</button>
                    <div class="result-area" id="result-async-start"></div>
                </div>
                <div class="action-card">
                    <div class="card-title">&#128269; Check Ingestion Status</div>
                    <div class="card-desc">Poll whether the async Future is done. If still running, shows elapsed time. If complete, shows full ingestion stats. Click multiple times to see the transition from In-Progress to Completed.</div>
                    <button class="btn btn-secondary" id="asyncCheckBtn" onclick="checkAsyncStatus()">Check Ingestion Status</button>
                    <div class="result-area" id="result-async-check"></div>
                </div>
            </div>

        </div>

        <!-- Nav buttons -->
        <div style="margin-top:24px;display:flex;gap:12px;">
            <a href="step4_guardrails.cfm" class="btn btn-secondary">&#8592; Guardrails</a>
            <a href="step6_rag_retrieval.cfm" class="btn btn-primary">Next: RAG Retrieval &#8594;</a>
        </div>
    </div>
</div>

<div id="toast"></div>

<script>
function showLoading(id) {
    document.getElementById(id).innerHTML = '<div class="loading-row"><div class="spinner"></div><span>Processing...</span></div>';
}
function showToast(msg, type) {
    const t = document.getElementById('toast');
    t.textContent = msg;
    t.className = 'show toast-' + (type || 'success');
    setTimeout(() => { t.className = ''; }, 4000);
}
function escHtml(s) {
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

async function runAction(action, resultId) {
    showLoading(resultId);
    try {
        const res  = await fetch(window.location.pathname, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=' + action
        });
        const data = cfNorm(await res.json());
        const el   = document.getElementById(resultId);
        if (data.success) {
            var extra = '';
            if (data.duration) extra += `<span class="metric-badge time">&#9201; ${data.duration}ms</span>`;
            if (data.files)    extra += `<span class="metric-badge">&#128196; ${data.files.split(',').length} files</span>`;
            el.innerHTML = `<div class="result-card success">
                <div class="result-text">${escHtml(data.message)}</div>
                <div class="metrics-row">${extra}</div>
            </div>`;
            showToast(data.message.substring(0, 80), 'success');
        } else {
            el.innerHTML = `<div class="result-card error"><span style="color:#fc8181">&#10007; ${escHtml(data.error)}</span></div>`;
            showToast('Error: ' + data.error, 'error');
        }
    } catch(e) {
        document.getElementById(resultId).innerHTML = `<div class="result-card error">${escHtml(e.message)}</div>`;
    }
}

async function startAsyncIngest() {
    const btn = document.getElementById('asyncStartBtn');
    btn.disabled = true;
    showLoading('result-async-start');
    try {
        const res  = await fetch(window.location.pathname, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=async_ingest_start'
        });
        const data = cfNorm(await res.json());
        const el   = document.getElementById('result-async-start');
        if (data.success) {
            el.innerHTML = `<div class="result-card running">
                <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;">
                    <div class="spinner"></div>
                    <strong style="color:#63b3ed">Ingestion In Progress...</strong>
                </div>
                <div class="result-text">${escHtml(data.message)}</div>
                <div class="metrics-row">
                    <span class="metric-badge">&#128196; ${data.docscount} documents</span>
                    <span class="metric-badge time">Started: ${escHtml(data.started)}</span>
                </div>
            </div>`;
            showToast('Async ingestion started.', 'success');
        } else {
            el.innerHTML = `<div class="result-card error">${escHtml(data.error)}</div>`;
        }
    } catch(e) {
        document.getElementById('result-async-start').innerHTML = `<div class="result-card error">${escHtml(e.message)}</div>`;
    } finally {
        btn.disabled = false;
    }
}

async function checkAsyncStatus() {
    showLoading('result-async-check');
    try {
        const res  = await fetch(window.location.pathname, {
            method: 'POST',
            headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
            body: 'action=async_ingest_check'
        });
        const data = cfNorm(await res.json());
        const el   = document.getElementById('result-async-check');
        if (data.success) {
            if (data.status === 'in_progress') {
                el.innerHTML = `<div class="result-card running">
                    <div style="display:flex;align-items:center;gap:8px;margin-bottom:8px;">
                        <div class="spinner"></div>
                        <strong style="color:#63b3ed">Still Running (${escHtml(data.elapsed)})</strong>
                    </div>
                    <div class="result-text">${escHtml(data.message)}</div>
                </div>`;
                showToast('Ingestion still running...', 'success');
            } else {
                el.innerHTML = `<div class="result-card success">
                    <strong style="color:#68d391">&#10003; Ingestion Complete! (${escHtml(data.elapsed)})</strong>
                    <div class="result-text" style="margin-top:8px">${escHtml(data.message)}</div>
                    <div class="metrics-row">
                        <span class="metric-badge score">&#10003; Completed</span>
                        <span class="metric-badge time">&#9201; ${escHtml(data.elapsed)}</span>
                    </div>
                </div>`;
                showToast('Async ingestion complete.', 'success');
            }
        } else {
            el.innerHTML = `<div class="result-card error">${escHtml(data.error)}</div>`;
        }
    } catch(e) {
        document.getElementById('result-async-check').innerHTML = `<div class="result-card error">${escHtml(e.message)}</div>`;
    }
}
</script>
</body>
</html>
