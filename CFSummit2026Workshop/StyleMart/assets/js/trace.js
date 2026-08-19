// assets/js/trace.js
import { appStore } from "./store.js";
import { api } from "./api.js";

const GROUP_BY_PREFIX = {
  "memory":      "memory",
  "preference":  "preferences",
  "preferences": "preferences",
  "tool":        "tools",
  "mcp":         "mcp",
  "retrieval":   "rag",
  "guardrail":   "guardrails",
};

export function routeEvent(event) {
  const prefix = event.type.split(".")[0];
  return { group: GROUP_BY_PREFIX[prefix] || "stream", event };
}

export function initTrace() {
  const root = document.querySelector("[data-trace-root]");
  if (!root) return;
  const groupEls = {
    memory:        root.querySelector('[data-group="memory"] [data-group-body]'),
    preferences:   root.querySelector('[data-group="preferences"] [data-group-body]'),
    tools:         root.querySelector('[data-group="tools"] [data-group-body]'),
    mcp:           root.querySelector('[data-group="mcp"] [data-group-body]'),
    rag:           root.querySelector('[data-group="rag"] [data-group-body]'),
    guardrails:    root.querySelector('[data-group="guardrails"] [data-group-body]'),
  };
  const stream = root.querySelector("[data-trace-stream]");
  const counts = {
    tools: root.querySelector('[data-group="tools"] [data-count]'),
    mcp:   root.querySelector('[data-group="mcp"] [data-count]'),
    rag:   root.querySelector('[data-group="rag"] [data-count]'),
  };

  root.querySelector("[data-trace-clear]").addEventListener("click", () => {
    appStore.set({ traceEvents: [] });
    for (const el of Object.values(groupEls)) el.innerHTML = `<div class="trace-empty">Cleared.</div>`;
    stream.innerHTML = "";
  });

  // Render new events as they arrive.
  let lastSeen = 0;
  appStore.subscribe((s) => {
    const events = s.traceEvents;
    if (events.length === lastSeen) return;
    for (let i = lastSeen; i < events.length; i++) renderEvent(events[i], groupEls, stream, counts);
    lastSeen = events.length;
  });

  // Trace persistence on load.
  const sid = appStore.get().sessionId;
  if (sid) replayPriorTrace(sid);
}

async function replayPriorTrace(sid) {
  try {
    const { items } = await api.replayTrace(sid, 0);
    if (items?.length) appStore.update((s) => ({ traceEvents: [...items, ...s.traceEvents] }));
  } catch (_) {/* ignore on first load */}
}

function renderEvent(event, groupEls, stream, counts) {
  const { group } = routeEvent(event);
  if (group === "stream") {
    appendStream(stream, event);
    return;
  }
  const target = groupEls[group];
  if (!target) return;
  if (target.firstElementChild?.classList?.contains("trace-empty")) target.innerHTML = "";
  target.appendChild(rowFor(group, event));
  if (counts[group]) counts[group].textContent = target.children.length;
}

function rowFor(group, e) {
  const row = document.createElement("div");
  row.className = "trace-row";
  const p = e.payload || {};
  switch (group) {
    case "memory": {
      if      (e.type === "memory.read")    row.innerHTML = `<span>read</span><span class="trace-pill">${p.messages ?? "·"}</span>`;
      else if (e.type === "memory.write")   row.innerHTML = `<span>write</span><span class="trace-pill">${p.messages ?? "·"}</span>`;
      else if (e.type === "memory.cleared") row.innerHTML = `<span>cleared</span><span class="trace-pill"><code>${p.userId ?? "?"}</code></span>`;
      return row;
    }
    case "preferences": {
      if      (e.type === "preference.persist")  row.innerHTML = `<span>persisted <code>${(p.fields || []).join(", ") || "·"}</code></span><span class="trace-pill">${p.userId ?? "?"}</span>`;
      else if (e.type === "preferences.invalid") row.innerHTML = `<span>⚠ invalid <code>${p.rule ?? "?"}</code></span><span class="trace-pill trace-pill--warn">recaptured</span>`;
      else if (e.type === "preferences.cleared") row.innerHTML = `<span>cleared</span><span class="trace-pill"><code>${p.userId ?? "?"}</code></span>`;
      return row;
    }
    case "tools":
      if (e.type === "tool.call") {
        const argsStr = p.args ? Object.entries(p.args).filter(([,v]) => v !== "" && v !== "0" && v !== "999999").map(([k,v]) => `${k}=${JSON.stringify(v)}`).join(", ") : "";
        row.innerHTML = `<span>⏳ ${p.toolName}</span><span class="trace-pill">${p.kind || "cfc"}</span>` +
          (argsStr ? `<div class="trace-row__args"><code>${argsStr}</code></div>` : "");
      } else if (e.type === "tool.result") {
        row.innerHTML = `<span>${p.status === "ok" ? "✓" : "✗"} <code>${p.callId}</code></span><span class="trace-pill trace-pill--${p.status === "ok" ? "ok" : "err"}">${p.summary || ""}${p.durationMs != null ? " · " + p.durationMs + "ms" : ""}</span>`;
      } else {
        return row;
      }
      return row;
    case "mcp":
      if (e.type === "mcp.call") {
        row.innerHTML = `<span>⏳ <code>${p.server || ""}</code>·${p.toolName || ""}</span><span class="trace-pill">${p.transport || ""}</span>`;
      } else if (e.type === "mcp.error") {
        row.innerHTML = `<span>✗ ${p.title || p.code || "error"}</span><span class="trace-pill trace-pill--err">${p.source || ""}</span>`;
      } else {
        row.innerHTML = `<span>${p.status === "ok" ? "✓" : "✗"} ${p.callId || ""}</span><span class="trace-pill trace-pill--${p.status === "ok" ? "ok" : "err"}">${p.durationMs != null ? p.durationMs + "ms" : ""}</span>`;
      }
      return row;
    case "rag":
      if (e.type === "retrieval.start") {
        row.innerHTML = `<span>query: <em>${p.query}</em></span><span class="trace-pill">k=${p.maxResults}</span>`;
      } else {
        row.innerHTML = `<span>${p.score?.toFixed(2)} ${p.metadata?.source || ""}</span><span class="trace-pill">${p.metadata?.docType || ""}</span>`;
      }
      return row;
    case "guardrails":
      if (e.type === "guardrail.check") {
        row.innerHTML = `<span>${p.passed ? "✓" : "⚠"} <code>${p.rule}</code></span><span class="trace-pill trace-pill--${p.passed ? "ok" : "warn"}">${p.passed ? "pass" : "fail"}</span>`;
      } else {
        // guardrail.violation — failure/fatal block (no in-place rewrite). Show the rule + message.
        const fatal = p.result === "fatal";
        row.innerHTML = `<span>✗ <code>${p.rule}</code>${p.message ? ` — ${p.message}` : ""}</span><span class="trace-pill trace-pill--${fatal ? "err" : "warn"}">${p.result || "block"}</span>`;
      }
      return row;
  }
  return row;
}

let deltaBuffer = "";
let deltaLine = null;
let deltaCount = 0;
const DELTA_FLUSH_EVERY = 1; // controls how many tokens are buffered before flushing to the UI.

function appendStream(stream, e) {

  const ts = (e.ts || new Date().toISOString()).split("T")[1]?.slice(0, 12) || "";
  const line = document.createElement("div");
  line.textContent = `${ts}  ${e.type}${streamPreview(e)}`;
  stream.appendChild(line);
  stream.scrollTop = stream.scrollHeight;
}

function streamPreview(e) {
  const p = e.payload || {};
  switch (e.type) {
    case "model.start": return p.model ? `  ${p.model}` : "";
    case "model.delta": return p.text != null ? `  ${JSON.stringify(p.text)}` : "";
    case "model.end":   return p.tokens
      ? `  in=${p.tokens.input_token ?? "?"} out=${p.tokens.output_token ?? "?"} (${p.tokens.finish_reason ?? "?"})`
      : "";
    case "done":        return p.status ? `  ${p.status}` : "";
    case "error":       return `  ${p.detail || p.title || p.message || ""}`;
    default:            return "";
  }
}
