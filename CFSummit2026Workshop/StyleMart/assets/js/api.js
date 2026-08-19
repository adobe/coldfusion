// assets/js/api.js — single transport, mock | live toggle.
// Cache-buster: v2.0
import { AgentRoute } from "./config.js";

export const API_CONFIG = {
  mode: "live",              // "mock" | "live"
  baseUrl: "/api",
  commercePrefix: "/api/commerce",      // Layer 1
  agentPrefix: "/api/agent",        // Layer 2 - REST app "agent"
  shopperId: "usr_demo_001",
};

let _mockHandlers = {};
export function __setMockHandlers(handlers) { _mockHandlers = handlers; }
export function registerMockHandlers(handlers) {
  _mockHandlers = { ..._mockHandlers, ...handlers };
}

export const api = {
  // Catalog
  listProducts:    (params)              => req("GET",  `${API_CONFIG.commercePrefix}/products`, params),
  getProduct:      (id)                  => req("GET",  `${API_CONFIG.commercePrefix}/products/${id}`),
  getProductBySlug:(slug)                => req("GET",  `${API_CONFIG.commercePrefix}/products/by-slug/${slug}`),
  compare:         (productIds, dims)    => req("POST", `${API_CONFIG.commercePrefix}/products/compare`, { productIds, dimensions: dims }),
  related:         (id, intent)          => req("GET",  `${API_CONFIG.commercePrefix}/products/${id}/related`, { intent }),
  listCategories:  ()                    => req("GET",  `${API_CONFIG.commercePrefix}/categories`),
  search:          (params)              => req("GET",  `${API_CONFIG.commercePrefix}/search`, params),

  // Cart
  getCart:         (cartId)              => req("GET",  `${API_CONFIG.commercePrefix}/carts/${cartId}`),
  getMyCart:       ()                    => req("GET",  `${API_CONFIG.commercePrefix}/me/cart`),
  getCartSummary:  ()                    => req("GET",  `${API_CONFIG.commercePrefix}/me/cart/summary`),
  addItem:         (cartId, body)        => req("POST", `${API_CONFIG.commercePrefix}/carts/${cartId}/items`, body),
  removeItem:      (cartId, variantId)   => req("DELETE", `${API_CONFIG.commercePrefix}/carts/${cartId}/items/${variantId}`),
  directAdd:       (body)               => req("POST", `${API_CONFIG.agentPrefix}/s3/ref/cart-actions/add`, body),
  directRemove:    (variantId)           => req("DELETE", `${API_CONFIG.agentPrefix}/s3/ref/cart-actions/remove/${variantId}`),
  // Add one or more products (by productId) to the shopper's cart. Used by the
  // capsule landing ("Resume Cart") and upsell ("Add") pages. Resolves an
  // in-stock variant server-side; size is optional for one-size add-ons.
  stageOutfit:     (cartId, { productIds = [], reason = "" } = {}) =>
                     Promise.all(productIds.map((pid) => api.directAdd({ productId: pid, reason })))
                       .then((added) => ({ pendingActionId: null, added })),
  applyCoupon:     (cartId, code)        => req("POST", `${API_CONFIG.commercePrefix}/carts/${cartId}/coupon`, { code }),
  removeCoupon:    (cartId)              => req("DELETE", `${API_CONFIG.commercePrefix}/carts/${cartId}/coupon`),

  // Orders & checkout
  checkout:        (cartId, body)        => req("POST", `${API_CONFIG.commercePrefix}/checkout`, { cartId, ...body }),
  listOrders:      ()                    => req("GET",  `${API_CONFIG.commercePrefix}/orders`),
  getOrder:        (orderId)             => req("GET",  `${API_CONFIG.commercePrefix}/orders/${orderId}`),

  // Inventory
  getInventory:    (productId)           => req("GET",  `${API_CONFIG.commercePrefix}/inventory/${productId}`),
  getInventoryBulk:(productIds)          => req("GET",  `${API_CONFIG.commercePrefix}/inventory/bulk`, { productIds: productIds.join(',') }),
  // Pricing
  getPricing:      (productId)           => req("GET",  `${API_CONFIG.commercePrefix}/pricing/${productId}`),
  getPricingBulk:  (productIds)          => req("GET",  `${API_CONFIG.commercePrefix}/pricing/bulk`, { productIds: productIds.join(',') }),
  // Loyalty
  getLoyaltyTiers: ()                    => req("GET",  `${API_CONFIG.commercePrefix}/loyalty/tiers`),
  getUserLoyalty:  (userId)              => req("GET",  `${API_CONFIG.commercePrefix}/users/${userId}/loyalty`),
  // Promotions
  listPromotions:  ()                    => req("GET",  `${API_CONFIG.commercePrefix}/promotions`),
  getPromotion:    (promoId)             => req("GET",  `${API_CONFIG.commercePrefix}/promotions/${promoId}`),
  // Reviews
  getReviews:      (productId, params)   => req("GET",  `${API_CONFIG.commercePrefix}/products/${productId}/reviews`, params),
  submitReview:    (productId, body)     => req("POST", `${API_CONFIG.commercePrefix}/products/${productId}/reviews`, body),
  // Categories (single)
  getCategory:     (slug)                => req("GET",  `${API_CONFIG.commercePrefix}/categories`, { slug }),
  // Users
  getUser:         (userId)              => req("GET",  `${API_CONFIG.commercePrefix}/users/${userId}`),
  getMe:           ()                    => req("GET",  `${API_CONFIG.commercePrefix}/me`),

  // Auth (§4.4 cflogin model)
  register:        (body)                => req("POST", `${API_CONFIG.commercePrefix}/auth/register`, body),
  login:           (username, password)  => req("POST", `${API_CONFIG.commercePrefix}/auth/login`, { username, password }),
  logout:          ()                    => req("POST", `${API_CONFIG.commercePrefix}/auth/logout`),
  getSession:      ()                    => req("GET",  `${API_CONFIG.commercePrefix}/auth/session`),

  // Shopper preferences
  getPrefs:        (shopperId)           => req("GET",  `${API_CONFIG.commercePrefix}/users/${shopperId}/preferences`),
  putPrefs:        (shopperId, prefs)    => req("PUT",  `${API_CONFIG.commercePrefix}/users/${shopperId}/preferences`, prefs),

  // Generated assets
  generateEmail:   (body, mode = "ref")  => req("POST", `${API_CONFIG.agentPrefix}/generated/recovery-email?mode=${encodeURIComponent(mode)}`, body),
  generateLanding: (body, mode = "ref")  => req("POST", `${API_CONFIG.agentPrefix}/generated/landing-section?mode=${encodeURIComponent(mode)}`, body),
  generateUpsell:  (body, mode = "ref")  => req("POST", `${API_CONFIG.agentPrefix}/generated/upsell-pitch?mode=${encodeURIComponent(mode)}`, body),
  getAsset:        (assetId)             => req("GET",  `${API_CONFIG.agentPrefix}/generated/${assetId}`),

  // Chat — SSE
  openSession:     ()                    => req("POST", `${API_CONFIG.agentPrefix}/s${AgentRoute.session}/${AgentRoute.mode}/chat/sessions`),
  resetSession:    (sid)                 => req("POST", `${API_CONFIG.agentPrefix}/s${AgentRoute.session}/${AgentRoute.mode}/chat/sessions/${sid}/reset`),
  history:         (sid)                 => req("GET",  `${API_CONFIG.agentPrefix}/s${AgentRoute.session}/${AgentRoute.mode}/chat/sessions/${sid}/messages`),
  resetPrefs:      (sid)                 => req("DELETE", `${API_CONFIG.agentPrefix}/s${AgentRoute.session}/${AgentRoute.mode}/chat/sessions/${sid}/preferences`),
  replayTrace:     (sid, afterSeq = 0)   => req("GET",  `${API_CONFIG.agentPrefix}/s${AgentRoute.session}/${AgentRoute.mode}/chat/sessions/${sid}/trace`, { afterSeq }),
  sendMessage:     (sid, body, onEvent)  => stream(`${API_CONFIG.agentPrefix}/s${AgentRoute.session}/${AgentRoute.mode}/chat/sessions/${sid}/messages`, body, onEvent),
};

// --- Internal: REST request dispatcher ---------------------------------------

async function req(method, path, payload) {
  if (API_CONFIG.mode === "mock") return mockReq(method, path, payload);
  return liveReq(method, path, payload);
}

function mockReq(method, path, payload) {
  // Strip prefixes for mock lookup
  const cleanPath = path.replace(API_CONFIG.commercePrefix, '').replace(API_CONFIG.agentPrefix, '');
  const key = `${method} ${normalizePath(cleanPath)}`;
  const handler = _mockHandlers[key];
  if (!handler) {
    throw problem({
      type: "about:blank",
      title: `No mock handler for ${key}`,
      status: 501,
      detail: `No mock handler registered for "${key}"`,
      code: "MOCK_MISSING",
    });
  }
  return Promise.resolve(handler(payload, cleanPath));
}

async function liveReq(method, path, payload) {
  // path is now full path with prefix
  const url = method === "GET" && payload
    ? `${path}?${new URLSearchParams(stringify(payload))}`
    : path;
  const res = await fetch(url, {
    method,
    credentials: 'same-origin',  // Include cookies for session
    headers: {
      "Content-Type": "application/json",
      "Accept":       "application/json",
      "X-Shopper-Id": API_CONFIG.shopperId,
    },
    body: method !== "GET" && payload ? JSON.stringify(payload) : undefined,
  });
  if (!res.ok) throw await parseProblem(res);
  return res.status === 204 ? null : res.json();
}

// --- Internal: SSE stream dispatcher ----------------------------------------

let _mockSSE = null;
export function __setMockSSE(fn) { _mockSSE = fn; }

function stream(path, body, onEvent) {
  if (API_CONFIG.mode === "mock") {
    if (!_mockSSE) throw new Error("Mock SSE engine not registered");
    // Strip agentPrefix for mock
    const cleanPath = path.replace(API_CONFIG.agentPrefix, '');
    return _mockSSE(cleanPath, body, onEvent);
  }
  const ctrl = new AbortController();
  fetch(path, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Shopper-Id": API_CONFIG.shopperId,
      "Accept": "text/event-stream",
    },
    body: JSON.stringify(body),
    signal: ctrl.signal,
  }).then((res) => parseSSEStream(res, onEvent))
    .catch((err) => { if (err.name !== "AbortError") onEvent({ type: "error", payload: { message: err.message } }); });
  return () => ctrl.abort();
}

async function parseSSEStream(res, onEvent) {
  if (!res.ok) return onEvent({ type: "error", payload: { status: res.status } });
  const reader = res.body.getReader();
  const dec = new TextDecoder();
  let buf = "";
  while (true) {
    const { value, done } = await reader.read();
    if (done) return;
    buf += dec.decode(value, { stream: true });
    let idx;
    while ((idx = buf.indexOf("\n\n")) >= 0) {
      const chunk = buf.slice(0, idx);
      buf = buf.slice(idx + 2);
      const dataLine = chunk.split("\n").find((l) => l.startsWith("data:"));
      if (dataLine) {
        try { onEvent(JSON.parse(dataLine.slice(5).trim())); } catch (_) { /* skip */ }
      }
    }
  }
}

// --- Helpers ---------------------------------------------------------------

function normalizePath(path) {
  // Replace ULID-style ids (prefix_alphanum...) so handlers can register `/products/:id`.
  // Also normalize slug paths: /by-slug/{slug} → /by-slug/:id
  return path.split("?")[0]
    .replace(/\/by-slug\/[a-z0-9-]+/g, "/by-slug/:id")
    .replace(/\/[a-z]+_[A-Za-z0-9_]+/g, "/:id");
}

function stringify(obj) {
  const out = {};
  for (const [k, v] of Object.entries(obj || {})) {
    if (v === undefined || v === null) continue;
    out[k] = Array.isArray(v) ? v.join(",") : String(v);
  }
  return out;
}

function problem(p) {
  const err = new Error(p.title || p.message || "API error");
  Object.assign(err, p);
  return err;
}

async function parseProblem(res) {
  const text = await res.text();
  try {
    return problem(JSON.parse(text));
  } catch {
    const match = text.match(/\[\S+\s*:\s*(.+?)\s*\]/);
    const title = match ? match[1] : (text || res.statusText);
    return problem({ title, status: res.status });
  }
}
