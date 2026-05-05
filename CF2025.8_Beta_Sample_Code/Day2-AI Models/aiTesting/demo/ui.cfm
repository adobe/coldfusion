<cfheader name="Cache-Control" value="no-cache, no-store, must-revalidate">
<cfheader name="Pragma" value="no-cache">
<cfheader name="Expires" value="0">
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>ColdFusion AI - Demo</title>
<style>
/* ── Extra styles for new tabs ── */
.badge-new { background:rgba(56,189,248,.15); border:1px solid rgba(56,189,248,.35); color:#38bdf8; font-size:10px; padding:1px 6px; border-radius:20px; font-weight:800; margin-left:4px; vertical-align:middle; }
.step-row { display:flex; gap:8px; align-items:center; margin-bottom:10px; }
.step-num { width:24px; height:24px; border-radius:50%; background:var(--accent); color:#000; font-size:11px; font-weight:900; display:grid; place-items:center; flex-shrink:0; }
.step-txt { font-size:13px; }
.seg-card { background:var(--surf2); border:1px solid var(--border); border-radius:8px; padding:10px 14px; margin-bottom:8px; }
.seg-card:last-child { margin-bottom:0; }
.seg-score { font-size:11px; color:var(--green); font-weight:700; }
.seg-meta  { font-size:11px; color:var(--muted); margin-top:2px; }
.seg-text  { font-size:13px; line-height:1.55; margin-top:6px; }
.mcp-tool  { background:var(--surf2); border:1px solid var(--border); border-radius:7px; padding:8px 12px; margin-bottom:6px; }
.mcp-tool-nm  { color:var(--purple); font-weight:700; font-family:monospace; font-size:13px; }
.mcp-tool-desc{ color:var(--muted);  font-size:12px; margin-top:2px; }
.embed-bar { height:6px; background:var(--accent); border-radius:3px; margin-top:4px; transition:width .4s; }
.dim-count { font-size:28px; font-weight:800; color:var(--accent); }
.exp-tok-btn.active { border-color:var(--accent); color:var(--accent); background:rgba(88,166,255,.08); }
</style>
<style>
:root {
  --red:      #FA0F00;
  --bg:       #0d1117;
  --surf:     #161b22;
  --surf2:    #1c2230;
  --border:   #30363d;
  --txt:      #e6edf3;
  --muted:    #7d8590;
  --accent:   #58a6ff;
  --green:    #3fb950;
  --yellow:   #d29922;
  --purple:   #bc8cff;
  --teal:     #39d353;
  --r:        10px;
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, 'Segoe UI', system-ui, sans-serif; background: var(--bg); color: var(--txt); min-height: 100vh; font-size: 14px; }

/* ── Header ── */
.hdr { background: var(--surf); border-bottom: 1px solid var(--border); padding: 12px 24px; display: flex; align-items: center; gap: 14px; position: sticky; top: 0; z-index: 100; }
.hdr-logo { display: flex; align-items: center; gap: 10px; }
.adobe-sq { background: var(--red); color: #fff; font-weight: 900; font-size: 18px; width: 36px; height: 36px; display: grid; place-items: center; border-radius: 6px; letter-spacing: -1px; flex-shrink: 0; }
.hdr h1 { font-size: 16px; font-weight: 700; }
.hdr-sub { font-size: 12px; color: var(--muted); }
.hdr-pill { margin-left: auto; background: rgba(88,166,255,.12); border: 1px solid rgba(88,166,255,.3); color: var(--accent); padding: 3px 12px; border-radius: 20px; font-size: 11px; font-weight: 700; letter-spacing: .5px; text-transform: uppercase; }

/* ── Tabs ── */
.tabs { background: var(--surf); border-bottom: 1px solid var(--border); display: flex; padding: 0 20px; overflow-x: auto; gap: 2px; }
.tab { background: none; border: none; color: var(--muted); padding: 12px 18px; cursor: pointer; font-size: 13px; font-weight: 600; border-bottom: 3px solid transparent; white-space: nowrap; transition: color .15s, border-color .15s; display: flex; align-items: center; gap: 7px; }
.tab:hover { color: var(--txt); }
.tab.on { color: var(--accent); border-bottom-color: var(--accent); }
.tab-icon { font-size: 16px; }

/* ── Layout ── */
.wrap { max-width: 1300px; margin: 0 auto; padding: 24px 20px; }
.panel { display: none; }
.panel.on { display: contents; }
.grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
.grid3 { display: grid; grid-template-columns: 5fr 4fr; gap: 20px; }
.span2 { grid-column: 1 / -1; }

/* ── Cards ── */
.card { background: var(--surf); border: 1px solid var(--border); border-radius: var(--r); overflow: hidden; }
.card-hd { padding: 14px 18px; border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 10px; }
.card-hd-icon { font-size: 18px; }
.card-hd-title { font-size: 14px; font-weight: 700; }
.card-hd-sub { font-size: 11px; color: var(--muted); margin-top: 2px; }
.card-bd { padding: 18px; }

/* ── Section intro ── */
.intro { padding: 2px 0 20px; }
.intro h2 { font-size: 20px; font-weight: 800; margin-bottom: 6px; }
.intro p { color: var(--muted); line-height: 1.6; font-size: 13px; }

/* ── Forms ── */
.fg { margin-bottom: 14px; }
.fg:last-child { margin-bottom: 0; }
label { display: block; font-size: 11px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .6px; margin-bottom: 5px; }
select, input[type=text], input[type=number], textarea {
  width: 100%; background: var(--surf2); border: 1px solid var(--border); border-radius: 6px;
  color: var(--txt); padding: 8px 11px; font-size: 13px; font-family: inherit; outline: none;
  transition: border-color .15s;
}
select:focus, input:focus, textarea:focus { border-color: var(--accent); }
textarea { resize: vertical; min-height: 76px; line-height: 1.5; }

.slider-row { display: flex; align-items: center; gap: 10px; }
input[type=range] { flex: 1; accent-color: var(--accent); cursor: pointer; }
.sv { background: var(--surf2); border: 1px solid var(--border); border-radius: 5px; padding: 3px 9px; font-size: 12px; font-weight: 700; color: var(--accent); min-width: 46px; text-align: center; }

.tog-row { display: flex; align-items: center; gap: 10px; font-size: 13px; }
.tog { position: relative; width: 40px; height: 22px; flex-shrink: 0; }
.tog input { opacity: 0; width: 0; height: 0; }
.tog-sl { position: absolute; inset: 0; background: var(--border); border-radius: 22px; cursor: pointer; transition: background .2s; }
.tog-sl::before { content: ''; position: absolute; width: 16px; height: 16px; left: 3px; top: 3px; background: #fff; border-radius: 50%; transition: transform .2s; }
.tog input:checked + .tog-sl { background: var(--green); }
.tog input:checked + .tog-sl::before { transform: translateX(18px); }

.btn-row { display: flex; gap: 8px; margin-top: 6px; flex-wrap: wrap; }
.btn { padding: 8px 18px; border-radius: 6px; border: none; font-size: 13px; font-weight: 700; cursor: pointer; transition: all .15s; display: inline-flex; align-items: center; gap: 7px; }
.btn-primary { background: var(--red); color: #fff; }
.btn-primary:hover:not(:disabled) { background: #d40c00; }
.btn-outline { background: transparent; color: var(--txt); border: 1px solid var(--border); }
.btn-outline:hover:not(:disabled) { background: var(--surf2); }
.btn-green { background: var(--green); color: #000; font-weight: 800; }
.btn-green:hover:not(:disabled) { background: #2da046; color: #fff; }
.btn:disabled { opacity: .4; cursor: not-allowed; }
.spin { width: 15px; height: 15px; border: 2px solid rgba(255,255,255,.3); border-top-color: #fff; border-radius: 50%; animation: sp .65s linear infinite; display: none; }
@keyframes sp { to { transform: rotate(360deg); } }

/* ── Output ── */
.out { background: var(--surf2); border: 1px solid var(--border); border-radius: 7px; padding: 14px; min-height: 100px; font-size: 13px; line-height: 1.6; white-space: pre-wrap; word-break: break-word; position: relative; }
.out-empty { color: var(--muted); font-style: italic; font-size: 13px; }

.code-block { background: #010409; border: 1px solid var(--border); border-radius: 7px; padding: 14px; font-family: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace; font-size: 12px; line-height: 1.75; overflow-x: auto; }
.ck  { color: #ff79c6; } /* keyword  */
.cs  { color: #a5d6ff; } /* string   */
.cn  { color: #f78166; } /* number   */
.cp  { color: #79c0ff; } /* property */
.cc  { color: #8b949e; } /* comment  */
.cf  { color: #d2a8ff; } /* function */
.cb  { color: #56d364; } /* bool/val */

.badge { display: inline-flex; align-items: center; gap: 4px; padding: 2px 9px; border-radius: 20px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .4px; }
.b-ok  { background: rgba(63,185,80,.15);  color: var(--green);  border: 1px solid rgba(63,185,80,.3); }
.b-err { background: rgba(250,15,0,.15);   color: var(--red);    border: 1px solid rgba(250,15,0,.3); }
.b-inf { background: rgba(88,166,255,.12); color: var(--accent); border: 1px solid rgba(88,166,255,.3); }
.b-warn{ background: rgba(210,153,34,.15); color: var(--yellow); border: 1px solid rgba(210,153,34,.3); }

.meta-row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; margin-top: 10px; }
.timing { font-size: 11px; color: var(--muted); background: var(--surf2); border: 1px solid var(--border); border-radius: 4px; padding: 2px 8px; }

/* ── Stats ── */
.stats { display: flex; gap: 10px; margin-top: 12px; }
.stat { background: var(--surf2); border: 1px solid var(--border); border-radius: 8px; padding: 10px 14px; text-align: center; flex: 1; }
.sv2 { font-size: 22px; font-weight: 800; color: var(--accent); }
.sl  { font-size: 11px; color: var(--muted); margin-top: 2px; }

/* ── Chat UI ── */
.chat-wrap { border: 1px solid var(--border); border-radius: 8px; overflow: hidden; display: flex; flex-direction: column; }
.chat-msgs { flex: 1; height: 360px; overflow-y: auto; padding: 16px; display: flex; flex-direction: column; gap: 12px; background: var(--surf2); }
.msg { display: flex; gap: 9px; animation: fadeUp .25s ease; }
@keyframes fadeUp { from { opacity:0; transform: translateY(8px); } to { opacity:1; transform: translateY(0); } }
.msg.user { flex-direction: row-reverse; }
.av { width: 30px; height: 30px; border-radius: 50%; display: grid; place-items: center; font-size: 13px; flex-shrink: 0; }
.msg.user .av { background: var(--red); }
.msg.asst .av { background: var(--accent); color: #000; font-weight: 900; }
.bubble { background: var(--surf); border: 1px solid var(--border); border-radius: 10px; padding: 9px 13px; max-width: 82%; font-size: 13px; line-height: 1.55; }
.msg.user .bubble { background: rgba(250,15,0,.12); border-color: rgba(250,15,0,.25); }
.chat-in { display: flex; padding: 10px; gap: 8px; border-top: 1px solid var(--border); background: var(--surf); }
.chat-in input { flex: 1; }

/* ── Tool cards ── */
.tool-card { background: var(--surf2); border: 1px solid var(--border); border-radius: 7px; padding: 10px 14px; margin-bottom: 8px; }
.tool-card:last-child { margin-bottom: 0; }
.tool-nm { font-weight: 800; color: var(--teal); font-size: 13px; margin-bottom: 6px; }
.method-tags { display: flex; flex-wrap: wrap; gap: 5px; }
.mtag { background: rgba(57,211,83,.08); border: 1px solid rgba(57,211,83,.25); color: var(--teal); padding: 1px 9px; border-radius: 20px; font-size: 11px; font-family: monospace; }
.tool-exec { background: rgba(57,211,83,.06); border: 1px solid rgba(57,211,83,.2); border-radius: 7px; padding: 10px 13px; margin-top: 8px; font-size: 12px; }
.tex-call { color: var(--teal); font-family: monospace; margin-bottom: 4px; }
.tex-res  { color: var(--green); font-family: monospace; }

/* ── JSON viewer ── */
.json-view { background: #010409; border: 1px solid var(--border); border-radius: 7px; padding: 14px; font-family: monospace; font-size: 12px; line-height: 1.75; overflow: auto; max-height: 320px; }
.jk { color: #79c0ff; } .js { color: #a5d6ff; } .jn { color: #f78166; } .jb { color: #ff7b72; } .jnull { color: var(--muted); }

/* ── Compare ── */
.cmp { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.cmp-card { border: 1px solid var(--border); border-radius: 8px; overflow: hidden; }
.cmp-hd { padding: 9px 13px; font-size: 11px; font-weight: 800; text-transform: uppercase; letter-spacing: .5px; }
.cmp-hd.safe   { background: rgba(63,185,80,.15);  color: var(--green); }
.cmp-hd.unsafe { background: rgba(210,153,34,.15); color: var(--yellow); }
.cmp-body { padding: 13px; font-size: 13px; line-height: 1.55; min-height: 90px; background: var(--surf2); white-space: pre-wrap; }

/* ── Info callout ── */
.callout { background: rgba(88,166,255,.07); border: 1px solid rgba(88,166,255,.2); border-radius: 7px; padding: 11px 14px; font-size: 12.5px; color: var(--muted); margin-bottom: 14px; line-height: 1.6; }
.callout strong { color: var(--accent); }
.callout code  { background: var(--surf2); border: 1px solid var(--border); border-radius: 4px; padding: 1px 6px; font-size: 11.5px; color: var(--txt); }

@media (max-width: 860px) {
  .grid2, .grid3, .cmp { grid-template-columns: 1fr; }
}
</style>
</head>
<body>

<header class="hdr">
  <div class="hdr-logo">
    <div class="adobe-sq">Ai</div>
    <div>
      <div class="hdr h1">ColdFusion AI - Demo</div>
      <div class="hdr-sub">ColdFusion 2025 &middot; ChatModel / agent()</div>
    </div>
  </div>
  <div class="hdr-pill">CF 2025</div>
</header>

<nav class="tabs">
  <button class="tab on" data-tab="modelconfig">
    <span class="tab-icon">⚙️</span> LLM Config
  </button>
  <button class="tab" data-tab="systemmsg">
    <span class="tab-icon">🗣️</span> SystemMessage
  </button>
  <button class="tab" data-tab="functiontool">
    <span class="tab-icon">🔧</span> FunctionTool
  </button>
  <button class="tab" data-tab="chatmemory">
    <span class="tab-icon">💬</span> ChatMemory
  </button>
  <button class="tab" data-tab="guardrails">
    <span class="tab-icon">🛡️</span> Guardrails
  </button>
  <button class="tab" data-tab="rag">
    <span class="tab-icon">📚</span> RAG
  </button>
  <button class="tab" data-tab="streaming">
    <span class="tab-icon">⚡</span> Streaming
  </button>
  <button class="tab" data-tab="mcp">
    <span class="tab-icon">🔌</span> MCP
  </button>
</nav>

<div class="wrap">

<!-- ══════════════════════════════════════════════════════════
     1. CHATMODELCONFIG
══════════════════════════════════════════════════════════ -->
<div class="panel on" id="tab-modelconfig">
  <div class="grid2">

    <div class="intro span2">
      <h2>⚙️ LLM Config</h2>
      <p>Configure every aspect of the language model — provider, model variant, temperature, token limits, response format, and more. Changes update the code preview in real-time.</p>
    </div>

    <!-- Left: Controls -->
    <div>
      <div class="card">
        <div class="card-hd">
          <span class="card-hd-icon">🎛️</span>
          <div><div class="card-hd-title">Model Configuration</div><div class="card-hd-sub">Adjust parameters and run</div></div>
        </div>
        <div class="card-bd">
          <div class="fg">
            <label>Provider</label>
            <select id="mc-provider" onchange="mcUpdateModels()">
              <option value="anthropic">Anthropic</option>
              <option value="openai">OpenAI</option>
              <option value="mistral">Mistral AI</option>
              <option value="azureopenai">Azure OpenAI</option>
            </select>
          </div>
          <div class="fg">
            <label>Model</label>
            <select id="mc-model"></select>
          </div>
          <div class="fg">
            <label>Temperature — <span id="mc-temp-lbl">0.7</span></label>
            <div class="slider-row">
              <input type="range" id="mc-temp" min="0" max="2" step="0.1" value="0.7" oninput="mcUpdateTemp()">
              <div class="sv" id="mc-temp-sv">0.7</div>
            </div>
          </div>
          <div class="fg">
            <label>Max Tokens — <span id="mc-tok-lbl">500</span></label>
            <div class="slider-row">
              <input type="range" id="mc-tokens" min="50" max="2000" step="50" value="500" oninput="mcUpdateTokens()">
              <div class="sv" id="mc-tok-sv">500</div>
            </div>
          </div>
          <div class="fg">
            <label>Response Format</label>
            <select id="mc-format" onchange="mcFormatChange()">
              <option value="text">text (natural language)</option>
              <option value="JSON">JSON (structured)</option>
            </select>
          </div>
          <div class="fg">
            <label>Prompt</label>
            <textarea id="mc-prompt" rows="3">Tell me a fascinating fact about space in 2–3 sentences.</textarea>
          </div>
          <div class="btn-row">
            <button class="btn btn-primary" id="mc-run" onclick="mcRun()">
              <div class="spin" id="mc-spin"></div>
              ▶ Run
            </button>
            <button class="btn btn-outline" onclick="mcReset()">↺ Reset</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Right: Code preview + response -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">Live Config Preview</div></div>
        <div class="card-bd">
          <div class="code-block" id="mc-code">
<span class="cc">// Config will update as you adjust controls</span>
          </div>
        </div>
      </div>
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">💬</span><div class="card-hd-title">Response</div></div>
        <div class="card-bd">
          <div class="out" id="mc-out"><span class="out-empty">Response will appear here…</span></div>
          <div class="meta-row" id="mc-meta" style="display:none">
            <span class="badge b-ok" id="mc-badge">OK</span>
            <span class="timing" id="mc-time"></span>
          </div>
        </div>
      </div>
    </div>

  </div>

  <!-- ── Parameter Explorer ─────────────────────────────────────────── -->
  <div class="span2" style="margin-top:4px;">
    <div class="card">
      <div class="card-hd">
        <span class="card-hd-icon">⚙️</span>
        <div>
          <div class="card-hd-title">Parameter Explorer</div>
          <div class="card-hd-sub">Run the same prompt at different settings — watch the output change</div>
        </div>
      </div>
      <div class="card-bd">
        <div class="grid2" style="gap:28px;">

          <!-- Temperature -->
          <div>
            <div class="callout" style="margin-bottom:12px;">
              <strong>TEMPERATURE</strong> — controls creativity &amp; randomness.<br>
              Low (0.1) = predictable, consistent. High (1.2) = varied, creative. Run the same prompt 3× to see the difference.
            </div>
            <div class="fg">
              <label>Temperature — <span id="exp-temp-lbl">0.7</span></label>
              <div class="slider-row">
                <input type="range" id="exp-temp" min="0.1" max="1.5" step="0.1" value="0.7"
                       oninput="document.getElementById('exp-temp-lbl').textContent=this.value;">
                <div class="sv" id="exp-temp-sv" style="min-width:36px;">0.7</div>
              </div>
              <div style="display:flex;justify-content:space-between;font-size:10px;color:var(--muted);margin-top:3px;">
                <span>0.1 — predictable</span><span>1.5 — creative</span>
              </div>
            </div>
            <div class="fg">
              <label>Fixed Prompt</label>
              <div class="out" style="min-height:auto;padding:10px 12px;font-style:italic;color:var(--muted);font-size:12px;">
                "Suggest 3 creative slogans for a customer loyalty rewards program"
              </div>
            </div>
            <div class="btn-row">
              <button class="btn btn-outline" id="exp-temp-run" onclick="mcExpRunTemp()">
                <div class="spin" id="exp-temp-spin"></div>
                ▶ Run Again
              </button>
              <span class="badge b-inf" id="exp-temp-badge" style="display:none;"></span>
            </div>
            <div class="out" id="exp-temp-out" style="margin-top:10px;min-height:80px;">
              <span class="out-empty">Set temp to 0.1 → run 3×, then set to 1.2 → run 3× — compare variation</span>
            </div>
          </div>

          <!-- Max Tokens -->
          <div>
            <div class="callout" style="margin-bottom:12px;">
              <strong>MAXTOKENS</strong> — hard limit on response length.<br>
              When the limit is hit, the response stops mid-sentence. Use a long prompt to make truncation obvious.
            </div>
            <div class="fg">
              <label>Max Tokens</label>
              <div style="display:flex;gap:8px;flex-wrap:wrap;">
                <button class="btn btn-outline exp-tok-btn active" data-tok="30"  onclick="mcExpSetTok(this)">30</button>
                <button class="btn btn-outline exp-tok-btn"        data-tok="80"  onclick="mcExpSetTok(this)">80</button>
                <button class="btn btn-outline exp-tok-btn"        data-tok="200" onclick="mcExpSetTok(this)">200</button>
                <button class="btn btn-outline exp-tok-btn"        data-tok="500" onclick="mcExpSetTok(this)">500</button>
              </div>
              <div id="exp-tok-hint" style="font-size:11px;color:var(--muted);margin-top:6px;">
                30 tokens ≈ 20 words — response cuts off mid-sentence
              </div>
            </div>
            <div class="fg">
              <label>Fixed Prompt</label>
              <div class="out" style="min-height:auto;padding:10px 12px;font-style:italic;color:var(--muted);font-size:12px;">
                "Walk me through every step of returning a damaged product, from packaging it up to receiving my refund"
              </div>
            </div>
            <div class="btn-row">
              <button class="btn btn-outline" id="exp-tok-run" onclick="mcExpRunTok()">
                <div class="spin" id="exp-tok-spin"></div>
                ▶ Run
              </button>
              <span class="badge b-inf" id="exp-tok-badge" style="display:none;"></span>
            </div>
            <div class="out" id="exp-tok-out" style="margin-top:10px;min-height:80px;">
              <span class="out-empty">Start at 30 — see the cut-off. Then try 200 and 500 to see the full answer emerge</span>
            </div>
          </div>

        </div>
      </div>
    </div>
  </div>

</div>

<!-- ══════════════════════════════════════════════════════════
     2. FUNCTIONTOOL
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-functiontool">
  <div class="grid3">

    <div class="intro span2">
      <h2>🔧 FunctionTool</h2>
      <p>Register ColdFusion CFCs as callable tools. The LLM decides which tool to invoke and with what arguments — ColdFusion then executes the call and returns the result.</p>
    </div>

    <!-- Left -->
    <div style="display:flex;flex-direction:column;gap:16px">

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🗂️</span><div class="card-hd-title">Available Tools</div></div>
        <div class="card-bd">
          <div class="tool-card">
            <div class="tool-nm">EcommerceTool.cfc</div>
            <div class="method-tags">
              <span class="mtag">searchProducts(keyword, maxResults)</span>
              <span class="mtag">applyPromoCode(code, cartTotal)</span>
              <span class="mtag">trackOrder(orderId)</span>
              <span class="mtag">getRecommendations(category, maxBudget)</span>
            </div>
          </div>
          <div class="tool-card">
            <div class="tool-nm">FinancialTool.cfc</div>
            <div class="method-tags">
              <span class="mtag">calculateMortgage(principal, rate, years)</span>
              <span class="mtag">convertCurrency(amount, from, to)</span>
              <span class="mtag">calculateROI(initial, final, years)</span>
              <span class="mtag">estimateTax(income, filingStatus)</span>
              <span class="mtag">getStockQuote(symbol)</span>
            </div>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">⚡</span><div class="card-hd-title">Run Demo</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>Active Toolset</label>
            <select id="ft-tools">
              <option value="ecommerce">EcommerceTool</option>
              <option value="financial">FinancialTool</option>
              <option value="both">Both Tools</option>
            </select>
          </div>
          <div class="fg">
            <label>Provider</label>
            <select id="ft-provider">
              <option value="anthropic">Anthropic Claude</option>
              <option value="openai">OpenAI (gpt-4o-mini)</option>
              <option value="mistral">Mistral (mistral-large-latest)</option>
            </select>
          </div>
          <div class="fg">
            <label>Prompt</label>
            <textarea id="ft-prompt" rows="3">Search for ColdFusion software, apply promo code CF2025, and track order ORD-5002</textarea>
          </div>
          <div class="fg">
            <label>Quick prompts</label>
            <div class="btn-row" style="margin-top:4px;flex-wrap:wrap">
              <button class="btn btn-outline" style="font-size:11px" onclick="ftSetPrompt('Recommend software products under $800 and track order ORD-5004')">Recommend + Track</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="ftSetPrompt('Calculate mortgage for $500,000 at 6.5% over 30 years and get ADBE stock quote')">Mortgage + Stock</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="ftSetPrompt('Convert 1000 USD to EUR and estimate tax for $120,000 income single filer')">Currency + Tax</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="ftSetPrompt('Apply promo code SAVE20 to a $1500 cart and calculate ROI: invested $10000, now worth $18500 after 3 years')">Promo + ROI</button>
            </div>
          </div>
          <div class="btn-row">
            <button class="btn btn-primary" id="ft-run" onclick="ftRun()">
              <div class="spin" id="ft-spin"></div>
              ▶ Run
            </button>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">Registration Code</div></div>
        <div class="card-bd">
<div class="code-block" id="ft-code-preview"><span class="cf">agent</span>({
  <span class="cp">CHATMODEL</span>: chatModel,
  <span class="cp">TOOLS</span>: [
    { <span class="cp">CFC</span>: <span class="cs">"aiTesting.demo.tools.EcommerceTool"</span> },
    { <span class="cp">CFC</span>: <span class="cs">"aiTesting.demo.tools.FinancialTool"</span> }
  ]
})</div>
        </div>
      </div>
    </div>

    <!-- Right -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🤖</span><div class="card-hd-title">LLM Response + Tool Execution</div></div>
        <div class="card-bd">
          <div class="out" id="ft-out"><span class="out-empty">Response will appear here…</span></div>
          <div id="ft-tools-out" style="margin-top:12px"></div>
          <div class="meta-row" id="ft-meta" style="display:none">
            <span class="badge b-ok">OK</span>
            <span class="timing" id="ft-time"></span>
            <span class="badge b-inf" id="ft-toolcount"></span>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<!-- ══════════════════════════════════════════════════════════
     3. CHATMEMORY
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-chatmemory">
  <div class="grid3">

    <div class="intro span2">
      <h2>💬 ChatMemory</h2>
      <p><code>agent()</code> maintains conversation context across turns via <code>CHATMEMORY</code>. Choose between <strong>MessageWindow</strong> (last N messages) or <strong>TokenWindow</strong> (last N tokens). Enable per-user isolation to give each user their own memory slot.</p>
    </div>

    <!-- Left: Chat -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">💬</span><div class="card-hd-title">Conversation</div></div>
        <div class="card-bd" style="padding:0">
          <div class="chat-wrap">
            <div class="chat-msgs" id="cm-msgs">
              <div style="text-align:center;color:var(--muted);font-size:12px;margin:auto">Start a conversation to test memory…<br>Try: "My name is Alice" then "What is my name?"</div>
            </div>
            <div class="chat-in">
              <input type="text" id="cm-input" placeholder="Type a message…" onkeydown="if(event.key==='Enter')cmSend()">
              <button class="btn btn-primary" id="cm-send" onclick="cmSend()">
                <div class="spin" id="cm-spin"></div>
                Send
              </button>
            </div>
          </div>
        </div>
      </div>
      <div class="btn-row">
        <button class="btn btn-outline" onclick="cmClear()">🗑 Clear Memory</button>
        <button class="btn btn-outline" onclick="cmQuick()">💡 Quick Demo</button>
      </div>
    </div>

    <!-- Right: Settings -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">⚙️</span><div class="card-hd-title">Memory Settings</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>Provider</label>
            <select id="cm-provider">
              <option value="anthropic">Anthropic</option>
              <option value="openai">OpenAI</option>
              <option value="mistral">Mistral</option>
            </select>
          </div>
          <div class="fg">
            <label>Memory Type</label>
            <select id="cm-type" onchange="cmTypeChange()">
              <option value="messageWindowChatMemory">MessageWindow (by message count)</option>
              <option value="tokenWindowChatMemory">TokenWindow (by token budget)</option>
            </select>
          </div>
          <div class="fg" id="cm-msg-fg">
            <label>Max Messages — <span id="cm-msg-lbl">10</span></label>
            <div class="slider-row">
              <input type="range" id="cm-maxmsg" min="2" max="50" step="1" value="10" oninput="document.getElementById('cm-msg-lbl').textContent=this.value;document.getElementById('cm-msg-sv').textContent=this.value">
              <div class="sv" id="cm-msg-sv">10</div>
            </div>
          </div>
          <div class="fg" id="cm-tok-fg" style="display:none">
            <label>Max Tokens — <span id="cm-tok-lbl">2000</span></label>
            <div class="slider-row">
              <input type="range" id="cm-maxtok" min="500" max="8000" step="500" value="2000" oninput="document.getElementById('cm-tok-lbl').textContent=this.value;document.getElementById('cm-tok-sv').textContent=this.value">
              <div class="sv" id="cm-tok-sv">2000</div>
            </div>
          </div>
          <div class="fg">
            <div class="tog-row">
              <label class="tog"><input type="checkbox" id="cm-peruser"><span class="tog-sl"></span></label>
              <span>Per-User Memory Isolation</span>
            </div>
          </div>
          <div class="fg" id="cm-uid-fg" style="display:none">
            <label>User ID</label>
            <input type="text" id="cm-userid" value="user_alice">
          </div>
          <div id="cm-peruser-check" style="display:none">
            <script>document.getElementById('cm-peruser').addEventListener('change',function(){
              document.getElementById('cm-uid-fg').style.display=this.checked?'block':'none';
            });</script>
          </div>
        </div>
      </div>
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">Configuration Code</div></div>
        <div class="card-bd">
<div class="code-block"><span class="cf">agent</span>({
  <span class="cp">CHATMODEL</span>: chatModel,
  <span class="cp">CHATMEMORY</span>: {
    <span class="cp">MAXMESSAGES</span>: <span class="cn">10</span>,
    <span class="cp">PERUSER</span>: <span class="cb">false</span>
  }
})</div>
        </div>
      </div>
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📊</span><div class="card-hd-title">Session Stats</div></div>
        <div class="card-bd">
          <div class="stats">
            <div class="stat"><div class="sv2" id="cm-stat-turns">0</div><div class="sl">Turns</div></div>
            <div class="stat"><div class="sv2" id="cm-stat-ms">0ms</div><div class="sl">Last Response</div></div>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<!-- ══════════════════════════════════════════════════════════
     5. GUARDRAILS
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-guardrails">
  <div class="grid2">

    <div class="intro span2">
      <h2>🛡️ Guardrails</h2>
      <p>Guardrails enforce content policies at the application layer. Use a <strong>system-prompt guardrail</strong> to instruct the model to refuse harmful requests, or a <strong>code-level PII guardrail</strong> to scan and redact sensitive data before it reaches the user.</p>
    </div>

    <!-- Left: Controls -->
    <div>
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">⚙️</span><div class="card-hd-title">Safety Configuration</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>Provider</label>
            <select id="gr-provider" onchange="grProviderChange()">
              <option value="anthropic">Anthropic Claude</option>
              <option value="openai">OpenAI GPT-4</option>
              <option value="mistral">Mistral AI</option>
            </select>
          </div>
          <div class="fg">
            <div class="callout">
              <strong>System Prompt Guardrail</strong> — A safety system prompt is injected via <code>aiSvc.systemMessage("...")</code> after agent creation, instructing the model to refuse harmful requests and keep responses family-friendly.
            </div>
            <div class="tog-row">
              <label class="tog"><input type="checkbox" id="gr-safe" checked><span class="tog-sl"></span></label>
              <span>Enable guardrail system prompt</span>
            </div>
          </div>
          <div class="fg">
            <label>Test Mode</label>
            <select id="gr-mode">
              <option value="compare">Side-by-side Comparison (guardrail ON vs OFF)</option>
              <option value="single">Single Run</option>
            </select>
          </div>
          <div class="fg">
            <label>Prompt</label>
            <textarea id="gr-prompt" rows="3">Write a short, fun story about a group of pirates looking for treasure.</textarea>
          </div>
          <div class="fg">
            <label>Try these test prompts</label>
            <div class="btn-row" style="margin-top:4px">
              <button class="btn btn-outline" style="font-size:11px" onclick="grSetPrompt('Tell me a joke.')">Joke</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="grSetPrompt('Explain the French Revolution in 3 sentences.')">History</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="grSetPrompt('Write a bedtime story for a 5-year-old.')">Children story</button>
            </div>
          </div>
          <div class="btn-row">
            <button class="btn btn-primary" id="gr-run" onclick="grRun()">
              <div class="spin" id="gr-spin"></div>
              ▶ Run
            </button>
          </div>
        </div>
      </div>

      <div class="card" style="margin-top:16px">
        <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">Code</div></div>
        <div class="card-bd">
<div class="code-block"><span class="cc">// Guardrails via agent() API — system prompt + output guardrails</span>
<span class="cc">// OUTPUTGUARDRAILS takes an array of absolute CFC file paths</span>
piiPath = <span class="cf">expandPath</span>(<span class="cs">"/aiTesting/demo/g.cfc"</span>);
aiSvc = <span class="cf">agent</span>({
  <span class="cp">CHATMODEL</span>: <span class="cf">ChatModel</span>({ ... }),
  <span class="cp">OUTPUTGUARDRAILS</span>: [piiPath]
});
aiSvc.<span class="cf">systemMessage</span>(<span class="cs">"Refuse harmful, illegal, or inappropriate requests."</span>);
response = aiSvc.<span class="cf">chat</span>(userPrompt);
<span class="cc">// Output guardrail validate() runs automatically before returning</span>
<span class="cc">// If guardrail blocks, an exception is thrown</span></div>
        </div>
      </div>
    </div>

    <!-- Right: Results -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📊</span><div class="card-hd-title">Results</div></div>
        <div class="card-bd">
          <div id="gr-out"><span class="out-empty" style="color:var(--muted);font-style:italic">Run a test to see results…</span></div>
          <div class="meta-row" id="gr-meta" style="display:none">
            <span class="badge b-ok">OK</span>
            <span class="timing" id="gr-time"></span>
          </div>
        </div>
      </div>
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🔍</span><div class="card-hd-title">Provider Safety Matrix</div></div>
        <div class="card-bd">
          <table style="width:100%;font-size:12px;border-collapse:collapse">
            <thead>
              <tr style="color:var(--muted);text-align:left;border-bottom:1px solid var(--border)">
                <th style="padding:6px 8px">Provider</th>
                <th style="padding:6px 8px">Safety Param</th>
                <th style="padding:6px 8px">Type</th>
              </tr>
            </thead>
            <tbody>
              <tr style="border-bottom:1px solid var(--border)">
                <td style="padding:6px 8px;font-weight:700">Mistral</td>
                <td style="padding:6px 8px"><code style="background:var(--surf2);padding:1px 6px;border-radius:4px;font-size:11px">safePrompt</code></td>
                <td style="padding:6px 8px"><span class="badge b-inf">Boolean</span></td>
              </tr>
              <tr style="border-bottom:1px solid var(--border)">
                <td style="padding:6px 8px;font-weight:700">Gemini</td>
                <td style="padding:6px 8px"><code style="background:var(--surf2);padding:1px 6px;border-radius:4px;font-size:11px">safetySettings</code></td>
                <td style="padding:6px 8px"><span class="badge b-warn">Enum</span></td>
              </tr>
              <tr style="border-bottom:1px solid var(--border)">
                <td style="padding:6px 8px;font-weight:700">OpenAI</td>
                <td style="padding:6px 8px"><span style="color:var(--muted)">Model-side</span></td>
                <td style="padding:6px 8px"><span class="badge b-ok">Built-in</span></td>
              </tr>
              <tr>
                <td style="padding:6px 8px;font-weight:700">Anthropic</td>
                <td style="padding:6px 8px"><span style="color:var(--muted)">Constitutional AI</span></td>
                <td style="padding:6px 8px"><span class="badge b-ok">Built-in</span></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

  </div>

    <!-- PII Guardrail — full-width row -->
    <div class="span2">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🔒</span><div class="card-hd-title">Code-Level PII Guardrail</div></div>
        <div class="card-bd">
          <p style="font-size:13px;color:var(--muted);margin:0 0 14px">A <strong>code-level guardrail</strong> runs after the LLM responds, scanning the output for PII before it reaches the user. Use the demo below to see it in action.</p>
          <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px">

            <div>
              <div style="font-weight:700;font-size:13px;margin-bottom:8px">Demo: LLM → PII Guardrail</div>
              <div class="fg">
                <label>Provider</label>
                <select id="grp-provider">
                  <option value="anthropic">Anthropic Claude</option>
                  <option value="openai">OpenAI GPT-4o-mini</option>
                  <option value="mistral">Mistral AI</option>
                </select>
              </div>
              <div class="fg">
                <label>Prompt (should generate PII)</label>
                <textarea id="grp-prompt" rows="3">Write a brief customer record. Include a name, email address, and some contact details.</textarea>
              </div>
              <div class="btn-row">
                <button class="btn btn-primary" id="grp-run" onclick="grPiiRun()">
                  <div class="spin" id="grp-spin"></div>
                  ▶ Run Demo
                </button>
              </div>
            </div>

            <div>
              <div style="font-weight:700;font-size:13px;margin-bottom:8px">Validate Text Directly</div>
              <div class="fg">
                <label>Text to validate</label>
                <textarea id="grp-text" rows="4" placeholder="Paste any text here to test the PII guardrail…">Contact John Doe at john.doe@example.com or call 555-1234. His SSN is 123-45-6789.</textarea>
              </div>
              <div class="btn-row">
                <button class="btn btn-outline" onclick="grPiiValidate()">🔍 Validate</button>
              </div>
              <div id="grp-validate-out" style="margin-top:10px;font-size:12px"></div>
            </div>

            <div>
              <div style="font-weight:700;font-size:13px;margin-bottom:8px">PiiGuardrail.cfc</div>
<div class="code-block" style="font-size:11px"><span class="ck">struct function</span> <span class="cf">validate</span>(output) {
  <span class="cc">// Block SSN: 123-45-6789</span>
  <span class="ck">if</span> (reFind(<span class="cs">"\d{3}-\d{2}-\d{4}"</span>, text))
    <span class="ck">return</span> { success:<span class="cb">false</span>, errorMessage:<span class="cs">"SSN detected"</span> };

  <span class="cc">// Block credit cards (16-digit)</span>
  <span class="ck">if</span> (reFind(<span class="cs">"\d{4}[\s\-]?\d{4}..."</span>, text))
    <span class="ck">return</span> { success:<span class="cb">false</span>, errorMessage:<span class="cs">"CC detected"</span> };

  <span class="cc">// Redact emails: user@domain → [protected]@domain</span>
  redacted = reReplace(text,
    <span class="cs">"[a-zA-Z0-9._%+\-]+@([\w\-]+\.\w+)"</span>,
    <span class="cs">"[protected]@"</span>, <span class="cs">"ALL"</span>);
  <span class="ck">if</span> (redacted neq text)
    <span class="ck">return</span> { successWith: redacted };

  <span class="ck">return</span> { success: <span class="cb">true</span> }; <span class="cc">// passed</span>
}</div>
            </div>

          </div>

          <div id="grp-out" style="margin-top:16px"></div>
        </div>
      </div>
    </div>

</div>


<!-- ══════════════════════════════════════════════════════════
     6. RAG
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-rag">
  <div class="grid3">

    <div class="intro span2">
      <h2>📚 RAG — Retrieval-Augmented Generation</h2>
      <p>Ingest documents into a vector store, then let the LLM answer questions grounded in that knowledge. ColdFusion's <code>simpleRAG()</code> and <code>agent()</code> INGESTION pipeline handle the full flow: load → split → embed → store → retrieve → generate.</p>
    </div>

    <!-- Left: Controls + pipeline -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">⚙️</span><div class="card-hd-title">Configuration</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>Provider</label>
            <select id="rag-provider">
              <option value="anthropic">Anthropic</option>
              <option value="openai">OpenAI</option>
              <option value="mistral">Mistral</option>
            </select>
          </div>
          <div class="fg">
            <label>RAG Mode</label>
            <select id="rag-mode">
              <option value="simple">Simple RAG (simpleRAG() — zero config)</option>
              <option value="advanced">Advanced RAG (agent() + INGESTION pipeline)</option>
            </select>
          </div>
          <div class="fg">
            <label>Knowledge Base Documents</label>
            <div id="rag-doc-list" style="font-size:12px;color:var(--muted)">Click "Check Docs" to list</div>
          </div>
          <div class="btn-row">
            <button class="btn btn-outline" onclick="ragStatus()">📂 Check Docs</button>
            <button class="btn btn-green" id="rag-ingest" onclick="ragIngest()">
              <div class="spin" id="rag-ingest-spin"></div>
              ⬆ Ingest Docs
            </button>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">❓</span><div class="card-hd-title">Ask a Question</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>Question</label>
            <textarea id="rag-question" rows="2">What is ColdFusion and what AI features does it support in 2025?</textarea>
          </div>
          <div class="fg">
            <label id="rag-quick-label">Quick questions</label>
            <div id="rag-quick-btns" class="btn-row" style="margin-top:4px;flex-wrap:wrap"></div>
            <div id="rag-quick-hint" style="display:none;font-size:11px;color:var(--muted);margin-top:5px">💡 Ask these in sequence — each follow-up is vague on purpose to show the query transformer enriching it with prior context.</div>
          </div>
          <div class="btn-row">
            <button class="btn btn-primary" id="rag-ask" onclick="ragAsk()">
              <div class="spin" id="rag-ask-spin"></div>
              ▶ Ask
            </button>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">ColdFusion Code</div></div>
        <div class="card-bd">
<div class="code-block"><span class="cc">// Simple RAG — simpleRAG(source, chatModel, options)</span>
chatModel = <span class="cf">ChatModel</span>({ <span class="cp">PROVIDER</span>:<span class="cs">"openai"</span>, <span class="cp">APIKEY</span>:apiKey, <span class="cp">MODELNAME</span>:<span class="cs">"gpt-4o-mini"</span> });
ragBot = <span class="cf">simpleRAG</span>(<span class="cs">"./docs/"</span>, chatModel, { <span class="cp">chunkSize</span>:500, <span class="cp">chunkOverlap</span>:100 });
ragBot.<span class="cf">ingest</span>(); <span class="cc">// synchronous — runs once, cache in application scope</span>
answer = ragBot.<span class="cf">ask</span>(<span class="cs">"What is the return policy?"</span>);
<span class="cf">writeOutput</span>(answer);

<span class="cc">// Advanced RAG — agent() with full INGESTION pipeline</span>
ragAgent = <span class="cf">agent</span>({
  <span class="cp">CHATMODEL</span>:  chatModel,
  <span class="cp">CHATMEMORY</span>: { <span class="cp">MAXMESSAGES</span>: <span class="cf">javacast</span>(<span class="cs">"int"</span>, 20) },
  <span class="cp">INGESTION</span>: {
    <span class="cp">source</span>:       <span class="cs">"./docs/"</span>,
    <span class="cp">chunkSize</span>:    500,
    <span class="cp">chunkOverlap</span>: 100,
    <span class="cp">embeddingModel</span>: { <span class="cp">provider</span>:<span class="cs">"mistral"</span>, <span class="cp">modelName</span>:<span class="cs">"mistral-embed"</span>, <span class="cp">apiKey</span>:apiKey },
    <span class="cp">vectorStoreIngestor</span>: { <span class="cp">vectorStore</span>: { <span class="cp">provider</span>:<span class="cs">"INMEMORY"</span> } }
  }
});
ragAgent.<span class="cf">ingest</span>(); <span class="cc">// synchronous</span>
resp = ragAgent.<span class="cf">chat</span>(<span class="cs">"What is the return policy?"</span>); <span class="cc">// stateful — remembers conversation</span></div>
        </div>
      </div>
    </div>

    <!-- Right: Answer + pipeline visual -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">💡</span><div class="card-hd-title">RAG Answer</div></div>
        <div class="card-bd">
          <div class="out" id="rag-out"><span class="out-empty">Ingest documents first, then ask a question…</span></div>
          <div class="meta-row" id="rag-meta" style="display:none">
            <span class="badge b-ok">Grounded Response</span>
            <span class="timing" id="rag-time"></span>
            <span class="badge b-inf" id="rag-mode-badge"></span>
            <span class="badge b-warn" id="rag-tokens" style="display:none"></span>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🔄</span><div class="card-hd-title">RAG Pipeline</div></div>
        <div class="card-bd">
          <div class="step-row"><div class="step-num">1</div><div class="step-txt"><strong>Load</strong> — FileSystemLoader reads .txt / .pdf / .docx</div></div>
          <div class="step-row"><div class="step-num">2</div><div class="step-txt"><strong>Split</strong> — RecursiveSplitter (1000 chars, 200 overlap)</div></div>
          <div class="step-row"><div class="step-num">3</div><div class="step-txt"><strong>Embed</strong> — EmbeddingModel converts chunks → vectors</div></div>
          <div class="step-row"><div class="step-num">4</div><div class="step-txt"><strong>Store</strong> — Vectors saved in InMemoryVectorStore</div></div>
          <div class="step-row"><div class="step-num">5</div><div class="step-txt"><strong>Retrieve</strong> — Top-K similar chunks fetched for query</div></div>
          <div class="step-row" style="margin-bottom:0"><div class="step-num">6</div><div class="step-txt"><strong>Generate</strong> — LLM answers using retrieved context</div></div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📂</span><div class="card-hd-title">Supported Document Formats</div></div>
        <div class="card-bd" style="display:flex;flex-wrap:wrap;gap:6px">
          <span class="mtag">.txt</span><span class="mtag">.md</span><span class="mtag">.pdf</span>
          <span class="mtag">.docx</span><span class="mtag">.xlsx</span><span class="mtag">.pptx</span>
          <span class="mtag">.html</span><span class="mtag">.csv</span><span class="mtag">.json</span>
          <span class="mtag">.xml</span><span class="mtag">.zip</span><span class="mtag">URL</span>
        </div>
      </div>
    </div>

  </div>
</div>

<!-- ══════════════════════════════════════════════════════════
     7. STREAMING
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-streaming">
  <div class="grid2">

    <div class="intro span2">
      <h2>⚡ Streaming</h2>
      <p>Stream AI responses token-by-token using <code>agent()</code> with <code>STREAMINGHANDLER</code>. The <code>StreamHandler2.cfc</code> receives each token via <code>onPartialResponse()</code> and writes it to a log file via <code>writeLog()</code>. The browser polls <code>stream_poll.cfm</code> every 200ms which parses the log to display tokens in real-time.</p>
    </div>

    <!-- Left: Controls + Code -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">⚙️</span><div class="card-hd-title">Configuration</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>Provider</label>
            <select id="st-provider">
              <option value="anthropic">Anthropic Claude</option>
              <option value="openai">OpenAI GPT-4o-mini</option>
              <option value="mistral">Mistral AI</option>
            </select>
          </div>
          <div class="fg">
            <label>Prompt</label>
            <textarea id="st-prompt" rows="3">Tell me a fun fact about ColdFusion in 3-4 sentences.</textarea>
          </div>
          <div class="fg">
            <label>Quick prompts</label>
            <div class="btn-row" style="margin-top:4px;flex-wrap:wrap">
              <button class="btn btn-outline" style="font-size:11px" onclick="stSetPrompt('Write a short poem about programming.')">Poem</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="stSetPrompt('Explain how neural networks work in simple terms.')">Neural nets</button>
              <button class="btn btn-outline" style="font-size:11px" onclick="stSetPrompt('Give me 5 tips for writing better CFML code.')">CFML tips</button>
            </div>
          </div>
          <div class="btn-row">
            <button class="btn btn-primary" id="st-run" onclick="stRun()">
              <div class="spin" id="st-spin"></div>
              ▶ Start Streaming
            </button>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">ColdFusion Code</div></div>
        <div class="card-bd">
<div class="code-block"><span class="cc">// STREAMINGHANDLER takes a dot-delimited CFC path from wwwroot</span>
chatModel = <span class="cf">ChatModel</span>({ <span class="cp">PROVIDER</span>:provider, <span class="cp">APIKEY</span>:apiKey, <span class="cp">MODELNAME</span>:modelName });

<span class="cc">// Run in cfthread so the request returns immediately</span>
<span class="cc">// and the browser can start polling for tokens</span>
<span class="cf">thread</span> name=<span class="cs">"streamThread"</span> action=<span class="cs">"run"</span> {
  aiService = <span class="cf">agent</span>({
    <span class="cp">CHATMODEL</span>:        chatModel,
    <span class="cp">STREAMINGHANDLER</span>: <span class="cs">"aiTesting.demo.StreamHandler2"</span>
  });
  response = aiService.<span class="cf">chat</span>(prompt);
}

<span class="cc">// StreamHandler2.cfc callbacks (write to log via writeLog):</span>
<span class="cc">//   onPartialResponse(token)  — fires per token, appends to buffer</span>
<span class="cc">//   onCompleteResponse(resp)  — fires when done</span>
<span class="cc">//   onError(err)              — fires on failure</span>
<span class="cc">// Browser polls stream_poll.cfm every 200ms for real-time display</span></div>
        </div>
      </div>
    </div>

    <!-- Right: Live output -->
    <div style="display:flex;flex-direction:column;gap:16px">
      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">⚡</span><div class="card-hd-title">Live Token Stream</div></div>
        <div class="card-bd">
          <div id="st-status" style="font-size:12px;color:var(--muted);margin-bottom:8px;min-height:18px"></div>
          <div id="st-out" class="out" style="white-space:pre-wrap;min-height:120px"><span class="out-empty">Start streaming to see tokens arrive in real-time…</span></div>
          <div class="meta-row" id="st-meta" style="display:none;margin-top:10px">
            <span class="badge b-ok">Complete</span>
            <span class="badge b-inf" id="st-tokens"></span>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🔄</span><div class="card-hd-title">How It Works</div></div>
        <div class="card-bd">
          <div class="step-row"><div class="step-num">1</div><div class="step-txt"><strong>Reset state</strong> — clear <code>application.streamBuffer</code> and <code>streamDone</code></div></div>
          <div class="step-row"><div class="step-num">2</div><div class="step-txt"><strong>agent() + STREAMINGHANDLER</strong> — <code>StreamHandler2.cfc</code> receives tokens via <code>onPartialResponse()</code></div></div>
          <div class="step-row"><div class="step-num">3</div><div class="step-txt"><strong>Tokens buffered</strong> — each token appended to <code>application.streamBuffer</code> in real-time</div></div>
          <div class="step-row"><div class="step-num">4</div><div class="step-txt"><strong>Browser polls</strong> <code>api/stream_poll.cfm</code> every 200ms, displays tokens as they arrive</div></div>
          <div class="step-row" style="margin-bottom:0"><div class="step-num">5</div><div class="step-txt"><strong>onCompleteResponse()</strong> — sets <code>streamDone=true</code>, browser shows final state</div></div>
        </div>
      </div>
    </div>

  </div>
</div>

<!-- ══════════════════════════════════════════════════════════
     8. MCP
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-mcp">
  <div class="grid3">

    <div class="intro span2">
      <h2>🔌 MCP — Model Context Protocol</h2>
      <p>Connect to any MCP server (local stdio subprocess or remote HTTP) and expose its tools to an LLM. ColdFusion can act as both <strong>MCP Client</strong> and <strong>MCP Server</strong>.</p>
    </div>

    <!-- Left: Controls -->
    <div style="display:flex;flex-direction:column;gap:20px">

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🖧</span><div class="card-hd-title">MCP Connection</div></div>
        <div class="card-bd">
          <div class="fg">
            <label>MCP Server</label>
            <select id="mcp-server">
              <option value="custom">Custom CF MCP Server (HTTP)</option>
            </select>
          </div>
          <div class="fg">
            <label>Provider</label>
            <select id="mcp-provider">
              <option value="anthropic">Anthropic</option>
              <option value="openai">OpenAI</option>
              <option value="mistral">Mistral AI</option>
            </select>
          </div>
          <div class="btn-row">
            <button class="btn btn-green" id="mcp-list" onclick="mcpListTools()">
              <div class="spin" id="mcp-list-spin"></div>
              List Tools
            </button>
            <button class="btn btn-outline" onclick="mcpListPrompts()">List Prompts</button>
            <button class="btn btn-outline" onclick="mcpListResources()">List Resources</button>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">🤖</span><div class="card-hd-title">AI Chat via MCP Tools</div></div>
        <div class="card-bd">
          <div class="callout">
            <strong>agent() + MCP</strong> — The LLM discovers tools at runtime and decides which to call based on your prompt.
          </div>
          <div class="fg">
            <label>Quick Prompts</label>
            <div style="display:flex;flex-wrap:wrap;gap:6px;margin-bottom:10px">
              <button class="btn btn-outline" style="font-size:11px;padding:4px 10px" onclick="mcpSetPrompt('Escalate order #99821 — it arrived damaged and I need urgent help filing a support ticket.')">Escalate damaged order</button>
              <button class="btn btn-outline" style="font-size:11px;padding:4px 10px" onclick="mcpSetPrompt('File a high priority ticket for order #77654 — the package has been stuck in transit for 2 weeks with no updates.')">Stuck in transit</button>
              <button class="btn btn-outline" style="font-size:11px;padding:4px 10px" onclick="mcpSetPrompt('I received the wrong item for order #55432. Please escalate this immediately and file a ticket.')">Wrong item received</button>
              <button class="btn btn-outline" style="font-size:11px;padding:4px 10px" onclick="mcpSetPrompt('Order #12345 was marked delivered but never arrived. I need a manager — please file an escalation ticket.')">Not delivered</button>
              <button class="btn btn-outline" style="font-size:11px;padding:4px 10px" onclick="mcpSetPrompt('My device from order #99821 stopped working after 3 days. I want to escalate this warranty issue.')">Warranty escalation</button>
            </div>
          </div>
          <div class="fg">
            <label>Prompt</label>
            <textarea id="mcp-prompt" rows="3">Escalate order #99821 — it arrived damaged and I need urgent help filing a support ticket.</textarea>
          </div>
          <div class="btn-row">
            <button class="btn btn-primary" id="mcp-chat" onclick="mcpAiChat()">
              <div class="spin" id="mcp-chat-spin"></div>
              ▶ Chat with MCP Tools
            </button>
          </div>
        </div>
      </div>

    </div>

    <!-- Right: Response first, then collapsible reference cards -->
    <div style="display:flex;flex-direction:column;gap:20px">

      <div class="card">
        <div class="card-hd"><span class="card-hd-icon">💬</span><div class="card-hd-title">AI Response</div></div>
        <div class="card-bd">
          <div class="out" id="mcp-chat-out"><span class="out-empty">Chat response will appear here…</span></div>
          <div id="mcp-chat-tools" style="margin-top:10px"></div>
          <div class="meta-row" id="mcp-chat-meta" style="display:none">
            <span class="badge b-ok">MCP-Assisted</span>
            <span class="timing" id="mcp-chat-time"></span>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd" style="cursor:pointer" onclick="mcpToggle('mcp-disc-body','mcp-disc-chev')">
          <span class="card-hd-icon">🔧</span>
          <div class="card-hd-title">Discovered: Tools / Prompts / Resources</div>
          <span id="mcp-disc-chev" style="margin-left:auto;color:var(--muted);font-size:12px">▼</span>
        </div>
        <div id="mcp-disc-body" class="card-bd">
          <div id="mcp-tools-out"><span class="out-empty" style="color:var(--muted);font-size:13px;font-style:italic">Click "List Tools" to discover available MCP tools…</span></div>
          <div class="meta-row" id="mcp-tools-meta" style="display:none">
            <span class="timing" id="mcp-tools-time"></span>
            <span class="badge b-inf" id="mcp-tools-count"></span>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd" style="cursor:pointer" onclick="mcpToggle('mcp-client-body','mcp-client-chev')">
          <span class="card-hd-icon">💻</span>
          <div class="card-hd-title">MCP Client (HTTP)</div>
          <span id="mcp-client-chev" style="margin-left:auto;color:var(--muted);font-size:12px">▼</span>
        </div>
        <div id="mcp-client-body" class="card-bd" style="display:none">
<div class="code-block"><span class="cc">// HTTP transport — connect to any MCP-compliant HTTP server</span>
mcpClient = <span class="cf">McpClient</span>({
  transport: { type:<span class="cs">"HTTP"</span>, URL:<span class="cs">"http://host/mcp/server.cfm"</span> },
  clientInfo: { name:<span class="cs">"nexora-mcp-client"</span>, version:<span class="cs">"1.0.0"</span> },
  initializationTimeout: <span class="cn">30</span>,
  requestTimeout: <span class="cn">30</span>
});

<span class="cc">// Discover tools at runtime</span>
tools = mcpClient.<span class="cf">listTools</span>();

<span class="cc">// Use as agent tool — LLM auto-calls tools</span>
aiAgent = <span class="cf">agent</span>({
  <span class="cp">CHATMODEL</span>: chatModel,
  <span class="cp">TOOLS</span>:     [{ <span class="cp">MCPCLIENT</span>: [mcpClient] }]
});</div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd" style="cursor:pointer" onclick="mcpToggle('mcp-server-body','mcp-server-chev')">
          <span class="card-hd-icon">🖧</span>
          <div class="card-hd-title">MCP Server (CFC)</div>
          <span id="mcp-server-chev" style="margin-left:auto;color:var(--muted);font-size:12px">▼</span>
        </div>
        <div id="mcp-server-body" class="card-bd" style="display:none">
<div class="code-block"><span class="cc">// Expose a CFC as an MCP server tool</span>
<span class="cc">// mcp/server.cfm</span>
<span class="ck">if</span> (!structKeyExists(application, <span class="cs">"nexoraMcpServer"</span>)) {
  application.nexoraMcpServer = <span class="cf">McpServer</span>({
    serverInfo:   { name:<span class="cs">"nexora-server"</span>, version:<span class="cs">"1.0.0"</span> },
    capabilities: { tools:<span class="cb">true</span> },
    tools:        [{ cfc:<span class="cs">"MyTool"</span> }]
  });
}
application.nexoraMcpServer.<span class="cf">handleRequest</span>();

<span class="cc">// MyTool.cfc — annotate functions with @mcpTool</span>
<span class="cc">/**
 * @mcpTool
 * @mcpDescription File a support escalation ticket and send email
 */</span>
<span class="ck">string function</span> <span class="cf">fileTicket</span>(required string summary, string orderId=<span class="cs">""</span>, string priority=<span class="cs">"high"</span>) { ... }</div>
        </div>
      </div>

      <div class="card">
        <div class="card-hd" style="cursor:pointer" onclick="mcpToggle('mcp-transport-body','mcp-transport-chev')">
          <span class="card-hd-icon">🔄</span>
          <div class="card-hd-title">MCP Transport Types</div>
          <span id="mcp-transport-chev" style="margin-left:auto;color:var(--muted);font-size:12px">▼</span>
        </div>
        <div id="mcp-transport-body" class="card-bd" style="display:none">
          <table style="width:100%;border-collapse:collapse;font-size:12px">
            <thead><tr style="border-bottom:1px solid var(--border)">
              <th style="padding:5px 8px;text-align:left">Transport</th>
              <th style="padding:5px 8px;text-align:left">Use Case</th>
              <th style="padding:5px 8px;text-align:left">Builder</th>
            </tr></thead>
            <tbody>
              <tr style="border-bottom:1px solid var(--border)">
                <td style="padding:5px 8px;font-weight:700">stdio</td>
                <td style="padding:5px 8px;color:var(--muted)">Local subprocess (node, java, exe)</td>
                <td style="padding:5px 8px"><code style="font-size:10px;background:var(--surf2);padding:1px 5px;border-radius:3px">McpTransportBuilder("stdio")</code></td>
              </tr>
              <tr>
                <td style="padding:5px 8px;font-weight:700">http</td>
                <td style="padding:5px 8px;color:var(--muted)">Remote HTTP/SSE server</td>
                <td style="padding:5px 8px"><code style="font-size:10px;background:var(--surf2);padding:1px 5px;border-radius:3px">McpTransportBuilder("http")</code></td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

    </div>

  </div>
</div>

<!-- ══════════════════════════════════════════════════════════
     8. SYSTEM MESSAGE
══════════════════════════════════════════════════════════ -->
<div class="panel" id="tab-systemmsg">
  <div class="grid2">

    <div class="intro span2">
      <h2>🗣️ SystemMessage</h2>
      <p>Set a persona or role on the agent with <code>agent().systemMessage()</code>. It shapes every response — the same question gets a completely different answer depending on the system message.</p>
    </div>

    <!-- Config card — full width -->
    <div class="card span2">
      <div class="card-hd"><span class="card-hd-icon">🎭</span><div><div class="card-hd-title">ColdFusion Support Bot</div><div class="card-hd-sub">Only answers ColdFusion questions — redirects everything else</div></div></div>
      <div class="card-bd" style="display:grid;grid-template-columns:1fr 1fr;gap:18px;align-items:start">
        <div>
          <div class="fg">
            <label>Provider</label>
            <select id="sm-provider">
              <option value="anthropic">Anthropic Claude</option>
              <option value="openai">OpenAI (gpt-4o-mini)</option>
              <option value="mistral">Mistral</option>
            </select>
          </div>
          <div class="fg">
            <label>Persona</label>
            <select id="sm-preset" onchange="smLoadPreset()">
              <option value="cfsupport" selected>💡 ColdFusion Support Bot</option>
              <option value="pirate">🏴‍☠️ Pirate Mode</option>
              <option value="reviewer">🔍 Strict Code Reviewer</option>
              <option value="concise">⚡ Ultra-Concise Mode</option>
              <option value="shakespeare">📜 Shakespearean Mode</option>
              <option value="custom">✏️ Custom</option>
            </select>
          </div>
          <div class="btn-row" style="margin-top:4px">
            <button class="btn btn-primary" id="sm-run" onclick="smRunBoth()">
              <div class="spin" id="sm-spin"></div>
              ▶ Run Both Prompts
            </button>
          </div>
        </div>
        <div>
          <div class="fg">
            <label>System Message (active persona)</label>
            <textarea id="sm-sysmsg" rows="5"></textarea>
          </div>
        </div>
      </div>
    </div>

    <!-- Chat 1: CF question -->
    <div class="card">
      <div class="card-hd"><span class="card-hd-icon">✅</span><div><div class="card-hd-title">On-Topic Prompt</div><div class="card-hd-sub">Related to ColdFusion — bot should answer fully</div></div></div>
      <div class="card-bd">
        <div class="fg">
          <label>Prompt</label>
          <input type="text" id="sm-prompt-cf" value="Tell me about ColdFusion 2025 AI features">
        </div>
        <div class="out" id="sm-out-cf" style="white-space:pre-wrap;min-height:80px"><span class="out-empty">Response will appear here…</span></div>
        <div class="meta-row" id="sm-meta-cf" style="display:none">
          <span class="badge b-ok">Answered</span>
          <span class="timing" id="sm-time-cf"></span>
        </div>
      </div>
    </div>

    <!-- Chat 2: Off-topic question -->
    <div class="card">
      <div class="card-hd"><span class="card-hd-icon">🚫</span><div><div class="card-hd-title">Off-Topic Prompt</div><div class="card-hd-sub">Unrelated to ColdFusion — bot should redirect</div></div></div>
      <div class="card-bd">
        <div class="fg">
          <label>Prompt</label>
          <input type="text" id="sm-prompt-offtopic" value="Tell me about Bangalore's weather">
        </div>
        <div class="out" id="sm-out-offtopic" style="white-space:pre-wrap;min-height:80px"><span class="out-empty">Response will appear here…</span></div>
        <div class="meta-row" id="sm-meta-offtopic" style="display:none">
          <span class="badge b-warn">Redirected</span>
          <span class="timing" id="sm-time-offtopic"></span>
        </div>
      </div>
    </div>

    <!-- Code preview -->
    <div class="card span2">
      <div class="card-hd"><span class="card-hd-icon">📄</span><div class="card-hd-title">ColdFusion Code</div></div>
      <div class="card-bd">
<div class="code-block"><span class="cc">// Create agent and set a system message to define its persona</span>
chatModel = <span class="cf">ChatModel</span>({ <span class="cp">PROVIDER</span>:<span class="cs">"openai"</span>, <span class="cp">APIKEY</span>:apiKey, <span class="cp">MODELNAME</span>:<span class="cs">"gpt-4o-mini"</span> });
aiService = <span class="cf">agent</span>({ <span class="cp">CHATMODEL</span>:chatModel, <span class="cp">CHATMEMORY</span>:{ MAXMESSAGES:<span class="cn">10</span> } });

<span class="cc">// systemMessage() shapes every response — same question, different persona = different answer</span>
aiService.<span class="cf">systemMessage</span>(<span class="cs">"You are a ColdFusion expert support bot. Answer CF questions
in detail. For unrelated topics, politely redirect back to ColdFusion."</span>);

r1 = aiService.<span class="cf">chat</span>(<span class="cs">"Tell me about ColdFusion 2025 AI features"</span>);   <span class="cc">// → full answer</span>
r2 = aiService.<span class="cf">chat</span>(<span class="cs">"Tell me about Bangalore's weather"</span>);            <span class="cc">// → redirect</span></div>
      </div>
    </div>

  </div>
</div>

</div><!-- /wrap -->

<script>
// ─────────────────────────────────────────────
// TAB SWITCHING
// ─────────────────────────────────────────────
document.querySelectorAll('.tab').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(b => b.classList.remove('on'));
    document.querySelectorAll('.panel').forEach(p => p.classList.remove('on'));
    btn.classList.add('on');
    document.getElementById('tab-' + btn.dataset.tab).classList.add('on');
  });
});

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────
function setLoading(spinId, btnId, on) {
  const sp = document.getElementById(spinId);
  const bt = document.getElementById(btnId);
  if (sp) sp.style.display = on ? 'block' : 'none';
  if (bt) bt.disabled = on;
}

// Normalize CF JSON keys: ALL-CAPS keys become lowercase (ColdFusion uppercases struct keys)
// We just use lowercase everywhere — all JS references use lowercase keys
function lcKeys(obj) {
  if (Array.isArray(obj)) return obj.map(lcKeys);
  if (obj !== null && typeof obj === 'object') {
    return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k.toLowerCase(), lcKeys(v)]));
  }
  return obj;
}

async function apiPost(endpoint, payload) {
  const resp = await fetch('api/' + endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  });
  const text = await resp.text();
  try {
    return lcKeys(JSON.parse(text));
  } catch(e) {
    // Response was not valid JSON — surface the raw text as the error
    return { success: false, error: 'Server returned non-JSON response', detail: text.substring(0, 800) };
  }
}

function errMsg(data) {
  return data.error || data.detail || JSON.stringify(data);
}

function esc(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function formatJSON(obj) {
  const s = JSON.stringify(obj, null, 2);
  return s.replace(/("[\w]+")\s*:/g, '<span class="jk">$1</span>:')
          .replace(/:\s*(".*?")/g, ': <span class="js">$1</span>')
          .replace(/:\s*(\d+\.?\d*)/g, ': <span class="jn">$1</span>')
          .replace(/:\s*(true|false)/g, ': <span class="jb">$1</span>')
          .replace(/:\s*(null)/g,       ': <span class="jnull">$1</span>');
}

// ─────────────────────────────────────────────
// 1. CHATMODELCONFIG
// ─────────────────────────────────────────────
const MC_MODELS = {
  openai:      ['gpt-4o-mini', 'gpt-4o', 'gpt-3.5-turbo'],
  anthropic:   ['claude-sonnet-4-6', 'claude-haiku-4-5-20251001', 'claude-opus-4-6'],
  mistral:     ['mistral-large-latest', 'mistral-medium-latest', 'mistral-small-latest'],
  azureopenai: ['gpt-4o-mini', 'gpt-4o', 'gpt-35-turbo']
};

function mcUpdateModels() {
  const pv = document.getElementById('mc-provider').value;
  const ms = document.getElementById('mc-model');
  ms.innerHTML = MC_MODELS[pv].map(m => `<option value="${m}">${m}</option>`).join('');
  mcUpdateCode();
}

function mcUpdateTemp()   { const v = document.getElementById('mc-temp').value; document.getElementById('mc-temp-lbl').textContent = v; document.getElementById('mc-temp-sv').textContent = v; mcUpdateCode(); }
function mcUpdateTokens() { const v = document.getElementById('mc-tokens').value; document.getElementById('mc-tok-lbl').textContent = v; document.getElementById('mc-tok-sv').textContent = v; mcUpdateCode(); }
function mcFormatChange() {
  const rf = document.getElementById('mc-format').value;
  // Switch to a JSON-friendly prompt when JSON mode is selected
  if (rf === 'JSON') {
    document.getElementById('mc-prompt').value = 'Return a JSON object describing a planet in our solar system with fields: name, diameter_km, moons, has_rings, distance_from_sun_au, fun_fact.';
  } else if (document.getElementById('mc-prompt').value.startsWith('Return a JSON')) {
    document.getElementById('mc-prompt').value = 'Tell me a fascinating fact about space in 2\u20133 sentences.';
  }
  mcUpdateCode();
}

function mcUpdateCode() {
  const pv = document.getElementById('mc-provider').value;
  const mn = document.getElementById('mc-model').value || MC_MODELS[pv][0];
  const tp = document.getElementById('mc-temp').value;
  const tk = document.getElementById('mc-tokens').value;
  const rf = document.getElementById('mc-format').value;

  const azLine = pv === 'azureopenai' ? `\n  <span class="cp">ENDPOINT</span>:  <span class="cs">"https://your-resource.openai.azure.com/"</span>,` : '';
  const rfLine = rf !== 'text' ? `\n  <span class="cp">responseFormat</span>: <span class="cs">"${rf}"</span>,` : '';

  document.getElementById('mc-code').innerHTML =
    `<span class="cf">ChatModel</span>({` +
    `\n  <span class="cp">PROVIDER</span>:    <span class="cs">"${pv}"</span>,` +
    azLine +
    `\n  <span class="cp">APIKEY</span>:      <span class="cs">application.apiKey</span>,` +
    `\n  <span class="cp">MODELNAME</span>:   <span class="cs">"${mn}"</span>,` +
    `\n  <span class="cp">temperature</span>: <span class="cn">${tp}</span>,` +
    `\n  <span class="cp">maxTokens</span>:   <span class="cn">${tk}</span>` +
    rfLine +
    `\n})`;
}

async function mcRun() {
  setLoading('mc-spin', 'mc-run', true);
  document.getElementById('mc-out').innerHTML = '<span class="out-empty">Thinking…</span>';
  document.getElementById('mc-meta').style.display = 'none';
  try {
    const data = await apiPost('modelconfig.cfm', {
      provider:       document.getElementById('mc-provider').value,
      model:          document.getElementById('mc-model').value,
      temperature:    parseFloat(document.getElementById('mc-temp').value),
      maxTokens:      parseInt(document.getElementById('mc-tokens').value),
      responseFormat: document.getElementById('mc-format').value,
      prompt:         document.getElementById('mc-prompt').value
    });
    if (data.success) {
      const rf = document.getElementById('mc-format').value;
      if (rf === 'JSON' && data.message) {
        try {
          const parsed = JSON.parse(data.message);
          document.getElementById('mc-out').innerHTML = `<pre style="margin:0;white-space:pre-wrap;font-size:12px">${formatJSON(parsed)}</pre>`;
        } catch(je) {
          document.getElementById('mc-out').textContent = data.message;
        }
      } else {
        document.getElementById('mc-out').textContent = data.message;
      }
      document.getElementById('mc-meta').style.display = 'flex';
      document.getElementById('mc-time').textContent = data.elapsed + 'ms';
    } else {
      document.getElementById('mc-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
    }
  } catch(e) {
    document.getElementById('mc-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('mc-spin', 'mc-run', false);
}

function mcReset() {
  document.getElementById('mc-temp').value = 0.7; mcUpdateTemp();
  document.getElementById('mc-tokens').value = 500; mcUpdateTokens();
  document.getElementById('mc-format').value = 'text';
  document.getElementById('mc-prompt').value = 'Tell me a fascinating fact about space in 2–3 sentences.';
  mcUpdateCode();
}

// ── Parameter Explorer ────────────────────────
var mcExpCurTok = 30;
var MC_EXP_TOK_HINTS = {
  '30' : '30 tokens ≈ 20 words — response cuts off mid-sentence',
  '80' : '80 tokens ≈ 60 words — partial answer, no conclusion',
  '200': '200 tokens ≈ 150 words — mostly complete',
  '500': '500 tokens ≈ 375 words — full detailed answer'
};
var mcExpTempN = 0, mcExpTokN = 0;

function mcExpSetTok(btn) {
  document.querySelectorAll('.exp-tok-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  mcExpCurTok = parseInt(btn.dataset.tok);
  document.getElementById('exp-tok-hint').textContent = MC_EXP_TOK_HINTS[btn.dataset.tok] || '';
}

async function mcExpRunTemp() {
  const temp = parseFloat(document.getElementById('exp-temp').value);
  document.getElementById('exp-temp-sv').textContent = temp;
  setLoading('exp-temp-spin', 'exp-temp-run', true);
  document.getElementById('exp-temp-out').innerHTML = '<span class="out-empty">Thinking…</span>';
  try {
    const data = await apiPost('modelconfig.cfm', {
      provider: document.getElementById('mc-provider').value,
      model:    document.getElementById('mc-model').value,
      temperature:    temp,
      maxTokens:      300,
      responseFormat: 'text',
      prompt: 'Suggest 3 creative slogans for a customer loyalty rewards program'
    });
    mcExpTempN++;
    const badge = document.getElementById('exp-temp-badge');
    badge.style.display = 'inline-flex';
    badge.textContent = 'run #' + mcExpTempN + ' @ temp ' + temp;
    document.getElementById('exp-temp-out').textContent = data.success ? data.message : 'Error: ' + errMsg(data);
  } catch(e) {
    document.getElementById('exp-temp-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(e.message)}</span>`;
  }
  setLoading('exp-temp-spin', 'exp-temp-run', false);
}

async function mcExpRunTok() {
  setLoading('exp-tok-spin', 'exp-tok-run', true);
  document.getElementById('exp-tok-out').innerHTML = '<span class="out-empty">Thinking…</span>';
  try {
    const data = await apiPost('modelconfig.cfm', {
      provider: document.getElementById('mc-provider').value,
      model:    document.getElementById('mc-model').value,
      temperature:    0.4,
      maxTokens:      mcExpCurTok,
      responseFormat: 'text',
      prompt: 'Walk me through every step of returning a damaged product, from packaging it up to receiving my refund'
    });
    mcExpTokN++;
    const badge = document.getElementById('exp-tok-badge');
    badge.style.display = 'inline-flex';
    badge.textContent = 'run #' + mcExpTokN + ' @ ' + mcExpCurTok + ' tokens';
    document.getElementById('exp-tok-out').textContent = data.success ? data.message : 'Error: ' + errMsg(data);
  } catch(e) {
    document.getElementById('exp-tok-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(e.message)}</span>`;
  }
  setLoading('exp-tok-spin', 'exp-tok-run', false);
}

// ─────────────────────────────────────────────
// 2. FUNCTIONTOOL
// ─────────────────────────────────────────────
function ftSetPrompt(p) { document.getElementById('ft-prompt').value = p; }

async function ftRun() {
  setLoading('ft-spin', 'ft-run', true);
  document.getElementById('ft-out').innerHTML = '<span class="out-empty">Invoking tools…</span>';
  document.getElementById('ft-tools-out').innerHTML = '';
  document.getElementById('ft-meta').style.display = 'none';
  try {
    const data = await apiPost('functiontool.cfm', {
      prompt:   document.getElementById('ft-prompt').value,
      tools:    document.getElementById('ft-tools').value,
      provider: document.getElementById('ft-provider').value
    });
    if (data.success) {
      document.getElementById('ft-out').textContent = data.message || '(no text — model used tools only)';

      // Show tool executions
      let toolHtml = '';
      const results = data.toolresults || [];
      if (results.length > 0) {
        toolHtml += `<div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Tool Executions (${results.length})</div>`;
        results.forEach(r => {
          const argStr = JSON.stringify(r.arguments || {});
          const resStr = typeof r.result === 'object' ? JSON.stringify(r.result, null, 1) : String(r.result);
          toolHtml += `<div class="tool-exec">
            <div class="tex-call">→ ${esc(r.name)}(${esc(argStr)})</div>
            <div class="tex-res">← ${esc(resStr)}</div>
          </div>`;
        });
      }
      document.getElementById('ft-tools-out').innerHTML = toolHtml;
      document.getElementById('ft-meta').style.display = 'flex';
      document.getElementById('ft-time').textContent = data.elapsed + 'ms';
      document.getElementById('ft-toolcount').textContent = (data.toolcount || 0) + ' tool call(s)';

    } else {
      document.getElementById('ft-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
    }
  } catch(e) {
    document.getElementById('ft-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('ft-spin', 'ft-run', false);
}

// ─────────────────────────────────────────────
// 3. CHATMEMORY
// ─────────────────────────────────────────────
let cmTurns = 0;

function cmTypeChange() {
  const t = document.getElementById('cm-type').value;
  document.getElementById('cm-msg-fg').style.display = t.includes('message') ? 'block' : 'none';
  document.getElementById('cm-tok-fg').style.display = t.includes('token')   ? 'block' : 'none';
}

function cmAddMsg(role, text) {
  const msgs = document.getElementById('cm-msgs');
  // Clear placeholder
  if (msgs.querySelector('.out-empty')) msgs.innerHTML = '';
  const icon = role === 'user' ? '👤' : '🤖';
  const div = document.createElement('div');
  div.className = 'msg ' + (role === 'user' ? 'user' : 'asst');
  div.innerHTML = `<div class="av">${icon}</div><div class="bubble">${esc(text)}</div>`;
  msgs.appendChild(div);
  msgs.scrollTop = msgs.scrollHeight;
}

async function cmSend() {
  const input = document.getElementById('cm-input');
  const msg = input.value.trim();
  if (!msg) return;
  input.value = '';
  cmAddMsg('user', msg);
  setLoading('cm-spin', 'cm-send', true);
  try {
    const perUser = document.getElementById('cm-peruser').checked;
    const memType = document.getElementById('cm-type').value;
    const data = await apiPost('chatmemory.cfm', {
      action:     'chat',
      message:    msg,
      memoryType: memType,
      maxMessages: parseInt(document.getElementById('cm-maxmsg').value),
      maxTokens:   parseInt(document.getElementById('cm-maxtok').value),
      perUser:     perUser,
      userId:      document.getElementById('cm-userid').value,
      provider:    document.getElementById('cm-provider').value
    });
    if (data.success) {
      cmAddMsg('assistant', data.message);
      cmTurns++;
      document.getElementById('cm-stat-turns').textContent = cmTurns;
      document.getElementById('cm-stat-ms').textContent = data.elapsed + 'ms';
    } else {
      cmAddMsg('assistant', 'Error: ' + errMsg(data));
    }
  } catch(e) {
    cmAddMsg('assistant', 'Network error: ' + e.message);
  }
  setLoading('cm-spin', 'cm-send', false);
}

async function cmClear() {
  const memType = document.getElementById('cm-type').value;
  const maxMsg  = parseInt(document.getElementById('cm-maxmsg').value);
  const perUser = document.getElementById('cm-peruser').checked;
  await apiPost('chatmemory.cfm', { action:'clear', memoryType: memType, maxMessages: maxMsg, perUser: perUser });
  document.getElementById('cm-msgs').innerHTML = '<div style="text-align:center;color:var(--muted);font-size:12px;margin:auto">Memory cleared. Start a fresh conversation…</div>';
  cmTurns = 0;
  document.getElementById('cm-stat-turns').textContent = '0';
  document.getElementById('cm-stat-ms').textContent = '0ms';
}

async function cmQuick() {
  document.getElementById('cm-input').value = "My name is Alice and I love hiking.";
  await cmSend();
  setTimeout(async () => {
    document.getElementById('cm-input').value = "My favorite sport is tennis.";
    await cmSend();
    setTimeout(async () => {
      document.getElementById('cm-input').value = "What do you know about me so far?";
      await cmSend();
    }, 1000);
  }, 1000);
}

// ─────────────────────────────────────────────
// 5. GUARDRAILS
// ─────────────────────────────────────────────
function grProviderChange() {
  // No provider-specific UI changes needed — guardrail approach is uniform across all providers
}

function grSetPrompt(p) { document.getElementById('gr-prompt').value = p; }

async function grRun() {
  setLoading('gr-spin', 'gr-run', true);
  document.getElementById('gr-out').innerHTML = '<span class="out-empty">Running guardrails test…</span>';
  document.getElementById('gr-meta').style.display = 'none';
  try {
    const pv   = document.getElementById('gr-provider').value;
    const mode = document.getElementById('gr-mode').value;
    const data = await apiPost('guardrails.cfm', {
      provider:     pv,
      mode:         document.getElementById('gr-mode').value,
      prompt:       document.getElementById('gr-prompt').value,
      useGuardrail: document.getElementById('gr-safe').checked
    });
    if (data.success) {
      if (data.mode === 'compare') {
        document.getElementById('gr-out').innerHTML = `
          <div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px">Side-by-side Comparison</div>
          <div class="cmp">
            <div class="cmp-card">
              <div class="cmp-hd safe">✓ Guardrail ON</div>
              <div class="cmp-body">${esc(data.safe.message)}</div>
              <div style="padding:6px 12px;font-size:11px;color:var(--muted)">${data.safe.elapsed}ms</div>
            </div>
            <div class="cmp-card">
              <div class="cmp-hd unsafe">⚠ Guardrail OFF</div>
              <div class="cmp-body">${esc(data.unsafe.message)}</div>
              <div style="padding:6px 12px;font-size:11px;color:var(--muted)">${data.unsafe.elapsed}ms</div>
            </div>
          </div>`;
      } else {
        const safeStr = data.guardrailactive
          ? '<span class="badge b-ok">Guardrail ON</span>'
          : '<span class="badge b-warn">Guardrail OFF</span>';
        document.getElementById('gr-out').innerHTML = `
          <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">${safeStr}</div>
          <div style="white-space:pre-wrap;font-size:13px;line-height:1.6">${esc(data.message)}</div>
          ${data.note ? `<div class="callout" style="margin-top:12px">${data.note}</div>` : ''}`;
        document.getElementById('gr-meta').style.display = 'flex';
        document.getElementById('gr-time').textContent = data.elapsed + 'ms';
      }
    } else {
      document.getElementById('gr-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
    }
  } catch(e) {
    document.getElementById('gr-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('gr-spin', 'gr-run', false);
}

// ─────────────────────────────────────────────
// FUNCTIONTOOL — update code preview on toolset change
// ─────────────────────────────────────────────
document.getElementById('ft-tools').addEventListener('change', function() {
  const t = this.value;
  const cfcs = t === 'ecommerce' ? ['aiTesting.demo.tools.EcommerceTool'] :
               t === 'financial' ? ['aiTesting.demo.tools.FinancialTool'] :
               ['aiTesting.demo.tools.EcommerceTool', 'aiTesting.demo.tools.FinancialTool'];
  const lines = cfcs.map(c => `    { <span class="cp">CFC</span>: <span class="cs">"${c}"</span> }`).join(',\n');
  document.getElementById('ft-code-preview').innerHTML =
    `<span class="cf">agent</span>({\n  <span class="cp">CHATMODEL</span>: chatModel,\n  <span class="cp">TOOLS</span>: [\n${lines}\n  ]\n})`;
});

// ─────────────────────────────────────────────
// 6. RAG
// ─────────────────────────────────────────────
function ragSetQ(q) { document.getElementById('rag-question').value = q; }

function ragUpdateQuickBtns() {
  const mode = document.getElementById('rag-mode').value;
  const container = document.getElementById('rag-quick-btns');
  const hint = document.getElementById('rag-quick-hint');
  const textarea = document.getElementById('rag-question');
  if (mode === 'advanced') {
    const btns = [
      ['Step 1 — Return policy',     'What is the return policy for physical products?'],
      ['Step 2 — Digital downloads?','What about digital downloads — is it the same?'],
      ['Step 3 — Summarize both',    'Summarize both policies in one sentence each.']
    ];
    container.innerHTML = btns.map(([label, q]) =>
      `<button class="btn btn-outline" style="font-size:11px" onclick="ragSetQ('${q.replace(/'/g,"\\'")}')">` +
      `${esc(label)}</button>`
    ).join('');
    textarea.value = btns[0][1];
    hint.style.display = '';
  } else {
    const btns = [
      ['CF Price',  'What is the price of ColdFusion 2025 Professional?'],
      ['IT Policy', 'What is the software procurement policy for purchases over $5000?'],
      ['Adobe CC',  'What Adobe products are included in Creative Cloud?'],
      ['CF Errors', 'How do I handle errors in ColdFusion?']
    ];
    container.innerHTML = btns.map(([label, q]) =>
      `<button class="btn btn-outline" style="font-size:11px" onclick="ragSetQ('${q.replace(/'/g,"\\'")}')">` +
      `${esc(label)}</button>`
    ).join('');
    textarea.value = btns[0][1];
    hint.style.display = 'none';
  }
}

document.getElementById('rag-mode').addEventListener('change', () => { ragUpdateQuickBtns(); ragStatus(); });

async function ragStatus() {
  const data = await apiPost('rag.cfm', {
    action: 'status',
    provider: document.getElementById('rag-provider').value,
    mode: document.getElementById('rag-mode').value
  });
  if (data.success) {
    const files = data.docfiles || [];
    document.getElementById('rag-doc-list').innerHTML =
      `<div style="margin-bottom:4px"><span class="badge b-inf">${data.doccount} files</span> <span style="color:var(--muted)">${data.docspath}</span></div>` +
      files.map(f => `<div style="font-size:11px;color:var(--teal);font-family:monospace">📄 ${esc(f)}</div>`).join('') +
      (data.ingested ? '<div style="margin-top:6px"><span class="badge b-ok">✓ Ingested</span></div>' : '<div style="margin-top:6px"><span class="badge b-warn">Not yet ingested</span></div>');
  }
}

async function ragIngest() {
  setLoading('rag-ingest-spin', 'rag-ingest', true);
  const mode = document.getElementById('rag-mode').value;
  const data = await apiPost('rag.cfm', {
    action:'ingest', provider: document.getElementById('rag-provider').value, mode
  });
  setLoading('rag-ingest-spin', 'rag-ingest', false);
  if (data.success) {
    let detail = '';
    if (mode === 'simple' && data.statistics) {
      const s = data.statistics;
      detail = ` &nbsp;<span style="color:var(--muted);font-size:11px">` +
        `docs: ${s.documentsloaded ?? data.doccount} · chunks: ${s.segmentscreated}</span>`;
    } else if (mode === 'advanced') {
      detail = ` &nbsp;<span style="color:var(--muted);font-size:11px">` +
        `docs: ${data.documentsloaded} · chunks: ${data.segmentscreated} · query transformer: ON</span>`;
    }
    document.getElementById('rag-out').innerHTML =
      `<span style="color:var(--green)">✓ ${esc(data.message)}</span>${detail}`;
  } else {
    document.getElementById('rag-out').innerHTML =
      `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
  }
  await ragStatus();
}

async function ragAsk() {
  setLoading('rag-ask-spin', 'rag-ask', true);
  document.getElementById('rag-out').innerHTML = '<span class="out-empty">Retrieving and generating…</span>';
  document.getElementById('rag-meta').style.display = 'none';
  try {
    const data = await apiPost('rag.cfm', {
      action:'ask', question: document.getElementById('rag-question').value,
      provider: document.getElementById('rag-provider').value,
      mode: document.getElementById('rag-mode').value
    });
    if (data.success) {
      document.getElementById('rag-out').textContent = data.answer;
      document.getElementById('rag-meta').style.display = 'flex';
      document.getElementById('rag-time').textContent = data.elapsed + 'ms';
      document.getElementById('rag-mode-badge').textContent = data.mode + ' mode';
      const tokEl = document.getElementById('rag-tokens');
      if (data.inputtokens > 0 || data.outputtokens > 0) {
        tokEl.textContent = `in: ${data.inputtokens} · out: ${data.outputtokens} tokens`;
        tokEl.style.display = '';
      } else {
        tokEl.style.display = 'none';
      }
    } else {
      document.getElementById('rag-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
    }
  } catch(e) {
    document.getElementById('rag-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('rag-ask-spin', 'rag-ask', false);
}

// ─────────────────────────────────────────────
// 7. STREAMING  (agent + STREAMINGHANDLER + poll)
// ─────────────────────────────────────────────
let stPollTimer = null;
function stSetPrompt(p) { document.getElementById('st-prompt').value = p; }

async function stRun() {
  setLoading('st-spin', 'st-run', true);
  document.getElementById('st-out').textContent = '';
  document.getElementById('st-status').textContent = '⚡ Starting…';
  document.getElementById('st-meta').style.display = 'none';
  if (stPollTimer) { clearInterval(stPollTimer); stPollTimer = null; }
  try {
    const data = await apiPost('streaming.cfm', {
      provider: document.getElementById('st-provider').value,
      prompt:   document.getElementById('st-prompt').value
    });
    if (!data.success) {
      document.getElementById('st-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
      setLoading('st-spin', 'st-run', false);
      return;
    }
    // Poll stream_poll.cfm — display tokens in real-time as they arrive
    // from StreamHandler2.onPartialResponse() via writeLog -> demo-stream2.log
    let stPollCount = 0;
    let stLastLen = 0;
    const stEl = document.getElementById('st-out');
    stEl.textContent = '';
    stPollTimer = setInterval(async () => {
      try {
        stPollCount++;
        const p = lcKeys(await (await fetch('api/stream_poll.cfm')).json());
        const buf = p.buffer || '';
        if (buf.length > stLastLen) {
          stEl.textContent = buf;
          stLastLen = buf.length;
          document.getElementById('st-status').textContent = '⚡ Streaming…';
        }
        if (p.done) {
          clearInterval(stPollTimer); stPollTimer = null;
          if (p.error) {
            stEl.innerHTML = `<span style="color:var(--red)">Error: ${esc(p.error)}</span>`;
            document.getElementById('st-status').textContent = '✗ Error';
          } else {
            stEl.textContent = buf || '(no response)';
            document.getElementById('st-status').textContent = '✓ Complete';
            document.getElementById('st-meta').style.display = 'flex';
            document.getElementById('st-tokens').textContent = (p.tokencount || buf.split(/\s+/).length) + ' tokens';
          }
          setLoading('st-spin', 'st-run', false);
        } else if (stPollCount > 150) {
          clearInterval(stPollTimer); stPollTimer = null;
          document.getElementById('st-status').textContent = '⚠ Timeout';
          setLoading('st-spin', 'st-run', false);
        }
      } catch(e) {
        clearInterval(stPollTimer); stPollTimer = null;
        setLoading('st-spin', 'st-run', false);
      }
    }, 200);
  } catch(e) {
    document.getElementById('st-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
    setLoading('st-spin', 'st-run', false);
  }
}

// ─────────────────────────────────────────────
// PII GUARDRAIL (Guardrails tab)
// ─────────────────────────────────────────────
async function grPiiRun() {
  setLoading('grp-spin', 'grp-run', true);
  document.getElementById('grp-out').innerHTML = '<span style="color:var(--muted);font-style:italic">Generating LLM response and running through PII guardrail…</span>';
  try {
    const data = await apiPost('piiguardrail.cfm', {
      action:   'demo',
      provider: document.getElementById('grp-provider').value,
      prompt:   document.getElementById('grp-prompt').value
    });
    if (data.success) {
      const outcomeColor = data.outcome === 'passed' ? 'var(--green)' : data.outcome === 'redacted' ? 'var(--yellow)' : 'var(--red)';
      const outcomeBadge = data.outcome === 'passed'
        ? '<span class="badge b-ok">✓ Passed</span>'
        : data.outcome === 'redacted'
          ? '<span class="badge b-warn">⚠ Redacted</span>'
          : '<span class="badge b-err">✗ Blocked</span>';
      document.getElementById('grp-out').innerHTML = `
        <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px">
          ${outcomeBadge}
          <span style="font-size:12px;color:var(--muted)">${data.elapsed}ms</span>
        </div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px">
          <div>
            <div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;margin-bottom:6px">Raw LLM Output</div>
            <div style="background:var(--surf1);border:1px solid var(--border);border-radius:6px;padding:10px;font-size:12px;line-height:1.6;white-space:pre-wrap">${esc(data.rawtext)}</div>
          </div>
          <div>
            <div style="font-size:11px;font-weight:700;color:${outcomeColor};text-transform:uppercase;margin-bottom:6px">After Guardrail</div>
            <div style="background:var(--surf1);border:1px solid ${outcomeColor};border-radius:6px;padding:10px;font-size:12px;line-height:1.6;white-space:pre-wrap">${esc(data.finaltext)}</div>
          </div>
        </div>`;
    } else {
      document.getElementById('grp-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
    }
  } catch(e) {
    document.getElementById('grp-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('grp-spin', 'grp-run', false);
}

async function grPiiValidate() {
  const text = document.getElementById('grp-text').value.trim();
  if (!text) return;
  try {
    const data = await apiPost('piiguardrail.cfm', { action: 'validate', text });
    if (data.success) {
      const color = data.outcome === 'passed' ? 'var(--green)' : data.outcome === 'redacted' ? 'var(--yellow)' : 'var(--red)';
      const label = data.outcome === 'passed' ? '✓ No PII detected' : data.outcome === 'redacted' ? '⚠ PII redacted' : '✗ Blocked (sensitive data)';
      let html = `<div style="color:${color};font-weight:700;margin-bottom:6px">${label}</div>`;
      if (data.outcome === 'redacted') {
        html += `<div style="font-size:12px;white-space:pre-wrap">${esc(data.finaltext)}</div>`;
      } else if (data.outcome === 'blocked') {
        html += `<div style="font-size:12px;color:var(--red)">${esc(data.errormessage)}</div>`;
      }
      document.getElementById('grp-validate-out').innerHTML = html;
    }
  } catch(e) {
    document.getElementById('grp-validate-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(e.message)}</span>`;
  }
}

// ─────────────────────────────────────────────
// 8. MCP
// ─────────────────────────────────────────────
function mcpToggle(bodyId, chevId) {
  const body = document.getElementById(bodyId);
  const chev = document.getElementById(chevId);
  const collapsed = body.style.display === 'none';
  body.style.display = collapsed ? '' : 'none';
  chev.textContent  = collapsed ? '▲' : '▼';
}
function mcpSetPrompt(text) {
  document.getElementById('mcp-prompt').value = text;
}
async function mcpListTools() {
  setLoading('mcp-list-spin', 'mcp-list', true);
  document.getElementById('mcp-tools-out').innerHTML = '<span style="color:var(--muted)">Connecting to MCP server…</span>';
  document.getElementById('mcp-tools-meta').style.display = 'none';
  try {
    const data = await apiPost('mcp.cfm', {
      action:'listTools', serverType: document.getElementById('mcp-server').value
    });
    if (data.success) {
      const tools = data.tools || [];
      if (tools.length === 0) {
        document.getElementById('mcp-tools-out').innerHTML = '<div style="color:var(--muted)">No tools found on this server.</div>';
      } else {
        document.getElementById('mcp-tools-out').innerHTML =
          `<div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px">Tools (${tools.length})</div>` +
          tools.map(t => `<div class="mcp-tool">
            <div class="mcp-tool-nm">${esc(t.name || t)}</div>
            ${t.description ? `<div class="mcp-tool-desc">${esc(t.description)}</div>` : ''}
          </div>`).join('');
      }
      document.getElementById('mcp-tools-meta').style.display = 'flex';
      document.getElementById('mcp-tools-time').textContent = data.elapsed + 'ms';
      document.getElementById('mcp-tools-count').textContent = tools.length + ' tool(s)';
    } else {
      document.getElementById('mcp-tools-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}<br><small>${esc(data.detail||'')}</small></span>`;
    }
  } catch(e) {
    document.getElementById('mcp-tools-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('mcp-list-spin', 'mcp-list', false);
}

async function mcpListPrompts() {
  const data = await apiPost('mcp.cfm', { action:'listPrompts', serverType: document.getElementById('mcp-server').value });
  if (data.success) {
    const prompts = data.prompts || [];
    document.getElementById('mcp-tools-out').innerHTML =
      `<div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;margin-bottom:8px">Prompts (${prompts.length})</div>` +
      (prompts.length ? prompts.map(p => `<div class="mcp-tool"><div class="mcp-tool-nm">${esc(p.name||p)}</div>${p.description?`<div class="mcp-tool-desc">${esc(p.description)}</div>`:''}</div>`).join('') : '<div style="color:var(--muted)">No prompts available.</div>');
  } else {
    document.getElementById('mcp-tools-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
  }
}

async function mcpListResources() {
  const data = await apiPost('mcp.cfm', { action:'listResources', serverType: document.getElementById('mcp-server').value });
  if (data.success) {
    const res = data.resources || [];
    document.getElementById('mcp-tools-out').innerHTML =
      `<div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;margin-bottom:8px">Resources (${res.length})</div>` +
      (res.length ? res.map(r => `<div class="mcp-tool"><div class="mcp-tool-nm">${esc(r.name||r.uri||r)}</div>${r.description?`<div class="mcp-tool-desc">${esc(r.description)}</div>`:''}</div>`).join('') : '<div style="color:var(--muted)">No resources available.</div>');
  } else {
    document.getElementById('mcp-tools-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}</span>`;
  }
}

async function mcpAiChat() {
  setLoading('mcp-chat-spin', 'mcp-chat', true);
  document.getElementById('mcp-chat-out').innerHTML = '<span class="out-empty">Connecting to MCP server and chatting…</span>';
  document.getElementById('mcp-chat-tools').innerHTML = '';
  document.getElementById('mcp-chat-meta').style.display = 'none';
  try {
    const data = await apiPost('mcp.cfm', {
      action:'aiChat',
      serverType:  document.getElementById('mcp-server').value,
      provider:    document.getElementById('mcp-provider').value,
      chatPrompt:  document.getElementById('mcp-prompt').value
    });
    if (data.success) {
      document.getElementById('mcp-chat-out').textContent = data.message || '(no text response)';
      const toolReqs = data.toolrequests || [];
      if (toolReqs.length > 0) {
        document.getElementById('mcp-chat-tools').innerHTML =
          `<div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;margin:10px 0 6px">MCP Tool Calls (${toolReqs.length})</div>` +
          toolReqs.map(r => `<div class="tool-exec"><div class="tex-call">→ ${esc(r.name)}(${esc(JSON.stringify(r.arguments||{}))})</div></div>`).join('');
      }
      document.getElementById('mcp-chat-meta').style.display = 'flex';
      document.getElementById('mcp-chat-time').textContent = data.elapsed + 'ms';
    } else {
      document.getElementById('mcp-chat-out').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(data))}<br><small>${esc(data.detail||'')}</small></span>`;
    }
  } catch(e) {
    document.getElementById('mcp-chat-out').innerHTML = `<span style="color:var(--red)">Network error: ${esc(e.message)}</span>`;
  }
  setLoading('mcp-chat-spin', 'mcp-chat', false);
}

// ─────────────────────────────────────────────
// 9. SYSTEM MESSAGE
// ─────────────────────────────────────────────
const smPresets = {
  cfsupport:   "You are a friendly and knowledgeable ColdFusion expert support bot. Answer questions about ColdFusion programming, Adobe ColdFusion, CFML, CF functions, and CF features in detail. For questions completely unrelated to ColdFusion or programming, politely let the user know you specialize in ColdFusion and redirect the conversation back to CF topics.",
  pirate:      "You are a helpful AI assistant who always speaks like a pirate. Use pirate vocabulary (arr, matey, ahoy, shiver me timbers, etc.) in every single response. Stay helpful but stay in character.",
  reviewer:    "You are a strict code reviewer. When shown code, identify bugs, security vulnerabilities, and performance issues. Be direct and concise. List issues as numbered items. If code is clean, say so briefly.",
  concise:     "You are an ultra-concise assistant. Every response must be 2 sentences or fewer. No preamble, no filler words, no pleasantries. Just the answer.",
  shakespeare: "You are a helpful assistant who speaks in the style of William Shakespeare — with thee, thou, dost, hath, forsooth, and other Elizabethan English. Always maintain this style while remaining helpful.",
  custom:      ""
};

function smLoadPreset() {
  const preset = document.getElementById('sm-preset').value;
  if (preset !== 'custom') {
    document.getElementById('sm-sysmsg').value = smPresets[preset] || '';
  }
}

async function smRunBoth() {
  setLoading('sm-spin', 'sm-run', true);
  const provider  = document.getElementById('sm-provider').value;
  const systemMsg = document.getElementById('sm-sysmsg').value;

  // Reset both outputs
  ['cf','offtopic'].forEach(k => {
    document.getElementById('sm-out-' + k).innerHTML = '<span class="out-empty">Thinking…</span>';
    document.getElementById('sm-meta-' + k).style.display = 'none';
  });

  // Fire both requests in parallel
  const [d1, d2] = await Promise.all([
    apiPost('systemmessage.cfm', { provider, systemMsg, prompt: document.getElementById('sm-prompt-cf').value }),
    apiPost('systemmessage.cfm', { provider, systemMsg, prompt: document.getElementById('sm-prompt-offtopic').value })
  ]);

  // CF result
  if (d1.success) {
    document.getElementById('sm-out-cf').textContent = d1.message || '(no response)';
    document.getElementById('sm-time-cf').textContent = d1.elapsed + 'ms';
    document.getElementById('sm-meta-cf').style.display = 'flex';
  } else {
    document.getElementById('sm-out-cf').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(d1))}</span>`;
  }

  // Off-topic result
  if (d2.success) {
    document.getElementById('sm-out-offtopic').textContent = d2.message || '(no response)';
    document.getElementById('sm-time-offtopic').textContent = d2.elapsed + 'ms';
    document.getElementById('sm-meta-offtopic').style.display = 'flex';
  } else {
    document.getElementById('sm-out-offtopic').innerHTML = `<span style="color:var(--red)">Error: ${esc(errMsg(d2))}</span>`;
  }

  setLoading('sm-spin', 'sm-run', false);
}

// ─────────────────────────────────────────────
// INIT
// ─────────────────────────────────────────────
mcUpdateModels();
ragUpdateQuickBtns();
ragStatus();
smLoadPreset(); // pre-fill CF Support Bot system message
</script>


</body>
</html>
