const readKey = (object, key, fallback = undefined) => {
    if (!object || typeof object !== "object") return fallback;
    if (Object.prototype.hasOwnProperty.call(object, key)) return object[key];
    const match = Object.keys(object).find((candidate) => candidate.toLowerCase() === key.toLowerCase());
    return match ? object[match] : fallback;
};

const escapeHtml = (value) => String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

const state = {
    warehouse: "",
    modelKey: "",
    selectedModel: {},
    chatBusy: false,
    items: [],
    stats: {},
    resultFilterLabel: "",
    tableMessage: ""
};

async function getJson(url) {
    const response = await fetch(url);
    const data = await response.json();
    if (!response.ok || readKey(data, "ok") === false) {
        throw new Error(readKey(data, "message", `Request failed: ${response.status}`));
    }
    return data;
}

async function postJson(url, payload) {
    const response = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
    });
    const data = await response.json();
    if (!response.ok || readKey(data, "ok") === false) {
        const error = new Error(readKey(data, "message", `Request failed: ${response.status}`));
        error.data = data;
        throw error;
    }
    return data;
}

function renderModelControls(options = [], selectedModel = {}) {
    const select = document.getElementById("modelSelect");
    const provider = document.getElementById("providerLabel");

    select.innerHTML = options.map((option) => {
        const key = readKey(option, "key", "");
        const label = readKey(option, "label", key);
        const modelName = readKey(option, "modelLabel", readKey(option, "modelName", ""));
        const available = readKey(option, "available", false);
        const selected = key === readKey(selectedModel, "key", state.modelKey) ? " selected" : "";
        const disabled = available ? "" : " disabled";
        const suffix = available ? "" : " (key needed)";
        return `<option value="${escapeHtml(key)}"${selected}${disabled}>${escapeHtml(label)} - ${escapeHtml(modelName)}${suffix}</option>`;
    }).join("");

    state.modelKey = readKey(selectedModel, "key", state.modelKey);
    state.selectedModel = selectedModel;
    provider.textContent = `MCP + ${readKey(selectedModel, "providerLabel", "AI")} ${readKey(selectedModel, "modelLabel", "")}`;
}

async function loadModels() {
    const data = await getJson("api/models.cfm");
    renderModelControls(readKey(data, "options", []), readKey(data, "selectedModel", {}));
}

async function setModel(modelKey) {
    const data = await postJson("api/models.cfm", { modelKey });
    renderModelControls(readKey(data, "options", []), readKey(data, "selectedModel", {}));
}

function stockClass(status) {
    const normalized = String(status || "ok").toLowerCase().replace(/\s+/g, "-");
    return `stock-${normalized}`;
}

function setChatBusy(isBusy) {
    state.chatBusy = isBusy;
    document.querySelector(".chat-sidebar").classList.toggle("chat-busy", isBusy);
    document.getElementById("chatBusyOverlay").setAttribute("aria-hidden", String(!isBusy));
    document.getElementById("chatInput").disabled = isBusy;
    document.querySelector(".send-btn").disabled = isBusy;
    document.getElementById("modelSelect").disabled = isBusy;
    document.querySelectorAll(".qq-btn").forEach((button) => {
        button.disabled = isBusy;
    });
}

function renderInventory() {
    const rows = document.getElementById("inventoryRows");
    const rowCount = document.getElementById("rowCount");
    rowCount.textContent = state.items.length;

    if (!state.items.length) {
        rows.innerHTML = `<tr><td colspan="8" class="empty-cell">${escapeHtml(state.tableMessage || "No inventory rows match the current filter.")}</td></tr>`;
        return;
    }

    rows.innerHTML = state.items.map((item) => {
        const sku = readKey(item, "sku");
        const name = readKey(item, "name", readKey(item, "itemName", ""));
        const category = readKey(item, "category");
        const warehouse = readKey(item, "warehouse");
        const quantity = readKey(item, "quantityOnHand");
        const reorderPoint = readKey(item, "reorderPoint", readKey(item, "reorderThreshold", ""));
        const reorderQuantity = readKey(item, "reorderQuantity", readKey(item, "recommendedQuantity", ""));
        const status = readKey(item, "status");
        const supplier = readKey(item, "supplier");
        const leadTime = Number(readKey(item, "leadTimeDays", 0));
        const value = readKey(item, "inventoryValue", readKey(item, "estimatedCost", ""));
        const stockHelp = Number(quantity) <= Number(reorderPoint)
            ? `${quantity} total items, reorder at ${reorderPoint}. Reorder ${reorderQuantity} units.`
            : `${quantity} total items, reorder at ${reorderPoint}. No action required.`;

        return `
            <tr>
                <td><span class="sku">${escapeHtml(sku)}</span></td>
                <td><div class="product-name">${escapeHtml(name)}</div><div class="product-cat">${escapeHtml(category)}</div></td>
                <td><span class="warehouse-tag">${escapeHtml(warehouse)}</span></td>
                <td>
                    <span class="stock-badge ${stockClass(status)}" tabindex="0" aria-label="${escapeHtml(stockHelp)}">
                        ${escapeHtml(quantity)} / ${escapeHtml(reorderPoint)} ${escapeHtml(status)}
                        <span class="stock-tip" role="tooltip">${escapeHtml(stockHelp)}</span>
                    </span>
                </td>
                <td><span class="sku">${escapeHtml(reorderQuantity)}</span></td>
                <td>${escapeHtml(supplier)}</td>
                <td><span class="lead-time ${leadTime >= 18 ? "long" : ""}">${leadTime}d</span></td>
                <td>${escapeHtml(value)}</td>
            </tr>`;
    }).join("");
}

function renderStats() {
    const stats = state.stats;
    document.getElementById("statItems").textContent = readKey(stats, "totalItems", "--");
    document.getElementById("statLow").textContent = readKey(stats, "lowStock", "--");

    document.getElementById("activeFilters").innerHTML = state.resultFilterLabel
        ? `<span class="filter-chip">MCP result: ${escapeHtml(state.resultFilterLabel)}</span>`
        : state.warehouse
        ? `<span class="filter-chip">warehouse=${escapeHtml(state.warehouse)}</span>`
        : `<span class="filter-chip">all warehouses</span>`;
}

async function loadInventory() {
    state.resultFilterLabel = "";
    state.tableMessage = "";
    const params = new URLSearchParams();
    if (state.warehouse) params.set("warehouse", state.warehouse);
    const data = await getJson(`api/inventory.cfm?${params.toString()}`);
    state.items = readKey(data, "items", []);
    state.stats = readKey(data, "stats", {});
    renderStats();
    renderInventory();
}

function renderInventoryMessage(message) {
    state.items = [];
    state.resultFilterLabel = "";
    state.tableMessage = message;
    document.getElementById("rowCount").textContent = "0";
    document.getElementById("activeFilters").innerHTML = `<span class="filter-chip">MCP result pending</span>`;
    renderInventory();
}

function affectedItemsFromToolResult(toolResult = {}) {
    const items = readKey(toolResult, "items", []);
    if (Array.isArray(items) && items.length) return items;

    const recommendations = readKey(toolResult, "recommendations", []);
    if (Array.isArray(recommendations) && recommendations.length) return recommendations;

    const item = readKey(toolResult, "item", {});
    if (item && typeof item === "object" && Object.keys(item).length) return [item];

    return [];
}

function applyToolResultToInventory(data = {}) {
    const toolCall = readKey(data, "toolCall", {});
    const toolName = readKey(toolCall, "name", "MCP tool");
    const toolResult = readKey(data, "toolResult", {});
    const affectedItems = affectedItemsFromToolResult(toolResult);
    const count = readKey(toolResult, "count", affectedItems.length);

    state.items = affectedItems;
    state.resultFilterLabel = `${toolName} (${count} ${Number(count) === 1 ? "row" : "rows"})`;
    state.tableMessage = affectedItems.length
        ? ""
        : "No inventory rows were affected by the latest MCP result.";

    renderStats();
    renderInventory();
}

function appendUserMessage(message) {
    document.getElementById("chatMessages").insertAdjacentHTML("beforeend", `
        <div class="message">
            <div class="msg-user"><div class="msg-user-bubble">${escapeHtml(message)}</div></div>
        </div>`);
}

function collapsePreviousResponses() {
    document.querySelectorAll(".message.agent-response:not(.collapsed)").forEach((message) => {
        setMessageCollapsed(message, true);
    });
}

function setMessageCollapsed(message, isCollapsed) {
    const button = message.querySelector(".collapse-btn");
    message.classList.toggle("collapsed", isCollapsed);
    if (button) {
        button.textContent = isCollapsed ? "Expand" : "Collapse";
        button.setAttribute("aria-expanded", String(!isCollapsed));
    }
}

function setSqlCardCollapsed(card, isCollapsed) {
    const button = card.querySelector(".sql-collapse-btn");
    card.classList.toggle("collapsed", isCollapsed);
    if (button) {
        button.textContent = isCollapsed ? "Expand" : "Collapse";
        button.setAttribute("aria-expanded", String(!isCollapsed));
    }
}

function collapsePreviousSqlCards() {
    document.querySelectorAll(".sql-card:not(.collapsed)").forEach((card) => {
        setSqlCardCollapsed(card, true);
    });
}

function appendAgentMessage(answer, data = {}, options = {}) {
    const toolCall = readKey(data, "toolCall", {});
    const name = readKey(toolCall, "name", "none");
    const elapsed = readKey(data, "elapsedMs", "--");
    const cairoi = readKey(data, "cairoi", {});
    const traceId = readKey(cairoi, "traceId", "");
    const traceUrl = readKey(cairoi, "traceUrl", "");
    const traceLink = traceId && traceUrl
        ? `<a class="msg-trace-link" href="${escapeHtml(traceUrl)}" target="_blank" rel="noopener">CAIROI ${escapeHtml(traceId)}</a>`
        : "";
    const collapsible = readKey(options, "collapsible", false);
    const messageClass = collapsible ? "message agent-response" : "message";
    const controls = collapsible
        ? `<button class="collapse-btn" type="button" aria-expanded="true">Collapse</button>`
        : "";

    document.getElementById("chatMessages").insertAdjacentHTML("beforeend", `
        <div class="${messageClass}">
            <div class="msg-agent">
                <div class="msg-ai-avatar">iAI</div>
                <div class="msg-agent-body">
                    <div class="msg-agent-bubble">${escapeHtml(answer)}</div>
                    <div class="msg-meta"><span class="msg-tag tag-tool">${escapeHtml(name)}</span><span>${escapeHtml(elapsed)}ms</span>${traceLink}${controls}</div>
                </div>
            </div>
        </div>`);

    const chatMessages = document.getElementById("chatMessages");
    chatMessages.scrollTop = chatMessages.scrollHeight;
    return chatMessages.lastElementChild;
}

function renderDebug(data = {}) {
    const toolCall = readKey(data, "toolCall", {});
    const toolResult = readKey(data, "toolResult", {});
    const mcp = readKey(data, "mcp", {});
    const cairoi = readKey(data, "cairoi", {});
    const traceId = readKey(cairoi, "traceId", "");
    const traceUrl = readKey(cairoi, "traceUrl", "");
    const traceLine = traceId && traceUrl
        ? `<br><span class="db-key">CAIROI trace</span>: <a href="${escapeHtml(traceUrl)}" target="_blank" rel="noopener">${escapeHtml(traceId)}</a>`
        : "";
    const count = readKey(toolResult, "count", readKey(readKey(toolResult, "items", []), "length", ""));
    const items = readKey(toolResult, "items", []);
    const topItem = Array.isArray(items) && items.length ? items[0] : {};
    const searchLines = [
        ["query", readKey(toolResult, "query", "")],
        ["normalized", readKey(toolResult, "normalizedQuery", "")],
        ["tokens", JSON.stringify(readKey(toolResult, "meaningfulTokens", []))],
        ["strategy", readKey(toolResult, "matchStrategy", readKey(topItem, "matchType", ""))],
        ["topScore", readKey(topItem, "matchScore", "")],
        ["matchedTerms", JSON.stringify(readKey(topItem, "matchedTerms", []))]
    ].filter(([, value]) => value !== "" && value !== "[]" && value !== undefined);
    const searchDebug = searchLines.length
        ? `<br>${searchLines.map(([key, value]) => `<span class="db-key">${escapeHtml(key)}</span>: <span class="db-val">${escapeHtml(value)}</span>`).join("<br>")}`
        : "";

    document.getElementById("debugPanel").innerHTML = `
        <div class="debug-block">
            <div class="db-header"><span class="db-type dbt-tool">TOOL</span><span>${escapeHtml(readKey(toolCall, "name", "none"))}</span><span class="db-time">${escapeHtml(readKey(data, "elapsedMs", "--"))}ms</span></div>
            <div class="db-body"><span class="db-key">model</span>: <span class="db-val">${escapeHtml(readKey(readKey(data, "model", {}), "modelLabel", readKey(data, "modelName", "")))}</span><br><span class="db-key">arguments</span>: <span class="db-str">${escapeHtml(JSON.stringify(readKey(toolCall, "arguments", {})))}</span></div>
        </div>
        <div class="debug-block">
            <div class="db-header"><span class="db-type dbt-result">RESULT</span><span>MCP response</span></div>
            <div class="db-body"><span class="db-key">mode</span>: <span class="db-val">${escapeHtml(readKey(mcp, "mode", ""))}</span><br><span class="db-key">count</span>: <span class="db-val">${escapeHtml(count)}</span>${searchDebug}<br><span class="db-key">endpoint</span>: <span class="db-str">${escapeHtml(readKey(mcp, "endpoint", ""))}</span>${traceLine}</div>
        </div>`;
}

function renderSqlDebug(data = {}) {
    const toolResult = readKey(data, "toolResult", {});
    const sqlDebug = readKey(toolResult, "sqlDebug", {});
    const sql = readKey(sqlDebug, "sql", "");
    const toolName = readKey(sqlDebug, "toolName", readKey(readKey(data, "toolCall", {}), "name", "MCP tool"));

    if (!sql) return;

    const params = readKey(sqlDebug, "params", {});
    const toolArguments = readKey(sqlDebug, "toolArguments", readKey(readKey(data, "toolCall", {}), "arguments", {}));
    const postFilters = readKey(sqlDebug, "postFilters", {});
    const sqlPanel = document.getElementById("sqlPanel");
    const emptyCard = sqlPanel.querySelector(".debug-block:not(.sql-card)");
    if (emptyCard) emptyCard.remove();

    sqlPanel.insertAdjacentHTML("beforeend", `
        <div class="debug-block sql-card">
            <div class="db-header">
                <span class="db-type dbt-result">SQL</span>
                <span>${escapeHtml(toolName)}</span>
                <button class="sql-collapse-btn" type="button" aria-expanded="true">Collapse</button>
            </div>
            <div class="db-body sql-card-body">
                <div class="sql-section-label">Tool arguments</div>
                <pre class="sql-json">${escapeHtml(JSON.stringify(toolArguments, null, 2))}</pre>
                <div class="sql-section-label">Parameterized SQL</div>
                <pre class="sql-code">${escapeHtml(sql)}</pre>
                <div class="sql-section-label">Bound params</div>
                <pre class="sql-json">${escapeHtml(JSON.stringify(params, null, 2))}</pre>
                ${Object.keys(postFilters).some((key) => String(postFilters[key] ?? "").length)
                    ? `<div class="sql-section-label">Post-query filters</div><pre class="sql-json">${escapeHtml(JSON.stringify(postFilters, null, 2))}</pre>`
                    : ""}
            </div>
        </div>`);

    const cards = sqlPanel.querySelectorAll(".sql-card");
    cards[cards.length - 1].scrollIntoView({ block: "nearest" });
}

async function sendChat(message) {
    if (state.chatBusy) return;

    collapsePreviousResponses();
    collapsePreviousSqlCards();
    setChatBusy(true);
    renderInventoryMessage("Waiting for MCP result...");
    appendUserMessage(message);
    const pendingMessage = appendAgentMessage("Calling inventory MCP tools...");

    try {
        const data = await postJson("api/chat.cfm", { message, modelKey: state.modelKey });
        const answer = readKey(data, "answer", "No answer returned.");
        const responseModel = readKey(data, "model", {});
        if (readKey(responseModel, "key", "")) {
            state.modelKey = readKey(responseModel, "key", state.modelKey);
            state.selectedModel = responseModel;
            document.getElementById("providerLabel").textContent = `MCP + ${readKey(responseModel, "providerLabel", "AI")} ${readKey(responseModel, "modelLabel", "")}`;
        }

        pendingMessage.remove();
        appendAgentMessage(answer, data, { collapsible: true });
        applyToolResultToInventory(data);
        renderDebug(data);
        renderSqlDebug(data);
    } catch (error) {
        pendingMessage.remove();
        appendAgentMessage(error.message, error.data || {});
        renderInventoryMessage("The latest MCP request failed. Refresh DB to reload all rows.");
    } finally {
        setChatBusy(false);
        document.getElementById("chatInput").focus();
    }
}

function attachEvents() {
    document.getElementById("chatForm").addEventListener("submit", async (event) => {
        event.preventDefault();
        const input = document.getElementById("chatInput");
        const message = input.value.trim();
        if (!message || state.chatBusy) return;
        input.value = "";
        await sendChat(message);
    });

    document.querySelectorAll(".qq-btn").forEach((button) => {
        button.addEventListener("click", () => {
            if (state.chatBusy) return;
            document.getElementById("chatInput").value = button.textContent;
            document.getElementById("chatForm").requestSubmit();
        });
    });

    document.getElementById("chatMessages").addEventListener("click", (event) => {
        const button = event.target.closest(".collapse-btn");
        if (!button) return;

        const message = button.closest(".message");
        setMessageCollapsed(message, !message.classList.contains("collapsed"));
    });

    document.getElementById("sqlPanel").addEventListener("click", (event) => {
        const button = event.target.closest(".sql-collapse-btn");
        if (!button) return;

        const card = button.closest(".sql-card");
        setSqlCardCollapsed(card, !card.classList.contains("collapsed"));
    });

    document.querySelectorAll(".wh-tab").forEach((button) => {
        button.addEventListener("click", async () => {
            document.querySelectorAll(".wh-tab").forEach((tab) => tab.classList.remove("active"));
            button.classList.add("active");
            state.warehouse = button.dataset.warehouse || "";
            await loadInventory();
        });
    });

    document.getElementById("modelSelect").addEventListener("change", async (event) => {
        if (state.chatBusy) return;
        try {
            await setModel(event.target.value);
        } catch (error) {
            appendAgentMessage(error.message);
            await loadModels();
        }
    });

    document.getElementById("seedBtn").addEventListener("click", async () => {
        await getJson("api/bootstrap.cfm?force=1");
        document.querySelectorAll(".wh-tab").forEach((tab) => tab.classList.remove("active"));
        document.querySelector('.wh-tab[data-warehouse=""]').classList.add("active");
        state.warehouse = "";
        await loadInventory();
    });

    document.querySelectorAll(".rtab").forEach((tab) => {
        tab.addEventListener("click", () => {
            document.querySelectorAll(".rtab").forEach((item) => item.classList.remove("active"));
            document.querySelectorAll(".rsection").forEach((section) => section.classList.remove("active"));
            tab.classList.add("active");
            document.getElementById(`${tab.dataset.tab}Panel`).classList.add("active");
        });
    });
}

attachEvents();
loadModels().catch((error) => {
    document.getElementById("providerLabel").textContent = error.message;
});
loadInventory().catch((error) => {
    document.getElementById("inventoryRows").innerHTML = `<tr><td colspan="8" class="empty-cell">${escapeHtml(error.message)}</td></tr>`;
});
