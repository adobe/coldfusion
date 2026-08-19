<cfoutput>
<div class="trace" data-trace-root>
    <div class="trace__header">
        <span class="brand-mark">AI Trace</span>
        <div class="trace__header-actions">
            <button class="icon-btn" data-trace-clear title="Clear">⌫</button>
            <button class="icon-btn" data-trace-minimize title="Minimize" aria-label="Minimize trace">−</button>
        </div>
    </div>
    <div class="trace__groups">
        <details class="trace-group" data-group="memory">
            <summary>🧠 Conversation memory</summary>
            <div class="trace-group__body" data-group-body><div class="trace-empty">No memory yet.</div></div>
        </details>
        <details class="trace-group" data-group="preferences">
            <summary>👤 Preference events</summary>
            <div class="trace-group__body" data-group-body><div class="trace-empty">No preferences yet.</div></div>
        </details>
        <details class="trace-group" data-group="tools" open>
            <summary>🔧 CFC Tools <span class="trace-group__badge" data-count>0</span></summary>
            <div class="trace-group__body" data-group-body><div class="trace-empty">No tool calls yet.</div></div>
        </details>
        <details class="trace-group" data-group="mcp" open>
            <summary>🌐 MCP <span class="trace-group__badge" data-count>0</span></summary>
            <div class="trace-group__body" data-group-body><div class="trace-empty">No MCP calls yet.</div></div>
        </details>
        <details class="trace-group" data-group="rag">
            <summary>📚 RAG <span class="trace-group__badge" data-count>0</span></summary>
            <div class="trace-group__body" data-group-body><div class="trace-empty">No retrievals yet.</div></div>
        </details>
        <details class="trace-group" data-group="guardrails">
            <summary>🛡 Guardrails</summary>
            <div class="trace-group__body" data-group-body><div class="trace-empty">No guardrails fired yet.</div></div>
        </details>
    </div>
    <div class="trace__stream-section">
        <div class="trace__stream-label">Live event stream</div>
        <div class="trace__stream" data-trace-stream></div>
    </div>
</div>
</cfoutput>
