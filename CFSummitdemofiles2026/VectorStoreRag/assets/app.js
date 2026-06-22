const escapeHtml = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

function readKey(object, key, fallback = undefined) {
    if (!object || typeof object !== "object") return fallback;
    if (Object.prototype.hasOwnProperty.call(object, key)) return object[key];

    const match = Object.keys(object).find((candidate) => candidate.toLowerCase() === key.toLowerCase());
    return match ? object[match] : fallback;
}

async function postJson(url, payload = {}) {
    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    });
    const data = await response.json();
    if (!response.ok || readKey(data, "ok") === false) {
        throw new Error(readKey(data, "message") || `Request failed with status ${response.status}`);
    }
    return data;
}

function renderIngestStatus(data) {
    const statusGrid = document.getElementById("statusGrid");
    if (!statusGrid) return;

    statusGrid.innerHTML = `
        <div class="status-row">
            <span class="status-label">API key</span>
            <span class="chip ok">configured</span>
        </div>
        <div class="status-row">
            <span class="status-label">Ingested</span>
            <span class="chip ok">${escapeHtml(readKey(data, "addedCount"))} chunks</span>
        </div>
        <div class="status-row">
            <span class="status-label">Ingested menu</span>
            <span class="chip ok">${escapeHtml(readKey(data, "sourceName"))}</span>
        </div>
        ${readKey(data, "collectionName", "") ? `
        <div class="status-row">
            <span class="status-label">Collection</span>
            <span class="muted">${escapeHtml(readKey(data, "collectionName"))}</span>
        </div>` : ""}
        <div class="status-row">
            <span class="status-label">Last message</span>
            <span class="muted">${escapeHtml(readKey(data, "message"))}</span>
        </div>`;
}

function attachIngest() {
    const button = document.getElementById("ingestBtn");
    if (!button) return;

    button.addEventListener("click", async () => {
        const originalText = button.textContent;
        const sourceSelect = document.getElementById("sourceSelect");
        const sourceName = sourceSelect?.value || button.dataset.source || "";

        button.disabled = true;
        button.textContent = "Ingesting...";

        try {
            const data = await postJson("api/ingest.cfm", { sourceName });
            renderIngestStatus(data);
            button.textContent = "Menu Ingested";
        } catch (error) {
            button.disabled = false;
            button.textContent = originalText;
            alert(error.message);
        }
    });
}

function renderResetStatus(data) {
    const statusGrid = document.getElementById("statusGrid");
    if (!statusGrid) return;

    statusGrid.innerHTML = `
        <div class="status-row">
            <span class="status-label">API key</span>
            <span class="chip ok">configured</span>
        </div>
        <div class="status-row">
            <span class="status-label">Ingested</span>
            <span class="chip warn">not yet</span>
        </div>
        <div class="status-row">
            <span class="status-label">Ingested menu</span>
            <span class="chip warn">${escapeHtml(readKey(data, "sourceName", "No menu ingested"))}</span>
        </div>
        <div class="status-row">
            <span class="status-label">Last message</span>
            <span class="muted">${escapeHtml(readKey(data, "message"))}</span>
        </div>`;
}

function attachReset() {
    const button = document.getElementById("resetBtn");
    if (!button) return;

    button.addEventListener("click", async () => {
        if (!confirm("Reset the in-memory vector store and clear the current menu?")) return;

        const originalText = button.textContent;
        button.disabled = true;
        button.textContent = "Resetting...";

        try {
            const data = await postJson("api/reset.cfm");
            renderResetStatus(data);
            button.textContent = "Reset Complete";
        } catch (error) {
            button.textContent = originalText;
            alert(error.message);
        } finally {
            button.disabled = false;
        }
    });
}

function renderSources(sources = []) {
    const sourceNode = document.getElementById("sources");
    if (!sourceNode) return;

    if (!sources.length) {
        sourceNode.innerHTML = `<div class="source-card"><div class="source-text muted">No vector matches returned.</div></div>`;
        return;
    }

    sourceNode.innerHTML = sources.map((source, index) => `
        <article class="source-card">
            <div class="source-meta">
                <span class="chip">#${index + 1}</span>
                <span class="chip ok">score ${escapeHtml(readKey(source, "score"))}</span>
                <span class="chip">${escapeHtml(readKey(source, "name", "donut"))}</span>
                <span class="chip">${escapeHtml(readKey(source, "category", "catalog"))}</span>
                <span class="chip">${escapeHtml(readKey(source, "source", ""))}</span>
            </div>
            <div class="source-text">${escapeHtml(readKey(source, "text"))}</div>
        </article>
    `).join("");
}

function renderSearchLoading() {
    const answer = document.getElementById("answer");
    const sourceNode = document.getElementById("sources");

    if (answer) {
        answer.classList.add("muted");
        answer.classList.remove("error");
        answer.innerHTML = `
            <div class="loading-wrap">
                <div class="spinning-donut" aria-hidden="true">
                    <span class="sprinkle sprinkle-a"></span>
                    <span class="sprinkle sprinkle-b"></span>
                    <span class="sprinkle sprinkle-c"></span>
                </div>
                <div>
                    <strong>Finding the tastiest vector match...</strong>
                    <span>Embedding your question, checking the donut case, and asking ChatGPT.</span>
                </div>
            </div>`;
    }

    if (sourceNode) {
        sourceNode.innerHTML = `
            <div class="source-card loading-card">
                <div class="mini-donut" aria-hidden="true"></div>
                <div class="source-text muted">Warming up the vector oven...</div>
            </div>`;
    }
}

async function runSearch(question) {
    const answer = document.getElementById("answer");
    const input = document.getElementById("questionInput");
    const submit = document.querySelector("#searchForm button[type='submit']");

    if (!question.trim()) return;

    renderSearchLoading();
    input.disabled = true;
    submit.disabled = true;

    try {
        const data = await postJson("api/search.cfm", { question });
        answer.classList.remove("muted");
        answer.textContent = readKey(data, "answer") || "No answer returned.";
        renderSources(readKey(data, "sources", []));
    } catch (error) {
        answer.classList.remove("muted");
        answer.classList.add("error");
        answer.textContent = error.message;
    } finally {
        input.disabled = false;
        submit.disabled = false;
        input.focus();
    }
}

function attachSearch() {
    const form = document.getElementById("searchForm");
    const input = document.getElementById("questionInput");
    if (!form || !input) return;

    form.addEventListener("submit", (event) => {
        event.preventDefault();
        runSearch(input.value);
    });

    document.querySelectorAll(".quick-question").forEach((button) => {
        button.addEventListener("click", () => {
            input.value = button.textContent;
            runSearch(input.value);
        });
    });
}

attachIngest();
attachReset();
attachSearch();
