<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"><title>ColdFusion RAG Demo</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
:root{--bg:#0d1117;--bg2:#161b22;--bg3:#21262d;--border:#30363d;--text:#e6e6e6;--muted:#8b949e;--dim:#484f58;--red:#eb1000;--amber:#f0883e;--amber-dim:rgba(240,136,62,.12);--green:#3fb950;--green-dim:rgba(63,185,80,.12);--blue:#58a6ff}
body{background:var(--bg);color:var(--text);font-family:'Segoe UI',system-ui,-apple-system,sans-serif;height:100vh;display:flex;flex-direction:column;overflow:hidden}

::-webkit-scrollbar{width:6px;height:6px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
::-webkit-scrollbar-thumb:hover{background:var(--muted)}

@keyframes fadeIn{from{opacity:0}to{opacity:1}}
@keyframes slideUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
@keyframes slideInLeft{from{opacity:0;transform:translateX(-16px)}to{opacity:1;transform:translateX(0)}}
@keyframes bounce{0%,80%,100%{transform:scale(0)}40%{transform:scale(1)}}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.4}}
@keyframes glow{0%,100%{box-shadow:0 0 4px rgba(235,16,0,.2)}50%{box-shadow:0 0 14px rgba(235,16,0,.45)}}

.top{background:var(--bg2);border-bottom:1px solid var(--border);padding:14px 28px;display:flex;align-items:center;gap:16px;flex-shrink:0;position:relative;overflow:hidden}
.top::after{content:'';position:absolute;bottom:0;left:0;right:0;height:2px;background:linear-gradient(90deg,transparent,var(--red),transparent)}
.top-logo{background:var(--red);color:#fff;width:40px;height:40px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:16px;animation:glow 3s ease-in-out infinite;flex-shrink:0}
.top-title{font-size:22px;font-weight:700;letter-spacing:-.3px;background:linear-gradient(135deg,#fff,#c9d1d9);-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.top-sub{font-size:13px;color:var(--muted);margin-top:2px}

.body-wrap{flex:1;display:flex;overflow:hidden}

.sidebar{width:270px;min-width:270px;background:var(--bg);border-right:1px solid var(--border);overflow-y:auto;padding:12px 0;display:flex;flex-direction:column;gap:2px}
.grp-item{padding:14px 20px;cursor:pointer;border-left:3px solid transparent;transition:all .25s ease;animation:slideInLeft .4s ease backwards;position:relative}
.grp-item:nth-child(1){animation-delay:.05s}
.grp-item:nth-child(2){animation-delay:.1s}
.grp-item:nth-child(3){animation-delay:.15s}
.grp-item:hover{background:rgba(255,255,255,.03)}
.grp-item.active{background:linear-gradient(90deg,rgba(235,16,0,.08),transparent);border-left-color:var(--red)}
.grp-item.active .grp-num{background:var(--red);color:#fff}
.grp-head{display:flex;align-items:center;gap:10px}
.grp-num{width:26px;height:26px;border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700;background:var(--bg3);color:var(--muted);transition:all .25s ease;flex-shrink:0}
.grp-title{font-size:15px;font-weight:700}
.grp-desc{font-size:12px;color:var(--dim);margin-top:4px;line-height:1.4;padding-left:36px}

.main{flex:1;display:flex;flex-direction:column;overflow:hidden}
.sub-row{background:var(--bg2);border-bottom:1px solid var(--border);padding:0 20px;display:flex;gap:4px;flex-shrink:0;overflow-x:auto}
.sub-btn{background:transparent;border:none;border-bottom:2px solid transparent;color:var(--muted);padding:12px 16px;font-size:14px;font-weight:600;cursor:pointer;transition:all .2s ease;position:relative;white-space:nowrap;flex-shrink:0}
.sub-btn:hover{color:var(--text)}
.sub-btn.active{color:var(--text);border-bottom-color:var(--red)}
.docs-ln{margin-left:auto;display:flex;align-items:center;padding:8px 4px}
.docs-btn{background:rgba(88,166,255,.08);color:var(--blue);border:1px solid rgba(88,166,255,.3);padding:7px 14px;border-radius:6px;font-size:13px;font-weight:600;cursor:pointer;transition:all .2s ease;display:inline-flex;align-items:center;gap:6px}
.docs-btn:hover{background:rgba(88,166,255,.15);transform:translateY(-1px)}

.grp-panel{flex:1;display:flex;flex-direction:column;overflow:hidden}
.sub-panel{flex:1;display:flex;flex-direction:column;overflow:hidden;animation:fadeIn .3s ease}
.dual-panel{flex:1;display:flex;overflow:hidden}
.panel-half{flex:1;display:flex;flex-direction:column;overflow:hidden;min-width:0}
.panel-divider{width:2px;background:linear-gradient(to bottom,transparent,var(--border),transparent);flex-shrink:0}

.panel-header{display:flex;align-items:center;gap:10px;padding:12px 18px;border-bottom:1px solid var(--border);flex-shrink:0;background:var(--bg2)}
.panel-badge{font-size:11px;font-weight:700;padding:4px 12px;border-radius:6px;text-transform:uppercase;letter-spacing:.8px;flex-shrink:0}
.panel-badge.before{background:var(--amber-dim);color:var(--amber);border:1px solid rgba(240,136,62,.25)}
.panel-badge.after{background:var(--green-dim);color:var(--green);border:1px solid rgba(63,185,80,.25)}
.panel-title{font-size:14px;font-weight:600;color:#c9d1d9}

.panel-info{padding:10px 18px;border-bottom:1px solid var(--border);flex-shrink:0;font-size:13px;line-height:1.6}
.panel-info.before-info{background:rgba(240,136,62,.03);border-left:3px solid rgba(240,136,62,.3)}
.panel-info.after-info{background:rgba(63,185,80,.03);border-left:3px solid rgba(63,185,80,.3)}
.info-what{color:#c9d1d9;margin-bottom:4px}
.info-scenario{color:var(--muted);font-size:12px}

.panel-start{padding:8px 18px;border-bottom:1px solid var(--border);flex-shrink:0}
.start-btn{border:1px solid var(--border);padding:9px 18px;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer;width:100%;transition:all .2s ease;background:var(--bg3);color:var(--text)}
.start-btn:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 4px 12px rgba(0,0,0,.3)}
.start-btn:disabled{opacity:.4;cursor:wait}
.start-btn.before-start{border-color:rgba(240,136,62,.35);color:var(--amber);background:rgba(240,136,62,.06)}
.start-btn.before-start:hover:not(:disabled){background:rgba(240,136,62,.12);box-shadow:0 4px 16px rgba(240,136,62,.15)}
.start-btn.after-start{border-color:rgba(63,185,80,.35);color:var(--green);background:rgba(63,185,80,.06)}
.start-btn.after-start:hover:not(:disabled){background:rgba(63,185,80,.12);box-shadow:0 4px 16px rgba(63,185,80,.15)}

.chat-area{flex:1;overflow-y:auto;padding:14px;display:flex;flex-direction:column;gap:8px;min-height:160px}
.chat-hint{color:var(--dim);font-size:14px;margin:auto;text-align:center;line-height:1.7;animation:pulse 2s ease-in-out infinite}
.msg{max-width:85%;padding:10px 14px;border-radius:12px;font-size:15px;line-height:1.7;word-wrap:break-word;animation:slideUp .25s ease-out}
.msg.user{align-self:flex-end;background:#1f3a5f;color:#79c0ff;border-bottom-right-radius:4px}
.msg.user::after{content:"You";display:block;font-size:10px;color:var(--blue);text-align:right;margin-top:2px}
.msg.bot{align-self:flex-start;background:var(--bg3);color:#c9d1d9;border-bottom-left-radius:4px}
.msg.bot::before{content:"AI";display:block;font-size:10px;color:var(--green);margin-bottom:2px}
.msg.sys{align-self:center;color:#6e7681;font-size:13px;font-style:italic}
.msg.blocked{align-self:flex-start;background:rgba(240,136,62,.1);color:var(--amber);border:1px solid rgba(240,136,62,.2);border-bottom-left-radius:4px}
.msg.blocked::before{content:"BLOCKED";display:block;font-size:10px;color:var(--amber);font-weight:700;margin-bottom:2px}

.typing{align-self:flex-start;background:var(--bg3);padding:12px 18px;border-radius:12px;border-bottom-left-radius:4px;display:flex;gap:4px;align-items:center}
.typing .dot{width:7px;height:7px;border-radius:50%;background:var(--muted);animation:bounce 1.4s infinite ease-in-out both}
.typing .dot:nth-child(1){animation-delay:-.32s}
.typing .dot:nth-child(2){animation-delay:-.16s}

.sugg-sec{padding:8px 14px;border-top:1px solid var(--border)}
.sugg-lbl{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px}
.after-lbl{color:var(--green)}.before-lbl{color:var(--amber)}.neutral-lbl{color:var(--muted)}
.sugg-row{display:flex;gap:5px;flex-wrap:wrap}
.sugg{border:1px solid var(--border);padding:6px 12px;border-radius:14px;font-size:13px;cursor:pointer;transition:all .2s ease;background:transparent;text-align:left}
.sugg.after-s{color:var(--green);border-color:rgba(63,185,80,.25)}
.sugg.after-s:hover{background:var(--green-dim);transform:translateY(-1px)}
.sugg.before-s{color:var(--amber);border-color:rgba(240,136,62,.25)}
.sugg.before-s:hover{background:var(--amber-dim);transform:translateY(-1px)}

.inp-row{display:flex;gap:8px;padding:10px 14px;border-top:1px solid var(--border);flex-shrink:0}
.inp-row input{flex:1;background:var(--bg);border:1px solid var(--border);border-radius:8px;padding:10px 14px;color:var(--text);font-size:15px;outline:none;transition:border-color .2s ease,box-shadow .2s ease}
.inp-row input:focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(88,166,255,.1)}
.inp-row input:disabled{opacity:.3}
.snd-btn{background:var(--red);color:#fff;border:none;padding:10px 20px;border-radius:8px;font-size:14px;font-weight:600;cursor:pointer;transition:all .2s ease}
.snd-btn:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 4px 12px rgba(235,16,0,.3)}
.snd-btn:disabled{opacity:.3}

.console{flex:1;overflow-y:auto;padding:18px;font-family:'Fira Code','Consolas','Courier New',monospace;font-size:13px;line-height:1.8;color:var(--green);white-space:pre-wrap;animation:fadeIn .5s ease}

.ctrl-bar{padding:8px 18px;border-bottom:1px solid var(--border);display:flex;flex-wrap:wrap;gap:14px;align-items:center;flex-shrink:0;background:rgba(63,185,80,.03)}
.ctrl{display:flex;align-items:center;gap:6px}
.ctrl label{font-size:12px;font-weight:600;color:var(--muted)}
.ctrl select,.ctrl input[type="number"]{background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:6px 10px;color:var(--text);font-size:13px;font-family:'Fira Code',monospace;min-width:70px;outline:none;transition:border-color .2s}
.ctrl select:focus,.ctrl input[type="number"]:focus{border-color:var(--blue)}

/* Retrieval info sidecar */
.rbox{border-top:1px solid var(--border);background:rgba(88,166,255,.03);font-family:'Fira Code','Consolas',monospace;font-size:12px;padding:8px 14px;max-height:34%;overflow-y:auto;flex-shrink:0}
.rbox .rbox-title{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--blue);margin-bottom:6px;display:flex;align-items:center;gap:8px}
.rbox .rbox-title .tag{background:rgba(88,166,255,.12);color:var(--blue);border:1px solid rgba(88,166,255,.25);padding:1px 7px;border-radius:10px;font-size:10px;font-weight:700}
.rbox .rgroup{margin-bottom:8px}
.rbox .rgroup-label{color:var(--muted);font-size:11px;margin-bottom:4px}
.rbox .rhit{background:var(--bg);border:1px solid var(--border);border-radius:6px;padding:6px 9px;margin-bottom:4px;display:flex;gap:8px;align-items:flex-start}
.rbox .rhit .score{color:var(--green);font-weight:700;flex-shrink:0;min-width:54px}
.rbox .rhit .txt{color:#c9d1d9;line-height:1.5;word-break:break-word}
.rbox .rhit .src{color:var(--muted);font-size:11px;display:block;margin-top:2px}
.rbox .rhit.winner{border-color:rgba(63,185,80,.4);background:rgba(63,185,80,.05)}
.rbox .rhit.winner .score{color:var(--green)}
.rbox .rempty{color:var(--muted);font-style:italic}

/* Prompt preview box */
.pbox{border-top:1px solid var(--border);background:rgba(240,136,62,.03);font-family:'Fira Code','Consolas',monospace;font-size:12px;padding:8px 14px;max-height:30%;overflow-y:auto;flex-shrink:0;white-space:pre-wrap;color:#c9d1d9}
.pbox .pbox-title{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--amber);margin-bottom:6px;font-family:'Segoe UI',sans-serif}
</style>
</head>
<body>

<div class="top">
<div class="top-logo">CF</div>
<div><div class="top-title">ColdFusion RAG Demo</div><div class="top-sub">Quick Start &rarr; Full Pipeline &rarr; Standalone Ingestion</div></div>
</div>

<div class="body-wrap">
<div class="sidebar">

<div class="grp-item active" data-grp="basic">
<div class="grp-head"><span class="grp-num">1</span><span class="grp-title">Simple RAG</span></div>
<div class="grp-desc">simpleRAG() &mdash; the fastest way to ship a RAG-powered chatbot.</div>
</div>
<div class="grp-item" data-grp="advanced">
<div class="grp-head"><span class="grp-num">2</span><span class="grp-title">Advanced RAG</span></div>
<div class="grp-desc">agent() &mdash; full pipeline control including retrieval tuning, guardrails and routing.</div>
</div>
<div class="grp-item" data-grp="pipeline">
<div class="grp-head"><span class="grp-num">3</span><span class="grp-title">Document Service</span></div>
<div class="grp-desc">Standalone ingestion: load, split, transform, ingest &mdash; then query with agent().</div>
</div>

</div><!-- /sidebar -->

<div class="main">

<!-- ==================== SIMPLE RAG ==================== -->
<div class="grp-panel" id="gp-basic" style="display:flex">
<div class="sub-row">
<button class="sub-btn active" data-sub="basic-ask" onclick="switchSub(this,'basic')">ask() &mdash; Stateless</button>
<button class="sub-btn" data-sub="basic-chat" onclick="switchSub(this,'basic')">chat() &mdash; Multi-Turn</button>
<span class="docs-ln"><button class="docs-btn" onclick="openDocsForActiveSub('basic')">View Docs</button></span>
</div>

<!-- ask() -->
<div class="sub-panel" id="sp-basic-ask" style="display:flex">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">Before</span><span class="panel-title">LLM alone</span></div>
  <div class="panel-info before-info">
    <div class="info-what">The LLM has never seen your product documentation &mdash; it only knows generic information.</div>
    <div class="info-scenario">A customer asks about your pricing; the model falls back to vague general knowledge.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('basic-ask-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-basic-ask-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Try these</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'basic-ask-problem')">What are the pricing plans?</button><button class="sugg before-s" onclick="sendQ(this,'basic-ask-problem')">What integrations are available?</button><button class="sugg before-s" onclick="sendQ(this,'basic-ask-problem')">How do I create a project?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-basic-ask-problem" placeholder="Ask a product question..." onkeydown="if(event.key==='Enter')sendQ(this,'basic-ask-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-basic-ask-problem'),'basic-ask-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">With simpleRAG()</span><span class="panel-title">Quick-start RAG</span></div>
  <div class="panel-info after-info">
    <div class="info-what">simpleRAG() ingests your docs and grounds every answer in your actual data &mdash; three lines, complete pipeline.</div>
    <div class="info-scenario">Same question, now answered from product-docs.txt with real, up-to-date pricing.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('basic-ask',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-basic-ask"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'basic-ask')">What are the pricing plans?</button><button class="sugg after-s" onclick="sendQ(this,'basic-ask')">What integrations are available?</button><button class="sugg after-s" onclick="sendQ(this,'basic-ask')">How do I create a project?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-basic-ask" placeholder="Ask a product question..." onkeydown="if(event.key==='Enter')sendQ(this,'basic-ask')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-basic-ask'),'basic-ask')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- chat() -->
<div class="sub-panel" id="sp-basic-chat" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">ask() &mdash; Stateless</span><span class="panel-title">One-shot Q&amp;A</span></div>
  <div class="panel-info before-info">
    <div class="info-what">ask() is perfect for search boxes and one-shot queries &mdash; each call runs independently.</div>
    <div class="info-scenario">Great for a knowledge base search. Not ideal when follow-up questions reference earlier context.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('basic-chat-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-basic-chat-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Try these in order</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'basic-chat-problem')">List every type of leave at ABC</button><button class="sugg before-s" onclick="sendQ(this,'basic-chat-problem')">Tell me more about the third one</button><button class="sugg before-s" onclick="sendQ(this,'basic-chat-problem')">What are the requirements for it?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-basic-chat-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'basic-chat-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-basic-chat-problem'),'basic-chat-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">chat() &mdash; Conversational</span><span class="panel-title">Follow-ups work</span></div>
  <div class="panel-info after-info">
    <div class="info-what">chat() carries the full conversation forward so short follow-ups stay on topic.</div>
    <div class="info-scenario">Same simpleRAG() service, different method &mdash; ideal for customer support bots.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('basic-chat',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-basic-chat"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these in order</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'basic-chat')">List every type of leave at ABC</button><button class="sugg after-s" onclick="sendQ(this,'basic-chat')">Tell me more about the third one</button><button class="sugg after-s" onclick="sendQ(this,'basic-chat')">What are the requirements for it?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-basic-chat" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'basic-chat')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-basic-chat'),'basic-chat')" disabled>Send</button></div>
</div>
</div>
</div>
</div>

<!-- ==================== ADVANCED RAG ==================== -->
<div class="grp-panel" id="gp-advanced" style="display:none">
<div class="sub-row">
<button class="sub-btn active" data-sub="advanced-precision" onclick="switchSub(this,'advanced')">Precision Tuning</button>
<button class="sub-btn" data-sub="advanced-transformers" onclick="switchSub(this,'advanced')">Transformers</button>
<button class="sub-btn" data-sub="advanced-routing" onclick="switchSub(this,'advanced')">Query Routing</button>
<button class="sub-btn" data-sub="advanced-retriever" onclick="switchSub(this,'advanced')">Content Retriever</button>
<button class="sub-btn" data-sub="advanced-aggregator" onclick="switchSub(this,'advanced')">Aggregator</button>
<button class="sub-btn" data-sub="advanced-injector" onclick="switchSub(this,'advanced')">Injector</button>
<button class="sub-btn" data-sub="advanced-guardrails" onclick="switchSub(this,'advanced')">Guardrails</button>
<span class="docs-ln"><button class="docs-btn" onclick="openDocsForActiveSub('advanced')">View Docs</button></span>
</div>

<!-- Precision Tuning -->
<div class="sub-panel" id="sp-advanced-precision" style="display:flex">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">Starter config</span><span class="panel-title">Large chunks, single match</span></div>
  <div class="panel-info before-info">
    <div class="info-what">Ingested with chunkSize 800, topK 1 and no similarity threshold &mdash; the kind of values you get when you haven&rsquo;t tuned anything yet.</div>
    <div class="info-scenario">Each answer is grounded in one large chunk &mdash; fast to set up, more context than needed and sometimes off-topic matches.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('advanced-precision-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-precision-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-precision-problem" style="display:none"><div class="rbox-title">Retrieved context<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Try these</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'advanced-precision-problem')">What integrations are available?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-precision-problem')">What phone support is offered?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-precision-problem')">What is the storage limit?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-precision-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-precision-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-precision-problem'),'advanced-precision-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">Tuned config</span><span class="panel-title">Full control</span></div>
  <div class="panel-info after-info">
    <div class="info-what">agent() exposes every knob: splitter type, chunk size, top-k and similarity threshold. Dial them in live.</div>
    <div class="info-scenario">Each change makes retrieval narrower or broader &mdash; see the retrieved chunks change in real time.</div>
  </div>
  <div class="ctrl-bar" id="ctrl-advanced-precision">
    <div class="ctrl"><label>Top K</label><input type="number" data-param="maxResults" value="3"></div>
    <div class="ctrl"><label>Min Score</label><input type="number" step="0.1" data-param="minScore" value="0.1"></div>
    <div class="ctrl"><label>Splitter</label><select data-param="splitterType"><option value="recursive">recursive</option><option value="sentence" selected>sentence</option><option value="paragraph">paragraph</option><option value="line">line</option></select></div>
    <div class="ctrl"><label>Chunk Size</label><input type="number" data-param="chunkSize" value="400"></div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initConfigDemo('advanced-precision',this)">Start with Settings</button></div>
  <div class="chat-area" id="chat-advanced-precision"><div class="chat-hint">Adjust settings, then click <b>Start with Settings</b></div></div>
  <div class="rbox" id="rbox-advanced-precision" style="display:none"><div class="rbox-title">Retrieved context<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'advanced-precision')">What integrations are available?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-precision')">What phone support is offered?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-precision')">What is the storage limit?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-precision" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-precision')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-precision'),'advanced-precision')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- Transformers -->
<div class="sub-panel" id="sp-advanced-transformers" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">No Transformers</span><span class="panel-title">Default metadata only</span></div>
  <div class="panel-info before-info">
    <div class="info-what">Segments carry only the default system metadata &mdash; no source tags, quality labels or timestamps.</div>
    <div class="info-scenario">Later in production you cannot filter by quality, trace by source or audit by ingestion date.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="runPipeline('advanced-transformers-problem',this)">Run</button></div>
  <div class="console" id="console-advanced-transformers-problem">Click <b>Run</b> to process without transformers</div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">With Transformers</span><span class="panel-title">Enriched at every stage</span></div>
  <div class="panel-info after-info">
    <div class="info-what">documentTransformer runs before splitting; textSegmentTransformer runs after. Both add custom metadata.</div>
    <div class="info-scenario">Look for the <b>[ADDED]</b> tag in the output &mdash; those are the fields that would not be there without the transformers.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="runPipeline('advanced-transformers',this)">Run</button></div>
  <div class="console" id="console-advanced-transformers">Click <b>Run</b> to process with transformers</div>
</div>
</div>
</div>

<!-- Query Routing -->
<div class="sub-panel" id="sp-advanced-routing" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">Single Retriever</span><span class="panel-title">All docs in one store</span></div>
  <div class="panel-info before-info">
    <div class="info-what">One retriever covers every topic &mdash; HR, product, FAQ &mdash; so every query searches the whole pile.</div>
    <div class="info-scenario">Works, but cross-domain queries can pull in off-topic chunks alongside the relevant ones.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('advanced-routing-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-routing-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-routing-problem" style="display:none"><div class="rbox-title">Retrieved from single store<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Try these</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'advanced-routing-problem')">What is the leave policy?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-routing-problem')">What are the pricing plans?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-routing-problem')">How do I reset my password?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-routing-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-routing-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-routing-problem'),'advanced-routing-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">Intelligent Routing</span><span class="panel-title">LLM picks the right store</span></div>
  <div class="panel-info after-info">
    <div class="info-what">Multiple retrievers with descriptions + a routingModel: the LLM reads the descriptions and picks the right KB.</div>
    <div class="info-scenario">The top match from each store is shown below &mdash; the highest-scoring store is what the router will pick.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('advanced-routing',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-routing"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-routing" style="display:none"><div class="rbox-title">Top match per store<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'advanced-routing')">What is the leave policy?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-routing')">What are the pricing plans?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-routing')">How do I reset my password?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-routing" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-routing')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-routing'),'advanced-routing')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- Content Retriever -->
<div class="sub-panel" id="sp-advanced-retriever" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">Loose retrieval</span><span class="panel-title">topK=10, minScore=0</span></div>
  <div class="panel-info before-info">
    <div class="info-what">Pulling the top 10 chunks with no minimum score brings in plenty of context &mdash; and plenty of noise.</div>
    <div class="info-scenario">See the retrieved chunks below &mdash; many have low scores yet still reach the LLM.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('advanced-retriever-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-retriever-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-retriever-problem" style="display:none"><div class="rbox-title">Retrieved chunks<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Try these</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'advanced-retriever-problem')">How does billing work?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-retriever-problem')">Is my data secure?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-retriever-problem')">Can I export my data?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-retriever-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-retriever-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-retriever-problem'),'advanced-retriever-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">Tuned retrieval</span><span class="panel-title">topK=3, minScore=0.3</span></div>
  <div class="panel-info after-info">
    <div class="info-what">Top-3 chunks that clear the similarity threshold &mdash; just the right amount of focused context.</div>
    <div class="info-scenario">Compare the two retrieval panels &mdash; the tuned one feeds the LLM a much cleaner, denser signal.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('advanced-retriever',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-retriever"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-retriever" style="display:none"><div class="rbox-title">Retrieved chunks<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'advanced-retriever')">How does billing work?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-retriever')">Is my data secure?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-retriever')">Can I export my data?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-retriever" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-retriever')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-retriever'),'advanced-retriever')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- Aggregator -->
<div class="sub-panel" id="sp-advanced-aggregator" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">Single store, one retriever</span><span class="panel-title">Nothing to aggregate</span></div>
  <div class="panel-info before-info">
    <div class="info-what">Every document lives in one store and one retriever pulls the top 5 chunks for every question.</div>
    <div class="info-scenario">For a question that spans two topics (HR + pricing), the top&#8209;5 chunks tend to cluster on whichever topic has the stronger vector match &mdash; the other topic gets starved out.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('advanced-aggregator-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-aggregator-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-aggregator-problem" style="display:none"><div class="rbox-title">Retrieved context (1 source)<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Multi-topic try these</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'advanced-aggregator-problem')">What integrations are offered, and what is the parental leave policy?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-aggregator-problem')">Tell me about leave policy and pricing</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-aggregator-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-aggregator-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-aggregator-problem'),'advanced-aggregator-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">Two stores + contentAggregator</span><span class="panel-title">Best chunks from every source</span></div>
  <div class="panel-info after-info">
    <div class="info-what">HR lives in its own store, Product/FAQ in another. Both retrievers run for every question; contentAggregator merges their result lists into one ranked context block.</div>
    <div class="info-scenario">Multi-topic questions now get chunks from <b>both</b> stores &mdash; the retrieved-context panel below shows two labeled sections, proving the aggregator is pulling from each source.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('advanced-aggregator',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-aggregator"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="rbox" id="rbox-advanced-aggregator" style="display:none"><div class="rbox-title">Retrieved context (2 sources merged)<span class="tag" data-tag></span></div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Multi-topic try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'advanced-aggregator')">What integrations are offered, and what is the parental leave policy?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-aggregator')">Tell me about leave policy and pricing</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-aggregator" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-aggregator')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-aggregator'),'advanced-aggregator')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- Injector -->
<div class="sub-panel" id="sp-advanced-injector" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">Default prompt</span><span class="panel-title">Free-form answer</span></div>
  <div class="panel-info before-info">
    <div class="info-what">No contentInjector &mdash; the built-in prompt is used. Free-form prose, no guaranteed structure.</div>
    <div class="info-scenario">See the prompt template used below; compare it with the custom one on the right.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('advanced-injector-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-injector-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="pbox" id="pbox-advanced-injector-problem" style="display:none"><div class="pbox-title">Prompt template sent to LLM</div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Try these</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'advanced-injector-problem')">What integrations are available?</button><button class="sugg before-s" onclick="sendQ(this,'advanced-injector-problem')">How does billing work?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-injector-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-injector-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-injector-problem'),'advanced-injector-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">contentInjector</span><span class="panel-title">Custom template + sources</span></div>
  <div class="panel-info after-info">
    <div class="info-what">A custom promptTemplate forces a fixed SUMMARY / DETAILS / SOURCES structure; metadataKeys exposes file_name in the context.</div>
    <div class="info-scenario">Every support reply looks the same and cites which document it came from.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('advanced-injector',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-advanced-injector"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="pbox" id="pbox-advanced-injector" style="display:none"><div class="pbox-title">Prompt template sent to LLM</div><div data-body></div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'advanced-injector')">What integrations are available?</button><button class="sugg after-s" onclick="sendQ(this,'advanced-injector')">How does billing work?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-advanced-injector" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'advanced-injector')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-advanced-injector'),'advanced-injector')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- Guardrails -->
<div class="sub-panel" id="sp-advanced-guardrails" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">No guardrails</span><span class="panel-title">Everything reaches the LLM</span></div>
  <div class="panel-info before-info">
    <div class="info-what">Without inputGuardrails every message &mdash; including SSNs, card numbers, passwords &mdash; is forwarded to the LLM API.</div>
    <div class="info-scenario">That data gets logged, indexed, and may be echoed back. A real compliance issue.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="initDemo('guardrails-input-problem',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-guardrails-input-problem"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="sugg-sec"><div class="sugg-lbl before-lbl">Send sensitive data</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'guardrails-input-problem')">My credit card is 4111-1111-1111-1111</button><button class="sugg before-s" onclick="sendQ(this,'guardrails-input-problem')">What is my SSN number?</button></div></div>
  <div class="sugg-sec"><div class="sugg-lbl neutral-lbl">Normal questions</div><div class="sugg-row"><button class="sugg before-s" onclick="sendQ(this,'guardrails-input-problem')">What are the pricing plans?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-guardrails-input-problem" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'guardrails-input-problem')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-guardrails-input-problem'),'guardrails-input-problem')" disabled>Send</button></div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">inputGuardrails</span><span class="panel-title">Blocked before the LLM</span></div>
  <div class="panel-info after-info">
    <div class="info-what">A custom CFC runs validate() on every inbound message. Sensitive patterns are blocked before any API call.</div>
    <div class="info-scenario">SSN/card/password messages never leave your server. Normal questions flow through untouched.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('guardrails-input',this)">Start Demo</button></div>
  <div class="chat-area" id="chat-guardrails-input"><div class="chat-hint">Click <b>Start Demo</b> to initialize</div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Send sensitive data &mdash; gets BLOCKED</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'guardrails-input')">My credit card is 4111-1111-1111-1111</button><button class="sugg after-s" onclick="sendQ(this,'guardrails-input')">What is my SSN number?</button></div></div>
  <div class="sugg-sec"><div class="sugg-lbl neutral-lbl">Normal questions still work</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'guardrails-input')">What are the pricing plans?</button></div></div>
  <div class="inp-row"><input type="text" id="inp-guardrails-input" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'guardrails-input')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-guardrails-input'),'guardrails-input')" disabled>Send</button></div>
</div>
</div>
</div>
</div>

<!-- ==================== DOCUMENT SERVICE ==================== -->
<div class="grp-panel" id="gp-pipeline" style="display:none">
<div class="sub-row">
<button class="sub-btn active" data-sub="pipeline-etl" onclick="switchSub(this,'pipeline')">Ingest + Query</button>
<button class="sub-btn" data-sub="pipeline-lazyload" onclick="switchSub(this,'pipeline')">Lazy Load</button>
<span class="docs-ln"><button class="docs-btn" onclick="openDocsForActiveSub('pipeline')">View Docs</button></span>
</div>

<!-- Ingest + Query -->
<div class="sub-panel" id="sp-pipeline-etl" style="display:flex">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">Step 1 &middot; documentService()</span><span class="panel-title">Ingest as a standalone job</span></div>
  <div class="panel-info after-info">
    <div class="info-what">documentService() runs each stage &mdash; load &rarr; transform &rarr; split &rarr; transformSegments &rarr; ingest &mdash; as explicit, inspectable calls.</div>
    <div class="info-scenario">A nightly ingestion job reads your documents, enriches metadata, and pushes the enriched segments into a vector store that any service can then reuse.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="runPipeline('pipeline-etl-ingest',this)">Run Ingestion</button></div>
  <div class="console" id="console-pipeline-etl-ingest">Click <b>Run Ingestion</b> to execute the staged ingestion job</div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">Step 2 &middot; agent()</span><span class="panel-title">Query the same vector store</span></div>
  <div class="panel-info after-info">
    <div class="info-what">A RAG service attaches to the vector store populated in Step 1 and answers questions &mdash; no re-ingestion on this side.</div>
    <div class="info-scenario">Ingest once, then let any number of chat / ask services share the same store.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="initDemo('pipeline-etl',this)">Start RAG Service</button></div>
  <div class="chat-area" id="chat-pipeline-etl"><div class="chat-hint">Run ingestion first, then click <b>Start RAG Service</b></div></div>
  <div class="sugg-sec"><div class="sugg-lbl after-lbl">Try these</div><div class="sugg-row"><button class="sugg after-s" onclick="sendQ(this,'pipeline-etl')">What are the pricing plans?</button><button class="sugg after-s" onclick="sendQ(this,'pipeline-etl')">Summarize the leave policy</button></div></div>
  <div class="inp-row"><input type="text" id="inp-pipeline-etl" placeholder="Type a message..." onkeydown="if(event.key==='Enter')sendQ(this,'pipeline-etl')" disabled><button class="snd-btn" onclick="sendQ(document.getElementById('inp-pipeline-etl'),'pipeline-etl')" disabled>Send</button></div>
</div>
</div>
</div>

<!-- Lazy Load -->
<div class="sub-panel" id="sp-pipeline-lazyload" style="display:none">
<div class="dual-panel">
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge before">load()</span><span class="panel-title">Eager &mdash; all into memory</span></div>
  <div class="panel-info before-info">
    <div class="info-what">load() reads every file into memory before returning. Simple, fast, but the whole corpus sits in heap.</div>
    <div class="info-scenario">Perfect for small document sets. Risky when you have thousands of files or very large docs.</div>
  </div>
  <div class="panel-start"><button class="start-btn before-start" onclick="runPipeline('pipeline-lazyload-problem',this)">Run</button></div>
  <div class="console" id="console-pipeline-lazyload-problem">Click <b>Run</b> to load the whole Corpus folder at once</div>
</div>
<div class="panel-divider"></div>
<div class="panel-half">
  <div class="panel-header"><span class="panel-badge after">lazyLoad()</span><span class="panel-title">Streaming iterator</span></div>
  <div class="panel-info after-info">
    <div class="info-what">lazyLoad() returns an iterator: one document at a time via hasNext() / next(). Memory stays flat.</div>
    <div class="info-scenario">Ideal for very large corpora &mdash; pipe each doc directly into split + ingest without buffering all of them.</div>
  </div>
  <div class="panel-start"><button class="start-btn after-start" onclick="runPipeline('pipeline-lazyload',this)">Run</button></div>
  <div class="console" id="console-pipeline-lazyload">Click <b>Run</b> to stream the Corpus folder</div>
</div>
</div>
</div>
</div>

</div><!-- /main -->
</div><!-- /body-wrap -->

<script>
// Which demo IDs use ask() (Simple RAG only — agent() has no ask method).
var ASK_DEMOS = ['basic-ask','basic-ask-problem','basic-chat-problem'];

// Which demo IDs have a "retrieval preview" sidecar.
var RETRIEVAL_DEMOS = [
    'advanced-precision','advanced-precision-problem',
    'advanced-routing','advanced-routing-problem',
    'advanced-retriever','advanced-retriever-problem',
    'advanced-aggregator','advanced-aggregator-problem'
];

// Map sub-id -> docs page. Several sub-ids share one page where appropriate.
var DOCS_MAP = {
    'basic-ask'     : 'basic-ask',
    'basic-chat'    : 'basic-chat',
    'advanced-precision'   : 'advanced-precision',
    'advanced-transformers': 'advanced-transformers',
    'advanced-routing'     : 'advanced-routing',
    'advanced-retriever'   : 'advanced-retriever',
    'advanced-aggregator'  : 'advanced-aggregator',
    'advanced-injector'    : 'advanced-injector',
    'advanced-guardrails'  : 'advanced-guardrails',
    'pipeline-etl'         : 'pipeline-etl',
    'pipeline-lazyload'    : 'pipeline-lazyload'
};

document.querySelectorAll('.grp-item').forEach(function(item){
    item.addEventListener('click',function(){
        document.querySelectorAll('.grp-item').forEach(function(n){n.classList.remove('active')});
        document.querySelectorAll('.grp-panel').forEach(function(p){p.style.display='none'});
        item.classList.add('active');
        document.getElementById('gp-'+item.dataset.grp).style.display='flex';
    });
});

function switchSub(btn,grpId){
    var panel=document.getElementById('gp-'+grpId);
    panel.querySelectorAll('.sub-btn').forEach(function(b){b.classList.remove('active')});
    panel.querySelectorAll('.sub-panel').forEach(function(p){p.style.display='none'});
    btn.classList.add('active');
    var sp=document.getElementById('sp-'+btn.dataset.sub);
    sp.style.display='flex';
    sp.style.animation='none';
    sp.offsetHeight;
    sp.style.animation='fadeIn .3s ease';
}

function openDocs(subId){
    var page=DOCS_MAP[subId]||subId;
    window.open('docs/'+page+'.html','_blank');
}
function openDocsForActiveSub(grpId){
    var panel=document.getElementById('gp-'+grpId);
    var active=panel.querySelector('.sub-btn.active');
    if(active) openDocs(active.dataset.sub);
}

function escapeHtml(s){
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function formatResponse(text){
    return escapeHtml(text)
        .replace(/\*\*(.*?)\*\*/g,'<strong>$1</strong>')
        .replace(/^\s*[-•]\s+(.*)/gm,'<span style="display:block;padding-left:12px">&#8226; $1</span>')
        .replace(/\n/g,'<br>');
}

function addMsg(id,text,cls){
    var a=document.getElementById('chat-'+id);
    if(!a)return;
    if(a.querySelector('.chat-hint'))a.innerHTML='';
    var old=a.querySelector('.typing');
    if(old)old.remove();
    var d=document.createElement('div');
    if(cls==='bot'||cls==='blocked'){
        d.className='msg '+cls;
        d.innerHTML=formatResponse(text);
    } else {
        d.className='msg '+cls;
        d.textContent=text;
    }
    a.appendChild(d);a.scrollTop=a.scrollHeight;
}

function showTyping(id){
    var a=document.getElementById('chat-'+id);
    if(!a)return;
    var old=a.querySelector('.typing');
    if(old)old.remove();
    var t=document.createElement('div');
    t.className='typing';
    t.innerHTML='<span class="dot"></span><span class="dot"></span><span class="dot"></span>';
    a.appendChild(t);a.scrollTop=a.scrollHeight;
}

function getParams(id){
    var r=document.getElementById('ctrl-'+id);
    if(!r)return{};
    var p={};
    r.querySelectorAll('[data-param]').forEach(function(e){p[e.dataset.param]=e.value});
    return p;
}

function initDemo(id,btn){
    btn.disabled=true;btn.textContent='Initializing...';
    var a=document.getElementById('chat-'+id);
    if(a){a.innerHTML='';addMsg(id,'Initializing...','sys');}
    var rbox=document.getElementById('rbox-'+id);
    if(rbox)rbox.style.display='none';
    var pbox=document.getElementById('pbox-'+id);
    if(pbox)pbox.style.display='none';
    fetch('runners/'+id+'-init.cfm').then(function(r){return r.text()}).then(function(t){
        btn.disabled=false;
        if(t.trim()==='ready'){
            if(a)addMsg(id,'Ready! Ask me anything.','bot');
            var inp=document.getElementById('inp-'+id);
            if(inp){inp.disabled=false;inp.focus();inp.closest('.inp-row').querySelector('.snd-btn').disabled=false;}
            btn.textContent='Re-ingest';
            loadPrompt(id);
        } else {
            if(a)addMsg(id,'Failed: '+t,'sys');
            btn.textContent='Start Demo';
        }
    }).catch(function(e){if(a)addMsg(id,'Error: '+e.message,'sys');btn.textContent='Start Demo';btn.disabled=false});
}

function initConfigDemo(id,btn){
    btn.disabled=true;btn.textContent='Initializing...';
    var a=document.getElementById('chat-'+id);
    if(a){a.innerHTML='';addMsg(id,'Initializing with settings...','sys');}
    var rbox=document.getElementById('rbox-'+id);
    if(rbox)rbox.style.display='none';
    var p=new URLSearchParams(getParams(id)).toString();
    fetch('runners/'+id+'-init.cfm?'+p).then(function(r){return r.text()}).then(function(t){
        btn.disabled=false;
        if(t.trim()==='ready'){
            if(a)addMsg(id,'Ready! Ask me anything.','bot');
            var inp=document.getElementById('inp-'+id);
            if(inp){inp.disabled=false;inp.focus();inp.closest('.inp-row').querySelector('.snd-btn').disabled=false;}
            btn.textContent='Re-ingest';
        } else {
            if(a)addMsg(id,'Failed: '+t,'sys');
            btn.textContent='Start with Settings';
        }
    }).catch(function(e){if(a)addMsg(id,'Error: '+e.message,'sys');btn.textContent='Start with Settings';btn.disabled=false});
}

function sendQ(el,id){
    var q='';
    if(el.tagName==='BUTTON'&&el.classList.contains('sugg'))q=el.textContent;
    else if(el.tagName==='INPUT'){q=el.value.trim();el.value=''}
    if(!q)return;
    addMsg(id,q,'user');
    showTyping(id);
    if(RETRIEVAL_DEMOS.indexOf(id)>=0) loadRetrieval(id,q);
    var method=ASK_DEMOS.indexOf(id)>=0?'ask':'chat';
    fetch('runners/query.cfm?id='+encodeURIComponent(id)+'&q='+encodeURIComponent(q)+'&method='+method).then(function(r){return r.text()}).then(function(t){
        var cls=t.indexOf('BLOCKED BY GUARDRAIL')===0?'blocked':'bot';
        addMsg(id,t,cls);
    }).catch(function(e){addMsg(id,'Error: '+e.message,'sys')});
}

function loadRetrieval(id,q){
    var rbox=document.getElementById('rbox-'+id);
    if(!rbox)return;
    var body=rbox.querySelector('[data-body]');
    var tag=rbox.querySelector('[data-tag]');
    body.innerHTML='<div class="rempty">Searching vector store...</div>';
    rbox.style.display='block';
    fetch('runners/retrieve.cfm?id='+encodeURIComponent(id)+'&q='+encodeURIComponent(q))
        .then(function(r){return r.json()})
        .then(function(data){
            if(data.error){body.innerHTML='<div class="rempty">'+escapeHtml(data.error)+'</div>';return}
            var html='';
            var totalTop=-1;
            data.retrievers.forEach(function(r){
                if(r.chunks.length>0 && r.chunks[0].score>totalTop) totalTop=r.chunks[0].score;
            });
            data.retrievers.forEach(function(r){
                var isWinner=(data.retrievers.length>1 && r.chunks.length>0 && r.chunks[0].score===totalTop);
                html+='<div class="rgroup"><div class="rgroup-label">'+escapeHtml(r.label)+(isWinner?' <span class="tag">picked</span>':'')+'</div>';
                if(r.chunks.length===0){
                    html+='<div class="rempty">No matches above the threshold.</div>';
                } else {
                    r.chunks.forEach(function(c,i){
                        var w=(isWinner && i===0)?' winner':'';
                        var preview=c.text.length>220?c.text.substring(0,220)+'...':c.text;
                        html+='<div class="rhit'+w+'"><span class="score">'+c.score.toFixed(3)+'</span><div class="txt">'+escapeHtml(preview)+(c.fileName?'<span class="src">'+escapeHtml(c.fileName)+'</span>':'')+'</div></div>';
                    });
                }
                html+='</div>';
            });
            body.innerHTML=html;
            if(tag)tag.textContent=data.retrievers.length===1?(data.retrievers[0].chunks.length+' chunks'):(data.retrievers.length+' stores');
        })
        .catch(function(e){body.innerHTML='<div class="rempty">Retrieval preview failed: '+escapeHtml(e.message)+'</div>'});
}

function loadPrompt(id){
    var pbox=document.getElementById('pbox-'+id);
    if(!pbox)return;
    fetch('runners/prompt.cfm?id='+encodeURIComponent(id))
        .then(function(r){return r.text()})
        .then(function(t){
            if(!t||t.indexOf('NOT_FOUND')===0)return;
            var body=pbox.querySelector('[data-body]');
            body.textContent=t;
            pbox.style.display='block';
        }).catch(function(){});
}

function runPipeline(id,btn){
    btn.disabled=true;btn.textContent='Running...';
    var c=document.getElementById('console-'+id);
    if(c)c.textContent='Starting...\n';
    fetch('runners/'+id+'.cfm').then(function(r){return r.text()}).then(function(t){
        if(c)c.textContent=t;
        btn.textContent='Run Again';btn.disabled=false;
    }).catch(function(e){
        if(c)c.textContent='Error: '+e.message;
        btn.textContent='Run';btn.disabled=false;
    });
}
</script>
</body>
</html>
