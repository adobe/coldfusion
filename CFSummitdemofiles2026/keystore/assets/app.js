(function () {
    const form = document.getElementById("keyForm");
    const clearBtn = document.getElementById("clearBtn");
    const refreshBtn = document.getElementById("refreshBtn");
    const formMessage = document.getElementById("formMessage");
    const keysBody = document.getElementById("keysBody");
    const emptyState = document.getElementById("emptyState");
    const keyCount = document.getElementById("keyCount");
    const headerKeyCount = document.getElementById("headerKeyCount");
    const nameInput = document.getElementById("name");
    const keyIdInput = document.getElementById("keyId");

    function escapeHtml(value) {
        return String(value || "")
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#39;");
    }

    function slug(value) {
        return String(value || "")
            .trim()
            .toLowerCase()
            .replace(/[^a-z0-9_.-]+/g, "-")
            .replace(/-+/g, "-")
            .replace(/^-+|-+$/g, "")
            .slice(0, 80);
    }

    function setMessage(text, tone) {
        formMessage.textContent = text || "";
        formMessage.className = "message" + (tone ? " " + tone : "");
    }

    function renderKeys(keys) {
        keysBody.innerHTML = "";
        keyCount.textContent = keys.length;
        headerKeyCount.textContent = keys.length + (keys.length === 1 ? " key" : " keys");
        emptyState.classList.toggle("hidden", keys.length > 0);

        keys.forEach((key) => {
            const tr = document.createElement("tr");
            tr.dataset.keyId = key.keyId;
            tr.innerHTML = `
                <td>
                    <strong>${escapeHtml(key.name)}</strong>
                    ${key.notes ? `<small>${escapeHtml(key.notes)}</small>` : ""}
                </td>
                <td><code>${escapeHtml(key.keyId)}</code></td>
                <td>${escapeHtml(key.hint)}</td>
                <td><code>${escapeHtml(String(key.fingerprint || "").slice(0, 12))}</code></td>
                <td>${escapeHtml(key.lastRetrievedAt || "Never")}</td>
                <td>${escapeHtml(key.retrievalCount || 0)}</td>
                <td class="actions">
                    <button class="secondary small" type="button" data-action="copy" data-id="${escapeHtml(key.keyId)}">Copy ID</button>
                    <button class="danger small" type="button" data-action="delete" data-id="${escapeHtml(key.keyId)}">Delete</button>
                </td>
            `;
            keysBody.appendChild(tr);
        });
    }

    async function requestJson(url, options) {
        const response = await fetch(url, options || {});
        const payload = await response.json();
        if (!response.ok || payload.ok === false) {
            throw new Error(payload.message || "Request failed.");
        }
        return payload;
    }

    async function refreshKeys() {
        const payload = await requestJson("api/keys.cfm");
        renderKeys(payload.keys || []);
    }

    nameInput.addEventListener("input", () => {
        if (!keyIdInput.dataset.touched) {
            keyIdInput.value = slug(nameInput.value);
        }
    });

    keyIdInput.addEventListener("input", () => {
        keyIdInput.dataset.touched = "1";
        keyIdInput.value = slug(keyIdInput.value);
    });

    clearBtn.addEventListener("click", () => {
        form.reset();
        delete keyIdInput.dataset.touched;
        setMessage("");
        nameInput.focus();
    });

    refreshBtn.addEventListener("click", async () => {
        try {
            await refreshKeys();
            setMessage("Key list refreshed.", "good");
        } catch (error) {
            setMessage(error.message, "bad");
        }
    });

    form.addEventListener("submit", async (event) => {
        event.preventDefault();
        setMessage("Saving...");

        const payload = Object.fromEntries(new FormData(form).entries());

        try {
            const result = await requestJson("api/keys.cfm", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(payload)
            });

            document.getElementById("apiKey").value = "";
            setMessage(result.message || "Key saved.", "good");
            await refreshKeys();
        } catch (error) {
            setMessage(error.message, "bad");
        }
    });

    keysBody.addEventListener("click", async (event) => {
        const button = event.target.closest("button[data-action]");
        if (!button) {
            return;
        }

        const id = button.dataset.id;
        const action = button.dataset.action;

        if (action === "copy") {
            try {
                await navigator.clipboard.writeText(id);
                setMessage("Copied " + id + ".", "good");
            } catch (error) {
                setMessage(id, "good");
            }
            return;
        }

        if (action === "delete") {
            if (!window.confirm("Delete " + id + "?")) {
                return;
            }

            try {
                await requestJson("api/delete.cfm", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({ keyId: id })
                });
                setMessage("Deleted " + id + ".", "good");
                await refreshKeys();
            } catch (error) {
                setMessage(error.message, "bad");
            }
        }
    });
})();
