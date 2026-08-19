import { api } from "../api.js";
import { formatDate } from "../utils/format-date.js";

export async function initOrders() {
  const root = document.querySelector("[data-orders-root]");
  if (!root) return;
  const list = root.querySelector("[data-orders-list]");

  try {
    const { items } = await api.listOrders();
    if (!items.length) {
      list.innerHTML = '<p>No orders yet. <a href="products.cfm">Start shopping</a></p>';
      return;
    }
    list.innerHTML = items.map(renderOrderCard).join('');
  } catch (err) {
    list.innerHTML = `<p class="error">${err.message}</p>`;
  }
}

function renderOrderCard(order) {
  const itemCount = order.items.reduce((s, i) => s + (i.quantity || 1), 0);
  const thumbs = order.items.slice(0, 3).map(i =>
    `<img src="${i.imageUrl}" alt="${i.name}" class="order-card__thumb">`
  ).join('');

  return `
    <a class="order-card" href="order-detail.cfm?id=${order.orderId}">
      <div class="order-card__images">${thumbs}</div>
      <div class="order-card__info">
        <span class="order-card__id">${order.orderId}</span>
        <span class="order-card__status order-card__status--${order.status}">${order.status}</span>
        <span class="order-card__meta">${itemCount} item${itemCount > 1 ? 's' : ''} · $${order.total.toFixed(2)}</span>
        <span class="order-card__date">${formatDate(order.placedAt)}</span>
      </div>
    </a>
  `;
}
