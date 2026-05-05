<style>
/* ===== Mintu's Baby Care Assistant — Dark Theme for Virtual Demos ===== */

*, *::before, *::after { box-sizing: border-box; }

body {
    margin: 0;
    font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
    background: #1a1215;
    color: #f0e6e0;
    display: flex;
    min-height: 100vh;
    font-size: 15px;
}

/* ===== SIDEBAR ===== */
#sidebar {
    width: 270px;
    min-width: 270px;
    background: #221a1e;
    border-right: 1px solid #3d2a30;
    display: flex;
    flex-direction: column;
    position: fixed;
    top: 0; left: 0; bottom: 0;
    overflow-y: auto;
    z-index: 100;
}

#sidebar .brand {
    padding: 22px 18px 18px;
    border-bottom: 1px solid #3d2a30;
}
#sidebar .brand h1 {
    margin: 0 0 5px;
    font-size: 16px;
    font-weight: 800;
    color: #ff8a80;
    letter-spacing: 0.05em;
    text-transform: uppercase;
}
#sidebar .brand p {
    margin: 0;
    font-size: 12px;
    color: #b89a8f;
}

#sidebar nav {
    flex: 1;
    padding: 14px 0;
}

#sidebar nav .nav-section {
    margin-bottom: 5px;
}

#sidebar nav a {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 9px 18px;
    text-decoration: none;
    color: #c0a898;
    font-size: 14px;
    border-left: 3px solid transparent;
    transition: all 0.15s;
}
#sidebar nav a:hover {
    background: #2d1f25;
    color: #f0e0d8;
    border-left-color: #ff8a80;
}
#sidebar nav a.active {
    background: #3a1f28;
    color: #ff8a80;
    border-left-color: #ff8a80;
    font-weight: 700;
}
#sidebar nav a.sub {
    padding-left: 36px;
    font-size: 13px;
}
#sidebar nav a .step-badge {
    background: #3d2a30;
    color: #c0a898;
    font-size: 11px;
    padding: 2px 7px;
    border-radius: 4px;
    font-weight: 700;
}
#sidebar nav a.active .step-badge {
    background: #5a2030;
    color: #ff8a80;
}
#sidebar nav .nav-divider {
    height: 1px;
    background: #3d2a30;
    margin: 10px 18px;
}

#sidebar .pmt-btn {
    margin: 14px 18px 18px;
    display: block;
    text-align: center;
    background: linear-gradient(135deg, #ff6b6b, #e84560);
    color: #fff;
    padding: 11px 14px;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 700;
    text-decoration: none;
    border: 1px solid #ff8a80;
    transition: all 0.2s;
}
#sidebar .pmt-btn:hover {
    background: linear-gradient(135deg, #ff8a80, #ff6b6b);
    box-shadow: 0 0 16px rgba(255,107,107,0.5);
}

#sidebar .pmt-tabs-hint {
    margin: 0 14px 16px;
    padding: 12px 14px;
    background: linear-gradient(135deg, #2d1f25 0%, #301a22 100%);
    border-radius: 8px;
    border: 1px solid #5a2030;
    border-left: 3px solid #ff6b6b;
}
#sidebar .pmt-tabs-hint .pmt-hint-label {
    display: flex;
    align-items: center;
    gap: 6px;
    color: #ff8a80;
    font-size: 11px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    margin-bottom: 10px;
}
#sidebar .pmt-tabs-hint .tab-chip {
    display: inline-flex;
    align-items: center;
    gap: 3px;
    background: #3a1f28;
    color: #ffab91;
    border: 1px solid #5a2030;
    border-radius: 5px;
    padding: 4px 10px;
    font-size: 12px;
    font-weight: 700;
    margin: 3px 4px 0 0;
    white-space: nowrap;
    text-decoration: none;
    cursor: pointer;
    transition: all 0.15s;
}
#sidebar .pmt-tabs-hint .tab-chip:hover {
    background: #5a2030;
    color: #fff;
    border-color: #ff6b6b;
}
#sidebar .pmt-tabs-hint .tab-chip::before {
    content: "\25B8";
    font-size: 10px;
    opacity: 0.7;
}

/* ===== MAIN CONTENT ===== */
#main {
    margin-left: 270px;
    flex: 1;
    display: flex;
    flex-direction: column;
    min-height: 100vh;
}

.page-header {
    padding: 28px 36px 24px;
    border-bottom: 1px solid #3d2a30;
    background: #221a1e;
}
.page-header .step-label {
    font-size: 13px;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: #b89a8f;
    margin-bottom: 8px;
    font-weight: 600;
}
.page-header h2 {
    margin: 0 0 10px;
    font-size: 26px;
    font-weight: 800;
    color: #fff;
}
.page-header p {
    margin: 0;
    color: #c0a898;
    font-size: 15px;
    max-width: 720px;
    line-height: 1.6;
}

.page-content {
    padding: 28px 36px;
    flex: 1;
}

/* ===== BANNERS ===== */
.banner {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 14px 18px;
    border-radius: 10px;
    margin-bottom: 22px;
    font-size: 14px;
    line-height: 1.6;
}
.banner-bottleneck {
    background: #2d1215;
    border: 1px solid #e84560;
    color: #ff8a80;
}
.banner-optimized {
    background: #0d2a1a;
    border: 1px solid #4caf70;
    color: #81d4a0;
}
.banner-info {
    background: #2d1f25;
    border: 1px solid #ff8a80;
    color: #ffccbc;
}
.banner-pmt {
    background: #2d1215;
    border: 1px solid #ff6b6b;
    border-left: 4px solid #ff6b6b;
    color: #ffab91;
    border-radius: 10px;
}
.banner-pmt .pmt-watch-label {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    font-size: 11px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: #ff6b6b;
    background: #3a1520;
    border: 1px solid #5a2030;
    border-radius: 5px;
    padding: 3px 10px;
    margin-bottom: 6px;
    white-space: nowrap;
}
.banner-pmt .pmt-tab-ref {
    font-weight: 700;
    color: #ff8a80;
    background: #3a1520;
    border-radius: 4px;
    padding: 2px 8px;
    font-size: 13px;
    white-space: nowrap;
}
.banner-icon {
    font-size: 24px;
}
.banner strong {
    display: block;
    font-size: 14px;
    margin-bottom: 5px;
    color: #fff;
}
.banner code {
    background: rgba(255,255,255,0.08);
    padding: 2px 6px;
    border-radius: 4px;
    font-family: 'Fira Code', monospace;
    font-size: 12px;
    color: #81d4a0;
}

/* ===== SECTION ===== */
.section {
    margin-bottom: 32px;
}
.section-title {
    font-size: 14px;
    font-weight: 800;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: #b89a8f;
    margin-bottom: 14px;
    padding-bottom: 8px;
    border-bottom: 1px solid #3d2a30;
}

/* ===== ACTION CARDS ===== */
.action-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 18px;
}

.action-card {
    background: #221a1e;
    border: 1px solid #3d2a30;
    border-radius: 12px;
    padding: 20px;
    display: flex;
    flex-direction: column;
    gap: 14px;
}

.action-card .card-title {
    font-size: 15px;
    font-weight: 700;
    color: #fff;
}
.action-card .card-desc {
    font-size: 13px;
    color: #c0a898;
    line-height: 1.6;
}

/* ===== BUTTONS ===== */
.btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 10px 20px;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
    border: none;
    transition: all 0.18s;
    text-decoration: none;
    white-space: nowrap;
}
.btn:disabled {
    opacity: 0.45;
    cursor: not-allowed;
}
.btn-primary {
    background: linear-gradient(135deg, #ff6b6b, #e84560);
    color: #fff;
    border: 1px solid #ff8a80;
}
.btn-primary:hover:not(:disabled) {
    background: linear-gradient(135deg, #ff8a80, #ff6b6b);
    box-shadow: 0 3px 14px rgba(255,107,107,0.45);
}
.btn-success {
    background: linear-gradient(135deg, #4caf70, #388e5c);
    color: #fff;
    border: 1px solid #66cc88;
}
.btn-success:hover:not(:disabled) {
    background: linear-gradient(135deg, #66cc88, #4caf70);
    box-shadow: 0 3px 14px rgba(76,175,112,0.4);
}
.btn-danger {
    background: linear-gradient(135deg, #ef5350, #c62828);
    color: #fff;
    border: 1px solid #ff8a80;
}
.btn-warning {
    background: linear-gradient(135deg, #ffb300, #f09000);
    color: #1a1215;
    border: 1px solid #ffd54f;
    font-weight: 800;
}
.btn-secondary {
    background: #3d2a30;
    color: #c0a898;
    border: 1px solid #5a3a42;
}
.btn-secondary:hover:not(:disabled) {
    background: #4d3a40;
    color: #f0e0d8;
}
.btn-run-all {
    background: linear-gradient(135deg, #ab47bc, #8e24aa);
    color: #fff;
    border: 1px solid #ce93d8;
    padding: 12px 26px;
    font-size: 15px;
}
.btn-run-all:hover:not(:disabled) {
    background: linear-gradient(135deg, #ce93d8, #ab47bc);
    box-shadow: 0 3px 14px rgba(171,71,188,0.5);
}

/* ===== RESULT DISPLAY ===== */
.result-area {
    min-height: 60px;
}

.result-card {
    background: #1a1215;
    border: 1px solid #3d2a30;
    border-radius: 10px;
    padding: 16px;
    font-size: 14px;
    line-height: 1.7;
}
.result-card.success { border-left: 4px solid #4caf70; }
.result-card.error   { border-left: 4px solid #ef5350; }
.result-card.warning { border-left: 4px solid #ffb300; }
.result-card.running { border-left: 4px solid #ff6b6b; }

.result-text {
    color: #f0e6e0;
    white-space: pre-wrap;
    word-break: break-word;
}

/* ===== METRIC BADGES ===== */
.metrics-row {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 12px;
}
.metric-badge {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 4px 10px;
    border-radius: 5px;
    font-size: 12px;
    font-weight: 700;
    background: #3d2a30;
    color: #c0a898;
}
.metric-badge.tokens  { background: #3a1520; color: #ff8a80; }
.metric-badge.time    { background: #2a1a30; color: #ce93d8; }
.metric-badge.score   { background: #0d2a1a; color: #81d4a0; }
.metric-badge.alert   { background: #2d1215; color: #ff8a80; }
.metric-badge.model   { background: #1a2530; color: #80cbc4; }
.metric-badge.savings { background: #0d2a1a; color: #81d4a0; }

/* ===== PROBLEM / IMPROVEMENT INDICATORS ===== */
.problem-indicator {
    margin-top: 12px;
    padding: 10px 14px;
    background: #2d1215;
    border: 1px solid #ef5350;
    border-radius: 8px;
    font-size: 13px;
    color: #ff8a80;
}
.problem-indicator::before { content: "\26A0 Problem: "; font-weight: 800; }

.improvement-indicator {
    margin-top: 12px;
    padding: 10px 14px;
    background: #0d2a1a;
    border: 1px solid #4caf70;
    border-radius: 8px;
    font-size: 13px;
    color: #81d4a0;
}
.improvement-indicator::before { content: "\2713 Improvement: "; font-weight: 800; }

/* ===== SPINNER ===== */
@keyframes spin { to { transform: rotate(360deg); } }
.spinner {
    width: 18px; height: 18px;
    border: 2px solid #3d2a30;
    border-top-color: #ff6b6b;
    border-radius: 50%;
    animation: spin 0.7s linear infinite;
    display: inline-block;
    flex-shrink: 0;
}

.loading-row {
    display: flex;
    align-items: center;
    gap: 12px;
    color: #ff8a80;
    font-size: 14px;
    padding: 14px;
}

/* ===== PROGRESS BAR ===== */
.progress-bar-wrap {
    background: #3d2a30;
    border-radius: 8px;
    height: 10px;
    overflow: hidden;
    margin-top: 10px;
}
.progress-bar-fill {
    height: 100%;
    background: linear-gradient(90deg, #ff6b6b, #ab47bc);
    border-radius: 8px;
    transition: width 0.5s ease;
}

/* ===== COMPARISON TABLE ===== */
.comparison-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
    margin-top: 14px;
}
.comparison-table th {
    background: #2d1f25;
    color: #ff8a80;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-size: 12px;
    padding: 10px 14px;
    text-align: left;
    font-weight: 700;
}
.comparison-table td {
    padding: 10px 14px;
    border-bottom: 1px solid #3d2a30;
    color: #f0e6e0;
}
.comparison-table tr:hover td { background: #221a1e; }

/* ===== CONFIG BOX ===== */
.config-box {
    background: #1a1215;
    border: 1px solid #3d2a30;
    border-radius: 10px;
    padding: 16px;
    font-family: 'Fira Code', 'Consolas', monospace;
    font-size: 13px;
    color: #c0a898;
    margin-bottom: 18px;
    line-height: 1.7;
}
.config-box .cfg-key   { color: #ff8a80; }
.config-box .cfg-value { color: #81d4a0; }
.config-box .cfg-bad   { color: #ff5252; }
.config-box .cfg-good  { color: #69f0ae; }

/* ===== CHAT TRANSCRIPT ===== */
.chat-transcript {
    background: #1a1215;
    border: 1px solid #3d2a30;
    border-radius: 10px;
    padding: 18px;
    max-height: 450px;
    overflow-y: auto;
}
.chat-turn {
    margin-bottom: 16px;
    padding-bottom: 16px;
    border-bottom: 1px solid #2d1f25;
}
.chat-turn:last-child { border-bottom: none; margin-bottom: 0; }
.chat-user {
    font-size: 13px;
    color: #b89a8f;
    margin-bottom: 8px;
}
.chat-user strong { color: #ff8a80; }
.chat-assistant {
    font-size: 14px;
    color: #f0e6e0;
    line-height: 1.7;
}

/* ===== SHARED CHAT BUBBLE UI ===== */
.chat-window {
    display: flex;
    flex-direction: column;
    height: 500px;
    background: #1a1215;
    border: 1px solid #3d2a30;
    border-radius: 12px;
    overflow: hidden;
}
.chat-win-header {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 12px 16px;
    background: #221a1e;
    border-bottom: 1px solid #3d2a30;
    font-size: 13px;
    color: #b89a8f;
    flex-shrink: 0;
}
.chat-win-dot { width: 8px; height: 8px; border-radius: 50%; background: #4caf70; flex-shrink: 0; }
.chat-msgs {
    flex: 1;
    overflow-y: auto;
    padding: 18px 16px;
    display: flex;
    flex-direction: column;
    gap: 16px;
    scroll-behavior: smooth;
    background: #1a1215;
}
.chat-msgs::-webkit-scrollbar { width: 5px; }
.chat-msgs::-webkit-scrollbar-thumb { background: #3d2a30; border-radius: 3px; }
.chat-row { display: flex; gap: 10px; align-items: flex-end; animation: fadeUpBbl 0.15s ease-out; }
.chat-row.user { flex-direction: row-reverse; }
@keyframes fadeUpBbl { from { opacity:0; transform:translateY(5px); } to { opacity:1; transform:translateY(0); } }
.chat-av { width: 32px; height: 32px; border-radius: 50%; display:flex; align-items:center; justify-content:center; font-size:15px; flex-shrink:0; }
.chat-av.bot  { background: #3a1f28; }
.chat-av.user { background: #2a1a35; }
.chat-bbl {
    max-width: 74%;
    padding: 12px 16px;
    border-radius: 14px;
    font-size: 14px;
    line-height: 1.7;
    white-space: pre-wrap;
    word-break: break-word;
}
.chat-bbl.bot  { background:#221a1e; border:1px solid #3d2a30; border-bottom-left-radius:4px; color:#f0e6e0; }
.chat-bbl.user { background:#e84560; border:1px solid #ff6b6b; border-bottom-right-radius:4px; color:#fff; }
.chat-bbl.bot.warn    { border-color:#ffb300; background:#2d2010; }
.chat-bbl.bot.blocked { border-color:#ef5350; background:#2d1215; }
.chat-bbl.bot.redacted{ border-color:#ab47bc; background:#2a1530; }
.chat-bbl.bot.errored { border-color:#ef5350; background:#2d1215; }
.chat-bbl-meta { font-size:11px; color:#8a7068; margin-top:5px; }
.chat-row.user .chat-bbl-meta { text-align:right; }
.chat-bbl-badges { display:flex; flex-wrap:wrap; gap:6px; margin-top:8px; }
/* typing indicator */
.typing-dots span { display:inline-block; width:6px; height:6px; background:#ff6b6b; border-radius:50%; margin:0 2px; animation:tdot 1.2s infinite; }
.typing-dots span:nth-child(2){ animation-delay:.2s; }
.typing-dots span:nth-child(3){ animation-delay:.4s; }
@keyframes tdot { 0%,80%,100%{transform:translateY(0)} 40%{transform:translateY(-6px)} }
/* preset action bar */
.preset-action-bar { display:flex; flex-wrap:wrap; gap:10px; margin-bottom:12px; }

/* ===== TOAST NOTIFICATION ===== */
#toast {
    position: fixed;
    bottom: 24px;
    right: 24px;
    background: #221a1e;
    border: 1px solid #3d2a30;
    border-radius: 10px;
    padding: 14px 20px;
    font-size: 14px;
    color: #f0e6e0;
    z-index: 1000;
    max-width: 360px;
    box-shadow: 0 6px 24px rgba(0,0,0,0.5);
    opacity: 0;
    transition: opacity 0.3s;
    pointer-events: none;
}
#toast.show { opacity: 1; }
#toast.toast-success { border-color: #4caf70; }
#toast.toast-error   { border-color: #ef5350; }
</style>
<script>
window.cfNorm = function cfNorm(o) {
    if (!o || typeof o !== 'object') return o;
    if (Array.isArray(o)) return o.map(cfNorm);
    const out = {};
    for (const [k, v] of Object.entries(o)) { out[k.toLowerCase()] = cfNorm(v); }
    return out;
};
</script>
