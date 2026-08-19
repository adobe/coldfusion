// assets/js/pages/category.js
//
// Category landing page. Hero metadata comes from GET /categories?slug=…,
// but the catalog grid uses the same paginated GET /products endpoint as
// the main PLP so users can scroll through every product in the category,
// not just the 4 curated "featured" ones.
import { api } from "../api.js";
import { ProductCard } from "../components/product-card.js";

const PAGE_SIZE = 24;

export async function initCategory() {
  const root = document.querySelector("[data-category-root]");
  if (!root) return;
  const slug = root.dataset.categorySlug;
  if (!slug) {
    root.innerHTML = `<p class="error">No category slug supplied.</p>`;
    return;
  }

  const grid = root.querySelector("[data-category-grid]");
  const status = root.querySelector("[data-category-status]");
  const sentinel = root.querySelector("[data-category-sentinel]");
  const countEl = root.querySelector("[data-category-count]");
  const headingEl = root.querySelector("[data-category-heading]");

  // Hero / metadata first — failure here is fatal because we can't even tell
  // the user what they're looking at.
  let category;
  try {
    category = await api.getCategory(slug);
  } catch (err) {
    root.innerHTML = `<p class="error">Could not load category: ${err.message}</p>`;
    return;
  }
  document.title = `StyleMart — ${category.name}`;
  const heroImg = root.querySelector("[data-hero-img]");
  if (heroImg) {
    heroImg.src = category.heroImageUrl;
    heroImg.alt = category.name;
  }
  root.querySelector("[data-category-name]").textContent = category.name;
  root.querySelector("[data-category-description]").textContent = category.description;
  if (headingEl) headingEl.textContent = category.name;

  let state = { page: 0, total: 0, loaded: 0, loading: false, done: false };

  function setStatus(html) {
    if (!html) { status.hidden = true; status.innerHTML = ""; return; }
    status.hidden = false;
    status.innerHTML = html;
  }

  function updateCount() {
    if (!countEl) return;
    if (state.total === 0) countEl.textContent = "";
    else if (state.loaded < state.total) countEl.textContent = `Showing ${state.loaded} of ${state.total}`;
    else countEl.textContent = `${state.total} item${state.total === 1 ? "" : "s"}`;
  }

  async function loadNextPage() {
    if (state.loading || state.done) return;
    state.loading = true;
    if (state.page > 0) {
      setStatus(`<div class="plp__loading">
        <span class="search-bar__loading-dot"></span>
        <span class="search-bar__loading-dot"></span>
        <span class="search-bar__loading-dot"></span>
        <span class="plp__loading-text">Loading more…</span>
      </div>`);
    }
    const nextPage = state.page + 1;
    let resp;
    try {
      resp = await api.listProducts({ category: slug, page: nextPage, pageSize: PAGE_SIZE });
    } catch (err) {
      setStatus(`<div class="plp__error">Couldn't load products: ${err.message}</div>`);
      state.loading = false;
      return;
    }
    const items = resp.items || [];
    state.page = nextPage;
    state.total = resp.total ?? items.length;
    state.loaded += items.length;

    if (nextPage === 1 && state.total === 0) {
      grid.innerHTML = `<p class="empty">No products found in this category.</p>`;
      setStatus("");
      state.done = true;
      state.loading = false;
      updateCount();
      return;
    }

    grid.insertAdjacentHTML("beforeend", items.map(ProductCard).join(""));
    updateCount();
    if (state.loaded >= state.total) {
      state.done = true;
      setStatus(state.total > PAGE_SIZE ? `<div class="plp__end">You've reached the end of ${category.name}.</div>` : "");
    } else {
      setStatus("");
    }
    state.loading = false;
  }

  if (sentinel && "IntersectionObserver" in window) {
    const io = new IntersectionObserver((entries) => {
      for (const e of entries) if (e.isIntersecting) loadNextPage();
    }, { rootMargin: "600px 0px" });
    io.observe(sentinel);
  }

  await loadNextPage();
}
