// tests/agent-route.test.js
import { test } from "node:test";
import assert from "node:assert/strict";

// Provide a minimal DOM-ish global so config.js can read the controls.
// `toggleValue` simulates the active segmented Lab/Ref button; `sessionValue`
// simulates the [data-chat-session] <select>.
function withFakeDom({ search = "", toggleValue = null, sessionValue = null } = {}) {
  const fakeWindowLocation = { search };
  globalThis.location = fakeWindowLocation;
  globalThis.URLSearchParams = URLSearchParams;
  globalThis.document = {
    addEventListener() {},
    dispatchEvent() {},
    querySelector(sel) {
      if (sel === "select[data-chat-mode]") return null; // legacy select removed
      if (sel === "[data-chat-mode-toggle] .chat__mode-btn.is-active") {
        return toggleValue == null ? null : { dataset: { mode: toggleValue } };
      }
      if (sel === "[data-chat-session]") {
        return sessionValue == null ? null : { value: sessionValue };
      }
      return null;
    },
    querySelectorAll() {
      return [];
    },
  };
}

test("AgentRoute.session reads ?s= and defaults to '1'", async () => {
  withFakeDom({ search: "?s=2" });
  // dynamic import so each test sees fresh module state
  const { AgentRoute } = await import(`../assets/js/config.js?case=session`);
  assert.equal(AgentRoute.session, "2");
});

test("AgentRoute.session defaults to '1' when ?s is missing", async () => {
  withFakeDom({ search: "" });
  const { AgentRoute } = await import(`../assets/js/config.js?case=session-default`);
  assert.equal(AgentRoute.session, "1");
});

test("AgentRoute.mode reads the chat-panel toggle live", async () => {
  withFakeDom({ search: "", toggleValue: "ref" });
  const { AgentRoute } = await import(`../assets/js/config.js?case=mode-ref`);
  assert.equal(AgentRoute.mode, "ref");
});

test("AgentRoute.mode defaults to 'lab' when toggle missing", async () => {
  withFakeDom({ search: "", toggleValue: null });
  const { AgentRoute } = await import(`../assets/js/config.js?case=mode-default`);
  assert.equal(AgentRoute.mode, "lab");
});
