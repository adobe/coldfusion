<!---
    Nexora — Problem 8: RAG (Retrieval-Augmented Generation)
    simpleRAG() — ingest docs once, retrieve relevant chunks per question.
    POST ?api=1 → chat, POST ?api=1&action=ingest → build KB, POST ?api=1&reset=1 → clear
--->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            if (structKeyExists(url, "reset")) {
                structDelete(session, "nexoraRagAI_v6");
                apiPayload = {}; apiPayload["success"] = true; apiPayload["reset"] = true;
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            if (structKeyExists(url, "action") && url.action == "ingest") {
                if (!isDefined("session.nexoraRagAI_v6")) {
                    lock scope="session" type="exclusive" timeout="120" {
                        if (!isDefined("session.nexoraRagAI_v6")) {

                            chatModel = ChatModel({
                                PROVIDER  : application.provider,
                                APIKEY    : application.apiKey,
                                MODELNAME : application.modelName,
                                MAXTOKENS : 500
                            });

                            docsPath = expandPath("docs/policies/");

                            ragBot = simpleRAG(docsPath, chatModel, {
                                chunkSize:    800,
                                chunkOverlap: 150,
                                vectorStore: {
                                    provider:       "INMEMORY",
                                    embeddingModel: {
                                        provider:  application.embedProvider,
                                        modelName: application.embedModelName,
                                        apiKey:    application.embedApiKey
                                    }
                                }
                            });

                            ragBot.ingest();
                            session.nexoraRagAI_v6 = ragBot;
                        }
                    }
                }
                docsPath  = expandPath("docs/policies/");
                docFiles  = directoryList(docsPath, false, "name", "*.txt");
                apiPayload = {};
                apiPayload["success"]  = true;
                apiPayload["ingested"] = true;
                apiPayload["docCount"] = arrayLen(docFiles);
                apiPayload["docs"]     = docFiles;
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            cfparam(name="form.question", default="");
            if (!len(trim(form.question))) {
                apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Please enter a question.";
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            if (!isDefined("session.nexoraRagAI_v6")) {
                apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Knowledge base is still loading — please wait a moment and try again.";
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            lock scope="session" type="exclusive" timeout="60" {
                response = session.nexoraRagAI_v6.ask(form.question);
            }
            answer = isSimpleValue(response) ? response : (response.message ?: response.toString());
            apiPayload = {}; apiPayload["success"] = true; apiPayload["message"] = answer;
            writeOutput(serializeJSON(apiPayload));

        } catch (any e) {
            apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Error: " & e.message & " | " & e.detail;
            writeOutput(serializeJSON(apiPayload));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Problem 8: RAG",
        subtitle    : "Problem 8 — RAG: Retrieval-Augmented Generation",
        activeNav   : "problem8-rag_demo.cfm",
        apiEndpoint : "problem8-rag_demo.cfm",
        placeholder : "Knowledge base loading — please wait...",
        hasReset    : true,
        inputAttrs  : "disabled",
        sendBtnAttrs: "disabled",
        pills       : [
            { label: application.modelName, class: "p-blue"   },
            { label: "System Message ✓", class: "p-green"  },
            { label: "Memory ✓",         class: "p-purple" },
            { label: "RAG ✓",            class: "p-teal"   }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.extraCSS">
:root{--teal:#39d353;}
.p-teal{background:rgba(57,211,83,.1);border-color:rgba(57,211,83,.3);color:var(--teal);}
.ingest-bar{padding:7px 20px;display:flex;align-items:center;gap:10px;font-size:12px;flex-shrink:0;transition:background .3s;}
.ingest-bar.loading{background:rgba(88,166,255,.08);border-bottom:1px solid rgba(88,166,255,.2);color:var(--accent);}
.ingest-bar.ready{background:rgba(63,185,80,.08);border-bottom:1px solid rgba(63,185,80,.2);color:var(--green);}
.ingest-bar.error{background:rgba(250,69,73,.08);border-bottom:1px solid rgba(250,69,73,.2);color:var(--red);}
.spin{display:inline-block;width:12px;height:12px;border:2px solid currentColor;border-top-color:transparent;border-radius:50%;animation:spin .7s linear infinite;flex-shrink:0;}
@keyframes spin{to{transform:rotate(360deg);}}
.ingest-dot{width:8px;height:8px;border-radius:50%;background:currentColor;flex-shrink:0;}
.flow-row{display:flex;align-items:center;justify-content:center;gap:6px;flex-wrap:wrap;margin:0 auto;max-width:640px;}
.flow-box{background:var(--surf2);border:1px solid var(--border);border-radius:8px;padding:7px 12px;font-size:11px;text-align:center;line-height:1.4;}
.flow-box.hi{border-color:var(--teal);color:var(--teal);}
.flow-box.dim{border-color:var(--border);color:var(--muted);}
.flow-arrow{color:var(--muted);font-size:16px;}
.compare{display:flex;gap:10px;max-width:540px;margin:14px auto 0;}
.compare-box{flex:1;background:var(--surf2);border:1px solid var(--border);border-radius:8px;padding:10px 12px;font-size:11px;line-height:1.5;}
.compare-box .lbl{font-weight:700;font-size:10px;text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px;}
.compare-box.bad .lbl{color:var(--red);}.compare-box.good .lbl{color:var(--green);}
.chip:disabled,.chip.disabled{opacity:.4;pointer-events:none;}
</cfsavecontent>

<cfsavecontent variable="ui.beforeChat">
<div class="ingest-bar loading" id="ingestBar">
  <div class="spin" id="ingestSpin"></div>
  <span id="ingestMsg">Ingesting knowledge base — loading 4 policy documents into vector store...</span>
</div>
</cfsavecontent>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 8 — RAG (Retrieval-Augmented Generation)</h2>
    <div class="info-box"><strong>&#x2713; Solves:</strong> Problem 2 injects <em>all</em> policy documents into the system message on every request — ~2 000 tokens wasted regardless of what the customer asked. RAG fixes this: docs are <strong>chunked, embedded, and stored once</strong> in a vector store. Each question retrieves only the semantically relevant ~500 tokens. Scales to thousands of documents without increasing per-request cost.</div>
    <div class="flow-row">
        <div class="flow-box dim">docs/policies/<br><span style="font-size:10px;color:var(--muted)">4 txt files</span></div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-box hi">Chunker<br><span style="font-size:10px">500 chars, 100 overlap</span></div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-box hi">Embed<br><span style="font-size:10px">Mistral vectors</span></div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-box hi">Vector Store<br><span style="font-size:10px">in-memory</span></div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-box" style="border-color:var(--accent);color:var(--accent)">Retrieve<br><span style="font-size:10px">top-K relevant chunks</span></div>
        <div class="flow-arrow">&rarr;</div>
        <div class="flow-box dim">LLM<br><span style="font-size:10px">answers from chunks</span></div>
    </div>
    <div class="compare">
        <div class="compare-box bad"><div class="lbl">Problem 2 — System Message</div>All 4 docs injected on <em>every</em> request<br>~2 000 tokens × every message<br>Irrelevant docs slow down the LLM</div>
        <div class="compare-box good"><div class="lbl">Problem 8 — RAG</div>Ingest once → retrieve on demand<br>~500 tokens of relevant context only<br>Scales to thousands of documents</div>
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Solves Problem 6 gaps — policy questions MCP could not answer</span>
    <span class="chip disabled" onclick="send(this.innerText)">Does the warranty cover accidental water damage?</span>
    <span class="chip disabled" onclick="send(this.innerText)">Can I return a digital download that won't install?</span>
    <span class="chip disabled" onclick="send(this.innerText)">What is your return policy for physical products?</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Problem 8: RAG — ingest once, retrieve per question</span>
<span class="cm">// CF 2025 simpleRAG() handles: load → chunk → embed → store → retrieve → generate</span>

chatModel = <span class="fn">ChatModel</span>({
    PROVIDER: <span class="str">"anthropic"</span>, APIKEY: application.anthropicKey,
    MODELNAME: <span class="str">"claude-sonnet-4-5"</span>, MAXTOKENS: <span class="kw">500</span>
});

<span class="diff-add">ragBot = <span class="fn">simpleRAG</span>(docsPath, chatModel, {</span>
<span class="diff-add">    chunkSize: <span class="kw">800</span>, chunkOverlap: <span class="kw">150</span>,</span>
<span class="diff-add">    vectorStore: {</span>
<span class="diff-add">        provider: <span class="str">"INMEMORY"</span>,</span>
<span class="diff-add">        embeddingModel: {</span>
<span class="diff-add">            provider: <span class="str">"mistral"</span>, modelName: <span class="str">"mistral-embed"</span>,</span>
<span class="diff-add">            apiKey: application.mistralkey</span>
<span class="diff-add">        }</span>
<span class="diff-add">    }</span>
<span class="diff-add">});</span>

ragBot.<span class="fn">ingest</span>();
session.nexoraRagAI = ragBot;
response = session.nexoraRagAI.<span class="fn">ask</span>(form.question);</cfsavecontent>

<cfsavecontent variable="ui.customJS">
(function(){
  var API='problem8-rag_demo.cfm';
  var chatInner=document.getElementById('chatInner'),chatArea=document.getElementById('chatArea'),
      input=document.getElementById('input'),sendBtn=document.getElementById('sendBtn'),
      chips=document.getElementById('chips'),welcome=document.getElementById('welcome'),
      ingestBar=document.getElementById('ingestBar'),ingestSpin=document.getElementById('ingestSpin'),
      ingestMsg=document.getElementById('ingestMsg'),newConvBtn=document.getElementById('newConvBtn'),
      busy=false,ready=false;

  input.addEventListener('input',function(){this.style.height='auto';this.style.height=Math.min(this.scrollHeight,120)+'px';});

  function enableChat(docCount){
    ready=true;ingestBar.className='ingest-bar ready';ingestSpin.style.display='none';
    var dot=document.createElement('div');dot.className='ingest-dot';ingestSpin.parentNode.insertBefore(dot,ingestSpin);
    ingestMsg.textContent='Knowledge base ready — '+docCount+' policy documents ingested into vector store';
    input.disabled=false;input.placeholder='Ask about returns, shipping, warranty, or digital products...';
    sendBtn.disabled=false;newConvBtn.disabled=false;
    Array.from(chips.querySelectorAll('.chip')).forEach(function(c){c.classList.remove('disabled');});
  }
  function showIngestError(msg){ingestBar.className='ingest-bar error';ingestSpin.style.display='none';ingestMsg.textContent='Ingestion failed: '+msg;}

  (async function(){
    try{
      var r=await fetch(API+'?api=1&action=ingest',{method:'POST'});var d=await r.json();
      if(d.ingested||d.INGESTED){enableChat(d.docCount||d.DOCCOUNT||0);}
      else{showIngestError((d.message||d.MESSAGE||'Unknown error'));}
    }catch(e){showIngestError('Connection error — '+e.message);}
  })();

  function addBubble(role,text){
    welcome.classList.add('hidden');
    var msg=document.createElement('div');msg.className='msg '+role;
    var av=document.createElement('div');av.className='av av-'+role;av.textContent=role==='ai'?'AI':'You';
    var bub=document.createElement('div');bub.className='bubble';bub.textContent=text;
    msg.appendChild(av);msg.appendChild(bub);chatInner.appendChild(msg);chatArea.scrollTop=chatArea.scrollHeight;return bub;
  }
  function addSysMsg(text){var w=document.createElement('div');w.className='sys-wrap';var s=document.createElement('div');s.className='sys-msg';s.textContent=text;w.appendChild(s);chatInner.appendChild(w);chatArea.scrollTop=chatArea.scrollHeight;}
  function showTyping(){var m=document.createElement('div');m.id='typing';m.className='msg ai';var av=document.createElement('div');av.className='av av-ai';av.textContent='AI';var b=document.createElement('div');b.className='bubble';b.innerHTML='<div class="typing"><div class="dot"></div><div class="dot"></div><div class="dot"></div></div>';m.appendChild(av);m.appendChild(b);chatInner.appendChild(m);chatArea.scrollTop=chatArea.scrollHeight;}
  function hideTyping(){var e=document.getElementById('typing');if(e)e.remove();}
  function typeText(bub,text){return new Promise(function(res){bub.textContent='';var i=0;var t=setInterval(function(){if(i<text.length){bub.textContent+=text[i++];chatArea.scrollTop=chatArea.scrollHeight;}else{clearInterval(t);res();}},11);});}

  window.send=function(t){if(!ready)return;input.value=t;sendMsg();};
  window.sendMsg=async function(){
    var q=input.value.trim();if(!q||busy||!ready)return;
    busy=true;sendBtn.disabled=true;input.value='';input.style.height='auto';
    addBubble('user',q);showTyping();
    try{
      var r=await fetch(API+'?api=1',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'question='+encodeURIComponent(q)});
      var d=await r.json();hideTyping();
      var reply=(d.message!==undefined&&d.message!==null)?d.message:(d.MESSAGE!==undefined&&d.MESSAGE!==null)?d.MESSAGE:'';
      var bub=addBubble('ai','');await typeText(bub,reply!==''?String(reply):'Sorry, I could not generate a response — please try again.');
    }catch(e){hideTyping();addBubble('ai','Connection error — please try again.');}
    finally{busy=false;sendBtn.disabled=false;input.focus();}
  };
  window.newConversation=async function(){
    if(busy||!ready)return;busy=true;newConvBtn.disabled=true;
    try{
      await fetch(API+'?api=1&reset=1',{method:'POST'});
      chatInner.innerHTML='';welcome.classList.remove('hidden');chips.classList.remove('hidden');chatInner.appendChild(welcome);
      ready=false;ingestBar.className='ingest-bar loading';ingestSpin.style.display='';
      ingestMsg.textContent='Re-ingesting knowledge base...';input.disabled=true;input.placeholder='Knowledge base loading — please wait...';
      sendBtn.disabled=true;Array.from(chips.querySelectorAll('.chip')).forEach(function(c){c.classList.add('disabled');});
      var r=await fetch(API+'?api=1&action=ingest',{method:'POST'});var d=await r.json();
      if(d.ingested||d.INGESTED){enableChat(d.docCount||d.DOCCOUNT||0);}
    }catch(e){showIngestError('Re-ingest failed');}
    finally{busy=false;newConvBtn.disabled=false;}
    addSysMsg('New conversation started — memory cleared.');
  };
  window.toggleCode=function(){
    var p=document.getElementById('codePanel'),b=document.querySelector('.code-toggle');
    if(p.style.display==='block'){p.style.display='none';b.textContent='Show active code \u2193';}
    else{p.style.display='block';b.textContent='Hide active code \u2191';}
  };
})();
</cfsavecontent>

<cfinclude template="_ui.cfm">
