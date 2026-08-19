// assets/js/mock/handlers/inventory.js
import productsData    from "../fixtures/products.json"    with { type: "json" };
import loyaltyData     from "../fixtures/loyalty.json"     with { type: "json" };
import promotionsData  from "../fixtures/promotions.json"  with { type: "json" };
import shoppersData    from "../fixtures/shoppers.json"    with { type: "json" };

const products = [...productsData];

// Loyalty tiers from seed (Bronze 0 / Silver $500 / Gold $1500).
// Note: §4.4 + seed use spend_threshold_cents; expose dollars for the existing
// /loyalty/tiers contract and derive discountPct from the seeded perks ladder.
const LOYALTY_TIERS = loyaltyData.tiers.map((t) => ({
  tierId: t.tierId,
  name: t.name,
  minSpend: t.spendThresholdCents / 100,
  discountPct: t.tierId === "tier_bronze" ? 0 : t.tierId === "tier_silver" ? 5 : 10,
  perks: t.perks,
  sortOrder: t.sortOrder,
}));

// Active promotions from seed: storewide 5% + jackets/raincoats 15%.
const PROMOTIONS = promotionsData.items.map((p) => ({
  promotionId: p.promotionId,
  name: p.name,
  type: p.type,
  value: p.value,
  active: p.active,
  startsAt: p.validFrom,
  endsAt: p.validUntil,
  scopeCategories: p.scopeCategories,
  displayBanner: p.displayBanner,
}));

export const inventoryHandlers = {
  "GET /inventory/:id": (_, path) => {
    const id = path.split("/").pop();
    const p = products.find((x) => x.productId === id);
    if (!p) throw problem(404, "Product not found", id);
    const variants = (p.variants || []).map((v) => ({
      variantId: v.variantId,
      inStock: v.inStock,
      quantity: v.stockQty,
      warehouseId: "wh_us_east_01",
    }));
    return { productId: id, variants };
  },

  "GET /inventory/bulk": (params) => {
    const ids = (params?.productIds || "").split(",").filter(Boolean);
    return {
      items: ids.map((id) => {
        const p = products.find((x) => x.productId === id);
        if (!p) return { productId: id, variants: [] };
        const variants = (p.variants || []).map((v) => ({
          variantId: v.variantId,
          inStock: v.inStock,
          quantity: v.stockQty,
          warehouseId: "wh_us_east_01",
        }));
        return { productId: id, variants };
      }),
    };
  },

  "GET /pricing/:id": (_, path) => {
    const id = path.split("/").pop();
    const p = products.find((x) => x.productId === id);
    if (!p) throw problem(404, "Product not found", id);
    return {
      productId: id,
      basePrice: p.basePrice || p.price,
      currentPrice: p.price,
      currency: p.currency || "USD",
      appliedRules: [],
    };
  },

  "GET /pricing/bulk": (params) => {
    const ids = (params?.productIds || "").split(",").filter(Boolean);
    return {
      items: ids.map((id) => {
        const p = products.find((x) => x.productId === id);
        if (!p) return { productId: id, basePrice: 0, currentPrice: 0, currency: "USD", appliedRules: [] };
        return {
          productId: id,
          basePrice: p.basePrice || p.price,
          currentPrice: p.price,
          currency: p.currency || "USD",
          appliedRules: [],
        };
      }),
    };
  },

  "GET /loyalty/tiers": () => LOYALTY_TIERS,

  "GET /users/:id/loyalty": (_, path) => {
    const userId = path.split("/")[2];
    const user = shoppersData[userId];
    const tierId = user?.loyaltyTierId || "tier_silver";
    const sorted = [...LOYALTY_TIERS].sort((a, b) => a.sortOrder - b.sortOrder);
    const currentIdx = sorted.findIndex((t) => t.tierId === tierId);
    const current = sorted[currentIdx];
    const next = sorted[currentIdx + 1] || null;
    // Demo spend: pick the midpoint between current and next tier threshold
    const totalSpend = next
      ? Math.round((current.minSpend + next.minSpend) / 2)
      : current.minSpend + 500;
    return {
      userId,
      tierId,
      tierName: current?.name || "Silver",
      totalSpend,
      nextTierId:      next?.tierId || null,
      nextTierName:    next?.name || null,
      spendToNextTier: next ? Math.max(0, next.minSpend - totalSpend) : 0,
    };
  },

  "GET /promotions": () => ({ items: PROMOTIONS }),

  "GET /promotions/:id": (_, path) => {
    const id = path.split("/").pop();
    const promo = PROMOTIONS.find((p) => p.promotionId === id);
    if (!promo) throw problem(404, "Promotion not found", id);
    return { ...promo };
  },
};

function problem(status, title, detail) {
  const err = new Error(title);
  Object.assign(err, { status, title, detail, type: "about:blank" });
  return err;
}
