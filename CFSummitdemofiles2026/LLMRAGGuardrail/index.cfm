<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>OnboardIQ - ColdFusion AI RAG Guardrail Demo</title>
    <link rel="icon" href="data:,">
    <link rel="stylesheet" href="assets/app.css?v=20260604a">
    <link rel="stylesheet" href="../assets/demo-window.css">
</head>
<body class="demo-windowed-workspace">
    <div class="demo-windowbar">
        <a class="demo-windowbar-back" href="/CFSummit2026/demos/" aria-label="Back to demo home">Back to home</a>
        <span class="demo-windowbar-title">CF2025 AI Demo</span>
        <span class="demo-windowbar-name">OnboardIQ</span>
    </div>
    <header class="topbar">
        <div class="brand">
            <div class="brand-mark">IQ</div>
            <div>
                <div class="brand-name">OnboardIQ</div>
                <div class="brand-sub">ColdFusion AI onboarding</div>
            </div>
        </div>

        <div class="topbar-status">
            <span class="status-chip" id="modelChip">Ollama checking</span>
            <span class="status-chip" id="kbChip">Knowledge base checking</span>
        </div>

        <div class="topbar-actions">
            <button class="mode-switch is-on" id="ragToggle" type="button" role="switch" aria-checked="true">
                <span class="switch-track"><span class="switch-dot"></span></span>
                <span>RAG</span>
            </button>
            <button class="mode-switch is-on" id="guardrailToggle" type="button" role="switch" aria-checked="true">
                <span class="switch-track"><span class="switch-dot"></span></span>
                <span>Guardrails</span>
            </button>
        </div>
    </header>

    <main class="main">
        <aside class="progress-sidebar" aria-label="Onboarding steps">
            <div class="progress-header">
                <div class="panel-label">Progress</div>
                <div class="progress-bar" aria-hidden="true"><div class="progress-fill" id="progressFill"></div></div>
                <div class="progress-meta">
                    <span id="progressText">0 / 0 complete</span>
                    <span id="phaseText">Day 1</span>
                </div>
            </div>
            <div class="steps-list" id="stepsList"></div>
        </aside>

        <section class="workspace">
            <div class="step-strip">
                <div>
                    <div class="panel-label" id="stepOwner">People Ops</div>
                    <h1 id="stepTitle">Welcome and paperwork</h1>
                    <p id="stepPhase">Day 1</p>
                </div>
                <div class="step-count" id="stepCount">Step 1 of 8</div>
            </div>

            <div class="checklist" id="checklist"></div>

            <section class="chat-panel" aria-label="Onboarding assistant">
                <div class="chat-messages" id="chatMessages">
                    <article class="message assistant">
                        <div class="avatar">AI</div>
                        <div class="bubble">
                            <div class="message-meta">OnboardIQ</div>
                            <div class="message-text">Welcome to Day 1. I can help with paperwork, IT setup, benefits, training, security, team introductions, first projects, and check-ins.</div>
                        </div>
                    </article>
                </div>

                <div class="quick-prompts" id="quickPrompts"></div>

                <form class="composer" id="chatForm">
                    <textarea id="questionInput" rows="1" placeholder="Ask about onboarding, benefits, IT setup, or company policy..."></textarea>
                    <button class="send-button" id="sendButton" type="submit" aria-label="Send question">
                        <span>Send</span>
                    </button>
                </form>
            </section>
        </section>

        <aside class="dashboard" aria-label="AI dashboard">
            <div class="dashboard-tabs">
                <button class="dash-tab active" type="button" data-tab="metrics">Metrics</button>
                <button class="dash-tab" type="button" data-tab="rag">RAG</button>
                <button class="dash-tab" type="button" data-tab="trace">Trace</button>
            </div>

            <div class="dashboard-body">
                <section class="dash-section active" id="tab-metrics">
                    <div class="metric-grid">
                        <div class="metric">
                            <span>Memory</span>
                            <strong id="memoryValue">-- MB</strong>
                            <div class="mini-bar"><div id="memoryFill"></div></div>
                        </div>
                        <div class="metric">
                            <span>Total tokens</span>
                            <strong id="tokenValue">0</strong>
                            <small id="lastTokenValue">last 0</small>
                        </div>
                        <div class="metric">
                            <span>Latency</span>
                            <strong id="latencyValue">-- ms</strong>
                            <small id="requestValue">0 requests</small>
                        </div>
                        <div class="metric">
                            <span>Guardrail</span>
                            <strong id="guardrailValue">on</strong>
                            <small id="ragCountValue">0 chunks</small>
                        </div>
                    </div>
                    <div class="history-list" id="historyList"></div>
                </section>

                <section class="dash-section" id="tab-rag">
                    <div class="empty-state" id="ragEmpty">No retrieved documents yet.</div>
                    <div class="source-list" id="sourceList"></div>
                </section>

                <section class="dash-section" id="tab-trace">
                    <div class="trace-panel">
                        <div class="trace-row"><span>RAG</span><strong id="traceRag">on</strong></div>
                        <div class="trace-row"><span>Guardrails</span><strong id="traceGuardrails">on</strong></div>
                        <div class="trace-row"><span>Guardrail mode</span><strong id="traceGuardrailMode">model inference</strong></div>
                        <div class="trace-row"><span>Decision</span><strong id="traceGuardrailDecision">pending</strong></div>
                        <div class="trace-row"><span>Category</span><strong id="traceGuardrailCategory">pending</strong></div>
                        <div class="trace-row"><span>Chat model</span><strong id="traceModel">llama3.2</strong></div>
                        <div class="trace-row"><span>Embeddings</span><strong id="traceEmbedding">nomic-embed-text</strong></div>
                        <div class="trace-row"><span>Collection</span><strong id="traceCollection">pending</strong></div>
                    </div>
                    <div class="dashboard-actions">
                        <button class="secondary-button" id="reingestButton" type="button">Reingest</button>
                        <button class="secondary-button" id="resetButton" type="button">Reset</button>
                    </div>
                    <div class="trace-note" id="traceNote">Knowledge base ready.</div>
                </section>
            </div>
        </aside>
    </main>

    <script src="assets/app.js?v=20260604c"></script>
</body>
</html>
