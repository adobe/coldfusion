// tests/api.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { API_CONFIG, api, __setMockHandlers } from "../assets/js/api.js";

test("API_CONFIG defaults to live mode and /api base", () => {
  assert.equal(API_CONFIG.mode, "live");
  assert.equal(API_CONFIG.baseUrl, "/api");
  assert.equal(API_CONFIG.shopperId, "usr_demo_001");
});

test("api.listProducts in mock mode invokes the registered mock handler", async () => {
  API_CONFIG.mode = "mock";
  __setMockHandlers({
    "GET /products": (payload) => ({ items: [{ productId: "prd_x" }], page: 1, pageSize: 24, total: 1 }),
  });
  const result = await api.listProducts({ category: "jackets" });
  assert.equal(result.items[0].productId, "prd_x");
  API_CONFIG.mode = "live";
});

test("api throws RFC 7807 problem when mock handler missing", async () => {
  API_CONFIG.mode = "mock";
  __setMockHandlers({});
  await assert.rejects(() => api.listProducts(), /no mock handler/i);
  API_CONFIG.mode = "live";
});
