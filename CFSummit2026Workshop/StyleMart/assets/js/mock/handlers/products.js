// assets/js/mock/handlers/products.js
import productsData from "../fixtures/products.json" with { type: "json" };
import categoriesData from "../fixtures/categories.json" with { type: "json" };
import reviewsData from "../fixtures/reviews.json" with { type: "json" };

let products = [...productsData];

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

export function __resetProducts() { products = [...productsData]; }

// Category list now driven by seed (categories.json). Only leaf categories
// (those with a parentSlug) are surfaced to the legacy /categories endpoint;
// the parent rollups (menswear, womenswear) are skipped to match the existing
// flat-list contract that header/sidebar consume.
const CATEGORIES = categoriesData.categories
  .filter((c) => c.parentSlug)
  .map((c) => ({ slug: c.slug, name: c.displayName }));

// Reviews are now real seed data (600 rows, 2-4/product, 5 demo users).
// Index by productId once at load for O(1) lookup in C6 and C2's histogram.
const REVIEWS_BY_PRODUCT = (() => {
  const idx = {};
  for (const r of reviewsData.items) {
    (idx[r.productId] ||= []).push(r);
  }
  return idx;
})();

// Sibling-product index for C2 PDP color-picker. Each product is single-color
// (per the §12 invariant); color browsing on the PDP cross-navigates to the
// matching sibling product within the same (category, subcategory) family.
// Built once at module load.
const SIBLINGS_BY_PRODUCT = (() => {
  const families = {};
  for (const p of productsData) {
    const key = `${p.category}::${p.subcategory}`;
    (families[key] ||= []).push(p);
  }
  const idx = {};
  for (const p of productsData) {
    const key = `${p.category}::${p.subcategory}`;
    idx[p.productId] = (families[key] || [])
      .filter((s) => s.productId !== p.productId)
      .map((s) => ({
        productId: s.productId,
        slug: s.slug,
        color: (s.colors && s.colors[0]) || "",
        swatch: COLOR_MAP[(s.colors && s.colors[0]) || ""] || "#888",
        imageUrl: s.imageUrl,
      }));
  }
  return idx;
})();

function withSiblings(p) {
  return { ...p, siblings: SIBLINGS_BY_PRODUCT[p.productId] || [] };
}

export const productHandlers = {
  "GET /products": (params = {}) => {
    // Apply each filter independently so facets can exclude their own filter
    function applyFilters(items, exclude) {
      if (exclude !== 'category' && params.category) {
        const cats = params.category.split(',');
        items = items.filter((p) => cats.includes(p.category));
      }
      if (exclude !== 'occasion' && params.occasion) items = items.filter((p) => (p.occasionTags || []).includes(params.occasion));
      if (exclude !== 'price' && params.priceMin) items = items.filter((p) => p.price >= +params.priceMin);
      if (exclude !== 'price' && params.priceMax) items = items.filter((p) => p.price < +params.priceMax);
      if (exclude !== 'q' && params.q) {
        const q = String(params.q).toLowerCase();
        items = items.filter((p) => p.name.toLowerCase().includes(q));
      }
      if (exclude !== 'size' && params.size) items = items.filter((p) => (p.availableSizes || []).includes(params.size));
      if (exclude !== 'colors' && params.colors) {
        const selectedColors = params.colors.split(',');
        items = items.filter((p) => (p.colors || []).some(c => selectedColors.includes(c)));
      }
      if (exclude !== 'fit' && params.fit) {
        const fits = params.fit.split(',');
        items = items.filter((p) => fits.includes(p.attributes?.fit));
      }
      return items;
    }

    // Items for display: all filters applied
    let items = applyFilters([...products], null);

    // Facets: each facet computed with its own filter excluded
    const facets = buildFacetsExcluding(params, products);

    const page = +params.page || 1;
    const pageSize = +params.pageSize || 24;
    const start = (page - 1) * pageSize;
    return {
      items: items.slice(start, start + pageSize),
      page, pageSize, total: items.length, facets,
    };

    function buildFacetsExcluding(params, allProducts) {
      const catItems = applyFilters([...allProducts], 'category');
      const sizeItems = applyFilters([...allProducts], 'size');
      const colorItems = applyFilters([...allProducts], 'colors');
      const priceItems = applyFilters([...allProducts], 'price');
      const fitItems = applyFilters([...allProducts], 'fit');

      const COLOR_SWATCH = COLOR_MAP;
      const sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

      // Collect ALL possible values from unfiltered catalog
      const allCategories = new Set();
      const allColors = new Set();
      const allSizes = new Set();
      const allFits = new Set();
      allProducts.forEach(p => {
        allCategories.add(p.category);
        (p.colors || []).forEach(c => allColors.add(c));
        (p.availableSizes || []).forEach(s => allSizes.add(s));
        const f = p.attributes?.fit;
        if (f) allFits.add(f);
      });

      // Count from filtered sets (excluding own filter)
      const categoryMap = {};
      allCategories.forEach(c => { categoryMap[c] = 0; });
      catItems.forEach(p => { categoryMap[p.category]++; });

      const colorMap = {};
      allColors.forEach(c => { colorMap[c] = 0; });
      colorItems.forEach(p => { (p.colors || []).forEach(c => { colorMap[c]++; }); });

      const sizeMap = {};
      allSizes.forEach(s => { sizeMap[s] = 0; });
      sizeItems.forEach(p => { (p.availableSizes || []).forEach(s => { sizeMap[s]++; }); });

      // Group sizes by sizing system
      const APPAREL = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
      const WAIST = ['28', '30', '32', '34', '36', '38'];
      const SHOE = ['7', '8', '9', '10', '11', '12'];
      const sizeGroups = [];
      const apparelSizes = Object.entries(sizeMap).filter(([v]) => APPAREL.includes(v));
      const waistSizes = Object.entries(sizeMap).filter(([v]) => WAIST.includes(v));
      const shoeSizes = Object.entries(sizeMap).filter(([v]) => SHOE.includes(v));
      const otherSizes = Object.entries(sizeMap).filter(([v]) => !APPAREL.includes(v) && !WAIST.includes(v) && !SHOE.includes(v));
      if (apparelSizes.length) sizeGroups.push({ label: "Apparel", sizes: apparelSizes.map(([value, count]) => ({ value, count })).sort((a, b) => APPAREL.indexOf(a.value) - APPAREL.indexOf(b.value)) });
      if (waistSizes.length) sizeGroups.push({ label: "Waist", sizes: waistSizes.map(([value, count]) => ({ value, count })).sort((a, b) => +a.value - +b.value) });
      if (shoeSizes.length) sizeGroups.push({ label: "Shoe US", sizes: shoeSizes.map(([value, count]) => ({ value, count })).sort((a, b) => +a.value - +b.value) });
      if (otherSizes.length) sizeGroups.push({ label: "One-size", sizes: otherSizes.map(([value, count]) => ({ value, count })) });

      const fitMap = {};
      allFits.forEach(f => { fitMap[f] = 0; });
      fitItems.forEach(p => { const f = p.attributes?.fit; if (f) fitMap[f]++; });

      return {
        category: Object.entries(categoryMap)
          .map(([value, count]) => ({ value, label: value.charAt(0).toUpperCase() + value.slice(1).replace(/-/g, ' '), count }))
          .sort((a, b) => a.value.localeCompare(b.value)),
        color: Object.entries(colorMap)
          .map(([value, count]) => ({ value, swatch: COLOR_SWATCH[value] || "#888", count }))
          .sort((a, b) => a.value.localeCompare(b.value)),
        size: sizeGroups,
        priceBuckets: [
          { min: 0, max: 100, count: priceItems.filter(p => p.price >= 0 && p.price < 100).length },
          { min: 100, max: 200, count: priceItems.filter(p => p.price >= 100 && p.price < 200).length },
          { min: 200, max: 500, count: priceItems.filter(p => p.price >= 200 && p.price < 500).length },
        ],
        fit: Object.entries(fitMap)
          .map(([value, count]) => ({ value, label: value.charAt(0).toUpperCase() + value.slice(1), count }))
          .sort((a, b) => a.value.localeCompare(b.value)),
      };
    }
  },

  "GET /products/:id": (_, path) => {
    const id = path.split("/").pop();
    const p = products.find((x) => x.productId === id);
    if (!p) throw problem(404, "Product not found", id);
    return withSiblings(p);
  },

  "GET /products/by-slug/:id": (_, path) => {
    const slug = path.split("/").pop();
    const p = products.find((x) => x.slug === slug);
    if (!p) throw problem(404, "Product not found by slug", slug);
    return withSiblings(p);
  },

  "POST /products/compare": ({ productIds = [], dimensions = ["price", "fabric", "care", "sizes", "colors", "fit"] }) => {
    const picked = productIds.map((id) => products.find((p) => p.productId === id)).filter(Boolean);
    const rows = dimensions.map((key) => ({
      key,
      values: Object.fromEntries(picked.map((p) => [p.productId, dimensionValue(p, key)])),
    }));
    return {
      dimensions,
      rows,
      products: picked.map((p) => ({ productId: p.productId, name: p.name, imageUrl: p.imageUrl })),
    };
  },

  "GET /products/:id/related": (params, path) => {
    const id = path.split("/")[2];
    const base = products.find((p) => p.productId === id);
    if (!base) return { items: [] };
    return {
      items: products.filter((p) => p.category !== base.category).slice(0, 3),
      intent: params?.intent || "complete-the-look",
    };
  },

  "GET /categories": (params) => {
    if (params?.slug) {
      const slug = params.slug;
      const meta = categoriesData.categories.find((c) => c.slug === slug);
      const matched = products.filter((p) => p.category === slug);
      const name = meta?.displayName || slug.charAt(0).toUpperCase() + slug.slice(1).replace(/-/g, " ");
      return {
        slug,
        name,
        description: `Browse our ${name} collection`,
        heroImageUrl: meta?.heroImageUrl || `assets/img/placeholders/${slug}-hero.svg`,
        productCount: matched.length,
        featured: matched.slice(0, 4),
      };
    }
    return CATEGORIES;
  },

  "GET /products/:id/reviews": (params, path) => {
    const id = path.split("/")[2];
    const p = products.find((x) => x.productId === id);
    if (!p) throw problem(404, "Product not found", id);

    const list = REVIEWS_BY_PRODUCT[id] || [];
    const sorted = [...list].sort((a, b) => (b.createdAt || "").localeCompare(a.createdAt || ""));
    const avg = sorted.length
      ? Math.round((sorted.reduce((s, r) => s + r.rating, 0) / sorted.length) * 10) / 10
      : (p.averageRating || 0);
    const histogram = histogramFrom(sorted);

    const page = +params?.page || 1;
    const pageSize = +params?.pageSize || 10;
    const start = (page - 1) * pageSize;
    const items = sorted.slice(start, start + pageSize).map((r) => ({
      reviewId:    r.reviewId,
      productId:   r.productId,
      userId:      r.userId,
      displayName: r.author,
      rating:      r.rating,
      title:       r.headline,
      body:        r.body,
      verified:    r.verified,
      createdAt:   r.createdAt,
    }));

    return {
      productId: id,
      summary: { averageRating: avg, totalReviews: sorted.length, histogram },
      items,
      page, pageSize, total: sorted.length,
    };
  },

  "GET /search": (params = {}) => {
    const q = (params.q || "").toLowerCase();
    if (!q) return { items: [], page: 1, pageSize: 24, total: 0, query: "" };

    const scored = products
      .map(p => {
        let score = 0;
        const name = p.name.toLowerCase();
        const desc = (p.description || "").toLowerCase();
        const cat = (p.category || "").toLowerCase();
        if (name.includes(q)) score += 10;
        if (name.startsWith(q)) score += 5;
        if (desc.includes(q)) score += 3;
        if (cat.includes(q)) score += 2;
        (p.colors || []).forEach(c => { if (c.toLowerCase().includes(q)) score += 2; });
        (p.occasionTags || []).forEach(t => { if (t.includes(q)) score += 2; });
        return { product: p, score };
      })
      .filter(x => x.score > 0)
      .sort((a, b) => b.score - a.score)
      .map(x => x.product);

    const page = +params.page || 1;
    const pageSize = +params.pageSize || 24;
    const start = (page - 1) * pageSize;

    return {
      items: scored.slice(start, start + pageSize),
      page,
      pageSize,
      total: scored.length,
      query: params.q,
    };
  },
};

function buildFacets(items) {
  const categoryMap = {};
  const colorMap = {};
  const sizeMap = {};
  const fitMap = {};

  items.forEach(p => {
    categoryMap[p.category] = (categoryMap[p.category] || 0) + 1;
    (p.colors || []).forEach(c => { colorMap[c] = (colorMap[c] || 0) + 1; });
    (p.availableSizes || []).forEach(s => { sizeMap[s] = (sizeMap[s] || 0) + 1; });
    const fit = p.attributes?.fit;
    if (fit) fitMap[fit] = (fitMap[fit] || 0) + 1;
  });

  const COLOR_SWATCH = {
    black: "#1a1a1a", navy: "#1B2A4E", gray: "#7a7a7a", beige: "#d6c4a6",
    cream: "#f0e8d8", charcoal: "#36454F", olive: "#5b6240", white: "#fafafa",
    brown: "#5a3920", tan: "#c8a878",
  };

  const sizeOrder = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  return {
    category: Object.entries(categoryMap)
      .map(([value, count]) => ({ value, label: value.charAt(0).toUpperCase() + value.slice(1).replace(/-/g, ' '), count }))
      .sort((a, b) => a.value.localeCompare(b.value)),
    color: Object.entries(colorMap)
      .map(([value, count]) => ({ value, swatch: COLOR_SWATCH[value] || "#888", count }))
      .sort((a, b) => a.value.localeCompare(b.value)),
    size: Object.entries(sizeMap)
      .map(([value, count]) => ({ value, count }))
      .sort((a, b) => {
        const aNum = parseInt(a.value), bNum = parseInt(b.value);
        if (!isNaN(aNum) && !isNaN(bNum)) return aNum - bNum;
        return sizeOrder.indexOf(a.value) - sizeOrder.indexOf(b.value);
      }),
    priceBuckets: [
      { min: 0, max: 100, count: items.filter(p => p.price >= 0 && p.price < 100).length },
      { min: 100, max: 200, count: items.filter(p => p.price >= 100 && p.price < 200).length },
      { min: 200, max: 500, count: items.filter(p => p.price >= 200 && p.price < 500).length },
    ],
    fit: Object.entries(fitMap)
      .map(([value, count]) => ({ value, label: value.charAt(0).toUpperCase() + value.slice(1), count }))
      .sort((a, b) => a.value.localeCompare(b.value)),
  };
}

function dimensionValue(p, key) {
  switch (key) {
    case "price":  return `$${p.price.toFixed(2)}`;
    case "fabric": return p.attributes?.fabric || "—";
    case "care":   return p.attributes?.care   || p.careInstructions || "—";
    case "sizes":  return (p.availableSizes || []).join(", ");
    case "colors": return (p.colors || []).join(", ");
    case "fit":    return p.attributes?.fit || "—";
    default:       return p.attributes?.[key] || "—";
  }
}

function histogramFrom(reviews) {
  const hist = { "5": 0, "4": 0, "3": 0, "2": 0, "1": 0 };
  for (const r of reviews) {
    const k = String(Math.max(1, Math.min(5, Math.round(r.rating))));
    hist[k]++;
  }
  return hist;
}

function problem(status, title, detail) {
  const err = new Error(title);
  Object.assign(err, { status, title, detail, type: "about:blank" });
  return err;
}
