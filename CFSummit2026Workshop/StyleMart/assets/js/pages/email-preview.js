// assets/js/pages/email-preview.js
import { api } from "../api.js";
import { appStore } from "../store.js";

// Friendly labels for the guardrail rule ids in the contract. The render only
// shows the chips for rules that actually ran, so live + mock both stay honest.
const GUARDRAIL_LABELS = {
  "no-unsupported-fit-guarantee": "No unsupported fit claims",
  "no-fake-discount":            "No fake discount language",
  "no-misleading-scarcity":      "No high-pressure scarcity",
  "no-pii-leak":                 "No personal-data leaks",
};

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

export async function initEmailPreview() {
  const root = document.querySelector("[data-email-root]");
  const client = root.querySelector("[data-email-client]");
  const sources = root.querySelector("[data-sources]");

  // "abandon" = the shopper clicked "I'll finish later" on the cart, which
  // simulates cart abandonment — the real-world trigger for this email.
  const from = new URLSearchParams(location.search).get("from") || "";
  renderContextBanner(root, from);

  // The email is generated live from the shopper's ACTUAL cart, preferences, and
  // chat memory — so the occasion/destination ("wedding", "Paris business trip",
  // "Varanasi") and the items shown reflect this shopper, not a hardcoded asset.
  // appStore.cartId isn't populated until refreshCartBadge() runs (after this
  // module boots), so we resolve the real cart/session from the server here.
  const ctx = await resolveShopperContext();
  let asset;
  try {
    asset = await api.generateEmail({
      userId:    ctx.userId,
      cartId:    ctx.cartId,
      sessionId: ctx.sessionId,
    }, "ref");
  }
  catch (err) { client.innerHTML = `<p class="error">${err.message}</p>`; return; }

  // The email asset already carries the shopper's actual cart items plus suggested
  // add-ons (the former Asset 3 "Upsell Pitch"), embedded server-side by
  // RecoveryEmailService.embedUpsell — so we render both from the SAME response.
  const cartItems   = asset.cartItems || [];
  const suggestions = asset.addOns    || [];

  sources.innerHTML = sourceGroups(asset)
    .map((g) => sourceBlock(g.label, g.items))
    .join("");

  const slug = asset.capsuleSlug || "jordan-london";
  const chips = (asset.guardrailResults || []).filter((g) => g.passed !== false);

  client.innerHTML = `
    <div class="email-client__toolbar">
      <span class="mac-dots"><i class="mac-dots__dot mac-dots__dot--r"></i><i class="mac-dots__dot mac-dots__dot--y"></i><i class="mac-dots__dot mac-dots__dot--g"></i></span>
      <button class="email-client__back" type="button" aria-label="Back">&larr;</button>
      <nav class="email-client__tabs">
        <span class="email-client__tab email-client__tab--active">Inbox</span>
        <span class="email-client__tab">Drafts</span>
        <span class="email-client__tab">Sent</span>
      </nav>
      <span class="preview-chip">PREVIEW · NOT YET SENT</span>
    </div>

    <div class="email-client__meta">
      <div class="email-client__row"><span class="email-client__key">From</span> <strong>${asset.fromName}</strong> &lt;${asset.fromEmail}&gt;</div>
      <div class="email-client__row"><span class="email-client__key">To</span> ${asset.toEmail}</div>
      <div class="email-client__row email-client__row--subject">
        <span class="email-client__subject"><span class="email-client__key">Subject</span> ${asset.subject}</span>
        <span class="email-client__date"><span class="email-client__key">Date</span> ${formatEmailDate(asset.date)}</span>
      </div>
    </div>

    <div class="email-client__body">
      <div class="email-brand">StyleMart</div>
      ${asset.bodyHtml}
      ${weatherLine(asset.weatherContext)}
      ${cartStrip(cartItems)}
      ${suggestionStrip(suggestions)}
      ${citationLine(asset)}
      <div class="email-cta">
        <a class="btn-primary email-cta__btn" href="capsule.cfm?capsule=${encodeURIComponent(slug)}&u=${encodeURIComponent(ctx.userId)}&c=${encodeURIComponent(ctx.cartId)}">Resume Cart</a>
      </div>
      <div class="guardrail-bar guardrail-bar--inline">
        ${chips.map((g) => `<span class="guard-chip guard-chip--ok">✓ ${guardLabel(g.rule)}</span>`).join("")}
      </div>
      <div class="email-footer">StyleMart · Personal shopping · <a href="##">Unsubscribe</a></div>
    </div>
  `;
}

// Resolve the shopper's real userId / cartId / sessionId. Priority: live server
// session + cart, then whatever is already in appStore, then demo fallbacks so the
// page still renders for an anonymous visitor.
async function resolveShopperContext() {
  const s = appStore.get();
  let userId = s.shopperId || "";
  let cartId = s.cartId || "";

  try {
    const session = await api.getSession();
    if (session && session.authenticated) {
      userId = session.userId || (session.user && session.user.userId) || userId;
    }
  } catch (_) { /* fall back to appStore/demo */ }

  if (!cartId) {
    try {
      const summary = await api.getCartSummary();
      cartId = summary?.cartId || cartId;
    } catch (_) { /* fall back to appStore/demo */ }
  }

  return {
    userId:    userId || "usr_demo_001",
    cartId:    cartId || "crt_demo_001",
    sessionId: s.sessionId || "ses_demo_001",
  };
}

// A small contextual line above the email so the demo narrative is explicit:
// the shopper is leaving with items in the cart, and THIS is the win-back email.
function renderContextBanner(root, from) {
  if (from !== "abandon") return;
  const layout = root.querySelector(".email-layout");
  if (!layout) return;
  const msg = "Saved for later — here's the recovery email we'd send to bring you back.";
  const banner = document.createElement("div");
  banner.className = "email-abandon-note";
  banner.innerHTML = `<span class="email-abandon-note__icon" aria-hidden="true">✉</span> ${msg}`;
  root.insertBefore(banner, layout);
}

function sourceGroups(asset) {
  const s = asset.sourceInputs || {};
  const gr = asset.guardrailResults || [];
  const blocks = gr.filter((g) => g.passed === false).length;
  const rewrites = gr.filter((g) => g.result === "reprompted" || (g.repromptMessage || "").length > 0).length;
  return [
    { label: "Memory",     items: s.memory || s.preferenceIds || [] },
    { label: "MCP",        items: s.mcp    || s.mcpToolCalls  || [] },
    { label: "RAG",        items: s.rag    || s.ragSourceIds  || [] },
    { label: "Guardrails", items: s.guardrails || [`${blocks} blocks`, `${rewrites} rewrites`] },
  ];
}

function sourceBlock(label, items) {
  const list = (items || []).length
    ? `<p class="source-block__line">${items.map((i) => `<span>${i}</span>`).join(" · ")}</p>`
    : `<p class="source-block__line source-block__line--empty">none</p>`;
  return `<div class="source-block"><h4>${label}</h4>${list}</div>`;
}

// "In your cart" — the shopper's actual cart items (display-only inside the email).
function cartStrip(items) {
  if (!items || !items.length) return "";
  const cards = items.map((it) => `
    <article class="email-product">
      <img src="${it.imageUrl}" alt="${it.name}">
      <span class="email-product__name">${it.name}</span>
      <span class="email-product__price">$${Number(it.unitPrice ?? it.price ?? 0).toFixed(2)}</span>
    </article>
  `).join("");
  return `
    <div class="email-strip">
      <h4 class="email-strip__title">Still in your cart</h4>
      <div class="email-strip__grid">${cards}</div>
    </div>`;
}

// "You might also like" — suggested add-ons (former Asset 3), display-only here.
function suggestionStrip(addOns) {
  if (!addOns || !addOns.length) return "";
  const cards = addOns.map((a) => `
    <article class="email-product">
      <img src="${a.imageUrl}" alt="${a.name}">
      <span class="email-product__name">${a.name}</span>
      <span class="email-product__price">$${Number(a.price ?? 0).toFixed(2)}</span>
    </article>
  `).join("");
  return `
    <div class="email-strip">
      <h4 class="email-strip__title">You might also like</h4>
      <div class="email-strip__grid">${cards}</div>
    </div>`;
}

// A small weather banner driven by the live forecast the server fetched (MCP weather
// tool). Explains the "why" behind the recommendations, e.g. "It's 5°C and overcast in
// London — we picked warm layers." Hidden when there's no usable forecast.
function weatherLine(weather) {
  if (!weather || !weather.summary) return "";
  const icon = weather.isCold ? "🧥" : "☀️";
  const tail = weather.isCold ? " We leaned toward warm layers for your trip." : "";
  return `
    <div class="email-weather">
      <span class="email-weather__icon" aria-hidden="true">${icon}</span>
      <span class="email-weather__text">${weather.summary}${tail}</span>
    </div>`;
}

function citationLine(asset) {
  const cites = asset.citations || asset.sourceInputs?.ragSourceIds || [];
  if (!cites.length) return "";
  return `<p class="email-citation">Backed by ${cites.join(", ")}.</p>`;
}

function guardLabel(rule) {
  return GUARDRAIL_LABELS[rule] || rule;
}

function formatEmailDate(dateStr) {
  const d = new Date(dateStr);
  if (isNaN(d)) return dateStr;
  const pad = (n) => String(n).padStart(2, "0");
  return `${MONTHS[d.getMonth()]} ${pad(d.getDate())}, ${d.getFullYear()} · ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}
