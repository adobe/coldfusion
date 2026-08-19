// tests/trace-router.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { routeEvent } from "../assets/js/trace.js";

test("routeEvent maps event types to groups", () => {
  assert.equal(routeEvent({ type: "memory.read" }).group,         "memory");
  assert.equal(routeEvent({ type: "memory.write" }).group,        "memory");
  assert.equal(routeEvent({ type: "preference.persist" }).group,  "memory");
  assert.equal(routeEvent({ type: "tool.call" }).group,           "tools");
  assert.equal(routeEvent({ type: "tool.result" }).group,         "tools");
  assert.equal(routeEvent({ type: "mcp.call" }).group,            "mcp");
  assert.equal(routeEvent({ type: "mcp.result" }).group,          "mcp");
  assert.equal(routeEvent({ type: "retrieval.start" }).group,     "rag");
  assert.equal(routeEvent({ type: "retrieval.hit" }).group,       "rag");
  assert.equal(routeEvent({ type: "guardrail.check" }).group,     "guardrails");
  assert.equal(routeEvent({ type: "guardrail.violation" }).group, "guardrails");
  assert.equal(routeEvent({ type: "action.required" }).group,     "confirmations");
  assert.equal(routeEvent({ type: "action.resolved" }).group,     "confirmations");
  assert.equal(routeEvent({ type: "model.start" }).group,         "stream");
  assert.equal(routeEvent({ type: "model.delta" }).group,         "stream");
  assert.equal(routeEvent({ type: "done" }).group,                "stream");
  assert.equal(routeEvent({ type: "error" }).group,               "stream");
});
