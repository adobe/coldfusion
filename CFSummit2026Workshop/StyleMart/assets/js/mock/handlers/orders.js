// assets/js/mock/handlers/orders.js
import { __resetCart, __getCart } from "./carts.js";

const orders = [];
let orderCounter = 0;

export const orderHandlers = {
  "POST /checkout": ({ cartId, shippingAddress }) => {
    const cart = __getCart();
    const orderId = `ord_${(++orderCounter).toString().padStart(6, '0')}`;
    const order = {
      orderId,
      userId: "usr_demo_001",
      status: "confirmed",
      items: [...cart.items],
      subtotal: cart.subtotal,
      discountTotal: cart.discountTotal,
      total: cart.total,
      currency: cart.currency,
      appliedCoupon: cart.appliedCoupon,
      shippingAddress: shippingAddress || {
        name: "Jordan",
        line1: "123 Demo Street",
        city: "San Francisco",
        state: "CA",
        zip: "94102",
        country: "US"
      },
      placedAt: new Date().toISOString(),
    };
    orders.push(order);

    // Clear the cart after checkout
    __resetCart(true);

    return order;
  },

  "GET /orders": () => ({
    items: orders.length > 0 ? orders : [
      {
        orderId: "ord_demo_001",
        status: "delivered",
        items: [
          { name: "Travel Blazer", imageUrl: "assets/img/placeholders/jacket-navy.svg", quantity: 1, unitPrice: 189.00 },
          { name: "Slim Chinos", imageUrl: "assets/img/placeholders/jeans-navy.svg", quantity: 1, unitPrice: 79.00 }
        ],
        total: 268.00,
        currency: "USD",
        placedAt: "2026-05-20T14:30:00Z"
      }
    ],
    page: 1,
    pageSize: 10,
    total: orders.length || 1
  }),

  "GET /orders/:id": (_, path) => {
    const id = path.split("/").pop();
    const order = orders.find(o => o.orderId === id);
    if (order) return order;
    // Return demo order
    return {
      orderId: id,
      userId: "usr_demo_001",
      status: "delivered",
      items: [
        { cartItemId: "cit_1", variantId: "var_01", productId: "prd_01HZX01T001", name: "Travel Blazer", imageUrl: "assets/img/placeholders/jacket-navy.svg", size: "M", color: "navy", quantity: 1, unitPrice: 189.00, lineTotal: 189.00 },
        { cartItemId: "cit_2", variantId: "var_03", productId: "prd_01HZX01T003", name: "Slim Chinos", imageUrl: "assets/img/placeholders/jeans-navy.svg", size: "32", color: "navy", quantity: 1, unitPrice: 79.00, lineTotal: 79.00 }
      ],
      subtotal: 268.00,
      discountTotal: 0,
      total: 268.00,
      currency: "USD",
      appliedCoupon: null,
      shippingAddress: { name: "Jordan", line1: "123 Demo Street", city: "San Francisco", state: "CA", zip: "94102", country: "US" },
      placedAt: "2026-05-20T14:30:00Z",
      deliveredAt: "2026-05-23T10:00:00Z"
    };
  },
};
