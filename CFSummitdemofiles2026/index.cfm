<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Adobe ColdFusion 2025 AI Demos</title>
    <link rel="icon" href="data:,">
    <style>
        :root {
            --bg: #eef1f5;
            --ink: #171a21;
            --muted: #5f6775;
            --muted-2: #7b8492;
            --surface: #ffffff;
            --surface-2: #f7f8fa;
            --line: #d9dee7;
            --line-strong: #c4cad5;
            --adobe-red: #eb1000;
            --red-soft: #ffe7e5;
            --blue: #2364d8;
            --blue-soft: #e8f0ff;
            --green: #087f5b;
            --green-soft: #e2f7ee;
            --violet: #6d45c5;
            --violet-soft: #efe9ff;
            --amber: #9a6500;
            --amber-soft: #fff2ce;
            --pink: #be2f75;
            --pink-soft: #ffe5f1;
            --shadow: 0 20px 48px rgba(28, 36, 48, 0.12);
            --sans: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            --mono: "SFMono-Regular", Consolas, "Liberation Mono", monospace;
        }

        * {
            box-sizing: border-box;
        }

        html,
        body {
            height: 100%;
        }

        body {
            margin: 0;
            overflow: hidden;
            background:
                linear-gradient(180deg, #f8f9fb 0%, var(--bg) 56%, #e5e9f0 100%);
            color: var(--ink);
            font-family: var(--sans);
        }

        a {
            color: inherit;
        }

        .launcher {
            display: grid;
            grid-template-rows: auto minmax(0, 1fr);
            height: 100vh;
            min-height: 0;
        }

        .masthead {
            position: relative;
            overflow: hidden;
            border-bottom: 1px solid rgba(255, 255, 255, 0.18);
            background:
                linear-gradient(135deg, #18171a 0%, #24242a 54%, #3a1713 100%);
            color: #fff;
        }

        .masthead::before {
            position: absolute;
            inset: 0;
            content: "";
            background:
                linear-gradient(90deg, rgba(235, 16, 0, 0.18), transparent 34%),
                repeating-linear-gradient(90deg, rgba(255, 255, 255, 0.035) 0 1px, transparent 1px 36px);
            pointer-events: none;
        }

        .masthead-inner {
            position: relative;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 24px;
            width: min(1600px, calc(100% - 44px));
            margin: 0 auto;
            padding: 26px 0 22px;
        }

        .masthead-actions {
            display: flex;
            align-items: center;
            gap: 10px;
            flex: 0 0 auto;
        }

        .attendee-chip {
            display: none;
            max-width: 280px;
            min-height: 38px;
            align-items: center;
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 999px;
            background: rgba(255, 255, 255, 0.09);
            color: rgba(255, 255, 255, 0.84);
            font-size: 0.78rem;
            font-weight: 700;
            padding: 0 13px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            backdrop-filter: blur(10px);
        }

        .attendee-chip.visible {
            display: inline-flex;
        }

        .reset-button {
            display: inline-flex;
            min-height: 38px;
            align-items: center;
            justify-content: center;
            border: 1px solid rgba(255, 255, 255, 0.28);
            border-radius: 7px;
            background: rgba(255, 255, 255, 0.1);
            color: #fff;
            font: inherit;
            font-size: 0.78rem;
            font-weight: 800;
            padding: 0 13px;
            cursor: pointer;
            backdrop-filter: blur(10px);
            transition: background 0.15s ease, transform 0.15s ease;
        }

        .reset-button:hover,
        .reset-button:focus-visible {
            background: rgba(255, 255, 255, 0.18);
            transform: translateY(-1px);
        }

        .title-block {
            min-width: 0;
        }

        .eyebrow {
            display: flex;
            align-items: center;
            gap: 10px;
            margin: 0 0 9px;
            color: rgba(255, 255, 255, 0.72);
            font-family: var(--mono);
            font-size: 0.74rem;
            font-weight: 700;
            letter-spacing: 0;
            text-transform: uppercase;
        }

        .brand-mark {
            display: inline-grid;
            width: 34px;
            height: 34px;
            place-items: center;
            border-radius: 7px;
            background: var(--adobe-red);
            box-shadow: 0 12px 28px rgba(235, 16, 0, 0.35);
            color: #fff;
            font-family: var(--mono);
            font-size: 0.75rem;
            font-weight: 800;
        }

        h1 {
            margin: 0;
            font-size: 3rem;
            line-height: 1;
            letter-spacing: 0;
            font-weight: 800;
        }

        .masthead-copy {
            max-width: none;
            margin: 11px 0 0;
            color: rgba(255, 255, 255, 0.72);
            font-size: 0.98rem;
            line-height: 1.45;
            white-space: nowrap;
        }

        .content {
            min-height: 0;
            padding: 18px 22px 22px;
        }

        .demo-grid {
            display: grid;
            grid-template-columns: repeat(5, minmax(0, 1fr));
            gap: 14px;
            align-items: stretch;
            width: min(1600px, 100%);
            height: 100%;
            min-height: 0;
            margin: 0 auto;
        }

        .demo-card {
            --accent: var(--blue);
            --accent-soft: var(--blue-soft);
            display: flex;
            min-width: 0;
            min-height: 0;
            overflow: hidden;
            flex-direction: column;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: var(--surface);
            box-shadow: var(--shadow);
        }

        .demo-card.inventory {
            --accent: var(--blue);
            --accent-soft: var(--blue-soft);
        }

        .demo-card.review {
            --accent: var(--green);
            --accent-soft: var(--green-soft);
        }

        .demo-card.onboard {
            --accent: #0f766e;
            --accent-soft: #e1f7f3;
        }

        .demo-card.glaze {
            --accent: var(--pink);
            --accent-soft: var(--pink-soft);
        }

        .demo-card.cases {
            --accent: var(--amber);
            --accent-soft: var(--amber-soft);
        }

        .preview {
            position: relative;
            flex: 0 0 auto;
            min-height: 132px;
            max-height: 230px;
            border-bottom: 1px solid var(--line);
            background: var(--surface-2);
            aspect-ratio: 16 / 10;
        }

        .preview img {
            display: block;
            width: 100%;
            height: 100%;
            object-fit: cover;
            object-position: left top;
        }

        .preview::after {
            position: absolute;
            inset: 0;
            content: "";
            background:
                linear-gradient(180deg, rgba(255, 255, 255, 0.06), transparent 40%),
                linear-gradient(0deg, rgba(0, 0, 0, 0.18), transparent 46%);
            pointer-events: none;
        }

        .screen-label {
            position: absolute;
            right: 10px;
            bottom: 10px;
            z-index: 1;
            display: inline-flex;
            align-items: center;
            min-height: 24px;
            border: 1px solid rgba(255, 255, 255, 0.48);
            border-radius: 999px;
            background: rgba(17, 20, 27, 0.72);
            color: #fff;
            font-family: var(--mono);
            font-size: 0.66rem;
            font-weight: 700;
            padding: 0 8px;
            backdrop-filter: blur(10px);
        }

        .card-body {
            display: flex;
            flex: 1 1 auto;
            min-height: 0;
            flex-direction: column;
            gap: 12px;
            padding: 16px;
        }

        .demo-meta {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            min-height: 24px;
        }

        .demo-number {
            display: inline-flex;
            align-items: center;
            color: var(--accent);
            font-family: var(--mono);
            font-size: 0.7rem;
            font-weight: 800;
            letter-spacing: 0;
            text-transform: uppercase;
        }

        .accent-line {
            flex: 1;
            height: 2px;
            border-radius: 999px;
            background: linear-gradient(90deg, var(--accent), transparent);
        }

        h2 {
            margin: 0;
            font-size: 1.18rem;
            line-height: 1.15;
            letter-spacing: 0;
        }

        .demo-copy {
            display: -webkit-box;
            min-height: 0;
            overflow: hidden;
            margin: 0;
            color: var(--muted);
            font-size: 0.9rem;
            line-height: 1.42;
            -webkit-box-orient: vertical;
            -webkit-line-clamp: 5;
        }

        .tech-list {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-top: auto;
        }

        .tech-pill {
            display: inline-flex;
            align-items: center;
            min-height: 24px;
            border: 1px solid var(--line);
            border-radius: 999px;
            background: var(--surface-2);
            color: var(--muted);
            font-family: var(--mono);
            font-size: 0.67rem;
            font-weight: 700;
            padding: 0 8px;
            white-space: nowrap;
        }

        .tech-pill.primary {
            border-color: color-mix(in srgb, var(--accent), white 58%);
            background: var(--accent-soft);
            color: var(--accent);
        }

        .launch-row {
            display: flex;
            gap: 10px;
            align-items: center;
            padding-top: 2px;
        }

        .launch-button {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            width: 100%;
            min-height: 38px;
            border: 1px solid color-mix(in srgb, var(--accent), black 7%);
            border-radius: 7px;
            background: var(--accent);
            color: #fff;
            font-size: 0.85rem;
            font-weight: 800;
            text-decoration: none;
            transition: transform 0.15s ease, box-shadow 0.15s ease, filter 0.15s ease;
        }

        .launch-button svg {
            width: 16px;
            height: 16px;
            flex: 0 0 auto;
            stroke-width: 2.4;
        }

        .launch-button:hover {
            filter: brightness(1.06);
            box-shadow: 0 12px 26px color-mix(in srgb, var(--accent), transparent 74%);
            transform: translateY(-1px);
        }

        .launch-button:focus-visible {
            outline: 3px solid color-mix(in srgb, var(--accent), white 42%);
            outline-offset: 2px;
        }

        .tracking-gate {
            position: fixed;
            inset: 0;
            z-index: 20;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 24px;
            background:
                linear-gradient(135deg, rgba(20, 20, 25, 0.74), rgba(48, 22, 18, 0.66)),
                rgba(12, 14, 20, 0.44);
            backdrop-filter: blur(14px);
        }

        .tracking-gate.visible {
            display: flex;
        }

        .tracking-dialog {
            width: min(520px, 100%);
            border: 1px solid rgba(255, 255, 255, 0.48);
            border-radius: 8px;
            background: rgba(255, 255, 255, 0.88);
            box-shadow: 0 28px 84px rgba(0, 0, 0, 0.28);
            color: var(--ink);
            padding: 26px;
        }

        .tracking-dialog h2 {
            margin: 0;
            font-size: 1.65rem;
            line-height: 1.12;
        }

        .tracking-dialog p {
            margin: 9px 0 20px;
            color: var(--muted);
            line-height: 1.5;
        }

        .tracking-form {
            display: grid;
            gap: 13px;
        }

        .field {
            display: grid;
            gap: 6px;
        }

        .field label {
            color: #2d3442;
            font-size: 0.78rem;
            font-weight: 800;
        }

        .field input {
            width: 100%;
            min-height: 44px;
            border: 1px solid var(--line-strong);
            border-radius: 7px;
            background: rgba(255, 255, 255, 0.9);
            color: var(--ink);
            font: inherit;
            padding: 0 12px;
        }

        .field input:focus {
            border-color: var(--blue);
            outline: 3px solid rgba(35, 100, 216, 0.16);
        }

        .tracking-submit {
            min-height: 46px;
            border: 0;
            border-radius: 7px;
            background: var(--adobe-red);
            color: #fff;
            font: inherit;
            font-weight: 900;
            cursor: pointer;
            margin-top: 4px;
        }

        .tracking-submit:disabled {
            cursor: wait;
            opacity: 0.72;
        }

        .tracking-error {
            min-height: 18px;
            color: #b42318;
            font-size: 0.82rem;
            font-weight: 700;
        }

        @media (max-width: 1180px) {
            .launcher {
                overflow: hidden;
            }

            .demo-grid {
                grid-template-columns: repeat(3, minmax(0, 1fr));
                overflow: auto;
                padding-bottom: 2px;
            }
        }

        @media (max-width: 820px) {
            body {
                overflow: auto;
            }

            .launcher {
                height: auto;
                min-height: 100vh;
            }

            .masthead-inner {
                flex-direction: column;
                align-items: flex-start;
                width: min(100% - 32px, 1600px);
            }

            .masthead-actions {
                width: 100%;
                flex-wrap: wrap;
            }

            h1 {
                font-size: 2.2rem;
            }

            .content {
                padding: 16px;
            }

            .demo-grid {
                grid-template-columns: 1fr;
                height: auto;
                overflow: visible;
            }
        }

        @media (max-height: 760px) and (min-width: 1181px) {
            .masthead-inner {
                padding: 20px 0 16px;
            }

            h1 {
                font-size: 2.5rem;
            }

            .masthead-copy {
                margin-top: 8px;
                font-size: 0.92rem;
            }

            .content {
                padding-top: 14px;
                padding-bottom: 16px;
            }

            .card-body {
                gap: 10px;
                padding: 14px;
            }

            .demo-copy {
                -webkit-line-clamp: 5;
            }

            .preview {
                min-height: 118px;
            }
        }
    </style>
</head>
<body>
    <div class="launcher">
        <header class="masthead">
            <div class="masthead-inner">
                <div class="title-block">
                    <p class="eyebrow"><span class="brand-mark">CF</span> ColdFusion Summit 2026</p>
                    <h1>Adobe ColdFusion 2025 AI Demos</h1>
                    <p class="masthead-copy">Five local demo experiences showing how ColdFusion can connect LLMs, retrieval, vector search, tool calls, guardrails, and stateful applications.</p>
                </div>
                <div class="masthead-actions">
                    <span class="attendee-chip" id="attendeeChip"></span>
                    <button class="reset-button" id="demoResetButton" type="button">Demo reset</button>
                </div>
            </div>
        </header>

        <main class="content" aria-label="Demo launcher">
            <section class="demo-grid">
                <article class="demo-card inventory">
                    <div class="preview">
                        <img src="assets/screenshots/inventory-ai.png" alt="Inventory AI demo screenshot">
                        <span class="screen-label">Inventory AI</span>
                    </div>
                    <div class="card-body">
                        <div class="demo-meta">
                            <span class="demo-number">Demo 01</span>
                            <span class="accent-line" aria-hidden="true"></span>
                        </div>
                        <h2>Inventory AI</h2>
                        <p class="demo-copy">Ask natural-language questions about stock, low inventory, and reorders while the LLM calls ColdFusion MCP tools against live data.</p>
                        <div class="tech-list" aria-label="Technologies used">
                            <span class="tech-pill primary">MCP</span>
                            <span class="tech-pill primary">LLM</span>
                            <span class="tech-pill">Tool Calling</span>
                            <span class="tech-pill">SQL</span>
                        </div>
                        <div class="launch-row">
                            <a class="launch-button" href="MCPToolLLM/" data-demo-key="MCPToolLLM" data-demo-name="Inventory AI">
                                <span>Launch experience</span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" aria-hidden="true">
                                    <path d="M7 17 17 7"></path>
                                    <path d="M9 7h8v8"></path>
                                </svg>
                            </a>
                        </div>
                    </div>
                </article>

                <article class="demo-card review">
                    <div class="preview">
                        <img src="assets/screenshots/code-review-cf.png" alt="CodeReview.CF demo screenshot">
                        <span class="screen-label">CodeReview.CF</span>
                    </div>
                    <div class="card-body">
                        <div class="demo-meta">
                            <span class="demo-number">Demo 02</span>
                            <span class="accent-line" aria-hidden="true"></span>
                        </div>
                        <h2>CodeReview.CF</h2>
                        <p class="demo-copy">Review ColdFusion files with selectable review modes and retrieved coding standards feeding LLM-generated findings.</p>
                        <div class="tech-list" aria-label="Technologies used">
                            <span class="tech-pill primary">RAG</span>
                            <span class="tech-pill primary">LLM</span>
                            <span class="tech-pill">Code Analysis</span>
                            <span class="tech-pill">Local Model</span>
                        </div>
                        <div class="launch-row">
                            <a class="launch-button" href="CodeReviewLocal/" data-demo-key="CodeReviewLocal" data-demo-name="CodeReview.CF">
                                <span>Launch experience</span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" aria-hidden="true">
                                    <path d="M7 17 17 7"></path>
                                    <path d="M9 7h8v8"></path>
                                </svg>
                            </a>
                        </div>
                    </div>
                </article>

                <article class="demo-card onboard">
                    <div class="preview">
                        <img src="assets/screenshots/onboard-iq.png" alt="OnboardIQ demo screenshot">
                        <span class="screen-label">OnboardIQ</span>
                    </div>
                    <div class="card-body">
                        <div class="demo-meta">
                            <span class="demo-number">Demo 03</span>
                            <span class="accent-line" aria-hidden="true"></span>
                        </div>
                        <h2>OnboardIQ</h2>
                        <p class="demo-copy">Guide new hires through tasks while RAG, guardrails, source traces, and metrics show how the assistant stays grounded.</p>
                        <div class="tech-list" aria-label="Technologies used">
                            <span class="tech-pill primary">RAG</span>
                            <span class="tech-pill primary">LLM</span>
                            <span class="tech-pill">Guardrails</span>
                        </div>
                        <div class="launch-row">
                            <a class="launch-button" href="LLMRAGGuardrail/" data-demo-key="LLMRAGGuardrail" data-demo-name="OnboardIQ">
                                <span>Launch experience</span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" aria-hidden="true">
                                    <path d="M7 17 17 7"></path>
                                    <path d="M9 7h8v8"></path>
                                </svg>
                            </a>
                        </div>
                    </div>
                </article>

                <article class="demo-card glaze">
                    <div class="preview">
                        <img src="assets/screenshots/glaze-against-the-machine.png" alt="Glaze Against the Machine demo screenshot">
                        <span class="screen-label">Glaze Against the Machine</span>
                    </div>
                    <div class="card-body">
                        <div class="demo-meta">
                            <span class="demo-number">Demo 04</span>
                            <span class="accent-line" aria-hidden="true"></span>
                        </div>
                        <h2>Glaze Against the Machine</h2>
                        <p class="demo-copy">Fun, customizable RAG menu based bot with local vector store showing a retail store front for a donut shop.</p>
                        <div class="tech-list" aria-label="Technologies used">
                            <span class="tech-pill primary">Vector Store</span>
                            <span class="tech-pill primary">RAG</span>
                            <span class="tech-pill">LLM</span>
                            <span class="tech-pill">Embeddings</span>
                        </div>
                        <div class="launch-row">
                            <a class="launch-button" href="VectorStoreRag/" data-demo-key="VectorStoreRag" data-demo-name="Glaze Against the Machine">
                                <span>Launch experience</span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" aria-hidden="true">
                                    <path d="M7 17 17 7"></path>
                                    <path d="M9 7h8v8"></path>
                                </svg>
                            </a>
                        </div>
                    </div>
                </article>

                <article class="demo-card cases">
                    <div class="preview">
                        <img src="assets/screenshots/cf-cases.png" alt="CF Cases demo screenshot">
                        <span class="screen-label">CF Cases</span>
                    </div>
                    <div class="card-body">
                        <div class="demo-meta">
                            <span class="demo-number">Demo 05</span>
                            <span class="accent-line" aria-hidden="true"></span>
                        </div>
                        <h2>CF Cases</h2>
                        <p class="demo-copy">Play a stateful mystery adventure where an LLM interprets commands, rooms, clues, and investigation progress.</p>
                        <div class="tech-list" aria-label="Technologies used">
                            <span class="tech-pill primary">LLM</span>
                            <span class="tech-pill">Game AI</span>
                            <span class="tech-pill">Local Model</span>
                        </div>
                        <div class="launch-row">
                            <a class="launch-button" href="CFCase/" data-demo-key="CFCase" data-demo-name="CF Cases">
                                <span>Launch experience</span>
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" aria-hidden="true">
                                    <path d="M7 17 17 7"></path>
                                    <path d="M9 7h8v8"></path>
                                </svg>
                            </a>
                        </div>
                    </div>
                </article>
            </section>
        </main>
    </div>

    <div class="tracking-gate" id="trackingGate" role="dialog" aria-modal="true" aria-labelledby="trackingTitle">
        <section class="tracking-dialog">
            <h2 id="trackingTitle">Sign in to explore the demos</h2>
            <p id="trackingMessage">Enter your details once. We will record which demos you open during this local session.</p>
            <form class="tracking-form" id="trackingForm">
                <div class="field">
                    <label for="trackingName">Name</label>
                    <input id="trackingName" name="name" autocomplete="name" required>
                </div>
                <div class="field">
                    <label for="trackingEmail">Email</label>
                    <input id="trackingEmail" name="email" type="email" autocomplete="email" required>
                </div>
                <div class="field">
                    <label for="trackingCompany">Company</label>
                    <input id="trackingCompany" name="company" autocomplete="organization" required>
                </div>
                <div class="tracking-error" id="trackingError" role="alert"></div>
                <button class="tracking-submit" id="trackingSubmit" type="submit">Start demos</button>
            </form>
        </section>
    </div>

    <script>
        (() => {
            const idleMs = 10 * 60 * 1000;
            const touchMs = 60 * 1000;
            const state = {
                active: false,
                attendee: null,
                idleTimer: null,
                lastTouchAt: 0
            };

            const gate = document.getElementById("trackingGate");
            const form = document.getElementById("trackingForm");
            const submitButton = document.getElementById("trackingSubmit");
            const errorBox = document.getElementById("trackingError");
            const message = document.getElementById("trackingMessage");
            const attendeeChip = document.getElementById("attendeeChip");
            const resetButton = document.getElementById("demoResetButton");

            function readKey(object, key, fallback = undefined) {
                if (!object || typeof object !== "object") return fallback;
                if (Object.prototype.hasOwnProperty.call(object, key)) return object[key];
                const match = Object.keys(object).find((candidate) => candidate.toLowerCase() === key.toLowerCase());
                return match ? object[match] : fallback;
            }

            async function jsonFetch(url, payload = null) {
                const options = payload
                    ? {
                        method: "POST",
                        headers: {"Content-Type": "application/json"},
                        body: JSON.stringify(payload)
                    }
                    : {};
                const response = await fetch(url, options);
                const data = await response.json();
                if (!response.ok || readKey(data, "ok", true) === false) {
                    throw new Error(readKey(data, "message", `Request failed: ${response.status}`));
                }
                return data;
            }

            function showGate(text = "") {
                state.active = false;
                window.clearTimeout(state.idleTimer);
                message.textContent = text || "Enter your details once. We will record which demos you open during this local session.";
                gate.classList.add("visible");
                attendeeChip.classList.remove("visible");
                window.setTimeout(() => document.getElementById("trackingName").focus(), 50);
            }

            function hideGate(attendee) {
                state.active = true;
                state.attendee = attendee;
                gate.classList.remove("visible");
                attendeeChip.textContent = `${readKey(attendee, "name", "Attendee")} - ${readKey(attendee, "company", "Company")}`;
                attendeeChip.classList.add("visible");
                resetIdleTimer();
            }

            function resetIdleTimer() {
                if (!state.active) return;
                window.clearTimeout(state.idleTimer);
                state.idleTimer = window.setTimeout(async () => {
                    await resetTracking(false);
                    showGate("Session timed out after 10 minutes without activity. Sign in the next attendee to continue.");
                }, idleMs);
            }

            async function touchTracking() {
                if (!state.active) return;
                const now = Date.now();
                if (now - state.lastTouchAt < touchMs) return;
                state.lastTouchAt = now;
                try {
                    const data = await jsonFetch("usertracking/api/status.cfm?touch=1");
                    if (!readKey(data, "active", false)) {
                        showGate("Session timed out. Sign in the next attendee to continue.");
                    }
                } catch (error) {
                    // Tracking should never interrupt the launcher once a session is active.
                }
            }

            async function resetTracking(showFreshGate = true) {
                try {
                    await jsonFetch("usertracking/api/reset.cfm", {});
                } catch (error) {
                }
                for (const endpoint of [
                    "CFCase/api/reset.cfm",
                    "LLMRAGGuardrail/api/session-reset.cfm",
                    "CodeReviewLocal/api/session-reset.cfm",
                    "MCPToolLLM/api/session-reset.cfm"
                ]) {
                    try {
                        await fetch(endpoint, {method: "POST", keepalive: true});
                    } catch (error) {
                    }
                }
                state.active = false;
                state.attendee = null;
                window.clearTimeout(state.idleTimer);
                if (showFreshGate) {
                    form.reset();
                    showGate("Demo session reset. Sign in the next attendee to continue.");
                }
            }

            function sendTrack(payload) {
                const body = JSON.stringify(payload);
                const blob = new Blob([body], {type: "application/json"});
                if (navigator.sendBeacon && navigator.sendBeacon("usertracking/api/track.cfm", blob)) {
                    return;
                }
                fetch("usertracking/api/track.cfm", {
                    method: "POST",
                    headers: {"Content-Type": "application/json"},
                    body,
                    keepalive: true
                }).catch(() => {});
            }

            form.addEventListener("submit", async (event) => {
                event.preventDefault();
                errorBox.textContent = "";
                submitButton.disabled = true;
                submitButton.textContent = "Signing in...";

                try {
                    const data = await jsonFetch("usertracking/api/login.cfm", {
                        name: form.elements.name.value.trim(),
                        email: form.elements.email.value.trim(),
                        company: form.elements.company.value.trim()
                    });
                    hideGate(readKey(data, "attendee", {}));
                } catch (error) {
                    errorBox.textContent = error.message;
                } finally {
                    submitButton.disabled = false;
                    submitButton.textContent = "Start demos";
                }
            });

            resetButton.addEventListener("click", () => resetTracking(true));

            document.querySelectorAll(".launch-button[data-demo-key]").forEach((link) => {
                link.addEventListener("click", (event) => {
                    if (!state.active) {
                        event.preventDefault();
                        showGate("Sign in before launching a demo.");
                        return;
                    }

                    resetIdleTimer();
                    sendTrack({
                        eventType: "demo_launch",
                        demoKey: link.dataset.demoKey,
                        demoName: link.dataset.demoName,
                        href: link.href
                    });
                });
            });

            ["pointerdown", "keydown", "wheel", "touchstart"].forEach((eventName) => {
                window.addEventListener(eventName, () => {
                    resetIdleTimer();
                    touchTracking();
                }, {passive: true});
            });

            jsonFetch("usertracking/api/status.cfm?touch=1")
                .then((data) => {
                    if (readKey(data, "active", false)) {
                        hideGate(readKey(data, "attendee", {}));
                    } else {
                        showGate();
                    }
                })
                .catch(() => showGate("Tracking is initializing. Enter your details to continue."));
        })();
    </script>
</body>
</html>
