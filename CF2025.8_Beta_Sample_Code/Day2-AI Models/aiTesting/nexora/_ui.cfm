<!---
    Nexora — Shared Chat UI Shell
    Each problem*.cfm sets a `ui` struct, then <cfinclude template="_ui.cfm">

    Required keys:
        title, subtitle, pills, activeNav, apiEndpoint, placeholder,
        welcomeHTML, chipsHTML, codeHTML, hasReset

    Optional keys for advanced pages (streaming, RAG, observability):
        extraCSS     — additional <style> content injected after base CSS
        beforeChat   — HTML injected between nav-bar and chat-area (e.g. ingest/session bars)
        afterChat    — HTML injected between chips and code-bar (e.g. session stats)
        inputAttrs   — extra attributes on <textarea> (e.g. "disabled")
        sendBtnAttrs — extra attributes on Send button (e.g. "disabled")
        extraButtons — HTML for additional buttons inside .input-inner
        customJS     — if set, replaces the entire default <script> block
        codeToggleLabel — custom label for code toggle button
--->
<cfscript>
    if (!isDefined("ui")) ui = {};
    param name="ui.title"           default="Nexora Support";
    param name="ui.subtitle"        default="";
    param name="ui.activeNav"       default="";
    param name="ui.apiEndpoint"     default="";
    param name="ui.placeholder"     default="Ask a question...";
    param name="ui.welcomeHTML"     default="";
    param name="ui.chipsHTML"       default="";
    param name="ui.codeHTML"        default="";
    param name="ui.hasReset"        default=false;
    param name="ui.extraCSS"        default="";
    param name="ui.beforeChat"      default="";
    param name="ui.afterChat"       default="";
    param name="ui.inputAttrs"      default="";
    param name="ui.sendBtnAttrs"    default="";
    param name="ui.extraButtons"    default="";
    param name="ui.customJS"        default="";
    param name="ui.codeToggleLabel" default="Show active code";
    if (!structKeyExists(ui, "pills")) ui.pills = [];

    navItems = [
        { href: "problem1-chatmodel_demo.cfm",    label: "Problem 1: Basic Chat" },
        { href: "problem2-systemMessage_demo.cfm", label: "Problem 2: System Msg" },
        { href: "problem3-chatmemory_demo.cfm",    label: "Problem 3: Memory" },
        { href: "problem4-functiontools_demo.cfm",  label: "Problem 4: Tools" },
        { href: "problem5-guardrails_demo.cfm",     label: "Problem 5: GuardRails" },
        { href: "problem6-streaming_demo.cfm",      label: "Problem 6: Streaming" },
        { href: "problem6-mcp_demo.cfm",             label: "Problem 7: MCP" },
        { href: "problem8-rag_demo.cfm",             label: "Problem 8: RAG" },
        { href: "problem9-observability_demo.cfm",   label: "Problem 9: Observability" }
    ];
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Nexora Support — <cfoutput>#encodeForHTML(ui.title)#</cfoutput></title>
<style>
:root{--bg:#0d1117;--surf:#161b22;--surf2:#1c2230;--border:#30363d;--txt:#e6edf3;--muted:#8b949e;--accent:#58a6ff;--green:#3fb950;--red:#fa4549;--orange:#f0883e;}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0;}
html,body{height:100%;overflow:hidden;}
body{background:var(--bg);color:var(--txt);font-family:-apple-system,'Segoe UI',system-ui,sans-serif;font-size:14px;line-height:1.5;display:flex;flex-direction:column;}
.hdr{background:var(--surf);border-bottom:1px solid var(--border);padding:11px 20px;display:flex;align-items:center;gap:12px;flex-shrink:0;}
.logo{width:34px;height:34px;background:#FA0F00;color:#fff;font-weight:900;font-size:14px;letter-spacing:-1px;display:grid;place-items:center;border-radius:6px;flex-shrink:0;}
.hdr-title{font-size:14px;font-weight:700;}
.hdr-sub{font-size:11px;color:var(--muted);}
.pills{margin-left:auto;display:flex;gap:5px;flex-wrap:wrap;justify-content:flex-end;}
.pill{padding:2px 8px;border-radius:20px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;border:1px solid;white-space:nowrap;}
.p-blue{background:rgba(88,166,255,.1);border-color:rgba(88,166,255,.3);color:var(--accent);}
.p-green{background:rgba(63,185,80,.1);border-color:rgba(63,185,80,.3);color:var(--green);}
.p-purple{background:rgba(188,140,255,.1);border-color:rgba(188,140,255,.3);color:#bc8cff;}
.p-orange{background:rgba(240,136,62,.1);border-color:rgba(240,136,62,.3);color:var(--orange);}
.p-red{background:rgba(250,69,73,.1);border-color:rgba(250,69,73,.3);color:var(--red);}
.p-muted{background:rgba(139,148,158,.1);border-color:rgba(139,148,158,.3);color:var(--muted);}
.nav-bar{background:var(--surf2);border-bottom:1px solid var(--border);padding:6px 20px;display:flex;align-items:center;gap:6px;flex-shrink:0;flex-wrap:wrap;}
.nav-btn{background:none;border:1px solid var(--border);color:var(--muted);padding:4px 12px;border-radius:20px;font-size:11px;cursor:pointer;text-decoration:none;display:inline-block;}
.nav-btn.active{border-color:var(--accent);color:var(--accent);background:rgba(88,166,255,.08);}
.nav-btn:hover:not(.active){border-color:var(--muted);color:var(--txt);}
.nav-sep{flex:1;}
.btn-new{background:none;border:1px solid var(--border);color:var(--muted);padding:4px 12px;border-radius:20px;font-size:11px;cursor:pointer;transition:border-color .15s,color .15s;}
.btn-new:hover{border-color:var(--red);color:var(--red);}
.chat-area{flex:1;overflow-y:auto;padding:24px 0;scroll-behavior:smooth;}
.chat-inner{max-width:720px;margin:0 auto;padding:0 20px;display:flex;flex-direction:column;gap:18px;}
.msg{display:flex;gap:10px;align-items:flex-start;}
.msg.user{flex-direction:row-reverse;}
.av{width:30px;height:30px;border-radius:50%;display:grid;place-items:center;font-size:11px;font-weight:800;flex-shrink:0;}
.av-ai{background:var(--accent);color:#000;}
.av-user{background:var(--surf2);border:1px solid var(--border);color:var(--muted);}
.bubble{max-width:80%;padding:11px 15px;border-radius:14px;font-size:14px;line-height:1.65;white-space:pre-wrap;word-break:break-word;}
.msg.ai .bubble{background:var(--surf);border:1px solid var(--border);border-top-left-radius:4px;}
.msg.user .bubble{background:var(--accent);color:#0d1117;font-weight:500;border-top-right-radius:4px;}
.typing{display:flex;gap:5px;align-items:center;padding:14px 16px;}
.dot{width:7px;height:7px;background:var(--muted);border-radius:50%;animation:bob 1.1s ease-in-out infinite;}
.dot:nth-child(2){animation-delay:.18s;}.dot:nth-child(3){animation-delay:.36s;}
@keyframes bob{0%,60%,100%{transform:translateY(0);opacity:.5;}30%{transform:translateY(-5px);opacity:1;}}
.sys-wrap{display:flex;justify-content:center;padding:4px 0;}
.sys-msg{text-align:center;font-size:11px;color:var(--muted);padding:6px 12px;background:var(--surf2);border-radius:20px;display:inline-block;}
#welcome{text-align:center;padding:36px 16px;color:var(--muted);}
#welcome h2{font-size:18px;font-weight:700;color:var(--txt);margin-bottom:8px;}
#welcome p{font-size:13px;line-height:1.7;max-width:510px;margin:0 auto 16px;}
.info-box{display:inline-block;background:rgba(63,185,80,.08);border:1px solid rgba(63,185,80,.3);border-radius:8px;padding:10px 16px;font-size:12px;color:var(--green);text-align:left;max-width:520px;}
.info-box strong{display:block;margin-bottom:4px;}
.warn-box{display:inline-block;background:rgba(240,136,62,.08);border:1px solid rgba(240,136,62,.3);border-radius:8px;padding:10px 16px;font-size:12px;color:var(--orange);text-align:left;max-width:520px;margin-top:10px;}
.warn-box strong{display:block;margin-bottom:4px;}
.chips{max-width:720px;margin:0 auto 10px;padding:0 20px;display:flex;gap:7px;flex-wrap:wrap;}
.chip{background:var(--surf);border:1px solid var(--border);color:var(--muted);padding:5px 13px;border-radius:20px;font-size:12px;cursor:pointer;transition:border-color .15s,color .15s;}
.chip:hover{border-color:var(--accent);color:var(--accent);}
.chip-label{width:100%;font-size:10px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;margin:6px 0 0;padding-left:2px;}
.chip-label.solved{color:rgba(63,185,80,.85);}
.chip-label.limits{color:rgba(255,160,0,.85);}
.hidden{display:none!important;}
.code-bar{background:var(--surf2);border-top:1px solid var(--border);padding:10px 20px;flex-shrink:0;}
.code-toggle{background:none;border:1px solid var(--border);color:var(--muted);padding:3px 10px;border-radius:4px;font-size:11px;cursor:pointer;}
.code-toggle:hover{border-color:var(--muted);color:var(--txt);}
.code-panel{background:#1e1e1e;border-top:1px solid var(--border);padding:14px 20px;flex-shrink:0;display:none;max-height:300px;overflow-y:auto;}
.code-panel pre{font-family:'Courier New',monospace;font-size:12px;line-height:1.6;color:#ced1d4;white-space:pre;}
.kw{color:#569cd6;}.cm{color:#6a9955;}.str{color:#ce9178;}.fn{color:#dcdcaa;}.diff-add{color:#3fb950;}
.input-wrap{background:var(--surf);border-top:1px solid var(--border);padding:12px 20px;flex-shrink:0;}
.input-inner{max-width:720px;margin:0 auto;display:flex;gap:8px;align-items:flex-end;}
textarea{flex:1;background:var(--bg);border:1px solid var(--border);border-radius:10px;color:var(--txt);padding:10px 14px;font-family:inherit;font-size:14px;resize:none;outline:none;line-height:1.5;max-height:120px;overflow-y:auto;transition:border-color .15s;}
textarea:focus{border-color:var(--accent);}
textarea::placeholder{color:var(--muted);}
.btn{border:none;border-radius:10px;padding:10px 16px;font-weight:700;font-size:13px;cursor:pointer;transition:opacity .15s;flex-shrink:0;}
.btn-send{background:var(--accent);color:#000;}
.btn:disabled{opacity:.35;cursor:not-allowed;}
.btn:hover:not(:disabled){opacity:.85;}
::-webkit-scrollbar{width:5px;}::-webkit-scrollbar-track{background:transparent;}::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px;}
<cfoutput>#ui.extraCSS#</cfoutput>
</style>
</head>
<body>

<header class="hdr">
  <div class="logo">Nx</div>
  <div>
    <div class="hdr-title">Nexora Support</div>
    <cfoutput><div class="hdr-sub">#encodeForHTML(ui.subtitle)#</div></cfoutput>
  </div>
  <div class="pills">
    <cfoutput><cfloop array="#ui.pills#" item="p">
      <span class="pill #encodeForHTMLAttribute(p.class)#">#encodeForHTML(p.label)#</span>
    </cfloop></cfoutput>
  </div>
</header>

<div class="nav-bar">
  <cfoutput><cfloop array="#navItems#" item="n">
    <a class="nav-btn<cfif n.href eq ui.activeNav> active</cfif>" href="#n.href#">#encodeForHTML(n.label)#</a>
  </cfloop></cfoutput>
  <a class="nav-btn" href="index.cfm">Full App &rarr;</a>
  <span class="nav-sep"></span>
  <button class="btn-new" id="newConvBtn" onclick="newConversation()">New Conversation</button>
</div>

<cfoutput>#ui.beforeChat#</cfoutput>

<div class="chat-area" id="chatArea">
  <div class="chat-inner" id="chatInner">
    <div id="welcome"><cfoutput>#ui.welcomeHTML#</cfoutput></div>
  </div>
</div>

<div class="chips" id="chips"><cfoutput>#ui.chipsHTML#</cfoutput></div>

<cfoutput>#ui.afterChat#</cfoutput>

<div class="code-bar">
  <cfoutput><button class="code-toggle" onclick="toggleCode()">#encodeForHTML(ui.codeToggleLabel)# &darr;</button></cfoutput>
</div>
<div class="code-panel" id="codePanel">
<pre><cfoutput>#ui.codeHTML#</cfoutput></pre>
</div>

<div class="input-wrap">
  <div class="input-inner">
    <cfoutput>
    <textarea id="input" rows="1" placeholder="#encodeForHTMLAttribute(ui.placeholder)#"
      onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();sendMsg();}" #ui.inputAttrs#></textarea>
    #ui.extraButtons#
    <button class="btn btn-send" id="sendBtn" onclick="sendMsg()" #ui.sendBtnAttrs#>Send</button>
    </cfoutput>
  </div>
</div>

<cfoutput>
<cfif len(trim(ui.customJS))>
<script>#ui.customJS#</script>
<cfelse>
<script>
(function(){
  var API='#jsStringFormat(ui.apiEndpoint)#',HAS_RESET=#ui.hasReset ? 'true' : 'false'#;
  var chatInner=document.getElementById('chatInner'),chatArea=document.getElementById('chatArea'),
      input=document.getElementById('input'),sendBtn=document.getElementById('sendBtn'),
      chips=document.getElementById('chips'),welcome=document.getElementById('welcome'),busy=false;

  input.addEventListener('input',function(){this.style.height='auto';this.style.height=Math.min(this.scrollHeight,120)+'px';});

  function addBubble(role,text){
    welcome.classList.add('hidden');
    var msg=document.createElement('div'); msg.className='msg '+role;
    var av=document.createElement('div'); av.className='av av-'+role; av.textContent=role==='ai'?'AI':'You';
    var bub=document.createElement('div'); bub.className='bubble'; bub.textContent=text;
    msg.appendChild(av); msg.appendChild(bub); chatInner.appendChild(msg);
    chatArea.scrollTop=chatArea.scrollHeight; return bub;
  }
  function addSysMsg(text){
    var w=document.createElement('div'); w.className='sys-wrap';
    var s=document.createElement('div'); s.className='sys-msg'; s.textContent=text;
    w.appendChild(s); chatInner.appendChild(w); chatArea.scrollTop=chatArea.scrollHeight;
  }
  function showTyping(){
    var m=document.createElement('div'); m.id='typing'; m.className='msg ai';
    var av=document.createElement('div'); av.className='av av-ai'; av.textContent='AI';
    var b=document.createElement('div'); b.className='bubble';
    b.innerHTML='<div class="typing"><div class="dot"></div><div class="dot"></div><div class="dot"></div></div>';
    m.appendChild(av); m.appendChild(b); chatInner.appendChild(m); chatArea.scrollTop=chatArea.scrollHeight;
  }
  function hideTyping(){var e=document.getElementById('typing'); if(e)e.remove();}
  function typeText(bub,text){
    return new Promise(function(res){
      bub.textContent=''; var i=0;
      var t=setInterval(function(){if(i<text.length){bub.textContent+=text[i++];chatArea.scrollTop=chatArea.scrollHeight;}else{clearInterval(t);res();}},11);
    });
  }
  window.send=function(t){input.value=t;sendMsg();};
  window.sendMsg=async function(){
    var q=input.value.trim(); if(!q||busy)return;
    busy=true; sendBtn.disabled=true; input.value=''; input.style.height='auto';
    addBubble('user',q); showTyping();
    try{
      var r=await fetch(API+'?api=1',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'question='+encodeURIComponent(q)});
      var d=await r.json(); hideTyping();
      var reply=(d.message!==undefined&&d.message!==null)?d.message:(d.MESSAGE!==undefined&&d.MESSAGE!==null)?d.MESSAGE:'';
      var bub=addBubble('ai',''); await typeText(bub,(reply!==''?String(reply):'Sorry, try again.'));
    }catch(e){hideTyping();addBubble('ai','Connection error — please try again.');}
    finally{busy=false;sendBtn.disabled=false;input.focus();}
  };
  window.newConversation=async function(){
    if(busy)return;
    busy=true; document.getElementById('newConvBtn').disabled=true;
    try{
      if(HAS_RESET) await fetch(API+'?api=1&reset=1',{method:'POST'});
      chatInner.innerHTML='';
      welcome.classList.remove('hidden'); chips.classList.remove('hidden');
      chatInner.appendChild(welcome);
    }catch(e){}
    finally{busy=false;document.getElementById('newConvBtn').disabled=false;input.focus();}
    if(HAS_RESET) addSysMsg('New conversation started — memory cleared.');
  };
  window.toggleCode=function(){
    var p=document.getElementById('codePanel'),b=document.querySelector('.code-toggle');
    if(p.style.display==='block'){p.style.display='none';b.textContent='#encodeForJavaScript(ui.codeToggleLabel)# \u2193';}
    else{p.style.display='block';b.textContent='Hide active code \u2191';}
  };
  input.focus();
})();
</script>
</cfif>
</cfoutput>
</body>
</html>
