// assets/js/pages/compare.js
import { api } from "../api.js";
import { appStore } from "../store.js";
import { getCompareList, clearCompareList } from "../components/product-card.js";

export async function initCompare() {
  const root = document.querySelector("[data-compare-root]");
  const urlIds = new URLSearchParams(location.search).get("ids");
  const ids = urlIds
    ? urlIds.split(",").filter(Boolean)
    : getCompareList();
  const table = root.querySelector("[data-compare-table]");

  if (ids.length < 2) {
    table.innerHTML = `<p class="empty">Add at least two products to compare. Use the "+ Compare" button on product cards.</p>`;
    return;
  }

  // Add clear button above table
  const clearBtn = document.createElement("button");
  clearBtn.className = "btn-secondary";
  clearBtn.textContent = "Clear Comparison";
  clearBtn.addEventListener("click", () => {
    clearCompareList();
    table.innerHTML = `<p class="empty">Comparison cleared. <a href="products.cfm">Browse products</a> to add items.</p>`;
    clearBtn.remove();
  });
  table.parentNode.insertBefore(clearBtn, table);

  appStore.set({ viewing: "compare", productIds: ids });
  const urlDims = new URLSearchParams(window.location.search).get("dims");
  const dims = urlDims ? urlDims.split(",") : ["price", "fabric", "care", "sizes", "colors", "fit"];

  try {
    const result = await api.compare(ids, dims);
    table.innerHTML = renderCompare(result);
  } catch (err) {
    table.innerHTML = `<p class="error">${err.message}</p>`;
  }
}

function renderCompare(c) {
  const head = c.products.map((p) => `
    <th>
      <img src="${p.imageUrl}" alt="" class="cmp-img">
      <div class="cmp-name">${p.name}</div>
      <button class="btn-secondary cmp-add" data-pid="${p.productId}">Add</button>
    </th>
  `).join("");

  const body = c.rows.map((row) => {
    const values = Object.values(row.values);
    const allSame = new Set(values).size === 1;
    return `
      <tr>
        <th class="cmp-dim">${row.key}</th>
        ${c.products.map((p) => `
          <td class="${allSame ? "" : "cmp-diff"}">${row.values[p.productId] ?? "—"}</td>
        `).join("")}
      </tr>
    `;
  }).join("");

  return `
    <table class="cmp-table">
      <thead><tr><th></th>${head}</tr></thead>
      <tbody>${body}</tbody>
    </table>
  `;
}
