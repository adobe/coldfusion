// assets/js/components/product-card.js

/**
 * Extract the primary image URL from a product object.
 * Supports both the new rich image structure (array of objects)
 * and the legacy format (imageUrl string or array of strings).
 */
function getImageUrl(product) {
  if (product.images && Array.isArray(product.images) && product.images.length > 0) {
    const first = product.images[0];
    return typeof first === 'string' ? first : first.url;
  }
  return product.imageUrl || 'assets/img/placeholders/default.svg';
}

// Fallback when the seed PNG hasn't been Firefly-generated yet.
// Maps category + first color to one of the on-disk SVG placeholders;
// falls back to the inline data-URI default if nothing matches.
const PLACEHOLDER_MAP = {
  tshirts:      ['tshirt-white.svg'],
  shirts:       ['shirts-white.svg', 'shirts-brown.svg'],
  jeans:        ['jeans-navy.svg', 'jeans-darkwash.svg', 'jeans-charcoal.svg', 'jeans-beige.svg', 'jeans-olive.svg'],
  pants:        ['jeans-charcoal.svg', 'jeans-beige.svg'],
  jackets:      ['jacket-navy.svg', 'jackets-charcoal.svg', 'jackets-olive.svg'],
  dresses:      ['dresses-navy.svg', 'dresses-beige.svg'],
  sweaters:     ['jackets-charcoal.svg'],
  raincoats:    ['raincoats-olive.svg', 'raincoats-beige.svg'],
  sneakers:     ['sneakers-white.svg', 'sneakers-black.svg', 'sneakers-gray.svg', 'sneakers-navy.svg'],
  'formal-shoes':['formal-shoes-black.svg', 'formal-shoes-tan.svg'],
  backpacks:    ['backpacks-charcoal.svg', 'backpacks-olive.svg'],
  sunglasses:   ['sunglasses-brown.svg', 'sunglasses-tan.svg'],
  accessories:  ['accessories-charcoal.svg', 'accessories-brown.svg'],
};
function getFallbackImage(product) {
  const cat = product.category;
  const list = PLACEHOLDER_MAP[cat];
  if (!list || !list.length) return 'assets/img/placeholders/cubes-beige.svg';
  // Prefer the placeholder whose color hint matches the first product color
  const firstColor = (product.colors || [])[0];
  if (firstColor) {
    const match = list.find((f) => f.toLowerCase().includes(String(firstColor).toLowerCase()));
    if (match) return `assets/img/placeholders/${match}`;
  }
  return `assets/img/placeholders/${list[0]}`;
}

/**
 * Extract alt text from the product's image structure,
 * falling back to the product name.
 */
function getImageAlt(product) {
  if (product.images && product.images.length > 0 && product.images[0].altText) {
    return product.images[0].altText;
  }
  return product.name;
}

export function ProductCard(product, options = {}) {
  const chatMode = options.chatMode || false;
  const resultNum = options.resultNum || 0;
  const allColors = product.colors || [];
  const visibleColors = allColors.slice(0, 4);
  const overflowCount = allColors.length - visibleColors.length;
  const colorDots = visibleColors
    .map((c) => `<span class="card-color" title="${c}" data-color-swatch="${c}" style="background:${colorToCss(c)}"></span>`)
    .join("")
    + (overflowCount > 0 ? `<span class="card-color card-color--more">+${overflowCount}</span>` : '');

  const rating = product.averageRating || 0;
  const reviewCount = product.reviewCount || 0;
  const ratingStr = rating > 0
    ? `<span class="product-card__rating">${"★".repeat(Math.round(rating))}${"☆".repeat(5 - Math.round(rating))} ${rating.toFixed(1)} <span class="card-meta">(${reviewCount})</span></span>`
    : "";

  const sizes = product.availableSizes || [];
  const sizeDropdown = chatMode && sizes.length
    ? `<select class="product-card__size-select" data-size-select="${product.productId}">
         <option value="">Select size</option>
         ${sizes.map(s => `<option value="${s}">${s}</option>`).join("")}
       </select>`
    : "";

  const addBtn = chatMode
    ? `<button class="btn btn--sm product-card__add-btn" data-add-to-cart="${product.productId}" disabled>Add to Cart</button>`
    : "";

  const compareCheck = chatMode
    ? `<button class="product-card__compare-toggle" data-compare-check="${product.productId}">+ Compare</button>`
    : "";

  const inCompare = getCompareList().includes(product.productId);

  const askBadge = chatMode
    ? `<button class="card-ask-badge" data-product-id="${product.productId}" data-product-name="${product.name}" title="Ask about this product">Ask ↗</button>`
    : '';

  const numBadge = chatMode && resultNum
    ? `<span class="product-card__num">#${resultNum}</span>`
    : "";

  return `
    <div class="product-card-wrap" data-pid="${product.productId}" data-result-num="${resultNum}">
      <a class="product-card" href="product.cfm?slug=${product.slug || product.productId}">
        <div class="product-card__media">
          ${numBadge}${askBadge}
          <img src="${getImageUrl(product)}" alt="${getImageAlt(product)}" loading="lazy" data-fallback="${getFallbackImage(product)}" onerror="if(this.dataset.fallback &amp;&amp; this.src.indexOf(this.dataset.fallback) === -1){this.src=this.dataset.fallback;}">
        </div>
        <div class="product-card__body">
          <h3 class="product-card__name">${product.name}</h3>
          <div class="product-card__row">
            <span class="product-card__price">$${product.price.toFixed(2)}</span>
            ${ratingStr}
          </div>
          <div class="product-card__colors">${colorDots}</div>
        </div>
      </a>
      ${chatMode ? `<div class="product-card__actions">${sizeDropdown}${addBtn}${compareCheck}</div>
      <div class="card-ask-actions">
        <button class="card-ask-btn" data-action="details" data-product-id="${product.productId}" data-product-name="${product.name}" title="Get full details">📋 Details</button>
        <button class="card-ask-btn" data-action="reviews" data-product-id="${product.productId}" data-product-name="${product.name}" title="See reviews">★ Reviews</button>
      </div>` : ''}
      ${!chatMode ? `<button class="compare-btn ${inCompare ? 'compare-btn--active' : ''}" data-compare-toggle="${product.productId}" title="${inCompare ? 'Remove from compare' : 'Add to compare'}">
        ${inCompare ? '✓ Compare' : '+ Compare'}
      </button>` : ''}
    </div>
  `;
}

// --- Compare list management ---
export function getCompareList() {
  try { return JSON.parse(sessionStorage.getItem("compareList") || "[]"); }
  catch { return []; }
}

export function toggleCompare(productId) {
  let list = getCompareList();
  if (list.includes(productId)) {
    list = list.filter(id => id !== productId);
  } else {
    if (list.length >= 6) return false;
    list.push(productId);
  }
  sessionStorage.setItem("compareList", JSON.stringify(list));
  updateCompareBar();
  return true;
}

export function clearCompareList() {
  sessionStorage.removeItem("compareList");
  updateCompareBar();
  document.querySelectorAll("[data-compare-toggle]").forEach(btn => {
    btn.classList.remove("compare-btn--active");
    btn.textContent = "+ Compare";
    btn.title = "Add to compare";
  });
}

export function updateCompareBar() {
  let bar = document.querySelector("[data-compare-bar]");
  const list = getCompareList();

  // Update header badge
  const headerBadge = document.querySelector("[data-compare-header]");
  if (headerBadge) {
    if (list.length > 0) {
      headerBadge.style.display = "";
      headerBadge.querySelector("[data-compare-count]").textContent = list.length;
    } else {
      headerBadge.style.display = "none";
    }
  }

  if (!list.length || document.body.dataset.page === "compare") {
    if (bar) bar.remove();
    return;
  }

  if (!bar) {
    bar = document.createElement("div");
    bar.className = "compare-bar";
    bar.setAttribute("data-compare-bar", "");
    document.body.appendChild(bar);
  }

  bar.innerHTML = `
    <span class="compare-bar__count">${list.length} product${list.length > 1 ? 's' : ''} selected</span>
    <a class="btn-primary compare-bar__go" href="compare.cfm?ids=${list.join(',')}">Compare Now</a>
    <button class="btn-secondary compare-bar__clear" data-compare-clear>Clear</button>
  `;

  bar.querySelector("[data-compare-clear]").addEventListener("click", clearCompareList);
}

export function initCompareListeners() {
  document.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-compare-toggle]");
    if (!btn) return;
    e.preventDefault();
    e.stopPropagation();
    const pid = btn.dataset.compareToggle;
    const added = toggleCompare(pid);
    if (added === false) return;
    const inList = getCompareList().includes(pid);
    btn.classList.toggle("compare-btn--active", inList);
    btn.textContent = inList ? "✓ Compare" : "+ Compare";
    btn.title = inList ? "Remove from compare" : "Add to compare";
  });

  updateCompareBar();
}

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
function colorToCss(name) { return COLOR_MAP[name.toLowerCase()] || "#888"; }
