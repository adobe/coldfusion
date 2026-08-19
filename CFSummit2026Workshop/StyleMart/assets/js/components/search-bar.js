// assets/js/components/search-bar.js
//
// Industry-standard search combobox for the site header.
//
// Features:
//   * Live typeahead with 200ms debounce against GET /search?q=…
//   * Sections in panel: Recent searches (when input empty), Products, Categories
//   * Keyboard navigation: ↓/↑ to move, Enter to open, Esc to close
//   * Click outside / blur to close
//   * Match highlighting in titles
//   * Recent searches persisted in localStorage (last 5)
//   * Mobile: a toggle button collapses the bar to an icon; tap expands a
//     header-anchored overlay
//   * Form action="search.cfm" still works without JS (graceful degradation)

import { api } from "../api.js";

const RECENT_KEY = "stylemart.recentSearches";
const RECENT_MAX = 5;
const DEBOUNCE_MS = 200;
const SUGGEST_PAGE_SIZE = 6;

const ICON_PRODUCT = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>`;
const ICON_CATEGORY = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>`;
const ICON_RECENT = `<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>`;
const ICON_ARROW = `<svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>`;

function readRecent() {
  try {
    const raw = localStorage.getItem(RECENT_KEY);
    if (!raw) return [];
    const list = JSON.parse(raw);
    return Array.isArray(list) ? list.slice(0, RECENT_MAX) : [];
  } catch {
    return [];
  }
}

function writeRecent(query) {
  const q = String(query || "").trim();
  if (!q) return;
  try {
    const existing = readRecent().filter((r) => r.toLowerCase() !== q.toLowerCase());
    const next = [q, ...existing].slice(0, RECENT_MAX);
    localStorage.setItem(RECENT_KEY, JSON.stringify(next));
  } catch {
    // localStorage unavailable; silent no-op
  }
}

function clearRecent() {
  try { localStorage.removeItem(RECENT_KEY); } catch { /* no-op */ }
}

function escapeHtml(s) {
  return String(s ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function highlight(text, query) {
  if (!query) return escapeHtml(text);
  const safeText = escapeHtml(text);
  const safeQuery = escapeHtml(query).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return safeText.replace(new RegExp(`(${safeQuery})`, "ig"), "<mark>$1</mark>");
}

function debounce(fn, ms) {
  let t;
  return (...args) => {
    clearTimeout(t);
    t = setTimeout(() => fn(...args), ms);
  };
}

let categoriesCache = null;
async function loadCategories() {
  if (categoriesCache) return categoriesCache;
  try {
    const list = await api.listCategories();
    categoriesCache = Array.isArray(list) ? list : [];
  } catch {
    categoriesCache = [];
  }
  return categoriesCache;
}

function matchCategories(cats, query) {
  const q = query.toLowerCase();
  return cats
    .filter((c) => c.name?.toLowerCase().includes(q) || c.slug?.toLowerCase().includes(q))
    .slice(0, 4);
}

function priceLabel(p) {
  const v = p.price ?? (p.basePrice ?? null);
  if (v === null || v === undefined) return "";
  const num = typeof v === "number" ? v : parseFloat(v);
  if (Number.isNaN(num)) return "";
  return `$${num.toFixed(2)}`;
}

export function initSearchBar(root = document) {
  const bar = root.querySelector("[data-search-bar]");
  if (!bar) return;
  const input = bar.querySelector("[data-search-input]");
  const panel = bar.querySelector("[data-search-panel]");
  const clearBtn = bar.querySelector("[data-search-clear]");
  const form = bar.querySelector("form");
  const mobileToggle = root.querySelector("[data-search-mobile-toggle]");
  if (!input || !panel) return;

  let activeIndex = -1;
  let lastQuery = "";

  function setExpanded(open) {
    input.setAttribute("aria-expanded", open ? "true" : "false");
    panel.hidden = !open;
    if (!open) {
      activeIndex = -1;
      input.removeAttribute("aria-activedescendant");
    }
  }

  function options() {
    return Array.from(panel.querySelectorAll("[data-search-option]"));
  }

  function setActiveOption(idx) {
    const items = options();
    if (!items.length) {
      activeIndex = -1;
      input.removeAttribute("aria-activedescendant");
      return;
    }
    activeIndex = ((idx % items.length) + items.length) % items.length;
    items.forEach((el, i) => {
      const on = i === activeIndex;
      el.setAttribute("aria-selected", on ? "true" : "false");
      if (on) {
        el.scrollIntoView({ block: "nearest" });
        if (el.id) input.setAttribute("aria-activedescendant", el.id);
      }
    });
  }

  function renderEmpty() {
    panel.innerHTML = `<div class="search-bar__empty">No matches. Press Enter to view all results.</div>`;
    setExpanded(true);
  }

  function renderLoading() {
    panel.innerHTML = `<div class="search-bar__loading"><span class="search-bar__loading-dot"></span><span class="search-bar__loading-dot"></span><span class="search-bar__loading-dot"></span></div>`;
    setExpanded(true);
  }

  function renderRecents() {
    const recents = readRecent();
    if (!recents.length) {
      setExpanded(false);
      return;
    }
    panel.innerHTML = `
      <div class="search-bar__section">
        <div class="search-bar__section-title">
          Recent searches
          <button type="button" class="search-bar__clear-recent" data-clear-recent>Clear</button>
        </div>
        ${recents.map((q, i) => `
          <a href="search.cfm?q=${encodeURIComponent(q)}" id="sbo-r-${i}" class="search-bar__option" role="option" data-search-option data-recent-query="${escapeHtml(q)}">
            <span class="search-bar__option-icon" aria-hidden="true">${ICON_RECENT}</span>
            <span class="search-bar__option-body">
              <span class="search-bar__option-title">${escapeHtml(q)}</span>
            </span>
          </a>
        `).join("")}
      </div>
    `;
    setExpanded(true);
  }

  async function renderResults(query) {
    if (lastQuery !== query) return; // stale
    let data;
    try {
      data = await api.search({ q: query, pageSize: SUGGEST_PAGE_SIZE });
    } catch {
      panel.innerHTML = `<div class="search-bar__empty">Search unavailable. Press Enter to retry.</div>`;
      setExpanded(true);
      return;
    }
    if (lastQuery !== query) return; // user kept typing

    const products = (data.items || []).slice(0, SUGGEST_PAGE_SIZE);
    const cats = matchCategories(await loadCategories(), query);

    if (!products.length && !cats.length) {
      renderEmpty();
      return;
    }

    const productsHtml = products.length ? `
      <div class="search-bar__section">
        <h3 class="search-bar__section-title">Products</h3>
        ${products.map((p, i) => `
          <a href="product.cfm?slug=${encodeURIComponent(p.slug)}" id="sbo-p-${i}" class="search-bar__option" role="option" data-search-option>
            <img class="search-bar__option-thumb" src="${escapeHtml(p.imageUrl || "")}" alt="" loading="lazy">
            <span class="search-bar__option-body">
              <span class="search-bar__option-title">${highlight(p.name, query)}</span>
              <span class="search-bar__option-sub">${escapeHtml((p.category || "").replace(/-/g, " "))}</span>
            </span>
            <span class="search-bar__option-price">${priceLabel(p)}</span>
          </a>
        `).join("")}
      </div>
    ` : "";

    const catsHtml = cats.length ? `
      <div class="search-bar__section">
        <h3 class="search-bar__section-title">Categories</h3>
        ${cats.map((c, i) => `
          <a href="category.cfm?slug=${encodeURIComponent(c.slug)}" id="sbo-c-${i}" class="search-bar__option" role="option" data-search-option>
            <span class="search-bar__option-icon" aria-hidden="true">${ICON_CATEGORY}</span>
            <span class="search-bar__option-body">
              <span class="search-bar__option-title">${highlight(c.name || c.slug, query)}</span>
            </span>
          </a>
        `).join("")}
      </div>
    ` : "";

    const totalCount = data.total ?? products.length;
    const footerHtml = `
      <div class="search-bar__footer">
        <a href="search.cfm?q=${encodeURIComponent(query)}" class="search-bar__view-all">
          <span>View all ${totalCount} result${totalCount === 1 ? "" : "s"} for <strong>"${escapeHtml(query)}"</strong></span>
          <span aria-hidden="true">${ICON_ARROW}</span>
        </a>
      </div>
    `;

    panel.innerHTML = productsHtml + catsHtml + footerHtml;
    setExpanded(true);
    setActiveOption(0); // pre-highlight first row so Enter has a target
  }

  const debouncedFetch = debounce((q) => renderResults(q), DEBOUNCE_MS);

  function handleInput() {
    const value = input.value.trim();
    clearBtn.hidden = value.length === 0;
    lastQuery = value;
    if (!value) {
      renderRecents();
      return;
    }
    if (value.length < 2) {
      renderLoading(); // show feedback for single chars; results land at 2+
      return;
    }
    renderLoading();
    debouncedFetch(value);
  }

  function navigate(href) {
    if (!href) return;
    writeRecent(input.value);
    window.location.href = href;
  }

  function activeHref() {
    const items = options();
    if (activeIndex < 0 || !items[activeIndex]) return null;
    return items[activeIndex].getAttribute("href");
  }

  // --- Wire up events ---
  input.addEventListener("focus", handleInput);
  input.addEventListener("input", handleInput);

  input.addEventListener("keydown", (e) => {
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (panel.hidden) handleInput();
      const items = options();
      if (items.length) setActiveOption(activeIndex + 1);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      const items = options();
      if (items.length) setActiveOption(activeIndex - 1);
    } else if (e.key === "Escape") {
      if (!panel.hidden) {
        e.preventDefault();
        setExpanded(false);
      }
    } else if (e.key === "Enter") {
      // If a suggestion is active, follow it; otherwise let the form submit.
      const href = activeHref();
      if (href) {
        e.preventDefault();
        navigate(href);
      }
    }
  });

  form.addEventListener("submit", () => {
    writeRecent(input.value);
    // form action="search.cfm" handles navigation
  });

  clearBtn.addEventListener("click", () => {
    input.value = "";
    clearBtn.hidden = true;
    input.focus();
    renderRecents();
  });

  panel.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-clear-recent]");
    if (btn) {
      e.preventDefault();
      clearRecent();
      renderRecents();
      return;
    }
    const opt = e.target.closest("[data-search-option]");
    if (!opt) return;
    // For a recent-search row, populate the input rather than directly navigating.
    const recentQ = opt.getAttribute("data-recent-query");
    if (recentQ) {
      e.preventDefault();
      input.value = recentQ;
      handleInput();
      return;
    }
    writeRecent(input.value);
    // Anchor href will navigate normally
  });

  panel.addEventListener("mousemove", (e) => {
    const opt = e.target.closest("[data-search-option]");
    if (!opt) return;
    const items = options();
    const idx = items.indexOf(opt);
    if (idx >= 0 && idx !== activeIndex) setActiveOption(idx);
  });

  document.addEventListener("click", (e) => {
    if (!bar.contains(e.target) && !mobileToggle?.contains(e.target)) {
      setExpanded(false);
      bar.classList.remove("search-bar--mobile-open");
    }
  });

  // Mobile toggle (icon → expand bar over header)
  if (mobileToggle) {
    mobileToggle.addEventListener("click", (e) => {
      e.stopPropagation();
      const wasOpen = bar.classList.contains("search-bar--mobile-open");
      bar.classList.toggle("search-bar--mobile-open", !wasOpen);
      if (!wasOpen) {
        setTimeout(() => input.focus(), 0);
      } else {
        setExpanded(false);
      }
    });
  }

  // Pre-fill from URL on the search results page so the bar reflects state
  const urlQ = new URLSearchParams(window.location.search).get("q");
  if (urlQ) {
    input.value = urlQ;
    clearBtn.hidden = false;
  }
}
