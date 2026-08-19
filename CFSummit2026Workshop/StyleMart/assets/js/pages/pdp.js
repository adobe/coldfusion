// assets/js/pages/pdp.js
import { api } from "../api.js";
import { appStore } from "../store.js";
import { refreshCartBadge } from "../main.js";
import { formatDate } from "../utils/format-date.js";

export async function initPDP() {
  const root = document.querySelector("[data-pdp-root]");
  if (!root) return;
  const params = new URLSearchParams(location.search);
  const slug = params.get("slug");
  const id = root.dataset.productId || params.get("id");
  if (!slug && !id) {
    root.innerHTML = `<p class="error">No product specified.</p>`;
    return;
  }

  let product;
  try { product = slug ? await api.getProductBySlug(slug) : await api.getProduct(id); }
  catch (err) {
    root.innerHTML = `<p class="error">Could not load product: ${err.message}</p>`;
    return;
  }

  document.title = `StyleMart — ${product.name}`;
  appStore.set({ viewing: "pdp", productIds: [product.productId] });

  // Breadcrumb
  const crumb = document.querySelector("[data-breadcrumb]");
  if (crumb) {
    const catLabel = product.category ? product.category.charAt(0).toUpperCase() + product.category.slice(1).replace(/-/g, ' ') : 'Shop';
    crumb.innerHTML = `
      <a href="index.cfm">Home</a> <span class="breadcrumb__sep">›</span>
      <a href="products.cfm">Shop</a> <span class="breadcrumb__sep">›</span>
      <a href="category.cfm?slug=${product.category}">${catLabel}</a> <span class="breadcrumb__sep">›</span>
      <span>${product.name}</span>
    `;
  }

  const $ = (sel) => root.querySelector(sel);
  $("[data-name]").textContent = product.name;
  $("[data-price]").textContent = `$${product.price.toFixed(2)}`;
  $("[data-rating]").textContent = product.averageRating
    ? `★ ${product.averageRating.toFixed(1)} (${product.reviewCount})` : "";
  $("[data-description]").textContent = product.description || "";
  $("[data-care]").textContent = product.careInstructions || "";

  const attrs = $("[data-attrs]");
  attrs.innerHTML = Object.entries(product.attributes || {})
    .map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`).join("");

  const mainImg = $("[data-main-img]");
  const mainImgWrap = mainImg.parentElement;

  // Build gallery from images array (objects or strings)
  const gallery = buildGallery(product);
  mainImg.src = gallery[0]?.url || product.imageUrl || '';
  mainImg.alt = gallery[0]?.altText || product.name;

  $("[data-thumbs]").innerHTML = gallery.map((img, i) => `
    <button class="pdp__thumb ${i === 0 ? 'pdp__thumb--active' : ''}" data-thumb-idx="${i}">
      <img src="${img.url}" alt="${img.altText || ''}">
    </button>
  `).join("");

  $("[data-thumbs]").addEventListener("click", (e) => {
    const btn = e.target.closest("[data-thumb-idx]");
    if (!btn) return;
    const idx = +btn.dataset.thumbIdx;
    mainImg.src = gallery[idx].url;
    mainImg.alt = gallery[idx].altText || product.name;
    $("[data-thumbs]").querySelectorAll(".pdp__thumb").forEach(t => t.classList.remove("pdp__thumb--active"));
    btn.classList.add("pdp__thumb--active");
  });

  // Hover zoom on main image
  mainImgWrap.addEventListener("mousemove", (e) => {
    const rect = mainImgWrap.getBoundingClientRect();
    const x = ((e.clientX - rect.left) / rect.width) * 100;
    const y = ((e.clientY - rect.top) / rect.height) * 100;
    mainImg.style.transformOrigin = `${x}% ${y}%`;
    mainImg.style.transform = "scale(1.8)";
  });
  mainImgWrap.addEventListener("mouseleave", () => {
    mainImg.style.transform = "scale(1)";
  });

  let selectedColor = product.colors?.[0];
  let selectedSize  = null;
  const variants = product.variants || [];

  function getVariant(size, color) {
    return variants.find(v => v.size === size && v.color === color)
      || variants.find(v => v.size === size);
  }

  function renderChips() {
    // Each product is single-color (per the §12 invariant). The "color picker"
    // navigates between sibling products (same category/subcategory family).
    // Current product's color is shown as the selected chip; sibling colors
    // are rendered as <a> links to those PDPs.
    $("[data-color-label]").textContent = selectedColor || "";
    const siblings = product.siblings || [];
    const currentChip = `
      <span class="chip chip--color chip--on" aria-current="true">
        <span class="chip__swatch" style="background:${colorToCss(selectedColor)}"></span>
        ${selectedColor || ""}
      </span>
    `;
    const siblingChips = siblings.map((s) => `
      <a href="?slug=${encodeURIComponent(s.slug)}" class="chip chip--color chip--link" title="${s.color}">
        <span class="chip__swatch" style="background:${colorToCss(s.color)}"></span>
        ${s.color}
      </a>
    `).join("");
    $("[data-colors]").innerHTML = currentChip + siblingChips;

    // Size chips with stock indication
    const SIZE_ORDER = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '28', '30', '32', '34', '36', '38', '7', '8', '9', '10', '11', '12'];
    const sortedSizes = [...(product.availableSizes || [])].sort((a, b) => {
      const ia = SIZE_ORDER.indexOf(a), ib = SIZE_ORDER.indexOf(b);
      if (ia !== -1 && ib !== -1) return ia - ib;
      if (ia !== -1) return -1;
      if (ib !== -1) return 1;
      return a.localeCompare(b);
    });
    $("[data-size-label]").textContent = selectedSize || "";
    $("[data-sizes]").innerHTML = sortedSizes.map((s) => {
      const variant = getVariant(s, selectedColor);
      const inStock = variant ? variant.inStock !== false : true;
      const qty = variant?.stockQty ?? null;
      const soldOut = !inStock || qty === 0;
      const lowStock = !soldOut && qty !== null && qty <= 3;
      return `
        <button type="button"
          class="chip ${s === selectedSize ? 'chip--on' : ''} ${soldOut ? 'chip--sold-out' : ''}"
          data-size="${s}"
          ${soldOut ? 'disabled title="Sold out"' : ''}>
          ${s}
        </button>
      `;
    }).join("");

    // Stock hint
    const hint = $("[data-stock-hint]");
    if (selectedSize) {
      const variant = getVariant(selectedSize, selectedColor);
      const qty = variant?.stockQty ?? null;
      if (variant && (variant.inStock === false || qty === 0)) {
        hint.textContent = "Sold out in this size";
        hint.className = "pdp__stock-hint pdp__stock-hint--oos";
      } else if (qty !== null && qty <= 3) {
        hint.textContent = `Only ${qty} left — order soon`;
        hint.className = "pdp__stock-hint pdp__stock-hint--low";
      } else {
        hint.textContent = "In stock";
        hint.className = "pdp__stock-hint pdp__stock-hint--ok";
      }
    } else {
      hint.textContent = "";
    }

    // CTA button state
    const btn = $("[data-add-to-cart]");
    if (!selectedSize) {
      btn.disabled = true;
      btn.textContent = "Select a size";
    } else {
      const variant = getVariant(selectedSize, selectedColor);
      const soldOut = variant && (variant.inStock === false || variant.stockQty === 0);
      btn.disabled = soldOut;
      btn.textContent = soldOut ? "Sold out" : "Add to Cart";
    }
  }
  renderChips();

  $("[data-colors]").addEventListener("click", async (e) => {
    const c = e.target.closest("[data-color]")?.dataset.color;
    if (!c || c === selectedColor) return;
    selectedColor = c;
    renderChips();

    // Switch gallery to images matching selected color
    const colorImages = (product.images || []).filter(img => img.colorRef === c);
    if (colorImages.length) {
      mainImg.src = colorImages[0].url;
      mainImg.alt = colorImages[0].altText || product.name;
      $("[data-thumbs]").innerHTML = colorImages.map((img, i) => `
        <button class="pdp__thumb ${i === 0 ? 'pdp__thumb--active' : ''}" data-thumb-idx="${i}">
          <img src="${img.url}" alt="${img.altText || ''}">
        </button>
      `).join("");
    } else {
      // No images for this color in current product — find sibling product with this color
      try {
        const { items } = await api.listProducts({ category: product.category, pageSize: 50 });
        const sibling = items.find(p =>
          p.productId !== product.productId &&
          p.images?.some(img => img.colorRef === c)
        );
        if (sibling) {
          window.location.href = `product.cfm?slug=${sibling.slug || sibling.productId}`;
        }
      } catch (_) {}
    }
  });
  $("[data-sizes]").addEventListener("click", (e) => {
    const s = e.target.closest("[data-size]")?.dataset.size;
    if (s && !e.target.closest("[disabled]")) { selectedSize = s; renderChips(); }
  });

  // Quantity stepper
  const qtyInput = $("[data-qty-input]");
  $("[data-qty-minus]").addEventListener("click", () => {
    const val = Math.max(1, parseInt(qtyInput.value) - 1);
    qtyInput.value = val;
  });
  $("[data-qty-plus]").addEventListener("click", () => {
    const val = Math.min(10, parseInt(qtyInput.value) + 1);
    qtyInput.value = val;
  });
  qtyInput.addEventListener("change", () => {
    qtyInput.value = Math.max(1, Math.min(10, parseInt(qtyInput.value) || 1));
  });

  $("[data-add-to-cart]").addEventListener("click", async () => {
    if (!selectedSize) return;
    const variant = getVariant(selectedSize, selectedColor);
    const variantId = variant?.variantId || `var_${product.productId.slice(4)}_${selectedSize}_${selectedColor}`;
    const quantity = parseInt(qtyInput.value) || 1;
    const btn = $("[data-add-to-cart]");
    btn.disabled = true;
    btn.textContent = "Adding...";
    try {
      let cartId = appStore.get().cartId;
      if (!cartId || cartId === "crt_demo_jordan") {
        const myCart = await api.getMyCart();
        cartId = myCart.cartId;
        appStore.set({ cartId });
      }
      const cart = await api.addItem(cartId, { variantId, quantity });
      const count = cart.items.reduce((sum, i) => sum + i.quantity, 0);
      appStore.set({ cartCount: count });
      refreshCartBadge(true);
      btn.textContent = "Added!";
      setTimeout(() => { btn.textContent = "Add to Cart"; btn.disabled = false; }, 1500);
    } catch (err) {
      btn.textContent = "Add to Cart";
      btn.disabled = false;
      alert(`Could not add to cart: ${err.message}`);
    }
  });

  $("[data-compare-add]").addEventListener("click", () => {
    const compareList = JSON.parse(sessionStorage.getItem("compareList") || "[]");
    if (!compareList.includes(product.productId)) compareList.push(product.productId);
    sessionStorage.setItem("compareList", JSON.stringify(compareList));
    location.href = `compare.cfm?ids=${compareList.join(",")}`;
  });

  // Tab switching
  root.querySelectorAll("[data-tab]").forEach(tab => {
    tab.addEventListener("click", () => {
      root.querySelectorAll("[data-tab]").forEach(t => { t.classList.remove("pdp__tab--active"); t.setAttribute("aria-selected", "false"); });
      root.querySelectorAll("[data-panel]").forEach(p => p.classList.remove("pdp__tab-panel--active"));
      tab.classList.add("pdp__tab--active");
      tab.setAttribute("aria-selected", "true");
      root.querySelector(`[data-panel="${tab.dataset.tab}"]`).classList.add("pdp__tab-panel--active");
    });
  });

  // Load and render reviews
  try {
    const reviews = await api.getReviews(product.productId);
    renderReviews(root, reviews);
  } catch (_) { /* reviews are non-critical */ }

  renderReviewForm(root, product.productId);
}

function renderReviews(root, reviews) {
  const summaryEl = root.querySelector("[data-reviews-summary]");
  const listEl = root.querySelector("[data-reviews-list]");
  if (!summaryEl || !listEl) return;

  const { summary } = reviews;
  const maxCount = Math.max(...Object.values(summary.histogram));

  summaryEl.innerHTML = `
    <div class="reviews-summary">
      <div class="reviews-summary__avg">
        <span class="reviews-summary__score">${summary.averageRating.toFixed(1)}</span>
        <span class="reviews-summary__stars">${renderStars(summary.averageRating)}</span>
        <span class="reviews-summary__count">${summary.totalReviews} reviews</span>
      </div>
      <div class="reviews-summary__histogram">
        ${[5, 4, 3, 2, 1].map((star) => {
          const count = summary.histogram[star] || 0;
          const pct = maxCount > 0 ? (count / maxCount) * 100 : 0;
          return `<div class="histogram-row">
            <span class="histogram-row__label">${star}★</span>
            <div class="histogram-row__bar"><div class="histogram-row__fill" style="width:${pct}%"></div></div>
            <span class="histogram-row__count">${count}</span>
          </div>`;
        }).join("")}
      </div>
    </div>
  `;

  listEl.innerHTML = reviews.items.map((r) => `
    <article class="review-card">
      <div class="review-card__header">
        <span class="review-card__stars">${renderStars(r.rating)}</span>
        <strong class="review-card__title">${r.title}</strong>
        ${r.verified ? '<span class="review-card__badge" title="This reviewer purchased this item from StyleMart">Verified Purchase</span>' : ''}
      </div>
      <p class="review-card__body">${r.body}</p>
      <footer class="review-card__footer">
        <span class="review-card__author">${r.displayName}</span>
        <time class="review-card__date">${formatDate(r.createdAt)}</time>
      </footer>
    </article>
  `).join("");
}

function renderReviewForm(root, productId) {
  const slot = root.querySelector("[data-review-form-slot]");
  if (!slot) return;

  slot.innerHTML = `
    <details class="review-form" data-review-form>
      <summary class="review-form__toggle">Write a Review</summary>
      <form class="review-form__inner" data-review-submit>
        <div class="review-form__stars" data-star-picker>
          ${[1,2,3,4,5].map(n => `<button type="button" class="review-form__star" data-star="${n}" aria-label="${n} star${n>1?'s':''}">☆</button>`).join("")}
          <span class="review-form__star-label" data-star-label>Select a rating</span>
        </div>
        <input type="text" class="review-form__title input" name="title" placeholder="Headline (optional)" maxlength="120">
        <textarea class="review-form__body input" name="body" placeholder="Share your experience (min 10 characters)..." maxlength="4000" rows="4"></textarea>
        <div class="review-form__footer">
          <span class="review-form__counter" data-char-count>0 / 4000</span>
          <button type="submit" class="btn-primary btn--sm" data-review-btn>Submit Review</button>
        </div>
        <div class="review-form__error" data-review-error></div>
      </form>
    </details>
  `;

  let selectedRating = 0;
  const form = slot.querySelector("[data-review-submit]");
  const starPicker = slot.querySelector("[data-star-picker]");
  const starLabel = slot.querySelector("[data-star-label]");
  const bodyInput = form.querySelector("[name=body]");
  const charCount = slot.querySelector("[data-char-count]");
  const submitBtn = slot.querySelector("[data-review-btn]");
  const errorEl = slot.querySelector("[data-review-error]");

  function updateStars() {
    starPicker.querySelectorAll("[data-star]").forEach(btn => {
      btn.textContent = +btn.dataset.star <= selectedRating ? "★" : "☆";
    });
    starLabel.textContent = selectedRating ? `${selectedRating} / 5` : "Select a rating";
  }

  function validate() {
    if (selectedRating === 0) return "Please select a star rating.";
    const bodyLen = bodyInput.value.trim().length;
    if (bodyLen === 0) return "Review text is required.";
    if (bodyLen < 10) return `Review must be at least 10 characters (currently ${bodyLen}).`;
    if (bodyInput.value.length > 4000) return "Review must not exceed 4000 characters.";
    return "";
  }

  starPicker.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-star]");
    if (!btn) return;
    selectedRating = +btn.dataset.star;
    updateStars();
    errorEl.textContent = "";
  });

  bodyInput.addEventListener("input", () => {
    charCount.textContent = `${bodyInput.value.length} / 4000`;
    errorEl.textContent = "";
  });

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    const err = validate();
    if (err) {
      errorEl.textContent = err;
      return;
    }
    errorEl.textContent = "";
    submitBtn.disabled = true;
    submitBtn.textContent = "Submitting...";

    try {
      const review = await api.submitReview(productId, {
        rating: selectedRating,
        title: form.querySelector("[name=title]").value.trim() || undefined,
        body: bodyInput.value.trim(),
      });

      slot.querySelector("[data-review-form]").remove();
      slot.innerHTML = `<p class="review-form__success">Thank you for your review!</p>`;

      const listEl = root.querySelector("[data-reviews-list]");
      const card = `
        <article class="review-card review-card--new">
          <div class="review-card__header">
            <span class="review-card__stars">${renderStars(review.rating)}</span>
            <strong class="review-card__title">${review.title || ""}</strong>
          </div>
          <p class="review-card__body">${review.body}</p>
          <footer class="review-card__footer">
            <span class="review-card__author">${review.displayName}</span>
            <time class="review-card__date">Just now</time>
          </footer>
        </article>
      `;
      listEl.insertAdjacentHTML("afterbegin", card);
    } catch (err) {
      errorEl.textContent = err.message || "Could not submit review.";
      submitBtn.disabled = false;
      submitBtn.textContent = "Submit Review";
    }
  });
}

function renderStars(rating) {
  const full = Math.floor(rating);
  const half = rating - full >= 0.5 ? 1 : 0;
  const empty = 5 - full - half;
  return "★".repeat(full) + (half ? "½" : "") + "☆".repeat(empty);
}

const COLOR_CSS = {
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
function colorToCss(name) { return COLOR_CSS[name?.toLowerCase()] || "#888"; }

function buildGallery(product) {
  const images = product.images || [];
  if (images.length && typeof images[0] === 'object') {
    // New format — use as-is, generate extra angles if only 1
    if (images.length >= 3) return images;
    const base = images[0];
    return [
      base,
      { ...base, imageId: base.imageId + '_b', altText: `${product.name} back view` },
      { ...base, imageId: base.imageId + '_c', altText: `${product.name} detail` },
      { ...base, imageId: base.imageId + '_d', altText: `${product.name} on model` },
    ];
  }
  // Legacy string array or single imageUrl
  const urls = images.length ? images : [product.imageUrl].filter(Boolean);
  return urls.map((url, i) => ({ url, altText: `${product.name} view ${i + 1}`, imageId: `img_${i}` }));
}
