// assets/js/mock/handlers/carts.js
import cartsData from "../fixtures/carts.json" with { type: "json" };
import productsData from "../fixtures/products.json" with { type: "json" };
import couponsData from "../fixtures/coupons.json" with { type: "json" };
import { consumeFail } from "../fail.js";

// Coupons from seed (SUMMIT10 10% storewide, WELCOME15 15% min $75,
// JACKETS20 20% jackets-only). Keyed by uppercased code for O(1) lookup.
const VALID_COUPONS = (() => {
  const out = {};
  for (const c of couponsData.items) {
    out[c.code.toUpperCase()] = {
      couponId: c.couponId,
      type: c.type,
      value: c.value,
      currency: c.currency,
      minSubtotal: (c.minSubtotalCents || 0) / 100,
      scopeCategories: c.scopeCategories || null,
    };
  }
  return out;
})();

// sessionStorage is browser-only; guard so Node tests can import this module.
const _session = (typeof sessionStorage !== "undefined") ? sessionStorage : null;

let cart;
let pending = new Map();
__resetCart();

export function __resetCart(force = false) {
  if (!force && _session) {
    const saved = _session.getItem("stylemart.mock.cart");
    if (saved) {
      try { cart = JSON.parse(saved); return; } catch (_) { /* fall through */ }
    }
  }
  cart = JSON.parse(JSON.stringify(cartsData["crt_demo_jordan"]));
  persistCart();
}

export function __getCart() { return cart; }

function persistCart() {
  if (!_session) return;
  try { _session.setItem("stylemart.mock.cart", JSON.stringify(cart)); } catch (_) {}
}

let pendingCounter = 0;
function newPendingId() { return `pen_01H${(++pendingCounter).toString().padStart(8, "0")}`; }

function priceOf(productIds) {
  return productIds.reduce((sum, id) => {
    const p = productsData.find((x) => x.productId === id);
    return sum + (p?.price || 0);
  }, 0);
}

export const cartHandlers = {
  "GET /carts/:id": () => ({ ...cart, items: [...cart.items] }),

  "GET /me/cart": () => ({ ...cart }),
  "GET /me/cart/summary": () => ({
    cartId: cart.cartId,
    itemCount: cart.items.reduce((sum, i) => sum + i.quantity, 0),
    total: cart.total,
    currency: cart.currency,
  }),

  "POST /carts/:id/items": ({ variantId, quantity = 1 }) => {
    // Find the product for this variant
    const product = productsData.find(p =>
      p.variants ? p.variants.some(v => v.variantId === variantId) : false
    );
    if (!product) {
      // Fallback: try to derive product from variantId pattern var_<slug>_<size>_<color>
      const parts = variantId.split("_");
      const slug = parts.slice(1, -2).join("_");
      const fallback = productsData.find(p => p.productId === `prd_${slug}`);
      if (!fallback) throw problem(404, "Variant not found", variantId);
      const size = parts[parts.length - 2];
      const color = parts[parts.length - 1];

      // Check if already in cart - increment quantity
      const existing = cart.items.find(i => i.variantId === variantId);
      if (existing) {
        existing.quantity += quantity;
        existing.lineTotal = existing.unitPrice * existing.quantity;
      } else {
        cart.items.push({
          cartItemId: `cit_${Date.now()}`,
          variantId,
          productId: fallback.productId,
          name: fallback.name,
          imageUrl: fallback.imageUrl || (fallback.images?.[0]?.url) || '',
          size,
          color,
          quantity,
          unitPrice: fallback.price,
          lineTotal: fallback.price * quantity,
          discountAmount: 0,
          currency: "USD",
          inStock: true,
          maxQty: 10,
          stale: false,
          appliedPromotionIds: [],
          addedAt: new Date().toISOString(),
        });
      }
      cart.subtotal = cart.items.reduce((s, i) => s + i.lineTotal, 0);
      cart.total = cart.subtotal - cart.discountTotal;
      cart.updatedAt = new Date().toISOString();
      persistCart();
      return { ...cart };
    }

    const variant = product.variants.find(v => v.variantId === variantId);

    // Check if already in cart - increment quantity
    const existing = cart.items.find(i => i.variantId === variantId);
    if (existing) {
      existing.quantity += quantity;
      existing.lineTotal = existing.unitPrice * existing.quantity;
    } else {
      cart.items.push({
        cartItemId: `cit_${Date.now()}`,
        variantId,
        productId: product.productId,
        name: product.name,
        imageUrl: product.imageUrl || (product.images?.[0]?.url) || '',
        size: variant?.size || '',
        color: variant?.color || '',
        quantity,
        unitPrice: product.price,
        lineTotal: product.price * quantity,
        discountAmount: 0,
        currency: "USD",
        inStock: true,
        maxQty: 10,
        stale: false,
        appliedPromotionIds: [],
        addedAt: new Date().toISOString(),
      });
    }
    cart.subtotal = cart.items.reduce((s, i) => s + i.lineTotal, 0);
    cart.total = cart.subtotal - cart.discountTotal;
    cart.updatedAt = new Date().toISOString();
    persistCart();
    return { ...cart };
  },

  "POST /carts/:id/outfit-pending": ({ productIds = [], reason }) => {
    const id = newPendingId();
    const subtotal = priceOf(productIds);
    const expired = consumeFail("confirm-expired");
    pending.set(id, { productIds, reason, status: "pending", createdAt: new Date().toISOString() });
    return {
      pendingActionId: id,
      summary: { itemCount: productIds.length, subtotal, currency: "USD" },
      expiresAt: new Date(Date.now() + (expired ? -1000 : 5 * 60 * 1000)).toISOString(),
    };
  },

  "POST /carts/:id/confirmations/:id": ({ decision }, path) => {
    const penId = path.split("/").pop();
    const action = pending.get(penId);
    if (!action) throw problem(404, "Pending action not found", penId);
    if (action.status !== "pending") throw problem(409, "Already decided", action.status);

    if (decision === "confirm") {
      const partial = consumeFail("partial-cart");
      const idsToApply = partial ? action.productIds.slice(0, 1) : action.productIds;
      for (const pid of idsToApply) {
        const p = productsData.find((x) => x.productId === pid);
        if (!p) continue;
        const color = p.colors?.[0] || "navy";
        const size = p.availableSizes?.[1] || p.availableSizes?.[0] || "M";
        const variantId = `var_${p.productId.slice(4)}_${size}_${color}`;
        cart.items.push({
          cartItemId: `cit_${cart.items.length + 1}`,
          variantId, productId: pid, name: p.name, imageUrl: p.imageUrl,
          size, color,
          quantity: 1,
          unitPrice: p.price,
          lineTotal: p.price,
          discountAmount: 0,
          currency: "USD",
          inStock: true,
          maxQty: 10,
          stale: false,
          appliedPromotionIds: [],
          addedAt: new Date().toISOString(),
        });
      }
      cart.subtotal = cart.items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
      cart.discountTotal = 0;
      cart.total = cart.subtotal - cart.discountTotal;
      cart.updatedAt = new Date().toISOString();
      action.status = "confirmed";
      persistCart();
      return { ...cart, appliedActions: [penId] };
    }

    action.status = "declined";
    return { ...cart, appliedActions: [] };
  },

  "DELETE /carts/:id/items/:id": (payload, path) => {
    const variantId = path.split("/").pop();
    cart.items = cart.items.filter((i) => i.variantId !== variantId);
    cart.subtotal = cart.items.reduce((s, i) => s + i.unitPrice * i.quantity, 0);
    cart.discountTotal = 0;
    cart.total = cart.subtotal - cart.discountTotal;
    cart.updatedAt = new Date().toISOString();
    persistCart();
    return cart;
  },

  "POST /carts/:id/coupon": ({ code }) => {
    const upper = (code || "").toUpperCase();
    const coupon = VALID_COUPONS[upper];
    if (!coupon) throw problem(404, "Coupon not found", code);

    // Min-subtotal enforcement (e.g. WELCOME15 needs $75+)
    if (coupon.minSubtotal > 0 && cart.subtotal < coupon.minSubtotal) {
      const err = problem(422, "Minimum subtotal not met",
        `${upper} requires a $${coupon.minSubtotal} minimum subtotal.`);
      err.code = "coupon_min_subtotal_not_met";
      err.meta = { minSubtotal: coupon.minSubtotal, currentSubtotal: cart.subtotal, currency: "USD" };
      throw err;
    }

    // Compute eligible-lines subtotal (scope-aware for JACKETS20-style coupons)
    let eligibleSubtotal = cart.subtotal;
    if (coupon.scopeCategories?.length) {
      eligibleSubtotal = cart.items
        .filter((i) => {
          const p = productsData.find((x) => x.productId === i.productId);
          return p && coupon.scopeCategories.includes(p.category);
        })
        .reduce((s, i) => s + i.lineTotal, 0);
      if (eligibleSubtotal <= 0) {
        const err = problem(422, "No cart line in coupon scope",
          `${upper} only applies to ${coupon.scopeCategories.join(", ")}.`);
        err.code = "coupon_categories_excluded";
        err.meta = { scopeCategories: coupon.scopeCategories };
        throw err;
      }
    }

    const discount = coupon.type === "percentage" || coupon.type === "percent"
      ? eligibleSubtotal * (coupon.value / 100)
      : Math.min(coupon.value, cart.subtotal);

    cart.appliedCoupon = {
      code: upper,
      couponId: coupon.couponId,
      type: coupon.type,
      value: coupon.value,
      currency: coupon.currency || "USD",
    };
    cart.discountTotal = Math.round(discount * 100) / 100;
    cart.total = Math.round((cart.subtotal - cart.discountTotal) * 100) / 100;
    cart.updatedAt = new Date().toISOString();
    persistCart();
    return { ...cart };
  },

  "DELETE /carts/:id/coupon": () => {
    cart.appliedCoupon = null;
    cart.discountTotal = 0;
    cart.total = cart.subtotal;
    cart.updatedAt = new Date().toISOString();
    persistCart();
    return { ...cart };
  },
};

function problem(status, title, detail) {
  const err = new Error(title);
  Object.assign(err, { status, title, detail, type: "about:blank" });
  return err;
}
