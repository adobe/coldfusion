// assets/js/pages/capsule.js
import { api, API_CONFIG } from "../api.js";
import { appStore } from "../store.js";

const CHIP_ICONS = { reviews: "📖", weather: "☔", memory: "🧠", sizing: "📏", comfort: "👟" };
const GUARDRAIL_LABELS = {
  "no-unsupported-fit-guarantee": "No unsupported claims",
  "no-fake-discount":            "No fake discount language",
  "no-misleading-scarcity":      "No fake scarcity",
  "no-pii-leak":                 "Source-cited only",
};

export async function initCapsule() {
  const root = document.querySelector("[data-capsule-root]");
  const params = new URLSearchParams(location.search);

  // Recovery-email re-entry: the email's "Resume Cart" link carries the shopper's
  // id (and cart id) so clicking it restores THEIR cart even after they've logged
  // out — the demo stand-in for a tokenized recovery link. Adopt that identity for
  // this page (and persist it so cart.cfm/checkout keep operating as that shopper).
  const resumeUser = params.get("u") || "";
  const resumeCart = params.get("c") || "";
  if (resumeUser) {
    API_CONFIG.shopperId = resumeUser;
    try { sessionStorage.setItem("stylemart.resumeShopperId", resumeUser); } catch (_) {}
    appStore.set({ shopperId: resumeUser, cartId: resumeCart || appStore.get().cartId });
  }

  const { authenticated, shopperId, cartId, sessionId } = appStore.get();
  const wantsCapsule = authenticated || params.has("capsule");

  // Asset 2 is cart-driven: generate the landing from the shopper's *actual*
  // cart (verified in stock) rather than a canned asset. Falls back to a
  // generic curated capsule for anonymous shoppers or an empty/expired cart.
  let asset, isLiveCart = false;
  if (wantsCapsule) {
    try {
      asset = await api.generateLanding({
        userId:    shopperId  || "usr_demo_001",
        cartId:    cartId     || "crt_demo_001",
        sessionId: sessionId  || "ses_demo_001",
      }, "ref");
      isLiveCart = !!(asset && Array.isArray(asset.items) && asset.items.length);
    } catch (err) { /* fall through to curated */ }
  }

  if (!isLiveCart) {
    try {
      const { items } = await api.listProducts({ pageSize: 4 });
      asset = {
        title: "Curated Essentials",
        subtitle: "A starter capsule wardrobe — sign in for personalized picks",
        rationale: "These versatile pieces mix and match for any occasion. Sign in to get recommendations tailored to your style preferences, trip plans, and size.",
        items: items.map((p) => ({
          productId: p.productId, name: p.name, price: p.price,
          imageUrl: p.imageUrl, evidence: ["popular", "versatile"],
        })),
        outOfStockSwaps: [],
        pricing: null,
        sourceInputs: { preferenceIds: [], ragSourceIds: [], mcpToolCalls: [] },
      };
    } catch (err) { root.innerHTML = `<p class="error">${err.message}</p>`; return; }
  }

  root.querySelector("[data-title]").textContent    = asset.title;
  root.querySelector("[data-subtitle]").textContent = asset.subtitle;
  root.querySelector("[data-rationale]").textContent = asset.rationale;
  renderWeather(root, asset.weatherContext);

  root.querySelector("[data-items]").innerHTML = asset.items.map((it) => `
    <article class="capsule-item">
      <img src="${it.imageUrl}" alt="${it.name}">
      <h4>${it.name}</h4>
      ${it.size || it.color ? `<div class="capsule-item__variant">${[it.color, it.size].filter(Boolean).join(" · ")}</div>` : ""}
      <div class="capsule-item__price">$${Number(it.price).toFixed(2)}</div>
      <div class="capsule-item__evidence">
        ${(it.evidence || []).map((e) => `<span class="evidence-chip">${e}</span>`).join("")}
      </div>
    </article>
  `).join("");

  renderSwaps(root, asset.outOfStockSwaps || []);
  renderPricing(root, asset.pricing);

  const s = asset.sourceInputs || {};
  root.querySelector("[data-sources]").innerHTML = [
    ...(s.preferenceIds || []).map((id) => `<span class="src-chip">memory · ${id}</span>`),
    ...(s.ragSourceIds  || []).map((id) => `<span class="src-chip">RAG · ${id}</span>`),
    ...(s.mcpToolCalls  || []).map((id) => `<span class="src-chip">MCP · ${id}</span>`),
  ].join("");

  root.querySelector("[data-resume]").addEventListener("click", async () => {
    if (isLiveCart) {
      // Items are already in the cart — just take the shopper to it.
      location.href = "cart.cfm";
      return;
    }
    // Curated fallback: stage the suggested items, then open the cart.
    const productIds = asset.items.map((i) => i.productId);
    const staged = await api.stageOutfit(appStore.get().cartId, { productIds, reason: "Resume from capsule landing" });
    const url = new URL("cart.cfm", location.href);
    if (staged.pendingActionId) url.searchParams.set("pending", staged.pendingActionId);
    location.href = url.toString();
  });

  // Merged "Upsell Pitch" (former Asset 3): the landing asset already carries the
  // add-ons (embedded server-side by LandingSectionService.embedUpsell), so we render
  // them inline from the SAME response — no extra API call. Non-fatal: if there are
  // no add-ons (e.g. curated fallback or upsell blocked), the section stays hidden.
  renderUpsellSuggestions(root, asset);
}

function renderUpsellSuggestions(root, asset) {
  const section = root.querySelector("[data-upsell]");
  if (!section) return;
  const addOns = (asset && asset.addOns) || [];
  if (!addOns.length) return;

  section.querySelector("[data-upsell-title]").textContent = "Complete your capsule";

  section.querySelector("[data-addons]").innerHTML = addOns.map((a) => `
    <article class="addon-card">
      <img src="${a.imageUrl}" alt="${a.name}">
      <h4>${a.name}</h4>
      <div class="addon-card__price">$${Number(a.price).toFixed(2)}</div>
      <p class="addon-card__evidence">“${a.evidence || ""}”</p>
      <button class="btn-secondary" data-add="${a.productId}">Add</button>
    </article>
  `).join("");

  section.querySelector("[data-rationale-chips]").innerHTML =
    (asset.addOnsChips || []).map((c) => `<span class="evidence-chip">${CHIP_ICONS[c] ? CHIP_ICONS[c] + " " : ""}${c}</span>`).join("");

  section.querySelector("[data-upsell-total]").innerHTML =
    `<strong>+$${asset.addOnsTotal || 0}</strong> added`;

  const chips = (asset.addOnsGuardrails || []).filter((g) => g.passed !== false);
  section.querySelector("[data-upsell-guardrails]").innerHTML =
    chips.map((g) => `<span class="guard-chip guard-chip--ok">✓ ${GUARDRAIL_LABELS[g.rule] || g.rule}</span>`).join("");

  section.hidden = false;

  section.addEventListener("click", async (e) => {
    const pid = e.target.dataset?.add;
    if (!pid) return;
    e.target.disabled = true;
    e.target.textContent = "Added ✓";
    try { await api.stageOutfit(appStore.get().cartId, { productIds: [pid], reason: "Upsell add-on (landing)" }); }
    catch (_) { e.target.disabled = false; e.target.textContent = "Add"; }
  });
}

// Surface the live trip forecast the server fetched (MCP weather tool) so the shopper
// sees WHY the capsule/add-ons were chosen, e.g. "It's 5°C and overcast in London."
// Injected right after the rationale; skipped when there's no usable forecast.
function renderWeather(root, weather) {
  const existing = root.querySelector("[data-weather]");
  if (existing) existing.remove();
  if (!weather || !weather.summary) return;
  const rationale = root.querySelector("[data-rationale]");
  if (!rationale) return;
  const icon = weather.isCold ? "🧥" : "☀️";
  const tail = weather.isCold ? " We leaned toward warm layers for your trip." : "";
  const el = document.createElement("p");
  el.className = "capsule-weather";
  el.setAttribute("data-weather", "");
  el.innerHTML = `<span aria-hidden="true">${icon}</span> ${weather.summary}${tail}`;
  rationale.insertAdjacentElement("afterend", el);
}

function renderSwaps(root, swaps) {
  const section = root.querySelector("[data-swaps]");
  if (!swaps.length) { section.hidden = true; return; }
  section.hidden = false;
  root.querySelector("[data-swap-list]").innerHTML = swaps.map((sw) => `
    <div class="swap-card">
      <span class="swap-card__oos">Out of stock</span>
      <span class="swap-card__name">${sw.originalName || sw.original}</span>
      <span class="swap-card__note">We'll suggest an in-stock alternative at checkout.</span>
    </div>
  `).join("");
}

function renderPricing(root, pricing) {
  const el = root.querySelector("[data-pricing]");
  if (!pricing || pricing.total == null) { el.hidden = true; return; }
  const bits = [];
  if (pricing.loyaltyTier) bits.push(`<span class="capsule-price__tag">${pricing.loyaltyTier} loyalty</span>`);
  if (pricing.couponCode)  bits.push(`<span class="capsule-price__tag">${pricing.couponCode}</span>`);
  el.hidden = false;
  el.innerHTML = `
    ${bits.join("")}
    <span class="capsule-price__total">Total <strong>$${Number(pricing.total).toFixed(2)}</strong></span>
  `;
}
