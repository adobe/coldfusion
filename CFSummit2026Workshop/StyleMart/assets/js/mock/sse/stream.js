// assets/js/mock/sse/stream.js
import { consumeFail } from "../fail.js";
import s1 from "./scenarios/session-1-baseline.json" with { type: "json" };
import s2 from "./scenarios/session-2-memory.json"   with { type: "json" };
import s3 from "./scenarios/session-3-tools.json"    with { type: "json" };
import s4 from "./scenarios/session-4-mcp.json"      with { type: "json" };
import s5 from "./scenarios/session-5-rag.json"      with { type: "json" };
import s6 from "./scenarios/session-6-final.json"    with { type: "json" };

const SCENARIOS = {
  "session-1-baseline": s1,
  "session-2-memory":   s2,
  "session-3-tools":    s3,
  "session-4-mcp":      s4,
  "session-5-rag":      s5,
  "session-6-final":    s6,
};

export function __registerScenario(name, events) { SCENARIOS[name] = events; }

export function pickScenario(userText = "") {
  const t = userText.toLowerCase();
  if (t.includes("london") && (t.includes("capsule") || t.includes("conference"))) return "session-6-final";
  if (t.includes("compare") || t.includes("which one")) return "session-3-tools";
  if (t.includes("return") || t.includes("fabric") || t.includes("care")) return "session-5-rag";
  if (t.includes("inventory") || t.includes("in stock")) return "session-4-mcp";
  if (t.includes("remember") || t.includes("size m")) return "session-2-memory";
  return "session-1-baseline";
}

export const __pickScenarioForTest = pickScenario;

let seq = 0;

export function mockSSE(path, body, onEvent) {
  const scenarioName = pickScenario(body?.userText || "");
  const script = SCENARIOS[scenarioName] || SCENARIOS["session-1-baseline"];
  const sessionId = path.match(/sessions\/([^/]+)/)?.[1] || "csn_mock";
  const messageId = body?.messageId || `msg_${Date.now()}`;
  let cancelled = false;

  function envelope(e) {
    return { sessionId, messageId, seq: ++seq, ts: new Date().toISOString(), type: e.type, payload: e.payload || {} };
  }

  (async () => {
    if (consumeFail("model")) {
      onEvent(envelope({ type: "error", payload: { status: 503, message: "Model unreachable" } }));
      onEvent(envelope({ type: "done" }));
      return;
    }
    if (consumeFail("rate")) {
      onEvent(envelope({ type: "error", payload: { status: 429, retryAfter: 12, message: "Rate limited" } }));
      onEvent(envelope({ type: "done" }));
      return;
    }

    for (const { delayMs, event } of script) {
      if (cancelled) return;
      await new Promise((r) => setTimeout(r, delayMs));
      if (cancelled) return;
      // Inject failures around specific event types.
      if (event.type === "tool.call" && consumeFail("tool")) {
        onEvent(envelope({ type: "tool.call", payload: event.payload }));
        onEvent(envelope({ type: "tool.result", payload: { callId: event.payload.callId, status: "error", error: "tool exception" } }));
        continue;
      }
      if (event.type === "tool.call" && consumeFail("tool-empty")) {
        onEvent(envelope({ type: "tool.call", payload: event.payload }));
        onEvent(envelope({ type: "tool.result", payload: { callId: event.payload.callId, status: "empty" } }));
        continue;
      }
      if (event.type === "mcp.call" && consumeFail("mcp")) {
        onEvent(envelope({ type: "mcp.call", payload: event.payload }));
        onEvent(envelope({ type: "mcp.result", payload: { callId: event.payload.callId, status: "error", error: "MCP unreachable" } }));
        continue;
      }
      if (event.type === "retrieval.start" && consumeFail("rag")) {
        onEvent(envelope({ type: "retrieval.start", payload: event.payload }));
        // No hits emitted.
        continue;
      }
      if (event.type === "guardrail.check" && consumeFail("guardrail")) {
        onEvent(envelope({ type: "guardrail.violation", payload: { rule: event.payload.rule, phase: event.payload.phase || "output", result: "failure", message: "Unsupported claim detected — re-answering with evidence.", repromptMessage: "Re-answer using only retrieved review/policy evidence." } }));
        continue;
      }
      if (event.type === "model.delta" && consumeFail("stream")) {
        onEvent(envelope({ type: "error", payload: { message: "Stream cut mid-token" } }));
        onEvent(envelope({ type: "done" }));
        return;
      }
      onEvent(envelope(event));
    }
  })();

  return () => { cancelled = true; };
}
