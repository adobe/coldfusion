import { api } from "../api.js";
import { formatDate } from "../utils/format-date.js";

export async function initOrderDetail() {
  const root = document.querySelector("[data-order-detail-root]");
  if (!root) return;

  const orderId = new URLSearchParams(window.location.search).get("id");
  if (!orderId) { root.innerHTML = '<p>No order ID provided.</p>'; return; }

  try {
    const order = await api.getOrder(orderId);
    root.innerHTML = renderDetail(order);
  } catch (err) {
    root.innerHTML = `<p class="error">${err.message}</p>`;
  }
}

function friendlyOrderId(id) {
  const num = id.replace(/[^0-9]/g, '').slice(-4) || '0001';
  return `#SM-${num}`;
}

function renderDetail(order) {
  const items = order.items.map(item => {
    const variant = [
      item.size ? `Size: ${item.size}` : '',
      item.color ? `Color: ${item.color}` : ''
    ].filter(Boolean).join(' · ');
    const imgSrc = item.imageUrl || 'assets/img/placeholders/cubes-beige.svg';
    return `
    <div class="order-item">
      <img src="${imgSrc}" alt="${item.name}" class="order-item__img"
           onerror="this.src='assets/img/placeholders/cubes-beige.svg'">
      <div class="order-item__info">
        <strong>${item.name}</strong>
        <span>${variant}</span>
        <span>Qty: ${item.quantity}</span>
      </div>
      <span class="order-item__price">$${(item.lineTotal || item.unitPrice || 0).toFixed(2)}</span>
    </div>
  `;
  }).join('');

  const addr = order.shippingAddress;
  const tracking = order.trackingNumber || 'N/A';
  const carrier = order.carrier || 'Standard Shipping';

  return `
    <div class="order-detail__header">
      <h1>Order ${friendlyOrderId(order.orderId)}</h1>
      <span class="order-detail__ref">Ref: ${order.orderId}</span>
    </div>

    <div class="order-detail__status-section">
      <div class="order-detail__badge">
        <span class="badge badge--${order.status}">${capitalize(order.status)}</span>
      </div>
      ${renderTimeline(order)}
    </div>

    <div class="order-detail__tracking">
      <h3>Shipping</h3>
      <p><strong>${carrier}</strong></p>
      <p>Tracking: ${tracking !== 'N/A' ? `<a href="#" class="tracking-link">${tracking}</a>` : '<span class="text-muted">Not yet available</span>'}</p>
    </div>

    <h3>Items</h3>
    <div class="order-detail__items">${items}</div>

    <div class="order-detail__summary">
      <div><span>Subtotal</span><span>$${order.subtotal.toFixed(2)}</span></div>
      <div><span>Shipping</span><span>${order.shippingCost ? '$' + order.shippingCost.toFixed(2) : 'Free'}</span></div>
      <div><span>Tax</span><span>${order.tax ? '$' + order.tax.toFixed(2) : '$0.00'}</span></div>
      ${order.discountTotal > 0 ? `<div class="order-detail__discount"><span>Discount${order.couponCode ? ' (' + order.couponCode + ')' : ''}</span><span>-$${order.discountTotal.toFixed(2)}</span></div>` : ''}
      <div class="order-detail__total"><span>Total</span><span>$${order.total.toFixed(2)}</span></div>
    </div>

    ${addr ? `
      <div class="order-detail__address">
        <h3>Delivery Address</h3>
        <p>${addr.name}<br>
           ${addr.line1}${addr.line2 ? '<br>' + addr.line2 : ''}<br>
           ${addr.city}, ${addr.state} ${addr.zip}<br>
           ${addr.country || ''}</p>
        ${addr.email ? `<p>${addr.email}</p>` : ''}
      </div>
    ` : ''}

    <a href="orders.cfm" class="btn-secondary">Back to Orders</a>
  `;
}

function renderTimeline(order) {
  const steps = [
    { key: 'placed', label: 'Placed', date: order.placedAt },
    { key: 'confirmed', label: 'Confirmed', date: order.confirmedAt || order.placedAt },
    { key: 'shipped', label: 'Shipped', date: order.shippedAt },
    { key: 'delivered', label: 'Delivered', date: order.deliveredAt }
  ];

  const statusOrder = ['placed', 'confirmed', 'shipped', 'delivered'];
  const currentIdx = statusOrder.indexOf(order.status) >= 0 ? statusOrder.indexOf(order.status) : 0;

  return `
    <div class="order-timeline">
      ${steps.map((step, i) => {
        const done = i <= currentIdx;
        const active = i === currentIdx;
        return `
          <div class="timeline-step ${done ? 'timeline-step--done' : ''} ${active ? 'timeline-step--active' : ''}">
            <div class="timeline-step__dot"></div>
            <div class="timeline-step__label">${step.label}</div>
            <div class="timeline-step__date">${step.date ? formatDate(step.date) : '—'}</div>
          </div>
        `;
      }).join('<div class="timeline-step__line"></div>')}
    </div>
  `;
}

function capitalize(str) {
  return str ? str.charAt(0).toUpperCase() + str.slice(1) : '';
}
