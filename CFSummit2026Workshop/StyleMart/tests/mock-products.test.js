// tests/mock-products.test.js
//
// Tests are agnostic of catalog scale — they pick the first product from the
// fixture at runtime so the 30→200 fixture swap doesn't require code updates.
import { test } from "node:test";
import assert from "node:assert/strict";
import { productHandlers, __resetProducts } from "../assets/js/mock/handlers/products.js";
import productsData from "../assets/js/mock/fixtures/products.json" with { type: "json" };

const FIRST_PRODUCT_ID = productsData[0].productId;
const FIRST_JACKET_ID  = (productsData.find((p) => p.category === "jackets") || productsData[0]).productId;

test("GET /products returns paginated items", () => {
  const h = productHandlers["GET /products"];
  const result = h({ page: 1, pageSize: 5 });
  assert.equal(result.items.length, 5);
  assert.equal(result.page, 1);
  assert.ok(result.total >= 30);
});

test("GET /products filters by category", () => {
  const h = productHandlers["GET /products"];
  const result = h({ category: "jackets", pageSize: 50 });
  assert.ok(result.items.every((p) => p.category === "jackets"));
});

test("GET /products/:id returns a single product", () => {
  const h = productHandlers["GET /products/:id"];
  const result = h(null, `/products/${FIRST_PRODUCT_ID}`);
  assert.equal(result.productId, FIRST_PRODUCT_ID);
  assert.ok(result.description);
  assert.ok(result.variants);
});

test("POST /products/compare returns per-dimension rows", () => {
  const h = productHandlers["POST /products/compare"];
  const result = h({ productIds: [FIRST_PRODUCT_ID, FIRST_JACKET_ID], dimensions: ["price", "fabric", "care"] });
  assert.equal(result.dimensions.length, 3);
  assert.equal(result.rows[0].key, "price");
  assert.ok(result.rows[0].values[FIRST_PRODUCT_ID]);
});

test("GET /categories returns the leaf-category list", () => {
  const h = productHandlers["GET /categories"];
  const result = h();
  // §12 row 1.5: 13 leaf categories under 2 parents. Handler only surfaces leaves.
  assert.ok(result.length >= 8);
  assert.ok(result.find((c) => c.slug === "jackets"));
  assert.ok(result.find((c) => c.slug === "tshirts"));
});
