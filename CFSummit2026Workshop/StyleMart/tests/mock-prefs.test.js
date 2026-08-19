// tests/mock-prefs.test.js
//
// Aligns with the §4.4 contract: preferences live at /users/:id/preferences
// and the response is { userId, preferences: {...}, updatedAt, schemaVersion }.
// Pre-migration this test used the legacy /shoppers/:id/preferences shape.
import { test } from "node:test";
import assert from "node:assert/strict";
import { prefsHandlers } from "../assets/js/mock/handlers/prefs.js";

test("GET /users/:id/preferences returns Jordan's defaults", () => {
  const handler = prefsHandlers["GET /users/:id/preferences"];
  const result = handler(null, "/users/usr_demo_001/preferences");
  assert.equal(result.userId, "usr_demo_001");
  assert.equal(result.schemaVersion, 1);
  assert.equal(result.preferences.topSize, "M");
  assert.equal(result.preferences.budget, 500);
});

test("PUT /users/:id/preferences echoes payload with updatedAt", () => {
  const handler = prefsHandlers["PUT /users/:id/preferences"];
  const payload = { topSize: "L", budget: 700 };
  const result = handler(payload, "/users/usr_demo_001/preferences");
  assert.equal(result.userId, "usr_demo_001");
  assert.equal(result.preferences.topSize, "L");
  assert.equal(result.preferences.budget, 700);
  assert.ok(result.updatedAt);
});
