<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Nexora — AI Support Assistant</title>
<style>
:root {
  --bg:      #0d1117;
  --surf:    #161b22;
  --surf2:   #1c2230;
  --border:  #30363d;
  --txt:     #e6edf3;
  --muted:   #8b949e;
  --accent:  #58a6ff;
  --green:   #3fb950;
  --red:     #fa4549;
  --purple:  #bc8cff;
  --orange:  #f0883e;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; overflow: hidden; }
body {
  background: var(--bg); color: var(--txt);
  font-family: -apple-system, 'Segoe UI', system-ui, sans-serif;
  font-size: 14px; line-height: 1.5;
  display: flex; flex-direction: column;
}

/* ── Header ────────────────────────────────────────────────── */
.hdr {
  background: var(--surf); border-bottom: 1px solid var(--border);
  padding: 11px 20px; display: flex; align-items: center; gap: 12px; flex-shrink: 0;
}
.logo {
  width: 34px; height: 34px; background: #FA0F00; color: #fff;
  font-weight: 900; font-size: 14px; letter-spacing: -1px;
  display: grid; place-items: center; border-radius: 6px; flex-shrink: 0;
}
.hdr-title { font-size: 14px; font-weight: 700; }
.hdr-sub   { font-size: 11px; color: var(--muted); }
.pills { margin-left: auto; display: flex; gap: 5px; flex-wrap: wrap; justify-content: flex-end; }
.pill {
  padding: 2px 8px; border-radius: 20px; font-size: 10px;
  font-weight: 700; text-transform: uppercase; letter-spacing: .4px; border: 1px solid;
  white-space: nowrap;
}
.p-blue   { background: rgba(88,166,255,.1);  border-color: rgba(88,166,255,.3);  color: var(--accent); }
.p-green  { background: rgba(63,185,80,.1);   border-color: rgba(63,185,80,.3);   color: var(--green); }
.p-purple { background: rgba(188,140,255,.1); border-color: rgba(188,140,255,.3); color: var(--purple); }
.p-orange { background: rgba(240,136,62,.1);  border-color: rgba(240,136,62,.3);  color: var(--orange); }
.p-red    { background: rgba(250,69,73,.1);   border-color: rgba(250,69,73,.3);   color: var(--red); }
.p-muted  { background: rgba(139,148,158,.1); border-color: rgba(139,148,158,.3); color: var(--muted); }

/* ── Nav bar ───────────────────────────────────────────────── */
.nav-bar {
  background: var(--surf2); border-bottom: 1px solid var(--border);
  padding: 6px 20px; display: flex; align-items: center; gap: 6px;
  flex-shrink: 0; flex-wrap: wrap;
}
.nav-btn {
  background: none; border: 1px solid var(--border); color: var(--muted);
  padding: 4px 10px; border-radius: 20px; font-size: 11px;
  cursor: pointer; text-decoration: none; display: inline-block;
  transition: border-color .15s, color .15s;
}
.nav-btn.active { border-color: var(--accent); color: var(--accent); background: rgba(88,166,255,.08); }
.nav-btn:hover:not(.active) { border-color: var(--muted); color: var(--txt); }

/* ── Chat area ──────────────────────────────────────────────── */
.chat-area { flex: 1; overflow-y: auto; padding: 24px 0; scroll-behavior: smooth; }
.chat-inner {
  max-width: 900px; margin: 0 auto; padding: 0 20px;
  display: flex; flex-direction: column; gap: 18px;
}

/* ── Messages ───────────────────────────────────────────────── */
.msg { display: flex; gap: 10px; align-items: flex-start; }
.msg.user { flex-direction: row-reverse; }
.av {
  width: 30px; height: 30px; border-radius: 50%;
  display: grid; place-items: center; font-size: 11px; font-weight: 800;
  flex-shrink: 0;
}
.av-ai   { background: var(--accent); color: #000; }
.av-user { background: var(--surf2); border: 1px solid var(--border); color: var(--muted); }
.bubble {
  max-width: 80%; padding: 11px 15px; border-radius: 14px;
  font-size: 14px; line-height: 1.65; white-space: pre-wrap; word-break: break-word;
}
.msg.ai .bubble {
  background: var(--surf); border: 1px solid var(--border); border-top-left-radius: 4px;
}
.msg.user .bubble {
  background: var(--accent); color: #0d1117; font-weight: 500; border-top-right-radius: 4px;
}

/* ── Typing indicator ───────────────────────────────────────── */
.typing { display: flex; gap: 5px; align-items: center; padding: 14px 16px; }
.dot {
  width: 7px; height: 7px; background: var(--muted); border-radius: 50%;
  animation: bob 1.1s ease-in-out infinite;
}
.dot:nth-child(2) { animation-delay: .18s; }
.dot:nth-child(3) { animation-delay: .36s; }
@keyframes bob {
  0%,60%,100% { transform: translateY(0); opacity: .5; }
  30%          { transform: translateY(-5px); opacity: 1; }
}

/* ── Welcome state ──────────────────────────────────────────── */
#welcome {
  text-align: center; padding: 36px 16px; color: var(--muted);
}
#welcome h2 { font-size: 18px; font-weight: 700; color: var(--txt); margin-bottom: 8px; }
#welcome p  { font-size: 13px; line-height: 1.7; max-width: 520px; margin: 0 auto 20px; }
.demo-orders {
  display: inline-flex; flex-direction: column; gap: 4px;
  text-align: left; background: var(--surf); border: 1px solid var(--border);
  border-radius: 10px; padding: 12px 16px; font-size: 12px; color: var(--muted);
}
.demo-orders strong { color: var(--txt); display: block; margin-bottom: 4px; font-size: 11px; text-transform: uppercase; letter-spacing: .5px; }
.demo-orders span { font-family: monospace; color: var(--accent); }

/* ── Chips ──────────────────────────────────────────────────── */
#chips {
  max-width: 900px; margin: 0 auto 0; padding: 0 20px 8px;
  display: flex; flex-direction: column; gap: 0; flex-shrink: 0;
}
.chip-group { border-bottom: 1px solid var(--border); }
.chip-group:last-child { border-bottom: none; }
.chip-header {
  display: flex; align-items: center; gap: 8px;
  padding: 7px 2px; cursor: pointer; user-select: none;
}
.chip-header:hover .chip-label { opacity: 1; }
.chip-arrow {
  font-size: 10px; color: var(--muted); transition: transform .2s;
  flex-shrink: 0; width: 14px; text-align: center;
}
.chip-group.open .chip-arrow { transform: rotate(90deg); }
.chip-label {
  font-size: 10px; font-weight: 700; letter-spacing: .06em;
  text-transform: uppercase; color: var(--muted); opacity: .85;
  transition: opacity .15s;
}
.chip-label.tools    { color: rgba(88,166,255,.85); }
.chip-label.policy   { color: rgba(63,185,80,.85); }
.chip-label.escalate { color: rgba(240,136,62,.85); }
.chip-label.guard    { color: rgba(250,69,73,.85); }
.chip-label.sysmsg   { color: rgba(188,140,255,.85); }
.chip-label.memory   { color: rgba(78,201,176,.85); }
.chip-body {
  display: none; padding: 0 0 8px 22px;
  gap: 6px; flex-wrap: wrap;
}
.chip-group.open .chip-body { display: flex; }
.chip {
  background: var(--surf); border: 1px solid var(--border); color: var(--muted);
  padding: 5px 13px; border-radius: 8px; font-size: 12px; line-height: 1.4;
  cursor: pointer; transition: border-color .15s, color .15s, background .15s;
  user-select: none; white-space: normal; word-break: break-word;
}
.chip:hover { border-color: var(--accent); color: var(--accent); background: rgba(88,166,255,.04); }
.hidden { display: none !important; }

/* ── Input area ─────────────────────────────────────────────── */
.input-wrap {
  background: var(--surf); border-top: 1px solid var(--border);
  padding: 12px 20px; flex-shrink: 0;
}
.input-inner {
  max-width: 900px; margin: 0 auto; display: flex; gap: 8px; align-items: flex-end;
}
textarea {
  flex: 1; background: var(--bg); border: 1px solid var(--border);
  border-radius: 10px; color: var(--txt); padding: 10px 14px;
  font-family: inherit; font-size: 14px; resize: none; outline: none;
  line-height: 1.5; max-height: 120px; overflow-y: auto; transition: border-color .15s;
}
textarea:focus { border-color: var(--accent); }
textarea::placeholder { color: var(--muted); }
.btn {
  border: none; border-radius: 10px; padding: 10px 16px;
  font-weight: 700; font-size: 13px; cursor: pointer; transition: opacity .15s; flex-shrink: 0;
}
.btn-send  { background: var(--accent); color: #000; }
.btn-reset { background: none; border: 1px solid var(--border); color: var(--muted); }
.btn-reset:hover { border-color: var(--muted); color: var(--txt); }
.btn:disabled { opacity: .35; cursor: not-allowed; }
.btn:hover:not(:disabled) { opacity: .85; }

/* ── Scrollbar ──────────────────────────────────────────────── */
::-webkit-scrollbar { width: 5px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
</style>
</head>
<body>

<!--- ── Header ─────────────────────────────────────────────────────────────── --->
<header class="hdr">
  <div class="logo">Nx</div>
  <div>
    <div class="hdr-title">Nexora Support</div>
    <div class="hdr-sub">AI-powered assistant</div>
  </div>
  <div class="pills">
    <cfoutput><span class="pill p-blue">#encodeForHTML(application.modelName)#</span></cfoutput>
    <span class="pill p-green">Memory</span>
    <span class="pill p-purple">Tools + MCP</span>
    <span class="pill p-orange">RAG</span>
    <span class="pill p-red">Guardrails</span>
    <span class="pill p-muted">Observability</span>
  </div>
</header>

<!--- ── Nav bar ───────────────────────────────────────────────────────────────── --->
<div class="nav-bar">
  <a class="nav-btn" href="problem1-chatmodel_demo.cfm">P1: Chat</a>
  <a class="nav-btn" href="problem2-systemMessage_demo.cfm">P2: System Msg</a>
  <a class="nav-btn" href="problem3-chatmemory_demo.cfm">P3: Memory</a>
  <a class="nav-btn" href="problem4-functiontools_demo.cfm">P4: Tools</a>
  <a class="nav-btn" href="problem5-guardrails_demo.cfm">P5: Guardrails</a>
  <a class="nav-btn" href="problem6-streaming_demo.cfm">P6: Streaming</a>
  <a class="nav-btn" href="problem6-mcp_demo.cfm">P7: MCP</a>
  <a class="nav-btn" href="problem8-rag_demo.cfm">P8: RAG</a>
  <a class="nav-btn" href="problem9-observability_demo.cfm">P9: Observability</a>
  <a class="nav-btn active" href="index.cfm">Full App</a>
</div>

<!--- ── Chat area ────────────────────────────────────────────────────────────── --->
<div class="chat-area" id="chatArea">
  <div class="chat-inner" id="chatInner">

    <div id="welcome">
      <h2>Hi, I'm Nexora's support assistant.</h2>
      <p>I can look up order status, answer policy questions from our documents, and escalate issues when needed. Ask me anything.</p>
      <div class="demo-orders">
        <strong>Demo order numbers to try</strong>
        <div><span>#12345</span> — Shipped (UPS, in transit)</div>
        <div><span>#11111</span> — Out for delivery today</div>
        <div><span>#99821</span> — Still processing</div>
        <div><span>#77654</span> — Delivered</div>
        <div><span>#55432</span> — Cancelled</div>
      </div>
    </div>

  </div>
</div>

<!--- ── Suggestion chips (collapsible groups) ──────────────────────────────── --->
<div id="chips">

  <div class="chip-group">
    <div class="chip-header" onclick="this.parentElement.classList.toggle('open')">
      <span class="chip-arrow">&#x25B6;</span>
      <span class="chip-label tools">Order status — live lookup via function tools</span>
    </div>
    <div class="chip-body">
      <span class="chip" onclick="send(this.innerText)">Where is my order #12345?</span>
      <span class="chip" onclick="send(this.innerText)">What's the status of order #99821?</span>
      <span class="chip" onclick="send(this.innerText)">Has order #77654 been delivered?</span>
      <span class="chip" onclick="send(this.innerText)">Will order #11111 arrive today?</span>
      <span class="chip" onclick="send(this.innerText)">What happened to my order #55432?</span>
    </div>
  </div>

  <div class="chip-group">
    <div class="chip-header" onclick="this.parentElement.classList.toggle('open')">
      <span class="chip-arrow">&#x25B6;</span>
      <span class="chip-label policy">Returns, warranty &amp; shipping — answered from policy documents (RAG)</span>
    </div>
    <div class="chip-body">
      <span class="chip" onclick="send(this.innerText)">What is your return policy?</span>
      <span class="chip" onclick="send(this.innerText)">My order arrived damaged — what do I do?</span>
      <span class="chip" onclick="send(this.innerText)">How long is the hardware warranty?</span>
      <span class="chip" onclick="send(this.innerText)">Does the warranty cover water damage?</span>
      <span class="chip" onclick="send(this.innerText)">How do I start a return?</span>
      <span class="chip" onclick="send(this.innerText)">Can I exchange for a different color?</span>
      <span class="chip" onclick="send(this.innerText)">Is shipping free on my order?</span>
      <span class="chip" onclick="send(this.innerText)">What are the express shipping options?</span>
      <span class="chip" onclick="send(this.innerText)">Do you ship to Canada?</span>
      <span class="chip" onclick="send(this.innerText)">My package shows delivered but I never got it</span>
      <span class="chip" onclick="send(this.innerText)">Can I return a digital download?</span>
      <span class="chip" onclick="send(this.innerText)">My software license won't activate — can I get a refund?</span>
      <span class="chip" onclick="send(this.innerText)">How do I cancel my subscription?</span>
    </div>
  </div>

  <div class="chip-group">
    <div class="chip-header" onclick="this.parentElement.classList.toggle('open')">
      <span class="chip-arrow">&#x25B6;</span>
      <span class="chip-label escalate">Escalation — creates a support ticket via MCP</span>
    </div>
    <div class="chip-body">
      <span class="chip" onclick="send(this.innerText)">I want to escalate my issue with order #99821 — it arrived damaged</span>
      <span class="chip" onclick="send(this.innerText)">I need to speak with a manager about order #77654 right now</span>
    </div>
  </div>

  <div class="chip-group">
    <div class="chip-header" onclick="this.parentElement.classList.toggle('open')">
      <span class="chip-arrow">&#x25B6;</span>
      <span class="chip-label guard">Guardrails — PII redaction &amp; blocking</span>
    </div>
    <div class="chip-body">
      <span class="chip" onclick="send(this.innerText)">What email is on my account for order #12345?</span>
      <span class="chip" onclick="send(this.innerText)">What email address did I use for order #99821?</span>
      <span class="chip" onclick="send(this.innerText)">Can you confirm the contact email for order #77654?</span>
      <span class="chip" onclick="send(this.innerText)">Escalate my billing issue — my account verification number is 987-65-4321</span>
      <span class="chip" onclick="send(this.innerText)">I was charged twice on card 4111-1111-1111-1111 for order #12345 — escalate this</span>
    </div>
  </div>

  <div class="chip-group">
    <div class="chip-header" onclick="this.parentElement.classList.toggle('open')">
      <span class="chip-arrow">&#x25B6;</span>
      <span class="chip-label sysmsg">System message — AI identity &amp; scope boundaries</span>
    </div>
    <div class="chip-body">
      <span class="chip" onclick="send(this.innerText)">Who are you and what can you help me with?</span>
      <span class="chip" onclick="send(this.innerText)">What is Amazon's return policy?</span>
      <span class="chip" onclick="send(this.innerText)">Tell me about Apple's warranty</span>
      <span class="chip" onclick="send(this.innerText)">Write me a poem about the ocean</span>
    </div>
  </div>

  <div class="chip-group">
    <div class="chip-header" onclick="this.parentElement.classList.toggle('open')">
      <span class="chip-arrow">&#x25B6;</span>
      <span class="chip-label memory">Memory — click in sequence to test conversation continuity</span>
    </div>
    <div class="chip-body">
      <span class="chip" onclick="send(this.innerText)">My name is Alex and I need help with order #12345</span>
      <span class="chip" onclick="send(this.innerText)">What carrier is it shipping with?</span>
      <span class="chip" onclick="send(this.innerText)">And when will it arrive?</span>
      <span class="chip" onclick="send(this.innerText)">What order number and name did I mention?</span>
    </div>
  </div>

</div>

<!--- ── Input area ───────────────────────────────────────────────────────────── --->
<div class="input-wrap">
  <div class="input-inner">
    <textarea id="input" rows="1" placeholder="Ask about your orders, returns, shipping, or policies..."
      onkeydown="if(event.key==='Enter'&&!event.shiftKey){event.preventDefault();sendMsg();}"></textarea>
    <button class="btn btn-reset" id="resetBtn" onclick="resetConvo()" title="Start a new conversation">↺ Reset</button>
    <button class="btn btn-send"  id="sendBtn"  onclick="sendMsg()">Send</button>
  </div>
</div>

<script>
(function() {

  const chatInner = document.getElementById('chatInner');
  const chatArea  = document.getElementById('chatArea');
  const input     = document.getElementById('input');
  const sendBtn   = document.getElementById('sendBtn');
  const resetBtn  = document.getElementById('resetBtn');
  const chips     = document.getElementById('chips');
  const welcome   = document.getElementById('welcome');
  let   busy      = false;

  // ── Stable session ID across page refreshes ──
  let sid = localStorage.getItem('acme_support_sid');
  if (!sid) {
    sid = (typeof crypto !== 'undefined' && crypto.randomUUID)
        ? crypto.randomUUID()
        : 'sid-' + Date.now() + '-' + Math.random().toString(36).slice(2);
    localStorage.setItem('acme_support_sid', sid);
  }

  // ── Auto-resize textarea ──
  input.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 120) + 'px';
  });

  // ── Add a chat bubble ──
  function addBubble(role, text) {
    welcome.classList.add('hidden');

    const msg    = document.createElement('div');
    msg.className = 'msg ' + role;

    const av     = document.createElement('div');
    av.className  = 'av av-' + role;
    av.textContent = role === 'ai' ? 'AI' : 'You';

    const bub    = document.createElement('div');
    bub.className = 'bubble';
    bub.textContent = text;

    msg.appendChild(av);
    msg.appendChild(bub);
    chatInner.appendChild(msg);
    scrollBottom();
    return bub;
  }

  // ── Typing indicator ──
  function showTyping() {
    const msg    = document.createElement('div');
    msg.id        = 'typingMsg';
    msg.className = 'msg ai';

    const av     = document.createElement('div');
    av.className  = 'av av-ai';
    av.textContent = 'AI';

    const bub    = document.createElement('div');
    bub.className = 'bubble';
    bub.innerHTML = '<div class="typing"><div class="dot"></div><div class="dot"></div><div class="dot"></div></div>';

    msg.appendChild(av);
    msg.appendChild(bub);
    chatInner.appendChild(msg);
    scrollBottom();
  }

  function hideTyping() {
    const el = document.getElementById('typingMsg');
    if (el) el.remove();
  }

  // ── Smooth typing animation ──
  function typeText(bub, text, msPerChar) {
    return new Promise(function(resolve) {
      bub.textContent = '';
      var i = 0;
      var speed = msPerChar || 11;
      var timer = setInterval(function() {
        if (i < text.length) {
          bub.textContent += text[i++];
          scrollBottom();
        } else {
          clearInterval(timer);
          resolve();
        }
      }, speed);
    });
  }

  function scrollBottom() {
    chatArea.scrollTop = chatArea.scrollHeight;
  }

  // ── Send a message ──
  window.send = function(text) {
    input.value = text;
    sendMsg();
  };

  window.sendMsg = async function() {
    var q = input.value.trim();
    if (!q || busy) return;

    busy = true;
    sendBtn.disabled = true;
    resetBtn.disabled = true;
    input.value = '';
    input.style.height = 'auto';

    addBubble('user', q);
    showTyping();

    try {
      var body = 'question=' + encodeURIComponent(q) + '&sessionId=' + encodeURIComponent(sid);
      var res  = await fetch('chat.cfm', {
        method  : 'POST',
        headers : { 'Content-Type': 'application/x-www-form-urlencoded' },
        body    : body
      });

      var data = await res.json();
      hideTyping();

      var reply=(data.message!==undefined&&data.message!==null)?data.message:(data.MESSAGE!==undefined&&data.MESSAGE!==null)?data.MESSAGE:'';
      var bub = addBubble('ai', '');
      await typeText(bub, (reply!==''?String(reply):"Sorry, I wasn't able to get a response. Please try again."), 11);

    } catch (err) {
      hideTyping();
      addBubble('ai', 'Sorry — I\'m having trouble connecting right now. Please try again in a moment.');
    } finally {
      busy = false;
      sendBtn.disabled = false;
      resetBtn.disabled = false;
      input.focus();
    }
  };

  // ── Reset conversation ──
  window.resetConvo = async function() {
    if (busy) return;
    if (!confirm('Start a new conversation? The current chat history will be cleared.')) return;

    try {
      await fetch('reset.cfm', { method: 'POST' });
    } catch(e) {}

    // Clear the chat UI
    chatInner.innerHTML = '';
    chatInner.appendChild(welcome);
    welcome.classList.remove('hidden');
    chips.classList.remove('hidden');
    input.focus();
  };

  input.focus();

})();
</script>
</body>
</html>
