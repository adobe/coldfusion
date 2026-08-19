// tests/mock-carts.test.js
//
// Picks the first product from the fixture at runtime so the 30→200 fixture
// swap doesn't require test updates.
import { test } from "node:test";
import assert from "node:assert/strict";
import { cartHandlers, __resetCart } from "../assets/js/mock/handlers/carts.js";
import productsData from "../assets/js/mock/fixtures/products.json" with { type: "json" };

const DEMO_PRODUCT_ID = productsData[0].productId;

test("GET /carts/:id returns empty cart for Jordan", () => {
  __resetCart(true);
  const r = cartHandlers["GET /carts/:id"](null, "/carts/crt_demo_jordan");
  assert.equal(r.cartId, "crt_demo_jordan");
  assert.deepEqual(r.items, []);
});

test("POST outfit-pending returns pendingActionId + summary", () => {
  __resetCart(true);
  const r = cartHandlers["POST /carts/:id/outfit-pending"](
    { productIds: [DEMO_PRODUCT_ID], reason: "London capsule" },
    "/carts/crt_demo_jordan/outfit-pending"
  );
  assert.ok(r.pendingActionId.startsWith("pen_"));
  assert.equal(r.summary.itemCount, 1);
  assert.ok(r.expiresAt);
});

test("POST confirm applies pending action to cart", () => {
  __resetCart(true);
  const staged = cartHandlers["POST /carts/:id/outfit-pending"](
    { productIds: [DEMO_PRODUCT_ID] },
    "/carts/crt_demo_jordan/outfit-pending"
  );
  const result = cartHandlers["POST /carts/:id/confirmations/:id"](
    { decision: "confirm" },
    `/carts/crt_demo_jordan/confirmations/${staged.pendingActionId}`
  );
  assert.equal(result.items.length, 1);
  assert.ok(result.appliedActions.includes(staged.pendingActionId));
});

test("POST decline does NOT add items", () => {
  __resetCart(true);
  const staged = cartHandlers["POST /carts/:id/outfit-pending"](
    { productIds: [DEMO_PRODUCT_ID] },
    "/carts/crt_demo_jordan/outfit-pending"
  );
  const result = cartHandlers["POST /carts/:id/confirmations/:id"](
    { decision: "decline" },
    `/carts/crt_demo_jordan/confirmations/${staged.pendingActionId}`
  );
  assert.equal(result.items.length, 0);
});
