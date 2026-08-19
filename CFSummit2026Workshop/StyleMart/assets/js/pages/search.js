import { api } from "../api.js";
import { ProductCard } from "../components/product-card.js";

export async function initSearch() {
  const root = document.querySelector("[data-search-root]");
  if (!root) return;

  const heading = root.querySelector("[data-search-heading]");
  const results = root.querySelector("[data-search-results]");
  const q = new URLSearchParams(window.location.search).get("q") || "";

  if (!q) {
    heading.textContent = "Search";
    results.innerHTML = '<p>Enter a search term to find products.</p>';
    return;
  }

  heading.textContent = `Results for "${q}"`;

  try {
    const { items, total } = await api.search({ q });
    if (!items.length) {
      results.innerHTML = `<p>No products found for "${q}". <a href="products.cfm">Browse all products</a></p>`;
      return;
    }
    results.innerHTML = `<p class="search-count">${total} result${total !== 1 ? 's' : ''}</p>` + items.map(ProductCard).join("");
  } catch (err) {
    results.innerHTML = `<p class="error">${err.message}</p>`;
  }
}
