<!---
    Nexora — Problem 9: Observability
    Every request is timed, token-counted, cost-estimated, and logged.
    API mode: ?api=1 (POST, returns JSON with message + metrics)
--->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            if (structKeyExists(url, "reset")) {
                apiPayload = {}; apiPayload["success"] = true; apiPayload["reset"] = true;
                writeOutput(serializeJSON(apiPayload)); return;
            }

            cfparam(name="form.question", default="");
            if (!len(trim(form.question))) {
                apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Please enter a question.";
                writeOutput(serializeJSON(apiPayload)); return;
            }

            startMs = getTickCount();

            chatModel = ChatModel({
                PROVIDER    : application.provider,
                APIKEY      : application.apiKey,
                MODELNAME   : application.modelName,
                TEMPERATURE : 0.3,
                MAXTOKENS   : 1500
            });

            aiAgent = agent({
                CHATMODEL  : chatModel,
                CHATMEMORY : { MAXMESSAGES: javacast("int", 20) },
                TOOLS      : [ { CFC: "SupportTool" } ]
            });

            aiAgent.systemMessage(
                "You are Nexora's friendly customer support assistant. " &
                "Only answer questions related to Nexora products, orders, and policies. " &
                "You have tools: use getOrderStatus for any order inquiry — NEVER guess. " &
                "Use escalateIssue when the customer asks to escalate or is very frustrated. " &
                "If asked about competitors, say: 'I can only help with Nexora products.' " &
                "Be concise and helpful."
            );

            toolsCalled = [];
            response    = aiAgent.chat(form.question);

            maxToolRounds = 3;
            for (round = 1; round <= maxToolRounds; round++) {
                rawRequests = response.toolExecutionRequests ?: [];
                toolRequests = [];
                for (req in rawRequests) { arrayAppend(toolRequests, req); }
                if (arrayLen(toolRequests) == 0) break;

                    supportTool    = new SupportTool();
                toolResultsStr = "";
                for (req in toolRequests) {
                    nm      = lCase(req.name ?: "");
                    rawArgs = req.arguments ?: {};
                    args    = isSimpleValue(rawArgs) ? deserializeJSON(rawArgs) : rawArgs;
                    arrayAppend(toolsCalled, nm);
                    try {
                        switch (nm) {
                            case "getorderstatus":
                                toolResult = supportTool.getOrderStatus(args.orderId ?: args.orderid ?: ""); break;
                            case "escalateissue":
                                toolResult = supportTool.escalateIssue(args.summary ?: "", args.orderId ?: args.orderid ?: ""); break;
                            default:
                                toolResult = "Unknown tool: " & nm;
                        }
                    } catch (any te) { toolResult = "Tool error: " & te.message; }
                    toolResultsStr &= "Tool " & (req.name ?: "") & " returned: " & toolResult & chr(10);
                }
                response = aiAgent.chat(
                    "Here are the tool results:" & chr(10) & toolResultsStr & chr(10) &
                    "Using ONLY these tool results, provide a complete, helpful answer to the customer. " &
                    "Do NOT say you are looking something up or executing a tool — the results are already here."
                );
            }

            elapsedMs = getTickCount() - startMs;
            msg = response.message ?: "";

            promptTokens = 0; completionTokens = 0; totalTokens = 0;
            try {
                u = {};
                if      (structKeyExists(response, "usage"))      { u = response.usage; }
                else if (structKeyExists(response, "tokenUsage")) { u = response.tokenUsage; }
                promptTokens     = u.promptTokens     ?: u.prompt_tokens     ?: u.inputTokens  ?: 0;
                completionTokens = u.completionTokens ?: u.completion_tokens ?: u.outputTokens ?: 0;
                totalTokens      = u.totalTokens      ?: u.total_tokens      ?: (promptTokens + completionTokens);
                if (promptTokens == 0 && completionTokens == 0) {
                    promptTokens     = int(len(form.question) / 4);
                    completionTokens = int(len(msg) / 4);
                    totalTokens      = promptTokens + completionTokens;
                }
            } catch (any ue) {}

            // Cost: claude-sonnet-4-5 — $3/1M input, $15/1M output
            estimatedCost = (promptTokens * 0.000003) + (completionTokens * 0.000015);

            writeLog(
                text = "OBSERVE | time=" & elapsedMs & "ms" &
                       " | prompt=" & promptTokens & " | completion=" & completionTokens &
                       " | cost=$" & numberFormat(estimatedCost, "0.000000") &
                       " | tools=" & (arrayLen(toolsCalled) ? arrayToList(toolsCalled) : "none") &
                       " | q=" & left(trim(form.question), 80),
                type = "information",
                file = "nexora"
            );

            metrics = {};
            metrics["responseMs"]       = elapsedMs;
            metrics["promptTokens"]     = promptTokens;
            metrics["completionTokens"] = completionTokens;
            metrics["totalTokens"]      = totalTokens;
            metrics["estimatedCost"]    = estimatedCost;
            metrics["toolsCalled"]      = arrayToList(toolsCalled);
            metrics["logged"]           = true;
            metrics["model"]            = application.modelName;

            apiPayload = {};
            apiPayload["success"] = true;
            apiPayload["message"] = msg;
            apiPayload["metrics"] = metrics;
            writeOutput(serializeJSON(apiPayload));

        } catch (any e) {
            elapsedMs = isDefined("startMs") ? (getTickCount() - startMs) : 0;
            writeLog(
                text = "OBSERVE_ERR | time=" & elapsedMs & "ms | error=" & e.message &
                       " | q=" & left(trim(form.question), 80),
                type = "error", file = "nexora"
            );
            apiPayload = {};
            apiPayload["success"] = false;
            apiPayload["message"] = "Error: " & e.message;
            apiPayload["metrics"] = { responseMs: elapsedMs, error: e.message, logged: true };
            writeOutput(serializeJSON(apiPayload));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Problem 9: Observability",
        subtitle    : "Problem 9 — Observability: Token Tracking, Cost &amp; Error Logging",
        activeNav   : "problem9-observability_demo.cfm",
        apiEndpoint : "problem9-observability_demo.cfm",
        placeholder : "Ask anything — watch the metrics appear after every response...",
        hasReset    : true,
        codeToggleLabel : "Show observability code",
        extraButtons: '<button class="btn-new2" id="newBtn" onclick="newConversation()">&##x21BA; Reset</button>',
        pills       : [
            { label: application.modelName, class: "p-blue"  },
            { label: "Token Tracking",  class: "p-teal"  },
            { label: "Cost Monitoring", class: "p-green" },
            { label: "Error Capture",   class: "p-orange" }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.extraCSS">
:root{--teal:#4ec9b0;}
.p-teal{background:rgba(78,201,176,.1);border-color:rgba(78,201,176,.3);color:var(--teal);}
.av-ai{background:var(--teal);color:#000;}
textarea:focus{border-color:var(--teal);}
.btn-send{background:var(--teal);color:#000;}
.chip:hover{border-color:var(--teal);color:var(--teal);}
.metrics-strip{max-width:calc(80% + 40px);margin-left:40px;display:flex;flex-wrap:wrap;gap:5px;padding:5px 0 10px;}
.m-pill{font-size:11px;padding:2px 9px;border-radius:20px;font-family:'Courier New',monospace;border:1px solid;white-space:nowrap;}
.m-time{background:rgba(78,201,176,.08);border-color:rgba(78,201,176,.3);color:var(--teal);}
.m-tokens{background:rgba(88,166,255,.08);border-color:rgba(88,166,255,.3);color:var(--accent);}
.m-cost{background:rgba(63,185,80,.08);border-color:rgba(63,185,80,.3);color:var(--green);}
.m-tool{background:rgba(240,136,62,.08);border-color:rgba(240,136,62,.3);color:var(--orange);}
.m-log{background:rgba(139,148,158,.08);border-color:rgba(139,148,158,.3);color:var(--muted);}
.m-error{background:rgba(250,69,73,.08);border-color:rgba(250,69,73,.3);color:var(--red);}
.session-bar{background:var(--surf2);border-top:1px solid var(--border);padding:7px 20px;display:flex;gap:20px;align-items:center;flex-shrink:0;flex-wrap:wrap;}
.session-bar .sb-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);margin-right:4px;}
.sb-val{font-size:12px;font-family:'Courier New',monospace;}
.sb-val.cost{color:var(--green);}.sb-val.time{color:var(--teal);}.sb-val.tok{color:var(--accent);}.sb-val.req{color:var(--txt);}
.prob-grid{display:inline-flex;flex-direction:column;gap:6px;text-align:left;max-width:560px;}
.prob-row{font-size:12.5px;padding:6px 12px;border-radius:6px;background:rgba(250,69,73,.07);border:1px solid rgba(250,69,73,.2);color:var(--txt);}
.prob-row .q{color:var(--red);font-weight:600;}
.btn-new2{background:none;border:1px solid var(--border);color:var(--muted);padding:10px 14px;border-radius:10px;font-size:13px;cursor:pointer;}
.btn-new2:hover{border-color:var(--muted);color:var(--txt);}
.btn-new2:disabled{opacity:.35;cursor:not-allowed;}
.nav-btn.active{border-color:var(--teal);color:var(--teal);background:rgba(78,201,176,.08);}
</cfsavecontent>

<cfsavecontent variable="ui.afterChat">
<div class="session-bar" id="sessionBar">
  <div><span class="sb-label">Requests</span><span class="sb-val req" id="sbReq">0</span></div>
  <div><span class="sb-label">Total Tokens</span><span class="sb-val tok" id="sbTok">0</span></div>
  <div><span class="sb-label">Session Cost</span><span class="sb-val cost" id="sbCost">$0.000000</span></div>
  <div><span class="sb-label">Avg Response</span><span class="sb-val time" id="sbAvg">—</span></div>
  <div><span class="sb-label">Errors</span><span class="sb-val" id="sbErr" style="color:var(--muted)">0</span></div>
</div>
</cfsavecontent>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 9 — The LLM is a Black Box</h2>
    <p style="color:var(--muted)">Without observability, every AI request is invisible. You can't explain costs, audit answers, or catch errors.</p>
    <div class="prob-grid">
        <div class="prob-row"><span class="q">&#x274C;</span> "Why is our AI bill $2,400 this month?" — no token tracking, can't answer</div>
        <div class="prob-row"><span class="q">&#x274C;</span> "Did the AI ever give a wrong answer?" — no log of AI responses</div>
        <div class="prob-row"><span class="q">&#x274C;</span> "Why did order #99821 query fail at 3:14 AM?" — no error capture</div>
        <div class="prob-row"><span class="q">&#x274C;</span> "Which questions generate the longest responses?" — no length monitoring</div>
        <div class="prob-row"><span class="q">&#x274C;</span> "Is the AI timing out sometimes?" — errors silently swallowed</div>
        <div class="prob-row"><span class="q">&#x274C;</span> "How do I know what prompts cost the most?" — blind to token usage</div>
    </div>
    <div class="info-box" style="margin-top:12px;">
        <strong>&#x2713; This demo solves all six — ask any question and watch the metrics appear live.</strong>
        Every response shows response time, prompt tokens, completion tokens, estimated cost, tools called, and a confirmed log entry.
        The session dashboard below accumulates totals — so you can answer "why is our AI bill $X?" in real time.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Watch the metrics — short queries vs long, tool calls vs direct</span>
    <span class="chip" onclick="send(this.innerText)">Where is my order #12345?</span>
    <span class="chip" onclick="send(this.innerText)">What's the status of order #99821?</span>
    <span class="chip" onclick="send(this.innerText)">What is your return policy?</span>
    <span class="chip" onclick="send(this.innerText)">Give me 5 tips for a great unboxing experience</span>
    <span class="chip" onclick="send(this.innerText)">Explain everything covered under the standard warranty and the Nexora Protect Plan</span>
    <span class="chip" onclick="send(this.innerText)">What are all your shipping options including international rates?</span>
    <span class="chip-label limits">&#x26A0; Even refused queries consume tokens and cost money</span>
    <span class="chip" onclick="send(this.innerText)">What's the weather like today?</span>
    <span class="chip" onclick="send(this.innerText)">Tell me about Amazon's return policy</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Every request: time it, count tokens, estimate cost, log everything</span>
<span class="fn">startMs</span> = <span class="fn">getTickCount</span>();

<span class="kw">try</span> {
    response  = aiAgent.<span class="fn">chat</span>( form.question );
    elapsedMs = <span class="fn">getTickCount</span>() - startMs;

    <span class="cm">// ── Extract token usage ──────────────────────────────────────</span>
    u                = response.usage ?: response.tokenUsage ?: {};
    promptTokens     = u.promptTokens     ?: u.prompt_tokens     ?: <span class="num">0</span>;
    completionTokens = u.completionTokens ?: u.completion_tokens ?: <span class="num">0</span>;

    <span class="cm">// ── Cost: claude-sonnet-4-5 ($3/1M input · $15/1M output) ──</span>
    estimatedCost = (promptTokens * <span class="num">0.000003</span>) + (completionTokens * <span class="num">0.000015</span>);

    <span class="cm">// ── Log every request ────────────────────────────────────────</span>
    <span class="fn">writeLog</span>(
        text = <span class="str">"OBSERVE | time="</span> & elapsedMs & <span class="str">"ms"</span> &
               <span class="str">" | prompt="</span>  & promptTokens &
               <span class="str">" | completion="</span> & completionTokens &
               <span class="str">" | cost=$"</span> & <span class="fn">numberFormat</span>(estimatedCost, <span class="str">"0.000000"</span>) &
               <span class="str">" | q="</span> & <span class="fn">left</span>(form.question, <span class="num">80</span>),
        type = <span class="str">"information"</span>, file = <span class="str">"nexora"</span>
    );

    apiPayload[<span class="str">"metrics"</span>] = {
        responseMs: elapsedMs, promptTokens: promptTokens,
        completionTokens: completionTokens, estimatedCost: estimatedCost
    };

} <span class="kw">catch</span> (any e) {
    <span class="fn">writeLog</span>( text=<span class="str">"OBSERVE_ERR | time="</span> & (<span class="fn">getTickCount</span>()-startMs) &
              <span class="str">"ms | error="</span> & e.message, type=<span class="str">"error"</span>, file=<span class="str">"nexora"</span> );
    rethrow;
}</cfsavecontent>

<cfsavecontent variable="ui.customJS">
(function(){
  var API='problem9-observability_demo.cfm';
  var chatInner=document.getElementById('chatInner'),chatArea=document.getElementById('chatArea'),
      input=document.getElementById('input'),sendBtn=document.getElementById('sendBtn'),
      newBtn=document.getElementById('newBtn'),chips=document.getElementById('chips'),
      welcome=document.getElementById('welcome'),busy=false;
  var sess={requests:0,tokens:0,cost:0,totalMs:0,errors:0};

  input.addEventListener('input',function(){this.style.height='auto';this.style.height=Math.min(this.scrollHeight,120)+'px';});

  function updateSessionBar(){
    document.getElementById('sbReq').textContent=sess.requests;
    document.getElementById('sbTok').textContent=sess.tokens.toLocaleString();
    document.getElementById('sbCost').textContent='$'+sess.cost.toFixed(6);
    document.getElementById('sbAvg').textContent=sess.requests?Math.round(sess.totalMs/sess.requests)+'ms':'—';
    var errEl=document.getElementById('sbErr');errEl.textContent=sess.errors;
    errEl.style.color=sess.errors>0?'var(--red)':'var(--muted)';
  }
  function addBubble(role,text){
    welcome.classList.add('hidden');
    var msg=document.createElement('div');msg.className='msg '+role;
    var av=document.createElement('div');av.className='av av-'+role;av.textContent=role==='ai'?'AI':'You';
    var bub=document.createElement('div');bub.className='bubble';bub.textContent=text;
    msg.appendChild(av);msg.appendChild(bub);chatInner.appendChild(msg);chatArea.scrollTop=chatArea.scrollHeight;return bub;
  }
  function addMetricsStrip(m){
    var strip=document.createElement('div');strip.className='metrics-strip';var parts=[];
    parts.push({cls:'m-time',text:'\u23F1 '+m.responseMs+'ms'});
    if(m.promptTokens||m.completionTokens){
      parts.push({cls:'m-tokens',text:'\u2B06 '+m.promptTokens+' prompt'});
      parts.push({cls:'m-tokens',text:'\u2B07 '+m.completionTokens+' completion'});
      parts.push({cls:'m-tokens',text:'= '+(m.promptTokens+m.completionTokens)+' total'});
    }
    if(m.estimatedCost!==undefined)parts.push({cls:'m-cost',text:'\uD83D\uDCB0 $'+m.estimatedCost.toFixed(6)});
    if(m.toolsCalled&&m.toolsCalled.length)parts.push({cls:'m-tool',text:'\uD83D\uDD27 '+m.toolsCalled});
    if(m.logged)parts.push({cls:'m-log',text:'\u2713 nexora.log'});
    parts.forEach(function(p){var sp=document.createElement('span');sp.className='m-pill '+p.cls;sp.textContent=p.text;strip.appendChild(sp);});
    chatInner.appendChild(strip);chatArea.scrollTop=chatArea.scrollHeight;
  }
  function addErrorStrip(msg,ms){
    var strip=document.createElement('div');strip.className='metrics-strip';
    [{cls:'m-time',text:'\u23F1 '+ms+'ms'},{cls:'m-error',text:'\u2717 ERROR — '+msg},{cls:'m-log',text:'\u2713 nexora.log'}].forEach(function(p){
      var sp=document.createElement('span');sp.className='m-pill '+p.cls;sp.textContent=p.text;strip.appendChild(sp);
    });chatInner.appendChild(strip);chatArea.scrollTop=chatArea.scrollHeight;
  }
  function showTyping(){var m=document.createElement('div');m.id='typing';m.className='msg ai';var av=document.createElement('div');av.className='av av-ai';av.textContent='AI';var b=document.createElement('div');b.className='bubble';b.innerHTML='<div class="typing"><div class="dot"></div><div class="dot"></div><div class="dot"></div></div>';m.appendChild(av);m.appendChild(b);chatInner.appendChild(m);chatArea.scrollTop=chatArea.scrollHeight;}
  function hideTyping(){var e=document.getElementById('typing');if(e)e.remove();}
  function typeText(bub,text){return new Promise(function(res){bub.textContent='';var i=0;var t=setInterval(function(){if(i<text.length){bub.textContent+=text[i++];chatArea.scrollTop=chatArea.scrollHeight;}else{clearInterval(t);res();}},11);});}

  window.send=function(t){input.value=t;sendMsg();};
  window.sendMsg=async function(){
    var q=input.value.trim();if(!q||busy)return;
    busy=true;sendBtn.disabled=true;if(newBtn)newBtn.disabled=true;input.value='';input.style.height='auto';
    addBubble('user',q);showTyping();
    try{
      var r=await fetch(API+'?api=1',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'question='+encodeURIComponent(q)});
      var d=await r.json();hideTyping();
      if(d.success!==false){
        var reply=(d.message||d.MESSAGE||'');var bub=addBubble('ai','');await typeText(bub,reply||'Sorry, try again.');
        if(d.metrics){var m=d.metrics;addMetricsStrip(m);sess.requests++;
          sess.tokens+=(m.totalTokens||(m.promptTokens+m.completionTokens)||0);
          sess.cost+=(m.estimatedCost||0);sess.totalMs+=(m.responseMs||0);updateSessionBar();}
      }else{var ms=(d.metrics&&d.metrics.responseMs)||0;addBubble('ai','Error: '+(d.message||'Unknown error'));
        addErrorStrip(d.message||'Unknown error',ms);sess.errors++;updateSessionBar();}
    }catch(e){hideTyping();addBubble('ai','Connection error — please try again.');
      addErrorStrip('Connection failed',0);sess.errors++;updateSessionBar();
    }finally{busy=false;sendBtn.disabled=false;if(newBtn)newBtn.disabled=false;input.focus();}
  };
  window.newConversation=function(){
    if(busy)return;chatInner.innerHTML='';chatInner.appendChild(welcome);welcome.classList.remove('hidden');
    sess={requests:0,tokens:0,cost:0,totalMs:0,errors:0};updateSessionBar();input.focus();
  };
  window.toggleCode=function(){
    var p=document.getElementById('codePanel'),b=document.querySelector('.code-toggle');
    if(p.style.display==='block'){p.style.display='none';b.textContent='Show observability code \u2193';}
    else{p.style.display='block';b.textContent='Hide observability code \u2191';}
  };
  input.focus();
})();
</cfsavecontent>

<cfinclude template="_ui.cfm">
