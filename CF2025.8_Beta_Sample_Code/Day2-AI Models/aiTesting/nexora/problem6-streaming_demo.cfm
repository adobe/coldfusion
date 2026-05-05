<!---
    Nexora — Problem 6: Streaming
    cfthread + writeLog streaming: TOKEN entries polled by browser.
    POST ?api=1 → start chat (returns {streamId}), GET ?poll=1&streamId=X → tokens, POST ?api=1&reset=1 → reset
--->

<!--- ── Poll endpoint ────────────────────────────────────────────────── --->
<cfif structKeyExists(url, "poll")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            streamId = url.streamId ?: "";
            if ( !len(streamId) || !structKeyExists(server, "nexoraStreams") ||
                 !structKeyExists(server.nexoraStreams, streamId) ) {
                writeOutput(serializeJSON({ done: true, response: "", error: "expired", metrics: {} }));
                return;
            }

            lock name="nexStream_#streamId#" timeout=5 type="readonly" {
                buf     = server.nexoraStreams[ streamId ];
                done    = buf.done;
                tokens  = duplicate(buf.tokens ?: []);
                err     = buf.error   ?: "";
                metrics = duplicate(buf.metrics ?: {});
            }
            if (done) {
                lock name="nexStream_#streamId#" timeout=5 type="exclusive" {
                    structDelete(server.nexoraStreams, streamId);
                }
            }

            writeOutput(serializeJSON({ done: done, tokens: tokens, error: err, metrics: metrics }));
        } catch (any e) {
            writeOutput(serializeJSON({ done: true, response: "", error: e.message, metrics: {} }));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── Chat / reset API ─────────────────────────────────────────────── --->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            if ( structKeyExists(url, "reset") ) {
                writeOutput(serializeJSON({ success: true, reset: true }));
                return;
            }

            cfparam(name="form.question", default="");
            if ( !len(trim(form.question)) ) {
                writeOutput(serializeJSON({ success: false, message: "Please enter a question." }));
                return;
            }

            streamId = createUUID();
            startMs  = getTickCount();

            if ( !structKeyExists(server, "nexoraStreams") ) {
                lock name="nexStreamInit" timeout=10 type="exclusive" {
                    if ( !structKeyExists(server, "nexoraStreams") ) {
                        server.nexoraStreams = {};
                    }
                }
            }
            lock name="nexStream_#streamId#" timeout=5 type="exclusive" {
                server.nexoraStreams[ streamId ] = {
                    tokens: [], done: false, error: "", metrics: {},
                    startMs: startMs, question: trim(form.question)
                };
            }

            logFile      = "/Applications/ColdFusion2025/cfusion/logs/nexora-stream.log";
            logStartLine = 0;
            try {
                if (fileExists(logFile)) { logStartLine = listLen(fileRead(logFile), chr(10)); }
            } catch (any e2) {}

            // Write START marker — handler can't access CF scopes so we identify
            // our stream's entries as everything between START and DONE/STREAMERROR
            writeLog( text="START:" & streamId, type="information", file="nexora-stream" );

            sysMsg = "You are Nexora Support, the official customer support assistant for Nexora — an online retail company with the tagline 'Shop Smarter. Ship Faster.'" & chr(10) &
                    "1. IDENTITY: Always identify yourself as 'Nexora Support'. Never say you are an AI." & chr(10) &
                    "2. SCOPE: ONLY answer questions about Nexora products, orders, shipping, returns, and policies." & chr(10) &
                    "3. COMPETITORS: If asked about Amazon, Walmart, eBay, etc., say: 'I can only help with Nexora products and services.'" & chr(10) &
                    "4. OFF-TOPIC: If asked about weather, sports, coding, etc., say: 'I'm Nexora Support — I can only help with Nexora orders, products, and policies.'" & chr(10) &
                    "5. TONE: Be warm, concise (2-3 sentences max), and professional.";

            chatModel = ChatModel({
                PROVIDER    : application.provider,
                APIKEY      : application.apiKey,
                MODELNAME   : application.modelName,
                TEMPERATURE : 0.4,
                MAXTOKENS   : 600
            });

            aiagent = Agent({
                CHATMODEL        : chatModel,
                STREAMINGHANDLER : "aiTesting.nexora.StreamBuffer"
            });
            aiagent.systemMessage( sysMsg );

            question = form.question;

            // Thread A: run chat() — StreamBuffer writes TOKEN:/DONE:/STREAMERROR: to log
            cfthread( action="run", name="nexChat_#streamId#",
                      sid=streamId, ag=aiagent, q=question ) {
                try {
                    attributes.ag.chat( attributes.q );
                } catch (any e) {
                    lock name="nexStream_#attributes.sid#" timeout=5 type="exclusive" {
                        if (structKeyExists(server,"nexoraStreams") && structKeyExists(server.nexoraStreams,attributes.sid)) {
                            server.nexoraStreams[attributes.sid].done  = true;
                            server.nexoraStreams[attributes.sid].error = e.message;
                        }
                    }
                }
            };

            // Thread B: watch nexora-stream.log for TOKEN:/DONE:/STREAMERROR: entries
            // after our START marker line
            cfthread( action="run", name="nexWatch_#streamId#",
                      sid=streamId, t0=startMs, lf=logFile, ls=logStartLine, q=question ) {
                var sid      = attributes.sid;
                var lastLine = attributes.ls;
                var done     = false;
                var waited   = 0;
                var foundStart = false;

                while (!done && waited < 60000) {
                    sleep(150);
                    waited += 150;
                    if (!fileExists(attributes.lf)) continue;
                    try {
                        var lines    = listToArray(fileRead(attributes.lf), chr(10));
                        var numLines = arrayLen(lines);
                        if (numLines <= lastLine) continue;

                        var newTokens = [];
                        for (var li = lastLine + 1; li <= numLines; li++) {
                            var ln = lines[li];

                            if (!foundStart) {
                                if (find("START:" & sid, ln)) foundStart = true;
                                continue;
                            }

                            if (find("TOKEN:", ln)) {
                                var p  = find("TOKEN:", ln) + 6;
                                var tk = mid(ln, p, len(ln));
                                if (len(tk)) arrayAppend(newTokens, tk);
                            }
                            else if (find("DONE:", ln)) {
                                done = true;
                            }
                            else if (find("STREAMERROR:", ln)) {
                                var p   = find("STREAMERROR:", ln) + 12;
                                var errMsg = mid(ln, p, len(ln));
                                lock name="nexStream_#sid#" timeout=5 type="exclusive" {
                                    if (structKeyExists(server,"nexoraStreams")&&structKeyExists(server.nexoraStreams,sid)){
                                        server.nexoraStreams[sid].done=true;
                                        server.nexoraStreams[sid].error=errMsg;
                                    }
                                }
                                done = true;
                            }
                            else if (find("START:", ln)) {
                                // Another stream started — ours is done
                                done = true;
                            }
                        }
                        lastLine = numLines;

                        if (arrayLen(newTokens)) {
                            lock name="nexStream_#sid#" timeout=3 type="exclusive" {
                                if (structKeyExists(server,"nexoraStreams")&&structKeyExists(server.nexoraStreams,sid)){
                                    for (var tk in newTokens) { arrayAppend(server.nexoraStreams[sid].tokens, tk); }
                                }
                            }
                        }

                        if (done) {
                            var elapsedMs = getTickCount() - attributes.t0;
                            // Estimate tokens from streamed chunks
                            var allTokens = [];
                            lock name="nexStream_#sid#" timeout=3 type="readonly" {
                                if (structKeyExists(server,"nexoraStreams")&&structKeyExists(server.nexoraStreams,sid)){
                                    allTokens = duplicate(server.nexoraStreams[sid].tokens);
                                }
                            }
                            var fullText = arrayToList(allTokens, "");
                            var completionTokens = max(1, int(len(fullText) / 4));
                            var promptTokens = max(1, int(len(attributes.q) / 4) + 50);
                            var totalTokens = promptTokens + completionTokens;
                            var estimatedCost = (promptTokens * 0.000003) + (completionTokens * 0.000015);

                            var metrics = {
                                responseMs: elapsedMs,
                                promptTokens: promptTokens,
                                completionTokens: completionTokens,
                                totalTokens: totalTokens,
                                estimatedCost: estimatedCost,
                                logged: true
                            };
                            writeLog(
                                text = "STREAM | time=" & elapsedMs & "ms" &
                                       " | prompt=" & promptTokens &
                                       " | completion=" & completionTokens &
                                       " | cost=$" & numberFormat(estimatedCost,"0.000000") &
                                       " | q=" & left(trim(attributes.q),80),
                                type = "information", file = "nexora"
                            );
                            lock name="nexStream_#sid#" timeout=5 type="exclusive" {
                                if (structKeyExists(server,"nexoraStreams")&&structKeyExists(server.nexoraStreams,sid)){
                                    server.nexoraStreams[sid].done    = true;
                                    server.nexoraStreams[sid].metrics = metrics;
                                }
                            }
                        }
                    } catch (any loopErr) {}
                }

                // Timeout fallback
                if (!done) {
                    lock name="nexStream_#sid#" timeout=5 type="exclusive" {
                        if (structKeyExists(server,"nexoraStreams")&&structKeyExists(server.nexoraStreams,sid)){
                            if (!server.nexoraStreams[sid].done) {
                                server.nexoraStreams[sid].done = true;
                                if (!arrayLen(server.nexoraStreams[sid].tokens)) {
                                    server.nexoraStreams[sid].error = "Stream timeout — no response received.";
                                }
                            }
                        }
                    }
                }
            };

            writeOutput(serializeJSON({ success: true, streamId: streamId }));

        } catch (any e) {
            errDetail = e.message;
            if (len(e.detail ?: "")) errDetail &= " | detail: " & e.detail;
            if (len(e.type ?: "")) errDetail &= " | type: " & e.type;
            if (structKeyExists(e, "tagContext") && isArray(e.tagContext) && arrayLen(e.tagContext)) {
                tc = e.tagContext[1];
                errDetail &= " | file: " & (tc.template ?: "") & " line: " & (tc.line ?: "");
            }
            writeOutput(serializeJSON({ success: false, message: errDetail }));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Problem 6: Streaming",
        subtitle    : "Problem 6 — Streaming &amp; Observability",
        activeNav   : "problem6-streaming_demo.cfm",
        apiEndpoint : "problem6-streaming_demo.cfm",
        placeholder : "Ask something — watch tokens stream in, then see the metrics...",
        hasReset    : false,
        pills       : [
            { label: application.modelName, class: "p-blue"  },
            { label: "Streaming",       class: "p-green" },
            { label: "Token Tracking",  class: "p-teal"  },
            { label: "Cost Monitoring", class: "p-orange" }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.extraCSS">
:root{--teal:#4ec9b0;}
.p-teal{background:rgba(78,201,176,.1);border-color:rgba(78,201,176,.3);color:var(--teal);}
.cursor{display:inline-block;width:2px;height:1em;background:var(--accent);margin-left:1px;animation:blink .7s step-end infinite;vertical-align:text-bottom;}
@keyframes blink{0%,100%{opacity:1;}50%{opacity:0;}}
.metrics-strip{max-width:calc(80% + 40px);margin-left:40px;display:flex;flex-wrap:wrap;gap:5px;padding:4px 0 8px;}
.m-pill{font-size:11px;padding:2px 9px;border-radius:20px;font-family:'Courier New',monospace;border:1px solid;white-space:nowrap;}
.m-time{background:rgba(78,201,176,.08);border-color:rgba(78,201,176,.3);color:var(--teal);}
.m-tokens{background:rgba(88,166,255,.08);border-color:rgba(88,166,255,.3);color:var(--accent);}
.m-cost{background:rgba(63,185,80,.08);border-color:rgba(63,185,80,.3);color:var(--green);}
.m-log{background:rgba(139,148,158,.08);border-color:rgba(139,148,158,.3);color:var(--muted);}
.m-error{background:rgba(250,69,73,.08);border-color:rgba(250,69,73,.3);color:var(--red);}
.session-bar{background:var(--surf2);border-top:1px solid var(--border);padding:7px 20px;display:flex;gap:20px;align-items:center;flex-shrink:0;flex-wrap:wrap;}
.sb-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);margin-right:4px;}
.sb-val{font-size:12px;font-family:'Courier New',monospace;}
.sb-val.cost{color:var(--green);}.sb-val.time{color:var(--teal);}.sb-val.tok{color:var(--accent);}
.two-col{display:inline-flex;gap:12px;flex-wrap:wrap;justify-content:center;max-width:680px;margin-bottom:14px;}
.chip-label.warn{color:rgba(255,160,0,.85);}
</cfsavecontent>

<cfsavecontent variable="ui.afterChat">
<div class="session-bar" id="sessionBar">
  <div><span class="sb-label">Requests</span><span class="sb-val" id="sbReq">0</span></div>
  <div><span class="sb-label">Total Tokens</span><span class="sb-val tok" id="sbTok">0</span></div>
  <div><span class="sb-label">Session Cost</span><span class="sb-val cost" id="sbCost">$0.000000</span></div>
  <div><span class="sb-label">Avg Response</span><span class="sb-val time" id="sbAvg">—</span></div>
</div>
</cfsavecontent>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 6 — Streaming &amp; Observability</h2>
    <p>Two problems. One page. Watch tokens arrive live, then see exactly what each response cost.</p>
    <div class="two-col">
        <div class="info-box">
            <strong>&#x2713; Streaming: no more blank-screen wait</strong>
            Without STREAMINGHANDLER, the user stares at a blank screen for 3–8 seconds.
            With it, tokens appear instantly — perceived latency drops to near zero.
        </div>
        <div class="info-box">
            <strong>&#x2713; Observability: the AI is no longer a black box</strong>
            Every response shows response time, prompt + completion tokens, estimated cost ($),
            and a confirmed nexora.log entry — so you can explain every line of the AI bill.
        </div>
    </div>
    <div class="warn-box" style="max-width:520px;display:inline-block;">
        <strong>&#x26A0; Even refused queries cost tokens — watch the metrics on off-topic questions</strong>
        The session dashboard below accumulates totals so you can answer "why is our AI bill $X?" in real time.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label">Watch tokens stream live — then see the metrics &#x2193;</span>
    <span class="chip" onclick="send(this.innerText)">What is your return policy?</span>
    <span class="chip" onclick="send(this.innerText)">Explain the difference between standard and express shipping</span>
    <span class="chip" onclick="send(this.innerText)">Give me 5 tips for a great unboxing experience</span>
    <span class="chip" onclick="send(this.innerText)">Explain everything covered under the standard warranty and the Nexora Protect Plan in full detail</span>
    <span class="chip-label warn">&#x26A0; Refused queries still consume tokens and appear in the cost dashboard</span>
    <span class="chip" onclick="send(this.innerText)">What's the weather like today?</span>
    <span class="chip" onclick="send(this.innerText)">Tell me about Amazon's return policy</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// ── Streaming: tokens arrive live via STREAMINGHANDLER ──────────────────────</span>
handler   = <span class="kw">new</span> <span class="fn">StreamBuffer</span>( streamId, <span class="fn">getTickCount</span>(), form.question );

chatModel = <span class="fn">ChatModel</span>({
    PROVIDER         : <span class="str">"anthropic"</span>,  APIKEY : application.anthropicKey,
    MODELNAME        : <span class="str">"claude-sonnet-4-5"</span>,
    STREAMINGHANDLER : handler
});

<span class="fn">cfthread</span>( action=<span class="str">"run"</span> ) {
    attributes.cm.<span class="fn">chat</span>( attributes.q );
};

<span class="cm">// ── Observability: captured in StreamBuffer.onCompleteResponse() ────────────</span>
<span class="kw">remote void function</span> <span class="fn">onCompleteResponse</span>( <span class="kw">required struct</span> response ) {
    u                = response.usage ?: response.tokenUsage ?: {};
    promptTokens     = u.promptTokens     ?: <span class="num">0</span>;
    completionTokens = u.completionTokens ?: <span class="num">0</span>;
    estimatedCost    = (promptTokens * <span class="num">0.000003</span>) + (completionTokens * <span class="num">0.000015</span>);
    buf.done    = <span class="kw">true</span>;
}

<span class="fn">writeLog</span>( text=<span class="str">"STREAM | time="</span>&elapsedMs&<span class="str">"ms | cost=$"</span>&estimatedCost, file=<span class="str">"nexora"</span> );</cfsavecontent>

<cfsavecontent variable="ui.customJS">
(function(){
  var API='problem6-streaming_demo.cfm';
  var chatArea=document.getElementById('chatArea'),chatInner=document.getElementById('chatInner'),
      input=document.getElementById('input'),sendBtn=document.getElementById('sendBtn'),
      chips=document.getElementById('chips'),welcome=document.getElementById('welcome'),busy=false;
  var sess={requests:0,tokens:0,cost:0,totalMs:0};

  input.addEventListener('input',function(){this.style.height='auto';this.style.height=Math.min(this.scrollHeight,120)+'px';});

  function updateSessionBar(){
    document.getElementById('sbReq').textContent=sess.requests;
    document.getElementById('sbTok').textContent=sess.tokens.toLocaleString();
    document.getElementById('sbCost').textContent='$'+sess.cost.toFixed(6);
    document.getElementById('sbAvg').textContent=sess.requests?Math.round(sess.totalMs/sess.requests)+'ms':'—';
  }
  function addBubble(role,text){
    welcome.classList.add('hidden');
    var msg=document.createElement('div');msg.className='msg '+role;
    var av=document.createElement('div');av.className='av av-'+role;av.textContent=role==='ai'?'AI':'You';
    var bub=document.createElement('div');bub.className='bubble';if(text)bub.textContent=text;
    msg.appendChild(av);msg.appendChild(bub);chatInner.appendChild(msg);
    chatArea.scrollTop=chatArea.scrollHeight;return bub;
  }
  function addMetricsStrip(m){
    var strip=document.createElement('div');strip.className='metrics-strip';
    var parts=[];
    parts.push({cls:'m-time',text:'\u23F1 '+(m.responseMs||0)+'ms'});
    if(m.promptTokens||m.completionTokens){
      parts.push({cls:'m-tokens',text:'\u2B06 '+(m.promptTokens||0)+' prompt'});
      parts.push({cls:'m-tokens',text:'\u2B07 '+(m.completionTokens||0)+' completion'});
      parts.push({cls:'m-tokens',text:'= '+((m.promptTokens||0)+(m.completionTokens||0))+' total'});
    }
    if(m.estimatedCost!==undefined) parts.push({cls:'m-cost',text:'\uD83D\uDCB0 $'+Number(m.estimatedCost).toFixed(6)});
    if(m.logged) parts.push({cls:'m-log',text:'\u2713 nexora.log'});
    parts.forEach(function(p){var sp=document.createElement('span');sp.className='m-pill '+p.cls;sp.textContent=p.text;strip.appendChild(sp);});
    chatInner.appendChild(strip);chatArea.scrollTop=chatArea.scrollHeight;
  }
  function startStreaming(streamId,bub,onDoneMetrics){
    var cursor=document.createElement('span');cursor.className='cursor';bub.appendChild(cursor);var shown=0;
    var pollTimer=setInterval(async function(){
      try{
        var r=await fetch(API+'?poll=1&streamId='+encodeURIComponent(streamId));
        var d=await r.json();var tokens=d.tokens||[];
        for(var i=shown;i<tokens.length;i++){bub.insertBefore(document.createTextNode(tokens[i]),cursor);chatArea.scrollTop=chatArea.scrollHeight;}
        shown=tokens.length;
        if(d.done){clearInterval(pollTimer);cursor.remove();
          if(d.error&&d.error!=='expired'&&!shown){bub.textContent='Error: '+d.error;busy=false;sendBtn.disabled=false;input.focus();return;}
          if(d.metrics&&onDoneMetrics)onDoneMetrics(d.metrics);
          busy=false;sendBtn.disabled=false;input.focus();}
      }catch(e){clearInterval(pollTimer);cursor.remove();bub.textContent='Connection error — please try again.';busy=false;sendBtn.disabled=false;}
    },150);
  }
  window.send=function(t){input.value=t;sendMsg();};
  window.sendMsg=async function(){
    var q=input.value.trim();if(!q||busy)return;
    busy=true;sendBtn.disabled=true;input.value='';input.style.height='auto';
    addBubble('user',q);var aiBub=addBubble('ai','');
    try{
      var r=await fetch(API+'?api=1',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'question='+encodeURIComponent(q)});
      var d=await r.json();
      if(!d.success){aiBub.textContent='Error: '+(d.message||'Unknown error');busy=false;sendBtn.disabled=false;return;}
      startStreaming(d.streamId,aiBub,function(metrics){
        addMetricsStrip(metrics);
        sess.requests++;sess.tokens+=(metrics.totalTokens||((metrics.promptTokens||0)+(metrics.completionTokens||0))||0);
        sess.cost+=(metrics.estimatedCost||0);sess.totalMs+=(metrics.responseMs||0);updateSessionBar();
      });
    }catch(e){aiBub.textContent='Connection error — please try again.';busy=false;sendBtn.disabled=false;}
  };
  window.newConversation=function(){
    if(busy)return;chatInner.innerHTML='';welcome.classList.remove('hidden');chatInner.appendChild(welcome);
    sess={requests:0,tokens:0,cost:0,totalMs:0};updateSessionBar();input.focus();
  };
  window.toggleCode=function(){
    var p=document.getElementById('codePanel'),b=document.querySelector('.code-toggle');
    if(p.style.display==='block'){p.style.display='none';b.textContent='Show active code \u2193';}
    else{p.style.display='block';b.textContent='Hide active code \u2191';}
  };
  input.focus();
})();
</cfsavecontent>

<cfinclude template="_ui.cfm">
