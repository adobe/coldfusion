// assets/js/pages/home.js
import { api } from "../api.js";
import { ProductCard } from "../components/product-card.js";

const OCCASIONS = [
  { slug: "travel", name: "Travel" },
  { slug: "smart-casual", name: "Work" },
  { slug: "weekend", name: "Weekend" },
  { slug: "formal", name: "Formal" },
  { slug: "outdoor", name: "Active" },
];

export async function initHome() {
  const grid = document.querySelector("[data-featured-grid]");
  const occasionsStrip = document.querySelector("[data-occasions]");
  const categoriesStrip = document.querySelector("[data-categories]");
  if (!grid) return;

  try {
    const [{ items: products }, categories] = await Promise.all([
      api.listProducts({ pageSize: 8 }),
      api.listCategories(),
    ]);
    grid.innerHTML = products.map(ProductCard).join("");

    if (occasionsStrip) {
      occasionsStrip.innerHTML = OCCASIONS.map((o) => `
        <a class="cat-tile" href="products.cfm?occasion=${o.slug}">
          <span class="cat-tile__name">${o.name}</span>
        </a>
      `).join("");
    }

    if (categoriesStrip) {
      categoriesStrip.innerHTML = categories.slice(0, 6).map((c) => `
        <a class="cat-tile" href="category.cfm?slug=${c.slug}">
          <span class="cat-tile__name">${c.name}</span>
        </a>
      `).join("");
    }
  } catch (err) {
    grid.innerHTML = `<p class="error">Could not load products: ${err.message}</p>`;
  }
}
