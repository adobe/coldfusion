// assets/js/pages/plp.js
//
// Product Listing Page with infinite scroll.
//
// Page is paginated server-side via GET /products?page&pageSize=24. We render
// page 1, then watch a sentinel below the grid with IntersectionObserver and
// auto-load each subsequent page as the user scrolls. A "generation" counter
// invalidates in-flight requests when filters/sort change so we never append
// stale results.
import { api } from "../api.js";
import { ProductCard } from "../components/product-card.js";
import { Facets } from "../components/facets.js";
import { appStore } from "../store.js";

const PAGE_SIZE = 24;

export async function initPLP() {
  const grid = document.querySelector("[data-plp-grid]");
  const count = document.querySelector("[data-result-count]");
  const facetsContainer = document.querySelector("[data-facets]");
  const status = document.querySelector("[data-plp-status]");
  const sentinel = document.querySelector("[data-plp-sentinel]");

  // Mutable state for the current filter scope.
  let state = {
    gen: 0,            // bumped on every resetAndLoad; stale loads are dropped
    page: 0,
    total: 0,
    loaded: 0,
    query: {},
    loading: false,
    done: false,
  };

  function setStatus(html) {
    if (!html) { status.hidden = true; status.innerHTML = ""; return; }
    status.hidden = false;
    status.innerHTML = html;
  }

  function loadingMarkup() {
    return `<div class="plp__loading">
      <span class="search-bar__loading-dot"></span>
      <span class="search-bar__loading-dot"></span>
      <span class="search-bar__loading-dot"></span>
      <span class="plp__loading-text">Loading more…</span>
    </div>`;
  }

  function endMarkup() {
    return `<div class="plp__end">You've reached the end of the catalog.</div>`;
  }

  function updateCount() {
    if (!count) return;
    if (state.total === 0) {
      count.textContent = "0 items";
    } else if (state.loaded < state.total) {
      count.textContent = `Showing ${state.loaded} of ${state.total} items`;
    } else {
      count.textContent = `${state.total} item${state.total === 1 ? "" : "s"}`;
    }
  }

  function readQueryFromUrl() {
    const params = new URLSearchParams(location.search);
    const q = {};
    for (const [k, v] of params.entries()) if (v) q[k] = v;
    return q;
  }

  function updateBreadcrumb(query) {
    const crumb = document.querySelector("[data-breadcrumb]");
    if (!crumb) return;
    if (query.category) {
      const label = query.category.charAt(0).toUpperCase() +
                    query.category.slice(1).replace(/-/g, " ");
      crumb.innerHTML = `
        <a href="index.cfm">Home</a> <span class="breadcrumb__sep">›</span>
        <a href="products.cfm">Shop</a> <span class="breadcrumb__sep">›</span>
        <span>${label}</span>
      `;
    } else {
      crumb.innerHTML = `
        <a href="index.cfm">Home</a> <span class="breadcrumb__sep">›</span>
        <span>Shop</span>
      `;
    }
  }

  // Sort happens client-side over the entire loaded set so far. When sort
  // changes we reset and refetch (which keeps results monotonic with how the
  // server orders them).
  function sortItems(items, sortKey) {
    if (!sortKey) return items;
    const sorted = [...items];
    switch (sortKey) {
      case "price-asc":   return sorted.sort((a, b) => a.price - b.price);
      case "price-desc":  return sorted.sort((a, b) => b.price - a.price);
      case "newest":      return sorted;
      case "rating":      return sorted.sort((a, b) => (b.averageRating || 0) - (a.averageRating || 0));
      case "popularity":  return sorted.sort((a, b) => (b.reviewCount || 0) - (a.reviewCount || 0));
      default:            return sorted;
    }
  }

  async function resetAndLoad() {
    const myGen = ++state.gen;
    const query = readQueryFromUrl();
    state = { gen: myGen, page: 0, total: 0, loaded: 0, query, loading: false, done: false };
    appStore.set({ filter: query });
    updateBreadcrumb(query);
    grid.innerHTML = "";
    setStatus(loadingMarkup());
    await loadNextPage(myGen);
  }

  async function loadNextPage(myGen) {
    if (myGen !== state.gen || state.loading || state.done) return;
    state.loading = true;
    if (state.page > 0) setStatus(loadingMarkup());
    const nextPage = state.page + 1;

    let resp;
    try {
      resp = await api.listProducts({
        ...state.query,
        page: nextPage,
        pageSize: PAGE_SIZE,
      });
    } catch (err) {
      if (myGen !== state.gen) return;
      setStatus(`<div class="plp__error">Couldn't load products: ${err.message} <button class="btn-link" data-plp-retry>Retry</button></div>`);
      status.querySelector("[data-plp-retry]")?.addEventListener("click", () => {
        state.loading = false;
        loadNextPage(myGen);
      }, { once: true });
      state.loading = false;
      return;
    }
    if (myGen !== state.gen) return; // filters changed mid-flight

    const { items = [], total = 0, facets } = resp;
    state.page = nextPage;
    state.total = total;
    state.loaded += items.length;

    const sorted = sortItems(items, state.query.sort);
    if (sorted.length) {
      grid.insertAdjacentHTML("beforeend", sorted.map(ProductCard).join(""));
    }

    // Facets only need to render once per filter change (page 1).
    if (nextPage === 1 && facetsContainer && facets) {
      facetsContainer.innerHTML = Facets(facets, state.query);
      bindFacetListeners(facetsContainer);
      renderAppliedFilters(state.query);
    }

    updateCount();

    // Empty result + first page: show the no-results message.
    if (nextPage === 1 && state.total === 0) {
      grid.innerHTML = `<p class="empty">No products match these filters.</p>`;
      setStatus("");
      state.done = true;
      state.loading = false;
      return;
    }

    if (state.loaded >= state.total) {
      state.done = true;
      setStatus(state.total > PAGE_SIZE ? endMarkup() : "");
    } else {
      setStatus("");
    }
    state.loading = false;
  }

  // IntersectionObserver triggers loadNextPage when the sentinel scrolls into
  // view. rootMargin pre-loads ~600px before the user actually reaches the
  // sentinel for a smoother feel.
  if (sentinel && "IntersectionObserver" in window) {
    const io = new IntersectionObserver((entries) => {
      for (const e of entries) {
        if (e.isIntersecting) loadNextPage(state.gen);
      }
    }, { rootMargin: "600px 0px" });
    io.observe(sentinel);
  }

  function bindFacetListeners(container) {
    container.querySelector("[data-clear-filters]")?.addEventListener("click", () => {
      history.replaceState({}, "", location.pathname);
      resetAndLoad();
    });

    container.querySelectorAll('input[name="category"]').forEach(input => {
      input.addEventListener("change", () => {
        const checked = [...container.querySelectorAll('input[name="category"]:checked')].map(el => el.value);
        updateParam("category", checked.length === 1 ? checked[0] : checked.join(',') || null);
      });
    });

    container.querySelectorAll('input[name="colors"]').forEach(input => {
      input.addEventListener("change", () => {
        const checked = [...container.querySelectorAll('input[name="colors"]:checked')].map(el => el.value);
        updateParam("colors", checked.join(',') || null);
      });
    });

    container.querySelectorAll('.facet__chip[name="size"]').forEach(btn => {
      btn.addEventListener("click", () => {
        const isActive = btn.classList.contains("facet__chip--active");
        updateParam("size", isActive ? null : btn.dataset.value);
      });
    });

    container.querySelectorAll('input[name="fit"]').forEach(input => {
      input.addEventListener("change", () => {
        const checked = [...container.querySelectorAll('input[name="fit"]:checked')].map(el => el.value);
        updateParam("fit", checked.join(',') || null);
      });
    });

    container.querySelectorAll('input[name="price"]').forEach(input => {
      input.addEventListener("change", () => {
        const [min, max] = input.value.split(',');
        const url = new URL(location.href);
        url.searchParams.set("priceMin", min);
        url.searchParams.set("priceMax", max);
        history.replaceState({}, "", url);
        resetAndLoad();
      });
    });
  }

  function updateParam(key, value) {
    const url = new URL(location.href);
    if (value) url.searchParams.set(key, value);
    else url.searchParams.delete(key);
    history.replaceState({}, "", url);
    resetAndLoad();
  }

  // Sort dropdown
  const sortSelect = document.querySelector("[data-sort]");
  if (sortSelect) {
    const initialSort = new URLSearchParams(location.search).get("sort");
    if (initialSort) sortSelect.value = initialSort;
    sortSelect.addEventListener("change", () => {
      updateParam("sort", sortSelect.value || null);
    });
  }

  function renderAppliedFilters(query) {
    const container = document.querySelector("[data-applied-filters]");
    if (!container) return;
    const chips = [];
    if (query.category) {
      query.category.split(',').forEach(v => {
        chips.push({ label: v.replace(/-/g, ' '), key: 'category', value: v });
      });
    }
    if (query.colors) {
      query.colors.split(',').forEach(v => {
        chips.push({ label: v, key: 'colors', value: v });
      });
    }
    if (query.size) {
      chips.push({ label: `Size: ${query.size}`, key: 'size', value: query.size });
    }
    if (query.fit) {
      query.fit.split(',').forEach(v => {
        chips.push({ label: v, key: 'fit', value: v });
      });
    }
    if (query.priceMin) {
      const label = +query.priceMin >= 500 ? `$${query.priceMin}+` : `$${query.priceMin}–$${query.priceMax}`;
      chips.push({ label, key: 'price', value: '' });
    }

    if (!chips.length) {
      container.innerHTML = '';
      return;
    }

    container.innerHTML = chips.map(c => `
      <button class="applied-chip" data-remove-filter="${c.key}" data-remove-value="${c.value}">
        ${c.label} <span class="applied-chip__x">×</span>
      </button>
    `).join('') + `<button class="applied-chip applied-chip--clear" data-clear-all>Clear all</button>`;

    container.querySelectorAll("[data-remove-filter]").forEach(btn => {
      btn.addEventListener("click", () => {
        const key = btn.dataset.removeFilter;
        if (key === 'price') {
          const url = new URL(location.href);
          url.searchParams.delete('priceMin');
          url.searchParams.delete('priceMax');
          history.replaceState({}, "", url);
          resetAndLoad();
        } else {
          const val = btn.dataset.removeValue;
          const url = new URL(location.href);
          const current = url.searchParams.get(key) || '';
          const remaining = current.split(',').filter(v => v !== val).join(',');
          if (remaining) url.searchParams.set(key, remaining);
          else url.searchParams.delete(key);
          history.replaceState({}, "", url);
          resetAndLoad();
        }
      });
    });

    container.querySelector("[data-clear-all]")?.addEventListener("click", () => {
      history.replaceState({}, "", location.pathname);
      resetAndLoad();
    });
  }

  await resetAndLoad();
}
