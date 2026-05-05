<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mintu's Baby Care Assistant — PMT Demo Suite</title>
<cfinclude template="_styles.cfm">
<style>
    body { display: block; }
    .hero {
        background: linear-gradient(135deg, #1a1215 0%, #2d1520 50%, #3a1828 100%);
        padding: 70px 40px 50px;
        border-bottom: 1px solid #3d2a30;
        text-align: center;
    }
    .hero .hero-badge {
        display: inline-block;
        background: #3a1520;
        border: 1px solid #ff6b6b;
        color: #ff8a80;
        font-size: 12px;
        font-weight: 800;
        letter-spacing: 0.1em;
        text-transform: uppercase;
        padding: 5px 16px;
        border-radius: 20px;
        margin-bottom: 18px;
    }
    .hero h1 {
        font-size: 42px;
        font-weight: 800;
        color: #fff;
        margin: 0 0 14px;
        letter-spacing: -0.02em;
    }
    .hero h1 span { color: #ff8a80; }
    .hero p {
        font-size: 17px;
        color: #c0a898;
        max-width: 640px;
        margin: 0 auto 32px;
        line-height: 1.7;
    }
    .hero-actions { display: flex; gap: 14px; justify-content: center; flex-wrap: wrap; }

    .content-wrap { max-width: 1100px; margin: 0 auto; padding: 44px; }

    .step-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(290px, 1fr));
        gap: 18px;
        margin-bottom: 44px;
    }
    .step-card {
        background: #221a1e;
        border: 1px solid #3d2a30;
        border-radius: 12px;
        padding: 22px;
        text-decoration: none;
        color: inherit;
        transition: all 0.2s;
        display: flex;
        flex-direction: column;
        gap: 10px;
        position: relative;
    }
    .step-card:hover {
        border-color: #ff8a80;
        background: #2d1f25;
        transform: translateY(-2px);
        box-shadow: 0 8px 24px rgba(0,0,0,0.4);
    }
    .step-card .card-num {
        font-size: 13px;
        font-weight: 700;
        color: #8a7068;
        letter-spacing: 0.05em;
        text-transform: uppercase;
    }
    .step-card h3 {
        margin: 0;
        font-size: 16px;
        font-weight: 700;
        color: #fff;
    }
    .step-card p {
        margin: 0;
        font-size: 13px;
        color: #b89a8f;
        line-height: 1.6;
    }
    .step-card .card-tabs {
        display: flex;
        flex-wrap: wrap;
        gap: 5px;
        margin-top: 5px;
    }
    .step-card .tab-chip {
        font-size: 11px;
        padding: 3px 8px;
        background: #3a1520;
        color: #ffab91;
        border-radius: 4px;
        font-weight: 700;
    }
    .bottleneck-badge {
        position: absolute;
        top: 14px; right: 14px;
        background: #2d1215;
        border: 1px solid #ef5350;
        color: #ff8a80;
        font-size: 10px;
        font-weight: 800;
        letter-spacing: 0.06em;
        text-transform: uppercase;
        padding: 3px 8px;
        border-radius: 4px;
    }
    .step-pair { display: flex; flex-direction: column; gap: 8px; }
    .step-pair .step-card { padding: 16px 20px; }

    .prereq-box {
        background: #221a1e;
        border: 1px solid #3d2a30;
        border-radius: 12px;
        padding: 28px;
        margin-bottom: 36px;
    }
    .prereq-box h3 {
        margin: 0 0 18px;
        font-size: 17px;
        font-weight: 800;
        color: #fff;
    }
    .prereq-list { list-style: none; padding: 0; margin: 0; }
    .prereq-list li {
        display: flex;
        align-items: flex-start;
        gap: 12px;
        padding: 10px 0;
        border-bottom: 1px solid #2d1f25;
        font-size: 14px;
        color: #c0a898;
    }
    .prereq-list li:last-child { border-bottom: none; }
    .prereq-list .prereq-icon { font-size: 18px; flex-shrink: 0; }
    .prereq-list code {
        background: #1a1215;
        padding: 2px 7px;
        border-radius: 4px;
        font-family: 'Fira Code', monospace;
        font-size: 12px;
        color: #81d4a0;
    }

    .acts-section { margin-bottom: 36px; }
    .acts-section h3 { font-size: 17px; color: #fff; margin-bottom: 16px; font-weight: 800; }
    .act-row {
        display: flex;
        gap: 12px;
        margin-bottom: 10px;
        flex-wrap: wrap;
    }
    .act-chip {
        background: #2d1f25;
        border: 1px solid #3d2a30;
        border-radius: 8px;
        padding: 10px 16px;
        font-size: 13px;
        color: #c0a898;
        display: flex;
        align-items: center;
        gap: 8px;
    }
    .act-chip .act-num {
        background: #ff6b6b;
        color: #fff;
        width: 22px;
        height: 22px;
        border-radius: 50%;
        font-size: 11px;
        font-weight: 800;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>
</head>
<body>

<div class="hero">
    <div class="hero-badge">PMT AI Services Demo - Baby Edition</div>
    <h1>Mintu's <span>Baby Care</span> Assistant</h1>
    <p>An AI-powered parenting helper built step by step — from first LLM call to full Care Agent. Each building block maps to a PMT dashboard tab. Welcome to the world, Mintu!</p>
    <div class="hero-actions">
        <a href="step1_chatmodel.cfm" class="btn btn-primary" style="padding:11px 24px;font-size:14px;">
            &#9654; Start Demo (Step 1)
        </a>
        <a href="http://localhost:9101/ai-services/home" target="_blank" class="btn btn-secondary" style="padding:11px 24px;font-size:14px;">
            &#128200; Open PMT Dashboard &nearr;
        </a>
    </div>
</div>

<div class="content-wrap">

    <!-- Prerequisites -->
    <div class="prereq-box">
        <h3>&#10003; Prerequisites &amp; Setup</h3>
        <ul class="prereq-list">
            <li>
                <span class="prereq-icon">&#127381;</span>
                <div><strong>Ollama running locally</strong> — Required for embedding model (<code>all-minilm</code>) and Ollama LLM provider (<code>llama3.2</code>).<br>
                Start with: <code>ollama serve</code> &nbsp;|&nbsp; Pull models: <code>ollama pull all-minilm &amp;&amp; ollama pull llama3.2</code></div>
            </li>
            <li>
                <span class="prereq-icon">&#128273;</span>
                <div><strong>API Keys configured</strong> — OpenAI, Anthropic, Mistral, Azure OpenAI keys are pre-configured in <code>Application.cfc</code>.</div>
            </li>
            <li>
                <span class="prereq-icon">&#128268;</span>
                <div><strong>MCP Servers</strong> — Baby Supplies MCP servers for Steps 3/3a.<br>
                Fast: <code>/mintu_baby/mcp/babySuppliesMcpServer.cfm</code><br>
                Slow: <code>/mintu_baby/mcp/babySuppliesMcpServerSlow.cfm</code></div>
            </li>
            <li>
                <span class="prereq-icon">&#128202;</span>
                <div><strong>PMT AI Services Dashboard enabled</strong> — Ensure Performance Monitoring is active.</div>
            </li>
            <li>
                <span class="prereq-icon">&#128193;</span>
                <div><strong>Data directory writable</strong> — Step 5 writes baby care guides to <code>/mintu_baby/data/</code>.</div>
            </li>
        </ul>
    </div>

    <!-- Demo Flow -->
    <div class="acts-section">
        <h3>&#127916; Demo Flow</h3>
        <div class="act-row">
            <div class="act-chip"><span class="act-num">1</span> ChatModel</div>
            <div class="act-chip"><span class="act-num">2</span> Care Agent &#x2192; &#x26a0; Verbose &#x2192; &#x2713; Fix</div>
            <div class="act-chip"><span class="act-num">3</span> MCP Supplies &#x2192; &#x26a0; Slow &#x2192; &#x2713; Fix</div>
            <div class="act-chip"><span class="act-num">4</span> Safety Guardrails</div>
        </div>
        <div class="act-row">
            <div class="act-chip"><span class="act-num">5</span> Knowledge Ingestion</div>
            <div class="act-chip"><span class="act-num">6</span> Knowledge Retrieval &#x2192; &#x26a0; Poor Config &#x2192; &#x2713; Fix</div>
        </div>
        <div class="act-row">
            <div class="act-chip"><span class="act-num">7</span> Full Care Agent</div>
            <div class="act-chip"><span class="act-num">8</span> Load Generator</div>
        </div>
    </div>

    <!-- Step Cards -->
    <div class="section-title" style="font-size:13px;letter-spacing:.08em;color:#b89a8f;text-transform:uppercase;margin-bottom:16px;padding-bottom:8px;border-bottom:1px solid #3d2a30;">All Steps</div>

    <div class="step-grid">

        <a href="step1_chatmodel.cfm" class="step-card">
            <div class="card-num">1 — ChatModel</div>
            <h3>LLM Foundation — 5 Providers</h3>
            <p>Ask baby care questions across OpenAI, Anthropic, Mistral, Azure, and Ollama.</p>
            <div class="card-tabs"><span class="tab-chip">LLMs</span></div>
        </a>

        <div class="step-pair">
            <a href="step2_agent.cfm" class="step-card">
                <div class="card-num">2 — Care Agent</div>
                <h3>Baby Care Agent with Tools &amp; Memory</h3>
                <p>Agent with family lookup, routine tracking, and care task creation.</p>
                <div class="card-tabs"><span class="tab-chip">Agents</span><span class="tab-chip">LLMs</span></div>
            </a>
            <a href="step2a_agent_problem.cfm" class="step-card">
                <div class="bottleneck-badge">&#9888; problem</div>
                <div class="card-num">2 — Agent: Verbose</div>
                <h3>The Problem — Token Waste</h3>
                <p>500-word system prompt, no MAXTOKENS. Rambling responses and slow calls.</p>
                <div class="card-tabs"><span class="tab-chip">Agents</span><span class="tab-chip">LLMs</span></div>
            </a>
        </div>

        <div class="step-pair">
            <a href="step3_mcp.cfm" class="step-card">
                <div class="card-num">3 — MCP: Baby Supplies</div>
                <h3>MCP — Baby Supplies Store</h3>
                <p>Query baby product catalog, check stock, and track orders via fast MCP server.</p>
                <div class="card-tabs"><span class="tab-chip">MCP Servers</span><span class="tab-chip">MCP Clients</span></div>
            </a>
            <a href="step3a_mcp_problem.cfm" class="step-card">
                <div class="bottleneck-badge">&#9888; problem</div>
                <div class="card-num">3 — MCP: Slow Server</div>
                <h3>The Problem — 2-4s Per Tool Call</h3>
                <p>Legacy server, no caching. PMT Slow MCP Client Calls grid lights up.</p>
                <div class="card-tabs"><span class="tab-chip">MCP Servers</span><span class="tab-chip">MCP Clients</span></div>
            </a>
        </div>

        <a href="step4_guardrails.cfm" class="step-card">
            <div class="card-num">4 — Safety Guardrails</div>
            <h3>Baby Safety &amp; Privacy</h3>
            <p>Input guardrail blocks unsafe advice. Output guardrail redacts PII. Pass, warn, block outcomes.</p>
            <div class="card-tabs"><span class="tab-chip">Agents</span><span class="tab-chip">Trace Viewer</span></div>
        </a>

        <a href="step5_rag_ingestion.cfm" class="step-card">
            <div class="card-num">5 — Knowledge Ingestion</div>
            <h3>Build the Baby Care Knowledge Base</h3>
            <p>Create baby care guides, sync ingest, then async ingest 20 parenting docs.</p>
            <div class="card-tabs"><span class="tab-chip">RAG</span><span class="tab-chip">Vector Stores</span></div>
        </a>

        <div class="step-pair">
            <a href="step6_rag_retrieval.cfm" class="step-card">
                <div class="card-num">6 — Knowledge Retrieval</div>
                <h3>Agent + Baby Care Knowledge Base</h3>
                <p>chunkSize:300, overlap:75, minScore:0.6. Precise baby care answers.</p>
                <div class="card-tabs"><span class="tab-chip">RAG</span><span class="tab-chip">Vector Stores</span></div>
            </a>
            <a href="step6a_rag_problem.cfm" class="step-card">
                <div class="bottleneck-badge">&#9888; problem</div>
                <div class="card-num">6 — RAG: Poor Config</div>
                <h3>Same Queries, Low Scores</h3>
                <p>chunkSize:2000, minScore:0.1. Generic answers instead of precise baby care guidance.</p>
                <div class="card-tabs"><span class="tab-chip">RAG</span><span class="tab-chip">Vector Stores</span></div>
            </a>
        </div>

        <a href="step7_full_agent.cfm" class="step-card">
            <div class="card-num">7 — Full Care Agent</div>
            <h3>All Components Together</h3>
            <p>4-turn conversation: RAG + care tools + MCP supplies + guardrails + memory. All 6 PMT tabs.</p>
            <div class="card-tabs">
                <span class="tab-chip">Agents</span><span class="tab-chip">LLMs</span><span class="tab-chip">RAG</span>
                <span class="tab-chip">Vector Stores</span><span class="tab-chip">MCP Clients</span><span class="tab-chip">Trace Viewer</span>
            </div>
        </a>

        <a href="step8_load_generator.cfm" class="step-card">
            <div class="card-num">8 — Load Generator</div>
            <h3>Populate All Dashboards</h3>
            <p>23 varied AI calls across all providers to fill every PMT chart and grid.</p>
            <div class="card-tabs"><span class="tab-chip">All Tabs</span></div>
        </a>

    </div>

</div>

</body>
</html>
