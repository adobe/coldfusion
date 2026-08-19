// assets/js/chat.js
import { api } from "./api.js";
import { appStore, getUiContext } from "./store.js";
import { ProductCard } from "./components/product-card.js";

export async function initChat() {
  const root = document.querySelector("[data-chat-root]");
  if (!root) return;
  const messages = root.querySelector("[data-chat-messages]");
  const form = root.querySelector("[data-chat-form]");
  const resetBtn = root.querySelector("[data-chat-reset]");

  const STORED_SID_KEY = "stylemart.sessionId";
  let sessionId = sessionStorage.getItem(STORED_SID_KEY);
  let savedPrefs = {};
  if (sessionId) {
    try {
      const history = await api.history(sessionId);
      history.forEach((m) => appendMessage(m.role, m.content));
      try {
        const prefsResult = await api.getPrefs(appStore.get().shopperId);
        savedPrefs = prefsResult?.preferences || {};
      } catch (_) {
        savedPrefs = {};
      }
      
    } catch (_) {
      sessionStorage.removeItem(STORED_SID_KEY);
      sessionId = null;
    }
  }
  if (!sessionId) {
    const opened = await api.openSession();
    sessionId = opened.sessionId;
    savedPrefs = opened.savedPrefs?.preferences || opened.savedPrefs || {};
    sessionStorage.setItem(STORED_SID_KEY, sessionId);
    renderWelcomeGreeting(savedPrefs);
  }
  appStore.set({ sessionId, savedPrefs });
  renderPrefsRail(savedPrefs);

  const sendQueue = [];
  let sending = false;

  function drainQueue() {
    if (sending || sendQueue.length === 0) return;
    sending = true;
    const { text, displayText, input } = sendQueue.shift();

    appendMessage("user", displayText || text);
    showTypingIndicator();
    let assistantEl = null;
    let buffer = "";
    let pendingCitations = [];
    let pendingToolCards = [];
    let pendingOrders = [];
    let pendingCart = null;
    let pendingProduct = null;
    let hadCompareTable = false;

    api.sendMessage(sessionId, { userText: text, uiContext: getUiContext() }, (event) => {
      appStore.update((s) => ({ traceEvents: [...s.traceEvents, event] }));

      if (event.type === "model.start") {
        // Don't clear _lastSearchResults here — keep old products linkable
        // until a new searchCatalog call replaces them in flushPendingCards
        window._turnHasNewSearch = false;
      } else if (event.type === "retrieval.hit") {
        pendingCitations.push({
          source: event.payload.metadata?.source || event.payload.metadata?.file_name || "unknown",
          score: event.payload.score || 0,
          docType: event.payload.metadata?.docType || ""
        });
      } else if (event.type === "model.delta") {
        if (!assistantEl) {
          hideTypingIndicator();
          assistantEl = appendMessage("assistant", "", { streaming: true });
        }
        buffer += event.payload.text || "";
        assistantEl.textContent = buffer;
      } else if (event.type === "model.end") {
        if (assistantEl && buffer) {
          let finalText = buffer;
          if (hadCompareTable) {
            finalText = finalText.replace(/^\|.*\|$/gm, "").replace(/\n{2,}/g, "\n").trim();
          }
          if (finalText) {
            assistantEl.innerHTML = renderMarkdown(finalText);
          } else {
            assistantEl.remove();
            assistantEl = null;
          }
        }
        if (pendingProduct && pendingToolCards.length > 0) {
          const searchIds = new Set(pendingToolCards.flatMap(c => c.products.map(p => p.productId)));
          if (!searchIds.has(pendingProduct.productId)) pendingProduct = null;
        }
        if (pendingProduct) {
          flushPendingProduct(pendingProduct);
          pendingProduct = null;
        }
        if (pendingToolCards.length > 0) {
          flushPendingCards(pendingToolCards);
          pendingToolCards = [];
        }
        if (pendingOrders.length > 0) {
          flushPendingOrders(pendingOrders);
          pendingOrders = [];
        }
        if (pendingCart) {
          flushPendingCart(pendingCart);
          pendingCart = null;
        }
        if (assistantEl && buffer) {
          requestAnimationFrame(() => linkifyProductReferences(assistantEl));
        }
        if (assistantEl && pendingCitations.length > 0) {
          const chipRow = document.createElement("div");
          chipRow.className = "chat-citation-row";
          const seen = new Set();
          for (const cite of pendingCitations) {
            if (seen.has(cite.source)) continue;
            seen.add(cite.source);
            const chip = document.createElement("span");
            chip.className = "chat-citation-chip";
            chip.title = `${cite.docType} — relevance: ${(cite.score * 100).toFixed(0)}%`;
            chip.textContent = cite.source;
            chipRow.appendChild(chip);
          }
          assistantEl.parentElement.appendChild(chipRow);
          pendingCitations = [];
        }
      } else if (event.type === "guardrail.violation") {
        // A guardrail returned failure/fatal. There is no in-place rewrite:
        // `failure` + repromptMessage drives an LLM re-answer; `fatal` hard-stops.
        const { rule, result, message } = event.payload || {};
        const fatal = result === "fatal";
        if (assistantEl) {
          const icon = document.createElement("span");
          icon.className = `chat-bubble__guard${fatal ? " chat-bubble__guard--fatal" : ""}`;
          icon.title = `${fatal ? "Blocked" : "Flagged"}: ${rule}${message ? ` — ${message}` : ""}`;
          icon.textContent = "\u{1F6E1}";
          assistantEl.appendChild(icon);
        } else if (message) {
          // fatal/flagged before any tokens streamed — surface a styled guardrail bubble
          hideTypingIndicator();
          renderGuardrailBubble(
            appendMessage("assistant", ""),
            fatal ? "🛡️ Blocked by a guardrail" : "🛡️ Flagged by a guardrail",
            message
          );
        }
      } else if (event.type === "tool.product") {
        const product = event.payload?.product;
        if (product) pendingProduct = product;
      } else if (event.type === "tool.products") {
        hideTypingIndicator();
        // Signal that this turn has new search results — triggers reset in flushPendingCards
        window._turnHasNewSearch = true;
        const products = event.payload?.products || [];
        const totalCount = event.payload?.totalCount || products.length;
        const query = event.payload?.query || "";
        const matchedCategories = event.payload?.matchedCategories || [];
        if (products.length) {
          pendingToolCards.push({ products, totalCount, query, matchedCategories });
        }
      } else if (event.type === "tool.order") {
        const order = event.payload?.order;
        if (order) pendingOrders.push(order);

      } else if (event.type === "tool.orders") {
        const orders = event.payload?.orders || [];
        if (orders.length) pendingOrders.push(...orders);
      } else if (event.type === "tool.compare") {
        hideTypingIndicator();
        hadCompareTable = true;
        const cmp = event.payload?.comparison;
        if (cmp && cmp.products && cmp.rows) {
          const tableEl = document.createElement("div");
          tableEl.className = "chat-compare-block";
          tableEl.innerHTML = renderCompareTable(cmp);
          appendToCurrentGroup(tableEl);

          tableEl.querySelectorAll("[data-compare-add]").forEach(btn => {
            btn.addEventListener("click", (e) => {
              e.preventDefault();
              const pid = btn.dataset.compareAdd;
              const input = document.querySelector("[data-chat-form] input[name=text]");
              if (input) {
                input.value = `add ${btn.dataset.productName || pid} to cart`;
                input.closest("form")?.requestSubmit();
              }
            });
          });
        }
      } else if (event.type === "tool.cart") {
        const cartItems = event.payload?.items || [];
        const subtotal = event.payload?.subtotal || 0;
        if (cartItems.length) pendingCart = { items: cartItems, subtotal };
      } else if (event.type === "error") {
        hideTypingIndicator();
        if (!assistantEl) assistantEl = appendMessage("assistant", "");
        const rawDetail = event.payload?.detail || event.payload?.title || event.payload?.message || "";
        // A guardrail block arrives here as a generic error; surface it as a calm,
        // intentional refusal (🛡️) rather than a scary "Something went wrong".
        const isGuardrail = event.payload?.type === "guardrail.blocked" || /guardrail/i.test(rawDetail);
        if (event.payload?.status === 429) {
          assistantEl.classList.add("chat-bubble--error");
          import("./components/banner.js").then(({ showBanner }) =>
            showBanner({ kind: "warn", text: `Rate limited — retry in ${event.payload.retryAfter || "a few"} seconds`, durationMs: 6000 })
          );
          assistantEl.textContent = "Slow down — try again in a moment.";
        } else if (isGuardrail) {
          const msgIdx = rawDetail.toLowerCase().indexOf("with this message:");
          let safeMsg = msgIdx >= 0 ? rawDetail.slice(msgIdx + "with this message:".length) : "";
          safeMsg = safeMsg.trim().replace(/\.+\s*$/, "");
          if (!safeMsg) safeMsg = "That request was blocked for safety reasons.";
          renderGuardrailBubble(assistantEl, "🛡️ Blocked by a guardrail", safeMsg);
        } else {
          assistantEl.classList.add("chat-bubble--error");
          assistantEl.textContent = `Something went wrong: ${rawDetail || "unknown error"}.`;
        }
      } else if (event.type === "done") {
        hideTypingIndicator();
        if (pendingProduct && pendingToolCards.length > 0) {
          const searchIds = new Set(pendingToolCards.flatMap(c => c.products.map(p => p.productId)));
          if (!searchIds.has(pendingProduct.productId)) pendingProduct = null;
        }
        if (pendingProduct) {
          flushPendingProduct(pendingProduct);
          pendingProduct = null;
        }
        if (pendingToolCards.length > 0) {
          flushPendingCards(pendingToolCards);
          pendingToolCards = [];
        }
        if (pendingOrders.length > 0) {
          flushPendingOrders(pendingOrders);
          pendingOrders = [];
        }
        if (pendingCart) {
          flushPendingCart(pendingCart);
          pendingCart = null;
        }
        if (assistantEl) assistantEl.classList.remove("chat-bubble--streaming");
        sending = false;
        input.disabled = sendQueue.length > 0;
        if (!input.disabled) input.focus();
        drainQueue();
      }
    });
  }

  function flushPendingCards(cardQueue) {
    // If this turn has a new search, reset results; otherwise keep old products for linkification
    if (window._turnHasNewSearch) {
      window._lastSearchResults = [];
    }
    let turnOffset = (window._lastSearchResults || []).length;

    for (const { products, totalCount, query, matchedCategories } of cardQueue) {
      const BATCH_SIZE = 6;
      let shown = 0;

      // Tag each product with its display number for reliable lookup
      products.forEach((p, i) => { p._displayNum = turnOffset + i + 1; });

      // Append ALL products to the running results
      window._lastSearchResults = (window._lastSearchResults || []).concat(products);

      const wrapper = document.createElement("div");
      wrapper.className = "chat-products-wrapper";

      const grid = document.createElement("div");
      grid.className = "product-grid chat-products-grid";
      wrapper.appendChild(grid);

      function renderBatch() {
        const batch = products.slice(shown, shown + BATCH_SIZE);
        grid.insertAdjacentHTML("beforeend", batch.map((p, i) => ProductCard(p, { chatMode: true, resultNum: turnOffset + shown + i + 1 })).join(""));
        shown += batch.length;
        wireProductCardButtons(grid, products);
        updateFooter();
      }

      const footer = document.createElement("div");
      footer.className = "chat-products-footer";
      wrapper.appendChild(footer);

      function updateFooter() {
        const remaining = products.length - shown;
        const moreAvailable = totalCount > products.length;
        let footerHtml = "";

        if (matchedCategories.length) {
          footerHtml += `<div class="chat-products-cats">
            ${matchedCategories.map(c => `<a href="category.cfm?slug=${c.slug}" class="chat-cat-chip">${escapeHtml(c.name)}</a>`).join("")}
          </div>`;
        }

        if (remaining > 0) {
          footerHtml += `<button class="btn btn--sm chat-products-load-more" data-load-more>Show ${remaining} more</button>`;
        } else if (moreAvailable) {
          footerHtml += `<a href="search.cfm?q=${encodeURIComponent(query)}" class="chat-products-view-all">View all ${totalCount} results &rarr;</a>`;
        }

        footer.innerHTML = footerHtml;

        const loadMoreBtn = footer.querySelector("[data-load-more]");
        if (loadMoreBtn) {
          loadMoreBtn.addEventListener("click", (e) => {
            e.preventDefault();
            renderBatch();
            grid.scrollLeft = grid.scrollWidth;
          });
        }
      }

      // Compare toggle functionality
      let compareSet = new Set();
      const compareBar = document.createElement("div");
      compareBar.className = "chat-compare-bar";
      compareBar.style.display = "none";
      wrapper.appendChild(compareBar);

      function updateCompareBar() {
        if (compareSet.size >= 2) {
          compareBar.style.display = "flex";
          compareBar.innerHTML = `
            <span class="chat-compare-bar__count">${compareSet.size} selected</span>
            <button class="btn btn--sm chat-compare-bar__btn" data-do-compare>Compare Now</button>
            <button class="btn btn--sm chat-compare-bar__clear" data-clear-compare>Clear</button>
          `;
          compareBar.querySelector("[data-do-compare]").addEventListener("click", async () => {
            const ids = [...compareSet];
            compareBar.querySelector("[data-do-compare]").textContent = "Comparing...";
            try {
              const result = await api.compare(ids, ["price", "fabric", "care", "sizes", "colors", "fit"]);
              const tableEl = document.createElement("div");
              tableEl.className = "chat-compare-block";
              tableEl.innerHTML = renderCompareTable(result);
              appendToCurrentGroup(tableEl);
              compareBar.style.display = "none";
              compareSet.clear();
              grid.querySelectorAll("[data-compare-check]").forEach(btn => {
                btn.textContent = "+ Compare";
                btn.classList.remove("product-card__compare-toggle--active");
              });
            } catch (err) {
              appendMessage("assistant", `Comparison failed: ${err.message || "error"}`);
              compareBar.querySelector("[data-do-compare]").textContent = "Compare Now";
            }
          });
          compareBar.querySelector("[data-clear-compare]").addEventListener("click", () => {
            compareSet.clear();
            grid.querySelectorAll("[data-compare-check]").forEach(btn => {
              btn.textContent = "+ Compare";
              btn.classList.remove("product-card__compare-toggle--active");
            });
            compareBar.style.display = "none";
          });
        } else {
          compareBar.style.display = "none";
        }
      }

      function wireCompareToggles(container) {
        container.querySelectorAll("[data-compare-check]").forEach(btn => {
          if (btn.dataset.wiredCompare) return;
          btn.dataset.wiredCompare = "1";
          btn.addEventListener("click", (e) => {
            e.preventDefault();
            e.stopPropagation();
            const pid = btn.dataset.compareCheck;
            if (compareSet.has(pid)) {
              compareSet.delete(pid);
              btn.textContent = "+ Compare";
              btn.classList.remove("product-card__compare-toggle--active");
            } else {
              if (compareSet.size >= 4) return;
              compareSet.add(pid);
              btn.textContent = "✓ Compare";
              btn.classList.add("product-card__compare-toggle--active");
            }
            updateCompareBar();
          });
        });
      }

      wireCompareToggles(grid);
      const observer = new MutationObserver(() => wireCompareToggles(grid));
      observer.observe(grid, { childList: true });

      renderBatch();
      appendToCurrentGroup(wrapper);
      turnOffset += products.length;

      // Suggestion chips — per-batch, referencing THIS batch's top products
      if (products.length >= 2) {
        const chips = document.createElement("div");
        chips.className = "suggestion-chips";
        const p1 = products[0];
        const p2 = products[1];
        // Detect category from batch for contextual chip labels
        const cat = (p1.category || "").replace(/-/g, " ");
        const catLabel = cat ? cat : "these";
        chips.innerHTML = `
          <button class="suggestion-chip" data-display="Compare top ${escapeHtml(catLabel)}" data-api="Compare ${escapeHtml(p1.name)} and ${escapeHtml(p2.name)} (product_ids: ${p1.productId}, ${p2.productId})">&#9878; Compare top ${escapeHtml(catLabel)}</button>
          <button class="suggestion-chip" data-display="Which ${escapeHtml(catLabel)} is better reviewed?" data-api="Which has better reviews: ${escapeHtml(p1.name)} (product_id: ${p1.productId}) or ${escapeHtml(p2.name)} (product_id: ${p2.productId})?">&#9733; Best reviewed?</button>
          <button class="suggestion-chip" data-display="Care and returns" data-api="What are the care instructions and return policy for ${escapeHtml(p1.name)} and ${escapeHtml(p2.name)}?">&#128203; Care &amp; returns</button>
        `;
        appendToCurrentGroup(chips);
      }
    }
  }

  function wireQtyButtons(container, pid, size, variantId, products) {
    const product = products.find(p => p.productId === pid);
    let qty = 1;

    container.querySelector("[data-qty-minus]")?.addEventListener("click", async () => {
      if (qty <= 1) {
        try {
          await api.directRemove(variantId);
          container.innerHTML = `
            <select class="product-card__size-select" data-size-select="${pid}">
              <option value="">Select size</option>
              ${(product?.availableSizes || []).map(s => `<option value="${s}" ${s === size ? "selected" : ""}>${s}</option>`).join("")}
            </select>
            <button class="btn btn--sm product-card__add-btn" data-add-to-cart="${pid}">Add to Cart</button>
          `;
          const newBtn = container.querySelector(`[data-add-to-cart="${pid}"]`);
          const newSel = container.querySelector(`[data-size-select="${pid}"]`);
          if (newSel) newSel.addEventListener("change", () => { if (newBtn) newBtn.disabled = !newSel.value; });
          if (newBtn) {
            newBtn.disabled = false;
            newBtn.addEventListener("click", async (ev) => {
              ev.preventDefault(); ev.stopPropagation();
              const s = newSel ? newSel.value : size;
              if (!s) return;
              newBtn.disabled = true; newBtn.textContent = "Adding...";
              try {
                const result = await api.directAdd({ productId: pid, size: s });
                container.dataset.variantId = result.variantId;
                container.innerHTML = `
                  <div class="product-card__qty-row">
                    <button class="qty-btn" data-qty-minus="${pid}">−</button>
                    <span class="qty-val" data-qty-val="${pid}">1</span>
                    <button class="qty-btn" data-qty-plus="${pid}">+</button>
                  </div>
                  <a href="cart.cfm" class="product-card__view-cart">View Cart</a>
                `;
                wireQtyButtons(container, pid, s, result.variantId, products);
                appendMessage("assistant", `Added ${product?.name || "item"} (${s}) to your cart.`);
                if (window.refreshCartBadge) window.refreshCartBadge(true);
              } catch (err) { newBtn.disabled = false; newBtn.textContent = "Add to Cart"; }
            });
          }
          appendMessage("assistant", `Removed ${product?.name || "item"} from your cart.`);
          if (window.refreshCartBadge) window.refreshCartBadge(true);
        } catch (err) {}
        return;
      }
      qty--;
      container.querySelector(`[data-qty-val="${pid}"]`).textContent = qty;
    });

    container.querySelector("[data-qty-plus]")?.addEventListener("click", async () => {
      qty++;
      container.querySelector(`[data-qty-val="${pid}"]`).textContent = qty;
      try {
        await api.directAdd({ productId: pid, size });
        if (window.refreshCartBadge) window.refreshCartBadge(true);
      } catch (err) {
        qty--;
        container.querySelector(`[data-qty-val="${pid}"]`).textContent = qty;
      }
    });
  }

  function wireProductCardButtons(grid, products) {
    grid.querySelectorAll("[data-size-select]").forEach(sel => {
      if (sel.dataset.wired) return;
      sel.dataset.wired = "1";
      sel.addEventListener("change", () => {
        const pid = sel.dataset.sizeSelect;
        const btn = grid.querySelector(`[data-add-to-cart="${pid}"]`);
        if (btn) btn.disabled = !sel.value;
      });
    });

    grid.querySelectorAll("[data-add-to-cart]").forEach(btn => {
      if (btn.dataset.wired) return;
      btn.dataset.wired = "1";
      btn.addEventListener("click", async (e) => {
        e.preventDefault();
        e.stopPropagation();
        const pid = btn.dataset.addToCart;
        const sel = grid.querySelector(`[data-size-select="${pid}"]`);
        const size = sel ? sel.value : "";
        const product = products.find(p => p.productId === pid);
        if (!product || !size) return;

        btn.disabled = true;
        btn.textContent = "Adding...";

        try {
          const result = await api.directAdd({ productId: pid, size });
          const actionsEl = btn.closest(".product-card__actions");
          if (actionsEl) {
            actionsEl.dataset.variantId = result.variantId;
            actionsEl.innerHTML = `
              <div class="product-card__qty-row">
                <button class="qty-btn" data-qty-minus="${pid}">−</button>
                <span class="qty-val" data-qty-val="${pid}">1</span>
                <button class="qty-btn" data-qty-plus="${pid}">+</button>
              </div>
              <a href="cart.cfm" class="product-card__view-cart">View Cart</a>
            `;
            wireQtyButtons(actionsEl, pid, size, result.variantId, products);
          }
          appendMessage("assistant", `Added ${product.name} (${size}) to your cart.`);
          if (window.refreshCartBadge) window.refreshCartBadge(true);
        } catch (err) {
          btn.disabled = false;
          btn.textContent = "Add to Cart";
          appendMessage("assistant", `Could not add: ${err.message || "error"}`);
        }
      });
    });
  }

  resetBtn.addEventListener("click", async () => {
    const response = await api.resetSession(sessionId);
    sessionId = response.sessionId || sessionId;
    sessionStorage.setItem(STORED_SID_KEY, sessionId);
    appStore.set({ sessionId, traceEvents: [] });
    messages.innerHTML = "";
    sendQueue.length = 0;
    sending = false;
    window._lastSearchResults = null;
  });

  // When the session (S1–S6) or mode (Lab/Ref) toggle changes, the cached
  // sessionId belongs to the old route. Drop it and open a fresh session
  // against the newly selected route so requests hit the right backend.
  let switching = false;
  document.addEventListener("chat:route-change", async () => {
    if (switching) return;
    switching = true;
    try {
      sessionStorage.removeItem(STORED_SID_KEY);
      sendQueue.length = 0;
      sending = false;
      window._lastSearchResults = null;
      messages.innerHTML = "";

      const opened = await api.openSession();
      sessionId = opened.sessionId;
      savedPrefs = opened.savedPrefs?.preferences || opened.savedPrefs || {};
      sessionStorage.setItem(STORED_SID_KEY, sessionId);
      appStore.set({ sessionId, savedPrefs, traceEvents: [] });
      renderWelcomeGreeting(savedPrefs);
      renderPrefsRail(savedPrefs);
    } finally {
      switching = false;
    }
  });

  document.querySelector("[data-prefs-reset]")?.addEventListener("click", async () => {
    if (!sessionId) return;
    try {
      await api.resetPrefs(sessionId);
    } catch (_) {}
    renderPrefsRail({});
    appStore.set({ savedPrefs: {} });
  });

  appStore.subscribe((s) => {
    const last = s.traceEvents[s.traceEvents.length - 1];
    if (last && last.type === "preference.persist") {
      const fields = last.payload?.fields || [];
      const values = last.payload?.values || {};
      fields.forEach((f) => {
        if (Object.prototype.hasOwnProperty.call(values, f)) savedPrefs[f] = values[f];
      });
      renderPrefsRail(savedPrefs);
    }
  });

  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const input = form.querySelector("input[name=text]");
    const raw = input.value.trim();
    if (!raw) return;
    input.value = "";
    input.disabled = true;

    let text;
    if (input.dataset.pendingProductRef) {
      try {
        const ref = JSON.parse(input.dataset.pendingProductRef);
        if (raw.startsWith(`@${ref.name}`)) {
          text = raw + `\n\n[Product reference: "${ref.name}" (product_id: ${ref.id})]`;
        } else {
          text = resolveProductReferences(raw);
        }
      } catch (_) {
        text = resolveProductReferences(raw);
      }
      delete input.dataset.pendingProductRef;
    } else {
      text = resolveProductReferences(raw);
    }

    sendQueue.push({ text, displayText: raw, input });
    drainQueue();
  });

  messages.addEventListener("click", (e) => {
    const askBadge = e.target.closest(".card-ask-badge");
    if (askBadge) {
      e.preventDefault();
      e.stopPropagation();
      const name = askBadge.dataset.productName;
      const productId = askBadge.dataset.productId;
      const input = form.querySelector("input[name=text]");
      input.value = `@${name} `;
      input.dataset.pendingProductRef = JSON.stringify({ name, id: productId });
      input.disabled = false;
      input.focus();
      input.setSelectionRange(input.value.length, input.value.length);
      return;
    }

    const ref = e.target.closest(".product-ref");
    if (ref) {
      e.preventDefault();
      const name = ref.dataset.name;
      const input = form.querySelector("input[name=text]");
      input.value = `@${name} `;
      input.disabled = false;
      input.focus();
      input.setSelectionRange(input.value.length, input.value.length);
      return;
    }

    const askBtn = e.target.closest(".card-ask-btn");
    if (askBtn) {
      e.preventDefault();
      const name = askBtn.dataset.productName;
      const pid = askBtn.dataset.productId;
      const action = askBtn.dataset.action;
      let displayMsg = "";
      let apiMsg = "";
      if (action === "details") {
        displayMsg = `Tell me about the ${name}`;
        apiMsg = `Tell me everything about ${name} (product_id: ${pid})`;
      } else if (action === "reviews") {
        displayMsg = `Reviews for ${name}`;
        apiMsg = `What do customers say about ${name} (product_id: ${pid})?`;
      }
      if (displayMsg) {
        const input = form.querySelector("input[name=text]");
        input.disabled = false;
        sendQueue.push({ text: apiMsg, displayText: displayMsg, input });
        drainQueue();
      }
      return;
    }

    const chip = e.target.closest(".suggestion-chip");
    if (chip) {
      e.preventDefault();
      const displayMsg = chip.dataset.display;
      const apiMsg = chip.dataset.api;
      if (displayMsg && apiMsg) {
        const input = form.querySelector("input[name=text]");
        input.disabled = false;
        sendQueue.push({ text: apiMsg, displayText: displayMsg, input });
        drainQueue();
      }
    }
  });

  // Hover tooltip for .product-ref elements (fixed positioning)
  const refTooltip = document.createElement("div");
  refTooltip.className = "product-ref-tooltip";
  document.body.appendChild(refTooltip);

  messages.addEventListener("mouseover", (e) => {
    const ref = e.target.closest(".product-ref");
    if (!ref) return;
    const image = ref.dataset.image;
    const name = ref.dataset.name;
    const price = ref.dataset.price;
    refTooltip.innerHTML = `
      ${image ? `<img src="${image}" alt="" class="ref-tooltip-img" onerror="this.style.display='none'">` : ""}
      <div class="ref-tooltip-info">
        <strong>${name}</strong>
        ${price ? `<span class="ref-tooltip-price">${price}</span>` : ""}
      </div>
    `;
    const rect = ref.getBoundingClientRect();
    refTooltip.style.top = (rect.top - 76) + "px";
    refTooltip.style.left = rect.left + "px";
    refTooltip.classList.add("visible");
  });

  messages.addEventListener("mouseout", (e) => {
    const ref = e.target.closest(".product-ref");
    if (!ref) return;
    refTooltip.classList.remove("visible");
  });
}

function appendMessage(kind, text, opts = {}) {
  const messages = document.querySelector("[data-chat-messages]");
  const { streaming = false } = opts;

  const lastGroup = messages.querySelector(".chat-msg-group:last-child");
  const sameGroup = lastGroup
    && lastGroup.dataset.sender === kind
    && !lastGroup.querySelector(".chat-products-wrapper, .chat-order-block, .chat-cart-block, .chat-compare-block, .chat-review-block");

  let group;
  if (sameGroup) {
    group = lastGroup;
  } else {
    group = document.createElement("div");
    group.className = `chat-msg-group chat-msg-group--${kind}`;
    group.dataset.sender = kind;

    if (kind === "assistant") {
      group.innerHTML = `
        <div class="chat-msg-group__avatar">
          <img src="assets/img/mira-avatar.svg" alt="Mira"
               onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'chat-msg-group__avatar-fallback',textContent:'M'}))">
        </div>
        <div class="chat-msg-group__bubbles"></div>
      `;
    } else {
      group.innerHTML = `<div class="chat-msg-group__bubbles"></div>`;
    }
    messages.appendChild(group);
  }

  const bubblesContainer = group.querySelector(".chat-msg-group__bubbles");
  const bubble = document.createElement("div");
  bubble.className = `chat-bubble chat-bubble--${kind}`;
  if (streaming) bubble.classList.add("chat-bubble--streaming");
  if (text) {
    if (kind === "assistant" && !streaming) {
      bubble.innerHTML = renderMarkdown(text);
    } else {
      bubble.textContent = text;
    }
  }
  bubblesContainer.appendChild(bubble);

  messages.scrollTop = messages.scrollHeight;
  return bubble;
}

// Style an assistant bubble as a calm, intentional guardrail notice (🛡️ badge +
// the guard's own safe message) instead of a red error. `bubble` is the element
// returned by appendMessage("assistant", "").
function renderGuardrailBubble(bubble, title, message) {
  if (!bubble) return;
  bubble.classList.remove("chat-bubble--error");
  bubble.classList.add("chat-bubble--guardrail");
  bubble.textContent = "";
  const badge = document.createElement("span");
  badge.className = "chat-bubble__guard-badge";
  badge.textContent = title;
  bubble.appendChild(badge);
  if (message) {
    const msg = document.createElement("span");
    msg.className = "chat-bubble__guard-msg";
    msg.textContent = message;
    bubble.appendChild(msg);
  }
  const messages = document.querySelector("[data-chat-messages]");
  if (messages) messages.scrollTop = messages.scrollHeight;
}

function showTypingIndicator() {
  const messages = document.querySelector("[data-chat-messages]");
  let indicator = messages.querySelector(".chat-typing");
  if (indicator) return indicator;

  indicator = document.createElement("div");
  indicator.className = "chat-typing";
  indicator.innerHTML = `
    <div class="chat-msg-group__avatar">
      <img src="assets/img/mira-avatar.svg" alt=""
           onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'chat-msg-group__avatar-fallback',textContent:'M'}))">
    </div>
    <div class="chat-typing__dots">
      <span></span><span></span><span></span>
    </div>
  `;
  messages.appendChild(indicator);
  messages.scrollTop = messages.scrollHeight;
  return indicator;
}

function hideTypingIndicator() {
  document.querySelector("[data-chat-messages] .chat-typing")?.remove();
}

function appendToCurrentGroup(element) {
  const messages = document.querySelector("[data-chat-messages]");
  const lastGroup = messages.querySelector(".chat-msg-group--assistant:last-child .chat-msg-group__bubbles");
  if (lastGroup) {
    lastGroup.appendChild(element);
  } else {
    const group = document.createElement("div");
    group.className = "chat-msg-group chat-msg-group--assistant";
    group.dataset.sender = "assistant";
    group.innerHTML = `
      <div class="chat-msg-group__avatar">
        <img src="assets/img/mira-avatar.svg" alt="Mira"
             onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'chat-msg-group__avatar-fallback',textContent:'M'}))">
      </div>
      <div class="chat-msg-group__bubbles"></div>
    `;
    group.querySelector(".chat-msg-group__bubbles").appendChild(element);
    messages.appendChild(group);
  }
  messages.scrollTop = messages.scrollHeight;
}

// Envelope keys are metadata the API wraps around the preference fact-set
// (re-attached on read). They are never user preferences, so they must be
// hidden from the UI AND stripped before persisting — otherwise a PUT would
// bake them into the stored JSON column.
const PREF_ENVELOPE_KEYS = new Set(["userid", "updatedat", "schemaversion", "_corrupt"]);
function isPrefEnvelopeKey(k) {
  return PREF_ENVELOPE_KEYS.has(String(k).toLowerCase());
}
function stripPrefEnvelope(prefs) {
  const out = {};
  for (const [k, v] of Object.entries(prefs || {})) {
    if (!isPrefEnvelopeKey(k)) out[k] = v;
  }
  return out;
}

function renderWelcomeGreeting(prefs) {
  const messages = document.querySelector("[data-chat-messages]");
  if (!messages) return;

  messages.querySelector(".chat-greeting")?.remove();

  const visible = Object.entries(prefs || {}).filter(([k]) => !isPrefEnvelopeKey(k));

  let lines;

  if (visible.length) {
    const parts = [];
    if (prefs.topSize) parts.push(`size ${prefs.topSize}`);
    if (prefs.bottomSize) parts.push(`bottoms in ${prefs.bottomSize}`);
    if (prefs.colors && prefs.colors.length) {
      const colorList = Array.isArray(prefs.colors) ? prefs.colors : [prefs.colors];
      parts.push(colorList.length === 1
        ? `${colorList[0]} tones`
        : `${colorList.slice(0, -1).join(", ")} and ${colorList[colorList.length - 1]} tones`);
    }
    if (prefs.budget) parts.push(`a budget around $${prefs.budget}`);
    if (prefs.style) parts.push(`a ${prefs.style} style`);

    const handled = ["topSize", "bottomSize", "colors", "budget", "style"];
    const extra = visible.filter(([k]) => !handled.includes(k));
    extra.forEach(([k, v]) => parts.push(`${k}: ${Array.isArray(v) ? v.join(", ") : v}`));

    const prefSentence = parts.length ? ` I remember you prefer ${parts.join(", ")}.` : "";
    lines = `<strong>Welcome back!</strong>${prefSentence} What can I help you find today?`;
  } else {
    lines = `<strong>Hi, I’m Mira</strong> — your personal style assistant. I can help you find outfits, check on orders, compare products, or write reviews. What are you looking for?`;
  }

  const group = document.createElement("div");
  group.className = "chat-msg-group chat-msg-group--assistant chat-greeting";
  group.dataset.sender = "assistant";
  group.innerHTML = `
    <div class="chat-msg-group__avatar">
      <img src="assets/img/mira-avatar.svg" alt="Mira"
           onerror="this.replaceWith(Object.assign(document.createElement(‘span’),{className:’chat-msg-group__avatar-fallback’,textContent:’M’}))">
    </div>
    <div class="chat-msg-group__bubbles">
      <div class="chat-bubble chat-bubble--assistant chat-bubble--greeting">${lines}</div>
    </div>
  `;
  messages.prepend(group);
}

function renderPrefsRail(prefs) {
  const body = document.querySelector("[data-prefs-body]");
  if (!body) return;
  const visible = Object.entries(prefs).filter(([k]) => !isPrefEnvelopeKey(k));
  if (!visible.length) {
    body.innerHTML = `<span class="chat__prefs-empty">No prefs yet.</span>`;
    return;
  }
  body.innerHTML = visible
    .map(([k, v]) => `<span class="chat__pref-chip" data-pref-key="${escapeHtml(k)}"><code>${escapeHtml(k)}</code>${escapeHtml(Array.isArray(v) ? v.join(", ") : String(v))}<button type="button" class="chat__pref-chip__remove" data-remove-pref="${escapeHtml(k)}" title="Remove ${escapeHtml(k)}" aria-label="Remove ${escapeHtml(k)}">×</button></span>`)
    .join("");

  // Per-chip delete: drop a single key and persist the reduced set (PUT replaces
  // the whole preferences object, so omitting one key removes it from the DB).
  body.querySelectorAll("[data-remove-pref]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const key = btn.dataset.removePref;
      const chip = btn.closest(".chat__pref-chip");
      chip?.classList.add("chat__pref-chip--removing");
      delete prefs[key];
      try {
        await api.putPrefs(appStore.get().shopperId, stripPrefEnvelope(prefs));
      } catch (_) {}
      appStore.set({ savedPrefs: { ...prefs } });
      renderPrefsRail(prefs);
    });
  });
}


function resolveProductReferences(messageText) {
  const results = window._lastSearchResults;
  if (!results || !results.length) return messageText;

  const atPattern = /@([^@\n]+?)(?=\s+\w{2,}|\s*$)/g;
  let resolved = messageText;
  const refs = [];

  let match;
  while ((match = atPattern.exec(messageText)) !== null) {
    const refName = match[1].trim().toLowerCase();

    // Priority 1: Exact match (case-insensitive)
    let product = results.find(p =>
      p.name && p.name.toLowerCase() === refName
    );

    // Priority 2: Product name starts with the reference
    if (!product) {
      product = results.find(p =>
        p.name && p.name.toLowerCase().startsWith(refName)
      );
    }

    // Priority 3: Reference starts with the product name (user typed more)
    if (!product) {
      product = results.find(p =>
        p.name && refName.startsWith(p.name.toLowerCase())
      );
    }

    // Priority 4: Reference without category suffix matches product without category suffix
    if (!product) {
      const refWithoutCategory = refName.replace(
        /\s+(jackets|dresses|shirts|pants|shoes|accessories|sweaters|tshirts|sneakers|backpacks|blazers|raincoats|sunglasses|jeans)$/i, ''
      );
      product = results.find(p => {
        if (!p.name) return false;
        const pNameClean = p.name.toLowerCase().replace(
          /\s+(jackets|dresses|shirts|pants|shoes|accessories|sweaters|tshirts|sneakers|backpacks|blazers|raincoats|sunglasses|jeans)$/i, ''
        );
        return pNameClean === refWithoutCategory;
      });
    }

    // Priority 5: All significant words in reference appear in product name (order-sensitive)
    if (!product) {
      const refWords = refName.split(/\s+/).filter(w => w.length > 2);
      if (refWords.length > 1) {
        product = results.find(p => {
          if (!p.name) return false;
          const pNameLower = p.name.toLowerCase();
          return refWords.every(word => pNameLower.includes(word));
        });
      }
    }

    if (product) {
      refs.push(`"${product.name}" (product_id: ${product.productId})`);
    }
  }

  // Handle #N references
  const hashPattern = /#(\d+)/g;
  let hashMatch;
  while ((hashMatch = hashPattern.exec(messageText)) !== null) {
    const num = parseInt(hashMatch[1]);
    const product = results.find(p => p._displayNum === num);
    if (product) {
      refs.push(`#${num} = "${product.name}" (product_id: ${product.productId})`);
    }
  }

  if (refs.length > 0) {
    resolved += '\n\n[Product references: ' + refs.join(', ') + ']';
  }

  return resolved;
}

function buildProductRefSpan(product, displayText) {
  const num = product._displayNum || "";
  const imageUrl = product.imageUrl || product.image || "";
  const name = product.name || "";
  const price = product.price ? `$${product.price.toFixed(2)}` : "";
  return `<span class="product-ref" data-result-num="${num}" data-product-id="${product.productId || ''}" data-image="${escapeHtml(imageUrl)}" data-name="${escapeHtml(name)}" data-price="${escapeHtml(price)}" title="${escapeHtml(name)}${price ? ' — ' + price : ''}">${displayText}</span>`;
}

function getNameVariants(productName) {
  if (!productName) return [];
  const variants = [productName];
  // Without trailing category word: "Camel Scarf Accessories" → "Camel Scarf"
  const withoutCategory = productName.replace(
    /\s+(Jackets|Dresses|Shirts|Pants|Shoes|Accessories|Sweaters|Tshirts|T-shirts|Sneakers|Backpacks|Blazers|Raincoats|Sunglasses|Jeans)$/i, ""
  );
  if (withoutCategory !== productName && withoutCategory.length >= 8) variants.push(withoutCategory);
  // Singular of category: "Deep Teal Sheath Dresses" → "Deep Teal Sheath Dress"
  const singularCategory = productName.replace(
    /\s+(Dresses|Jackets|Shirts|Pants|Shoes|Accessories|Sweaters|Tshirts|Sneakers|Backpacks|Blazers|Raincoats|Sunglasses|Jeans)$/i,
    (m) => " " + m.trim().replace(/es$/i, "e").replace(/s$/i, "")
  );
  if (singularCategory !== productName && singularCategory.length >= 8 && !variants.includes(singularCategory)) {
    variants.push(singularCategory);
  }
  return variants;
}

function linkifyProductReferences(bubbleElement) {
  const results = window._lastSearchResults;
  if (!results || !results.length) return;
  let html = bubbleElement.innerHTML;
  let changed = false;

  // Step 1: Linkify #N references
  html = html.replace(/#(\d+)\b/g, (match, numStr) => {
    const num = parseInt(numStr);
    const product = results.find(p => p._displayNum === num);
    if (!product) return match;
    changed = true;
    return buildProductRefSpan(product, match);
  });

  // Step 2: Linkify product names in text (fuzzy: full name + variants)
  const sortedProducts = [...results]
    .filter(p => p.name && p.name.length >= 8)
    .sort((a, b) => b.name.length - a.name.length);

  for (const product of sortedProducts) {
    // Skip if already linkified
    if (html.includes(`data-product-id="${product.productId}"`)) continue;

    const variants = getNameVariants(product.name);
    for (const variant of variants) {
      const escaped = variant.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      // Match only in text between tags: >(text)< pattern
      const re = new RegExp(`(>[^<]*?)(${escaped})([^<]*?<)`, "gi");
      const before = html;
      html = html.replace(re, (full, pre, name, post) => {
        changed = true;
        return pre + buildProductRefSpan(product, name) + post;
      });
      if (html !== before) break; // matched this variant, skip shorter ones
    }
  }

  if (changed) {
    bubbleElement.innerHTML = html;
  }
}

function renderMarkdown(text) {
  if (typeof marked !== "undefined" && marked.parse) {
    marked.setOptions({ breaks: true, gfm: true });
    return marked.parse(text);
  }
  return escapeHtml(text).replace(/\n/g, "<br>");
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
  })[c]);
}

function flushPendingProduct(product) {
  if (!product) return;

  const siblings = product.siblings || [];
  const imgUrl = (product.images && product.images.length > 0)
    ? (typeof product.images[0] === "string" ? product.images[0] : product.images[0].url)
    : (product.imageUrl || "");

  // If no image and no siblings, nothing to render
  if (!imgUrl && !siblings.length) return;

  const block = document.createElement("div");
  block.className = "chat-product-detail-card";

  const imgHtml = imgUrl
    ? `<div class="chat-pdp__img-wrap">
        <img class="chat-pdp__img" src="${imgUrl}" alt="${escapeHtml(product.name)}"
             onerror="this.closest('.chat-pdp__img-wrap').remove()">
      </div>`
    : "";

  const colorChips = siblings.length
    ? `<div class="chat-pdp__colors">
        <span class="chat-pdp__colors-label">Also available in:</span>
        ${siblings.map(s => `<button class="chat-pdp__color-chip" data-sibling-query="${escapeHtml(s.productId)}" data-sibling-name="${escapeHtml(s.color)}" title="${escapeHtml(s.color)}" style="background:${colorToCss(s.color)}"></button>`).join("")}
      </div>`
    : "";

  block.innerHTML = `${imgHtml}${colorChips}`;

  appendToCurrentGroup(block);

  block.querySelectorAll("[data-sibling-query]").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      const pid = btn.dataset.siblingQuery;
      const colorName = btn.dataset.siblingName || "";
      const input = document.querySelector("[data-chat-form] input[name=text]");
      if (input) {
        input.value = `Tell me about the ${colorName} version (product_id: ${pid})`;
        input.disabled = false;
        input.closest("form")?.requestSubmit();
      }
    });
  });

  const msgEl = document.querySelector("[data-chat-messages]");
  if (msgEl) msgEl.scrollTop = msgEl.scrollHeight;
}

function colorToCss(name) {
  const COLOR_MAP = {
    "all black": "#1a1a1a", amber: "#FFBF00", beige: "#d6c4a6", black: "#1a1a1a",
    "bleached blue": "#a8c4d6", "blush pink": "#de98ab", brown: "#5a3920",
    burgundy: "#800020", "butter yellow": "#FFFACD", camel: "#c19a6b",
    charcoal: "#36454F", clear: "#e8e8e8", cognac: "#9A463D", coral: "#FF7F50",
    cream: "#f0e8d8", "dark brown": "#3B2214", "deep blue": "#0A1F44",
    "deep burgundy": "#5C0021", "deep teal": "#005F5F", "dusty blue": "#6B8EAE",
    "dusty rose": "#DCAE96", ecru: "#C2B280", espresso: "#3C1414",
    "forest green": "#228B22", graphite: "#4A4A4A", gray: "#7a7a7a",
    gunmetal: "#536267", indigo: "#3F51B5", ivory: "#FFFFF0", khaki: "#C3B091",
    lavender: "#B57EDC", "light gray": "#C0C0C0", "light wash blue": "#A4C8E1",
    maroon: "#800000", "matte black": "#2B2B2B", "mid blue": "#4682B4",
    "midnight blue": "#191970", mustard: "#FFDB58", navy: "#1B2A4E",
    oatmeal: "#D4C4A8", "off white": "#FAF0E6", olive: "#5b6240",
    oxblood: "#4A0000", "oxford blue": "#4A6FA5", "pale pink": "#FFD1DC",
    "pebble gray": "#9E9E8E", pewter: "#8E9196", plum: "#8E4585",
    "raw indigo": "#2E3A6E", rust: "#B7410E", sage: "#9CAF88",
    "sage green": "#8FBC8F", sand: "#C2B280", silver: "#C0C0C0",
    "sky blue": "#87CEEB", slate: "#708090", "slate blue": "#6A5ACD",
    "slate gray": "#708090", "steel blue": "#4682B4", stone: "#928E85",
    tan: "#c8a878", taupe: "#8B7D6B", teal: "#008080", terracotta: "#CC6644",
    tortoise: "#8B5A2B", "translucent black": "#333333", "vintage blue": "#5B7FA4",
    walnut: "#5C4033", white: "#fafafa", wine: "#722F37",
  };
  return COLOR_MAP[name.toLowerCase()] || "#888";
}

function flushPendingCart(cart) {
  if (!cart || !cart.items.length) return;
  const { items: cartItems, subtotal } = cart;
  const cartBlock = document.createElement("div");
  cartBlock.className = "chat-cart-block";
  cartBlock.innerHTML = `
    <div class="chat-cart-header">
      <span class="chat-cart-label">Your Cart</span>
      <span class="chat-cart-summary">${cartItems.length} item${cartItems.length > 1 ? "s" : ""} · $${subtotal.toFixed(2)}</span>
      <a href="checkout.cfm" class="btn btn--sm chat-cart-checkout">Checkout</a>
    </div>
  `;
  const grid = document.createElement("div");
  grid.className = "product-grid chat-products-grid chat-cart-items-grid";
  grid.innerHTML = cartItems.map(item => CartItemCard(item)).join("");
  cartBlock.appendChild(grid);
  appendToCurrentGroup(cartBlock);

  grid.querySelectorAll("[data-remove-from-cart]").forEach(btn => {
    btn.addEventListener("click", async (e) => {
      e.preventDefault();
      e.stopPropagation();
      const variantId = btn.dataset.removeFromCart;
      const itemName = btn.dataset.itemName || "item";
      btn.disabled = true;
      btn.textContent = "Removing...";
      try {
        await api.directRemove(variantId);
        const card = btn.closest(".product-card-wrap");
        if (card) card.remove();
        const remainingCards = grid.querySelectorAll(".product-card-wrap");
        const headerSummary = cartBlock.querySelector(".chat-cart-summary");
        if (remainingCards.length === 0) {
          cartBlock.remove();
        } else if (headerSummary) {
          headerSummary.textContent = `${remainingCards.length} item${remainingCards.length > 1 ? "s" : ""} · updated`;
        }
        appendMessage("assistant", `Removed ${itemName} from your cart.`);
        if (window.refreshCartBadge) window.refreshCartBadge(true);
      } catch (err) {
        btn.disabled = false;
        btn.textContent = "Remove";
      }
    });
  });
  const cartMsgEl = document.querySelector("[data-chat-messages]");
  if (cartMsgEl) cartMsgEl.scrollTop = cartMsgEl.scrollHeight;
}

function flushPendingOrders(orders) {
  if (!orders.length) return;
  const PAGE_SIZE = 5;
  const container = document.createElement("div");
  container.className = "chat-orders-container";
  appendToCurrentGroup(container);

  const firstBatch = orders.slice(0, PAGE_SIZE);
  firstBatch.forEach(order => renderSingleOrder(container, order));

  if (orders.length > PAGE_SIZE) {
    container._bufferedOrders = orders.slice(PAGE_SIZE);
    const moreBtn = document.createElement("button");
    moreBtn.className = "btn btn--sm chat-order-show-more";
    moreBtn.textContent = `Show more orders (${container._bufferedOrders.length} remaining)`;
    moreBtn.addEventListener("click", () => {
      const nextBatch = (container._bufferedOrders || []).splice(0, PAGE_SIZE);
      nextBatch.forEach(o => renderSingleOrder(container, o));
      if (!container._bufferedOrders.length) {
        moreBtn.remove();
      } else {
        moreBtn.textContent = `Show more orders (${container._bufferedOrders.length} remaining)`;
      }
      const el = document.querySelector("[data-chat-messages]");
      if (el) el.scrollTop = el.scrollHeight;
    });
    container.appendChild(moreBtn);
  }
  const orderMsgEl = document.querySelector("[data-chat-messages]");
  if (orderMsgEl) orderMsgEl.scrollTop = orderMsgEl.scrollHeight;
}

function renderSingleOrder(container, order) {
  const orderEl = document.createElement("div");
  orderEl.className = "chat-order-block";
  const statusClass = (order.status || "").toLowerCase().replace(/\s+/g, "-");
  orderEl.innerHTML = `
    <div class="chat-order-header">
      <span class="chat-order-date">${formatDate(order.placedAt)}</span>
      <span class="chat-order-status chat-order-status--${statusClass}">${order.status || "Unknown"}</span>
      <span class="chat-order-total">$${(order.total || 0).toFixed(2)}</span>
      <a href="order-detail.cfm?id=${order.orderId}" class="chat-order-link">View Details →</a>
    </div>
  `;
  const grid = document.createElement("div");
  grid.className = "product-grid chat-products-grid chat-order-items-grid";
  grid.innerHTML = (order.items || []).map(item => OrderItemCard(item)).join("");
  orderEl.appendChild(grid);
  container.appendChild(orderEl);

  grid.querySelectorAll("[data-write-review]").forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      e.stopPropagation();
      const productId = btn.dataset.writeReview;
      const productName = btn.dataset.productName || "this item";
      const card = btn.closest(".product-card-wrap");
      const imgSrc = card?.querySelector("img")?.src || "assets/img/placeholders/cubes-beige.svg";

      if (btn.disabled) return;
      btn.disabled = true;
      btn.textContent = "Writing...";

      function markDone() {
        btn.textContent = "✓ Reviewed";
        btn.classList.add("product-card__review-btn--done");
      }
      function markReset() {
        btn.disabled = false;
        btn.textContent = "Write Review";
      }

      const formBlock = createChatReviewBlock(productId, productName, imgSrc, markDone, markReset);
      container.parentElement.appendChild(formBlock);
      formBlock.querySelector("[data-review-body]")?.focus();
    });
  });
}

function OrderItemCard(item) {
  const imgSrc = item.imageUrl || "assets/img/placeholders/cubes-beige.svg";
  const sizeLine = [item.size, item.color].filter(Boolean).join(" · ");
  const href = item.slug ? `product.cfm?slug=${item.slug}` : (item.productId ? `product.cfm?slug=${item.productId}` : "#");
  const pid = item.productId || "";
  const hasReview = item.hasReview === true;

  const reviewBtn = !pid ? "" : hasReview
    ? `<div class="product-card__actions">
        <span class="btn btn--sm product-card__review-btn product-card__review-btn--done" disabled>&#10003; Reviewed</span>
      </div>`
    : `<div class="product-card__actions">
        <button class="btn btn--sm product-card__review-btn" data-write-review="${escapeHtml(pid)}" data-product-name="${escapeHtml(item.name)}">Write Review</button>
      </div>`;

  return `
    <div class="product-card-wrap order-item-card" data-order-item-pid="${escapeHtml(pid)}">
      <a class="product-card" href="${href}">
        <div class="product-card__media">
          <img src="${imgSrc}" alt="${escapeHtml(item.name)}" loading="lazy"
               onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
        </div>
        <div class="product-card__body">
          <h3 class="product-card__name">${escapeHtml(item.name)}</h3>
          <div class="product-card__row">
            <span class="product-card__price">$${(item.unitPrice || 0).toFixed(2)}</span>
            <span class="order-item__qty">×${item.quantity || 1}</span>
          </div>
          ${sizeLine ? `<div class="order-item__variant">${escapeHtml(sizeLine)}</div>` : ""}
        </div>
      </a>
      ${reviewBtn}
    </div>
  `;
}

function CartItemCard(item) {
  const imgSrc = item.imageUrl || "assets/img/placeholders/cubes-beige.svg";
  const sizeLine = [item.size, item.color].filter(Boolean).join(" · ");
  const href = item.slug ? `product.cfm?slug=${item.slug}` : (item.productId ? `product.cfm?slug=${item.productId}` : "#");
  return `
    <div class="product-card-wrap cart-item-card">
      <a class="product-card" href="${href}">
        <div class="product-card__media">
          <img src="${imgSrc}" alt="${escapeHtml(item.name)}" loading="lazy"
               onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
        </div>
        <div class="product-card__body">
          <h3 class="product-card__name">${escapeHtml(item.name)}</h3>
          <div class="product-card__row">
            <span class="product-card__price">$${(item.unitPrice || 0).toFixed(2)}</span>
            <span class="order-item__qty">×${item.quantity || 1}</span>
          </div>
          ${sizeLine ? `<div class="order-item__variant">${escapeHtml(sizeLine)}</div>` : ""}
        </div>
      </a>
      <div class="product-card__actions">
        <button class="btn btn--sm product-card__remove-btn" data-remove-from-cart="${item.variantId}" data-item-name="${escapeHtml(item.name)}">Remove</button>
      </div>
    </div>
  `;
}

function formatDate(isoStr) {
  if (!isoStr) return "";
  try {
    const d = new Date(isoStr);
    return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
  } catch (_) {
    return isoStr;
  }
}

function renderCompareTable(cmp) {
  const products = cmp.products || [];
  const rows = cmp.rows || [];
  const productIds = products.map(p => p.productId).join(",");

  const headerCells = products.map(p => `
    <th class="cmp-cell cmp-cell--header">
      <a href="product.cfm?slug=${p.slug || p.productId}" class="cmp-product-link">
        <img src="${p.imageUrl || 'assets/img/placeholders/cubes-beige.svg'}" alt="${escapeHtml(p.name)}" class="cmp-product-img"
             onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
        <span class="cmp-product-name">${escapeHtml(p.name)}</span>
      </a>
      <button class="btn btn--xs cmp-add-btn" data-compare-add="${p.productId}" data-product-name="${escapeHtml(p.name)}">Add to Cart</button>
    </th>
  `).join("");

  const bodyRows = rows.map(row => {
    const values = products.map(p => row.values[p.productId] ?? "—");
    const allSame = new Set(values).size === 1;

    let winnerPid = null;
    if (row.key === "price" && !allSame) {
      let minPrice = Infinity;
      products.forEach(p => {
        const raw = row.values[p.productId] || "";
        const num = parseFloat(String(raw).replace(/[^0-9.]/g, ""));
        if (!isNaN(num) && num < minPrice) { minPrice = num; winnerPid = p.productId; }
      });
    }

    const cells = products.map(p => {
      const val = row.values[p.productId] ?? "—";
      const isWinner = winnerPid === p.productId;
      const diffClass = allSame ? "" : "cmp-cell--diff";
      const winClass = isWinner ? "cmp-cell--winner" : "";
      return `<td class="cmp-cell ${diffClass} ${winClass}">${escapeHtml(String(val))}${isWinner ? " ✓" : ""}</td>`;
    }).join("");
    const dimLabel = row.key.charAt(0).toUpperCase() + row.key.slice(1);
    return `<tr><th class="cmp-cell cmp-dim-label">${escapeHtml(dimLabel)}</th>${cells}</tr>`;
  }).join("");

  return `
    <div class="cmp-table-scroll">
      <table class="chat-cmp-table">
        <thead><tr><th class="cmp-cell cmp-corner"></th>${headerCells}</tr></thead>
        <tbody>${bodyRows}</tbody>
      </table>
    </div>
    <div class="cmp-footer">
      <a href="compare.cfm?ids=${productIds}" class="cmp-view-full">View full comparison →</a>
    </div>
  `;
}

function createChatReviewBlock(productId, productName, imgSrc, onSuccess, onCancel) {
  const block = document.createElement("div");
  block.className = "chat-review-block";
  block.innerHTML = `
    <div class="chat-review-block__header">
      <img class="chat-review-block__img" src="${imgSrc}" alt=""
           onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
      <div class="chat-review-block__meta">
        <span class="chat-review-block__label">Write a review</span>
        <span class="chat-review-block__product">${escapeHtml(productName)}</span>
      </div>
      <button class="chat-review-block__close" data-review-cancel aria-label="Cancel">×</button>
    </div>
    <div class="chat-review-block__stars" data-star-picker>
      ${[1,2,3,4,5].map(n => `<button type="button" class="chat-review-block__star" data-star="${n}" aria-label="${n} star${n>1?'s':''}">☆</button>`).join("")}
      <span class="chat-review-block__star-label" data-star-label>Tap to rate</span>
    </div>
    <input type="text" class="chat-review-block__title" data-review-title placeholder="Headline (optional)" maxlength="120">
    <div class="chat-review-block__body-wrap">
      <textarea class="chat-review-block__body" data-review-body placeholder="What did you like or dislike? How did it fit? Share your experience..." maxlength="4000" rows="4"></textarea>
      <span class="chat-review-block__counter" data-review-counter>0 / 4000</span>
    </div>
    <div class="chat-review-block__actions">
      <button class="btn btn--sm chat-review-block__cancel" data-review-cancel-btn>Cancel</button>
      <button class="btn btn--sm chat-review-block__submit" data-review-submit>Submit Review</button>
    </div>
    <div class="chat-review-block__error" data-review-error></div>
  `;

  let selectedRating = 0;
  const starPicker = block.querySelector("[data-star-picker]");
  const starLabel = block.querySelector("[data-star-label]");
  const bodyInput = block.querySelector("[data-review-body]");
  const titleInput = block.querySelector("[data-review-title]");
  const counter = block.querySelector("[data-review-counter]");
  const submitBtn = block.querySelector("[data-review-submit]");
  const errorEl = block.querySelector("[data-review-error]");
  const cancelBtn = block.querySelector("[data-review-cancel]");
  const cancelBtn2 = block.querySelector("[data-review-cancel-btn]");

  const STAR_LABELS = ["", "Poor", "Fair", "Good", "Very Good", "Excellent"];

  function updateStars() {
    starPicker.querySelectorAll("[data-star]").forEach(btn => {
      btn.textContent = +btn.dataset.star <= selectedRating ? "★" : "☆";
      btn.classList.toggle("chat-review-block__star--active", +btn.dataset.star <= selectedRating);
    });
    starLabel.textContent = selectedRating ? STAR_LABELS[selectedRating] : "Tap to rate";
  }

  starPicker.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-star]");
    if (!btn) return;
    selectedRating = +btn.dataset.star;
    updateStars();
    errorEl.textContent = "";
  });

  bodyInput.addEventListener("input", () => {
    counter.textContent = `${bodyInput.value.length} / 4000`;
    errorEl.textContent = "";
  });

  function handleCancel() {
    block.remove();
    if (onCancel) onCancel();
  }
  cancelBtn.addEventListener("click", handleCancel);
  cancelBtn2.addEventListener("click", handleCancel);

  submitBtn.addEventListener("click", async () => {
    if (selectedRating === 0) { errorEl.textContent = "Please select a star rating."; return; }
    const bodyText = bodyInput.value.trim();
    if (bodyText.length < 10) { errorEl.textContent = `Review must be at least 10 characters (currently ${bodyText.length}).`; return; }

    submitBtn.disabled = true;
    submitBtn.textContent = "Submitting...";
    errorEl.textContent = "";

    try {
      await api.submitReview(productId, {
        rating: selectedRating,
        title: titleInput.value.trim() || undefined,
        body: bodyText,
        fromOrder: true
      });

      block.innerHTML = `
        <div class="chat-review-block__success">
          <img class="chat-review-block__img" src="${imgSrc}" alt=""
               onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
          <div class="chat-review-block__success-body">
            <span class="chat-review-block__success-icon">✓</span>
            <span class="chat-review-block__success-text">Review submitted for ${escapeHtml(productName)}</span>
            <span class="chat-review-block__success-stars">${"★".repeat(selectedRating)}${"☆".repeat(5 - selectedRating)}</span>
          </div>
        </div>
      `;
      if (onSuccess) onSuccess();
    } catch (err) {
      const msg = err.message || err.title || err.detail || "Could not submit review.";
      if (msg.toLowerCase().includes("already") || msg.toLowerCase().includes("duplicate")) {
        block.innerHTML = `
          <div class="chat-review-block__success chat-review-block__success--info">
            <img class="chat-review-block__img" src="${imgSrc}" alt=""
                 onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
            <div class="chat-review-block__success-body">
              <span class="chat-review-block__success-icon chat-review-block__success-icon--info">ℹ</span>
              <span class="chat-review-block__success-text">You've already reviewed ${escapeHtml(productName)}</span>
            </div>
          </div>
        `;
        if (onSuccess) onSuccess();
      } else {
        errorEl.textContent = msg;
        submitBtn.disabled = false;
        submitBtn.textContent = "Submit Review";
      }
    }
  });

  return block;
}
