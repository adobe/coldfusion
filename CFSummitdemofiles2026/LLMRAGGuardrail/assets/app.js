const state = {
    steps: [],
    currentIndex: 0,
    ragEnabled: true,
    guardrailsEnabled: true,
    lastSources: [],
    lastTrace: {}
};

const fallbackSteps = [
    {
        id: "welcome-paperwork",
        label: "Welcome and paperwork",
        phase: "Day 1",
        owner: "People Ops",
        items: ["Complete day-one forms.", "Review employment acknowledgements.", "Attend orientation."],
        prompts: ["What paperwork is due today?", "Who do I contact if a form is wrong?"]
    }
];

function readKey(object, key, fallback = undefined) {
    if (!object || typeof object !== "object") return fallback;
    if (Object.prototype.hasOwnProperty.call(object, key)) return object[key];
    const match = Object.keys(object).find((candidate) => candidate.toLowerCase() === key.toLowerCase());
    return match ? object[match] : fallback;
}

function escapeHtml(value) {
    return String(value ?? "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

function formatText(value) {
    return escapeHtml(value).replace(/\n/g, "<br>");
}

async function requestJson(url, payload) {
    const options = payload === undefined
        ? { method: "GET" }
        : {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(payload)
        };

    const response = await fetch(url, options);
    let data = {};
    try {
        data = await response.json();
    } catch (error) {
        data = {};
    }

    if (!response.ok || readKey(data, "ok") === false) {
        throw new Error(readKey(data, "message", `Request failed with status ${response.status}`));
    }

    return data;
}

function currentStep() {
    return state.steps[state.currentIndex] || state.steps[0] || fallbackSteps[0];
}

function setSwitch(button, enabled) {
    button.classList.toggle("is-on", enabled);
    button.setAttribute("aria-checked", enabled ? "true" : "false");
}

function renderToggles() {
    setSwitch(document.getElementById("ragToggle"), state.ragEnabled);
    setSwitch(document.getElementById("guardrailToggle"), state.guardrailsEnabled);
    document.getElementById("traceRag").textContent = state.ragEnabled ? "on" : "off";
    document.getElementById("traceGuardrails").textContent = state.guardrailsEnabled ? "on" : "off";
    document.getElementById("traceGuardrailMode").textContent = state.guardrailsEnabled ? "model inference" : "off";
    if (!state.guardrailsEnabled) {
        document.getElementById("traceGuardrailDecision").textContent = "off";
        document.getElementById("traceGuardrailCategory").textContent = "disabled";
    }
}

function renderSteps() {
    const list = document.getElementById("stepsList");
    const completed = state.currentIndex;

    list.innerHTML = state.steps.map((step, index) => {
        const isDone = index < state.currentIndex;
        const isCurrent = index === state.currentIndex;
        const marker = isDone ? "&check;" : isCurrent ? "&rarr;" : String(index + 1);
        return `
            <button class="step-button ${isDone ? "done" : ""} ${isCurrent ? "current" : ""}" type="button" data-step-index="${index}">
                <span class="step-marker">${marker}</span>
                <span>
                    <span class="step-name">${escapeHtml(readKey(step, "label", ""))}</span>
                    <span class="step-sub">${escapeHtml(readKey(step, "phase", ""))}</span>
                </span>
            </button>`;
    }).join("");

    list.querySelectorAll(".step-button").forEach((button) => {
        button.addEventListener("click", () => selectStep(Number(button.dataset.stepIndex)));
    });

    const total = state.steps.length || 1;
    const pct = Math.round((completed / total) * 100);
    document.getElementById("progressFill").style.width = `${pct}%`;
    document.getElementById("progressText").textContent = `${completed} / ${total} complete`;
    document.getElementById("phaseText").textContent = readKey(currentStep(), "phase", "");
}

function renderStepDetails() {
    const step = currentStep();
    const items = readKey(step, "items", []);
    const prompts = readKey(step, "prompts", []);

    document.getElementById("stepOwner").textContent = readKey(step, "owner", "");
    document.getElementById("stepTitle").textContent = readKey(step, "label", "");
    document.getElementById("stepPhase").textContent = readKey(step, "phase", "");
    document.getElementById("stepCount").textContent = `Step ${state.currentIndex + 1} of ${state.steps.length}`;

    document.getElementById("checklist").innerHTML = items.map((item) => `
        <div class="todo-item">
            <span class="todo-dot"></span>
            <span class="todo-text">${escapeHtml(item)}</span>
        </div>
    `).join("");

    const quickPrompts = [...prompts, "Write a regex for validating phone numbers"];
    document.getElementById("quickPrompts").innerHTML = quickPrompts.map((prompt) => `
        <button class="quick-button" type="button">${escapeHtml(prompt)}</button>
    `).join("");

    document.querySelectorAll(".quick-button").forEach((button) => {
        button.addEventListener("click", () => {
            const input = document.getElementById("questionInput");
            input.value = button.textContent;
            input.focus();
            autoResize(input);
        });
    });
}

function selectStep(index) {
    if (index < 0 || index >= state.steps.length) return;
    state.currentIndex = index;
    renderSteps();
    renderStepDetails();
}

function appendMessage(role, text, meta = []) {
    const messages = document.getElementById("chatMessages");
    const article = document.createElement("article");
    article.className = `message ${role}`;

    const avatar = role === "user" ? "You" : "AI";
    const tagHtml = meta.map((tag) => `<span class="tag ${tag.className || ""}">${escapeHtml(tag.label)}</span>`).join("");

    article.innerHTML = `
        <div class="avatar">${avatar}</div>
        <div class="bubble">
            <div class="message-meta">${role === "user" ? "Employee" : "OnboardIQ"} ${tagHtml}</div>
            <div class="message-text">${formatText(text)}</div>
        </div>`;

    messages.appendChild(article);
    messages.scrollTop = messages.scrollHeight;
    return article;
}

function appendLoading() {
    const loading = appendMessage("assistant", "Thinking through the current onboarding context...", [
        { label: state.ragEnabled ? "RAG" : "No RAG", className: state.ragEnabled ? "green" : "amber" },
        { label: state.guardrailsEnabled ? "Guardrails" : "Open", className: state.guardrailsEnabled ? "green" : "amber" }
    ]);
    loading.classList.add("thinking");
    loading.setAttribute("role", "status");
    loading.setAttribute("aria-live", "polite");
    return loading;
}

function renderAssistantResponse(data) {
    const refusal = readKey(data, "refusal", false);
    const meta = [
        { label: state.ragEnabled ? "RAG" : "No RAG", className: state.ragEnabled ? "green" : "amber" },
        { label: state.guardrailsEnabled ? (refusal ? "Refused" : "Guarded") : "Open", className: refusal ? "red" : state.guardrailsEnabled ? "green" : "amber" }
    ];

    appendMessage("assistant", readKey(data, "answer", "No answer returned."), meta);
}

function renderSources(sources = []) {
    state.lastSources = sources;
    const list = document.getElementById("sourceList");
    const empty = document.getElementById("ragEmpty");

    if (!sources.length) {
        empty.style.display = "block";
        empty.textContent = state.ragEnabled ? "No retrieved documents yet." : "RAG is off for the current request.";
        list.innerHTML = "";
        return;
    }

    empty.style.display = "none";
    list.innerHTML = sources.map((source, index) => `
        <article class="source-card">
            <div class="source-title">${index + 1}. ${escapeHtml(readKey(source, "section", "Section"))}</div>
            <div class="source-meta">
                <span class="tag green">score ${escapeHtml(readKey(source, "score", "n/a"))}</span>
                <span class="tag">${escapeHtml(readKey(source, "source", ""))}</span>
            </div>
            <div class="source-excerpt">${formatText(readKey(source, "excerpt", ""))}</div>
        </article>
    `).join("");
}

function renderMetrics(metrics = {}, memory = {}) {
    const runtime = readKey(memory, "runtime", {});
    const usedMb = Number(readKey(runtime, "usedMb", 0));
    const maxMb = Number(readKey(runtime, "maxMb", 0));
    const usedPct = Number(readKey(runtime, "usedPct", maxMb ? Math.round((usedMb / maxMb) * 100) : 0));

    document.getElementById("memoryValue").textContent = usedMb ? `${usedMb} MB` : "-- MB";
    document.getElementById("memoryFill").style.width = `${Math.min(100, usedPct)}%`;
    document.getElementById("tokenValue").textContent = Number(readKey(metrics, "totalTokens", 0)).toLocaleString();
    document.getElementById("lastTokenValue").textContent = `last ${Number(readKey(metrics, "lastTokens", 0)).toLocaleString()}`;
    document.getElementById("latencyValue").textContent = `${Number(readKey(metrics, "lastLatencyMs", 0)).toLocaleString()} ms`;
    document.getElementById("requestValue").textContent = `${Number(readKey(metrics, "requestCount", 0)).toLocaleString()} requests`;
    document.getElementById("guardrailValue").textContent = readKey(metrics, "lastGuardrailStatus", state.guardrailsEnabled ? "on" : "off");
    document.getElementById("ragCountValue").textContent = `${Number(readKey(metrics, "lastRagCount", 0)).toLocaleString()} chunks`;
}

function renderHistory(history = []) {
    const list = document.getElementById("historyList");
    if (!history.length) {
        list.innerHTML = `
            <div class="history-item">
                <div class="history-role">session</div>
                <div class="history-text">Conversation memory appears here after the first question.</div>
            </div>`;
        return;
    }

    list.innerHTML = history.slice(-6).reverse().map((entry) => {
        const text = readKey(entry, "text", "");
        const role = readKey(entry, "role", "entry");
        return `
            <div class="history-item">
                <div class="history-role">${escapeHtml(role)}</div>
                <div class="history-text">${escapeHtml(text.length > 120 ? `${text.slice(0, 120)}...` : text)}</div>
            </div>`;
    }).join("");
}

function renderTrace(trace = {}) {
    state.lastTrace = trace;
    const guardrail = readKey(trace, "guardrail", {});
    document.getElementById("traceRag").textContent = state.ragEnabled ? "on" : "off";
    document.getElementById("traceGuardrails").textContent = state.guardrailsEnabled ? "on" : "off";
    document.getElementById("traceGuardrailMode").textContent = String(readKey(
        guardrail,
        "mode",
        state.guardrailsEnabled ? "model-inference" : "off"
    )).replace(/-/g, " ");
    document.getElementById("traceGuardrailDecision").textContent = readKey(
        guardrail,
        "decision",
        state.guardrailsEnabled ? "pending" : "off"
    );
    document.getElementById("traceGuardrailCategory").textContent = String(readKey(
        guardrail,
        "category",
        state.guardrailsEnabled ? "pending" : "disabled"
    )).replace(/-/g, " ");
    document.getElementById("traceModel").textContent = readKey(trace, "model", "llama3.2");
    document.getElementById("traceEmbedding").textContent = readKey(trace, "embeddingModel", "nomic-embed-text");
    document.getElementById("traceCollection").textContent = readKey(trace, "collectionName", "pending") || "pending";
    const guardrailReason = readKey(guardrail, "reason", "");
    if (guardrailReason) {
        document.getElementById("traceNote").textContent = `Guardrail: ${guardrailReason}`;
    }
}

function renderStatus(data) {
    const steps = readKey(data, "steps", fallbackSteps);
    state.steps = Array.isArray(steps) && steps.length ? steps : fallbackSteps;

    const selectedStepId = readKey(data, "selectedStepId", readKey(currentStep(), "id", ""));
    const selectedIndex = state.steps.findIndex((step) => readKey(step, "id") === selectedStepId);
    state.currentIndex = selectedIndex >= 0 ? selectedIndex : state.currentIndex;

    const model = readKey(data, "model", {});
    const ingestStatus = readKey(data, "ingestStatus", {});
    const modelReachable = readKey(model, "reachable", false);
    const ingestReady = readKey(ingestStatus, "ready", false);

    const modelChip = document.getElementById("modelChip");
    modelChip.textContent = modelReachable
        ? `Ollama ${readKey(model, "chatModel", "ready")}`
        : "Ollama offline";
    modelChip.className = `status-chip ${modelReachable ? "ok" : "bad"}`;

    const kbChip = document.getElementById("kbChip");
    kbChip.textContent = ingestReady
        ? `${readKey(ingestStatus, "chunkCount", 0)} chunks ready`
        : "Knowledge base pending";
    kbChip.className = `status-chip ${ingestReady ? "ok" : "warn"}`;

    renderSteps();
    renderStepDetails();
    renderToggles();
    renderMetrics(readKey(data, "metrics", {}), readKey(data, "memory", {}));
    renderHistory(readKey(data, "history", []));
    renderTrace({
        model: readKey(model, "chatModel", "llama3.2"),
        embeddingModel: readKey(model, "embeddingModel", "nomic-embed-text"),
        collectionName: readKey(ingestStatus, "collectionName", "pending")
    });
}

async function loadStatus() {
    try {
        const data = await requestJson("api/status.cfm");
        renderStatus(data);
    } catch (error) {
        state.steps = fallbackSteps;
        renderSteps();
        renderStepDetails();
        document.getElementById("modelChip").textContent = error.message;
        document.getElementById("modelChip").className = "status-chip bad";
        appendMessage("assistant", error.message, [{ label: "Error", className: "red" }]);
    }
}

async function sendQuestion(question) {
    if (!question.trim()) return;

    appendMessage("user", question);
    const loading = appendLoading();
    const input = document.getElementById("questionInput");
    const button = document.getElementById("sendButton");
    input.disabled = true;
    button.disabled = true;

    try {
        const data = await requestJson("api/ask.cfm", {
            question,
            stepId: readKey(currentStep(), "id", ""),
            ragEnabled: state.ragEnabled,
            guardrailsEnabled: state.guardrailsEnabled
        });

        loading.remove();
        renderAssistantResponse(data);
        renderSources(readKey(data, "sources", []));
        renderMetrics(readKey(data, "metrics", {}), readKey(data, "memory", {}));
        renderHistory(readKey(data, "history", []));
        renderTrace(readKey(data, "trace", {}));
        selectDashboardTab("rag");
    } catch (error) {
        loading.remove();
        appendMessage("assistant", error.message, [{ label: "Error", className: "red" }]);
    } finally {
        input.disabled = false;
        button.disabled = false;
        input.focus();
    }
}

function selectDashboardTab(name) {
    document.querySelectorAll(".dash-tab").forEach((tab) => {
        tab.classList.toggle("active", tab.dataset.tab === name);
    });
    document.querySelectorAll(".dash-section").forEach((section) => {
        section.classList.toggle("active", section.id === `tab-${name}`);
    });
}

function autoResize(textarea) {
    textarea.style.height = "auto";
    textarea.style.height = `${Math.min(textarea.scrollHeight, 120)}px`;
}

function attachEvents() {
    document.getElementById("ragToggle").addEventListener("click", () => {
        state.ragEnabled = !state.ragEnabled;
        renderToggles();
        renderSources(state.ragEnabled ? state.lastSources : []);
    });

    document.getElementById("guardrailToggle").addEventListener("click", () => {
        state.guardrailsEnabled = !state.guardrailsEnabled;
        renderToggles();
        document.getElementById("guardrailValue").textContent = state.guardrailsEnabled ? "on" : "off";
    });

    document.getElementById("chatForm").addEventListener("submit", (event) => {
        event.preventDefault();
        const input = document.getElementById("questionInput");
        const question = input.value.trim();
        input.value = "";
        autoResize(input);
        sendQuestion(question);
    });

    document.getElementById("questionInput").addEventListener("input", (event) => {
        autoResize(event.currentTarget);
    });

    document.querySelectorAll(".dash-tab").forEach((tab) => {
        tab.addEventListener("click", () => selectDashboardTab(tab.dataset.tab));
    });

    document.getElementById("reingestButton").addEventListener("click", async () => {
        const button = document.getElementById("reingestButton");
        button.disabled = true;
        button.textContent = "Ingesting";
        try {
            const data = await requestJson("api/ingest.cfm", { force: true });
            document.getElementById("traceNote").textContent = readKey(data, "message", "Knowledge base ingested.");
            await loadStatus();
        } catch (error) {
            document.getElementById("traceNote").textContent = error.message;
        } finally {
            button.disabled = false;
            button.textContent = "Reingest";
        }
    });

    document.getElementById("resetButton").addEventListener("click", async () => {
        const button = document.getElementById("resetButton");
        button.disabled = true;
        button.textContent = "Resetting";
        try {
            const data = await requestJson("api/reset.cfm", {});
            state.lastSources = [];
            renderSources([]);
            renderMetrics(readKey(data, "metrics", {}), readKey(data, "memory", {}));
            renderHistory([]);
            document.getElementById("traceNote").textContent = "Session and vector store reset.";
            await loadStatus();
        } catch (error) {
            document.getElementById("traceNote").textContent = error.message;
        } finally {
            button.disabled = false;
            button.textContent = "Reset";
        }
    });
}

attachEvents();
loadStatus();
