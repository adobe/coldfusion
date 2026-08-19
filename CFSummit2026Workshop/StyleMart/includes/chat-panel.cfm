<cfoutput>
<div class="chat" data-chat-root>
    <div class="chat__header">
        <span class="brand-mark chat__title">Assistant</span>
        <div class="chat__header-actions">
            <select class="chat__session-select" data-chat-session aria-label="Session">
                <option value="1">S1 — ChatModel</option>
                <option value="2">S2 — Memory</option>
                <option value="3">S3 — Tools</option>
                <option value="4">S4 — MCP</option>
                <option value="5">S5 — RAG</option>
                <option value="6">S6 — Guardrails</option>
            </select>
            <div class="chat__mode-toggle" data-chat-mode-toggle role="group" aria-label="Mode">
                <button type="button" class="chat__mode-btn" data-mode="lab" aria-pressed="false">Lab</button>
                <button type="button" class="chat__mode-btn is-active" data-mode="ref" aria-pressed="true">Ref</button>
            </div>
            <button class="icon-btn" data-chat-reset title="Reset memory" aria-label="Reset memory">↺</button>
            <button class="icon-btn" data-chat-minimize title="Minimize" aria-label="Minimize chat">−</button>
        </div>
    </div>
    <div class="chat__prefs" data-prefs-rail>
        <div class="chat__prefs-head">
            <span class="chat__prefs-title">Persisted preferences</span>
            <button type="button" class="chat__prefs-reset" data-prefs-reset>Reset</button>
        </div>
        <div class="chat__prefs-body" data-prefs-body>
            <span class="chat__prefs-empty">No prefs yet.</span>
        </div>
    </div>
    <div class="chat__messages" data-chat-messages></div>
    <form class="chat__form" data-chat-form>
        <input type="text" name="text" placeholder="Ask anything..." autocomplete="off" required>
        <button class="btn-primary" type="submit">Send</button>
    </form>
</div>
</cfoutput>
