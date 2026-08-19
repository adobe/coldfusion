// tests/mock-sse.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { mockSSE, __pickScenarioForTest } from "../assets/js/mock/sse/stream.js";

test("pickScenario routes 'London' + 'conference' to session-6", () => {
  assert.equal(__pickScenarioForTest("I'm going to London for a tech conference"), "session-6-final");
});

test("pickScenario falls back to baseline", () => {
  assert.equal(__pickScenarioForTest("hi"), "session-1-baseline");
});

test("mockSSE emits events in order with delays", async () => {
  const events = [];
  await new Promise((resolve) => {
    const abort = mockSSE("/chat/sessions/csn_x/messages", { userText: "hi" }, (e) => {
      events.push(e.type);
      if (e.type === "done") { abort(); resolve(); }
    });
  });
  assert.equal(events[0], "model.start");
  assert.equal(events.at(-1), "done");
});
