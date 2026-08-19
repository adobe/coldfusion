import { api } from "../api.js";

export async function initCheckout() {
  const root = document.querySelector("[data-checkout-root]");
  if (!root) return;

  const summaryEl = root.querySelector("[data-checkout-summary]");
  let cart;

  try {
    cart = await api.getMyCart();
    if (!cart.items.length) {
      root.innerHTML = '<p class="empty">Your cart is empty. <a href="products.cfm">Continue shopping</a></p>';
      return;
    }
    summaryEl.innerHTML = renderOrderSummary(cart);
    bindCheckoutCoupon(summaryEl, cart);
  } catch (err) {
    summaryEl.innerHTML = `<p class="error">${err.message}</p>`;
    return;
  }

  let currentStep = 1;
  const shippingData = {};
  const paymentData = {};

  // Step navigation
  function goToStep(step) {
    currentStep = step;
    root.querySelectorAll("[data-step]").forEach(el => {
      el.style.display = el.dataset.step == step ? "" : "none";
    });
    root.querySelectorAll("[data-step-ind]").forEach(el => {
      const s = +el.dataset.stepInd;
      el.classList.toggle("stepper__step--active", s === step);
      el.classList.toggle("stepper__step--done", s < step);
    });
  }

  // Step 1: Shipping
  const shippingForm = root.querySelector("[data-shipping-form]");
  addInlineValidation(shippingForm);
  shippingForm.addEventListener("submit", (e) => {
    e.preventDefault();
    if (!validateShipping(shippingForm)) return;
    const fd = new FormData(shippingForm);
    Object.assign(shippingData, Object.fromEntries(fd.entries()));
    goToStep(2);
  });

  // Step 2: Payment
  const paymentForm = root.querySelector("[data-payment-form]");
  addInlineValidation(paymentForm);
  formatCardInputs(paymentForm);
  paymentForm.addEventListener("submit", (e) => {
    e.preventDefault();
    if (!validatePayment(paymentForm)) return;
    const fd = new FormData(paymentForm);
    Object.assign(paymentData, Object.fromEntries(fd.entries()));
    renderReview();
    goToStep(3);
  });

  // Back buttons
  root.querySelectorAll("[data-back]").forEach(btn => {
    btn.addEventListener("click", () => goToStep(+btn.dataset.back));
  });

  // Step 3: Review
  function renderReview() {
    const reviewEl = root.querySelector("[data-review-content]");
    const maskedCard = paymentData.cardNumber ? "•••• " + paymentData.cardNumber.slice(-4) : "";
    reviewEl.innerHTML = `
      <div class="review-section">
        <h3>Shipping</h3>
        <p>${shippingData.name}<br>
           ${shippingData.line1}<br>
           ${shippingData.city}, ${shippingData.state} ${shippingData.zip}<br>
           ${shippingData.country}</p>
        <p>${shippingData.email} &middot; ${shippingData.phone}</p>
      </div>
      <div class="review-section">
        <h3>Payment</h3>
        <p>${maskedCard} &middot; Expires ${paymentData.expiry}</p>
      </div>
      <div class="review-section">
        <h3>Order Total</h3>
        <p class="review-total">$${cart.total.toFixed(2)}</p>
      </div>
    `;
  }

  // Place Order
  root.querySelector("[data-place-order]").addEventListener("click", async () => {
    const btn = root.querySelector("[data-place-order]");
    btn.disabled = true;
    btn.textContent = "Placing order...";

    try {
      const order = await api.checkout(cart.cartId, { shippingAddress: shippingData });
      root.innerHTML = `
        <div class="checkout__success">
          <h1>Order Confirmed!</h1>
          <p>Order ID: <strong>${order.orderId}</strong></p>
          <p>A confirmation email will be sent to <strong>${shippingData.email}</strong></p>
          <p>Status: ${order.status}</p>
          <a href="orders.cfm" class="btn-primary">View Orders</a>
          <a href="index.cfm" class="btn-secondary">Continue Shopping</a>
        </div>
      `;
    } catch (err) {
      btn.disabled = false;
      btn.textContent = "Place Order";
      alert("Checkout failed: " + err.message);
    }
  });
}

function renderOrderSummary(cart) {
  const items = cart.items.map(item => {
    const variant = [
      item.size ? `Size: ${item.size}` : '',
      item.color ? `Color: ${item.color}` : ''
    ].filter(Boolean).join(' · ');
    return `
    <div class="checkout-item">
      <img src="${item.imageUrl}" alt="${item.name}" class="checkout-item__img">
      <div class="checkout-item__info">
        <span class="checkout-item__name">${item.name}</span>
        <span class="checkout-item__variant">${variant}</span>
        <span class="checkout-item__qty">Qty: ${item.quantity} · <a href="cart.cfm" class="checkout-item__edit">Edit</a></span>
      </div>
      <span class="checkout-item__price">$${item.lineTotal.toFixed(2)}</span>
    </div>
  `;
  }).join('');

  const discountLabel = cart.appliedCoupon?.code
    ? `Discount (${cart.appliedCoupon.code})`
    : 'Discount (promo)';

  return `
    <h2>Order Summary</h2>
    ${items}
    <div class="checkout__totals">
      <div><span>Subtotal</span><span>$${cart.subtotal.toFixed(2)}</span></div>
      <div><span>Shipping</span><span>${cart.shippingCost ? '$' + cart.shippingCost.toFixed(2) : 'Free'}</span></div>
      <div><span>Tax</span><span>${cart.tax ? '$' + cart.tax.toFixed(2) : '$0.00'}</span></div>
      ${cart.discountTotal > 0 ? `<div class="checkout__discount"><span>${discountLabel}</span><span>-$${cart.discountTotal.toFixed(2)}</span></div>` : ''}
      <div class="checkout__total"><span>Total</span><span>$${cart.total.toFixed(2)}</span></div>
    </div>
    <div class="checkout__promo" data-checkout-promo>
      <button type="button" class="coupon-toggle" data-checkout-coupon-toggle>Have a promo code?</button>
      <div class="coupon-input" style="display:none" data-checkout-coupon-form>
        <input type="text" class="input" placeholder="Enter code" data-checkout-coupon-code>
        <button type="button" class="btn btn--sm" data-checkout-apply-coupon>Apply</button>
        <span class="coupon-input__error" data-checkout-coupon-error></span>
      </div>
    </div>
  `;
}

function bindCheckoutCoupon(container, cart) {
  const toggle = container.querySelector("[data-checkout-coupon-toggle]");
  const form = container.querySelector("[data-checkout-coupon-form]");
  if (!toggle || !form) return;

  toggle.addEventListener("click", () => {
    form.style.display = form.style.display === "none" ? "flex" : "none";
  });

  const applyBtn = container.querySelector("[data-checkout-apply-coupon]");
  const codeInput = container.querySelector("[data-checkout-coupon-code]");
  const errorSpan = container.querySelector("[data-checkout-coupon-error]");

  applyBtn.addEventListener("click", async () => {
    const code = codeInput.value.trim();
    if (!code) return;
    errorSpan.textContent = "";
    applyBtn.disabled = true;
    applyBtn.textContent = "Applying...";
    try {
      await api.applyCoupon(cart.cartId, code);
      const updated = await api.getMyCart();
      Object.assign(cart, updated);
      container.innerHTML = renderOrderSummary(cart);
      bindCheckoutCoupon(container, cart);
    } catch (err) {
      errorSpan.textContent = err.title || err.message || "Invalid code";
      applyBtn.disabled = false;
      applyBtn.textContent = "Apply";
    }
  });
}

// --- Validation ---

function showFieldError(input, msg) {
  clearFieldError(input);
  input.classList.add("input--error");
  const err = document.createElement("span");
  err.className = "field-error";
  err.textContent = msg;
  input.parentNode.appendChild(err);
}

function clearFieldError(input) {
  input.classList.remove("input--error");
  const existing = input.parentNode.querySelector(".field-error");
  if (existing) existing.remove();
}

function addInlineValidation(form) {
  form.querySelectorAll("input, select").forEach(input => {
    input.addEventListener("blur", () => {
      if (input.required && !input.value.trim()) {
        showFieldError(input, "This field is required");
      } else {
        clearFieldError(input);
      }
    });
    input.addEventListener("input", () => clearFieldError(input));
  });
}

function validateShipping(form) {
  let valid = true;
  const fields = {
    name: { msg: "Full name is required", min: 2 },
    email: { msg: "Valid email is required", pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/ },
    phone: { msg: "Phone number is required", min: 7 },
    line1: { msg: "Street address is required", min: 3 },
    city: { msg: "City is required", min: 2 },
    state: { msg: "State is required" },
    zip: { msg: "ZIP / postal code is required", pattern: /^[A-Za-z0-9\s\-]{3,10}$/ },
  };

  for (const [name, rule] of Object.entries(fields)) {
    const input = form.querySelector(`[name="${name}"]`);
    if (!input) continue;
    const val = input.value.trim();
    if (!val || (rule.min && val.length < rule.min)) {
      showFieldError(input, rule.msg);
      valid = false;
    } else if (rule.pattern && !rule.pattern.test(val)) {
      showFieldError(input, rule.msg);
      valid = false;
    } else {
      clearFieldError(input);
    }
  }
  return valid;
}

function validatePayment(form) {
  let valid = true;
  const cardNum = form.querySelector("[name=cardNumber]");
  const expiry = form.querySelector("[name=expiry]");
  const cvv = form.querySelector("[name=cvv]");
  const cardName = form.querySelector("[name=cardName]");

  const numClean = cardNum.value.replace(/\s/g, "");
  if (!/^\d{13,19}$/.test(numClean)) {
    showFieldError(cardNum, "Enter a valid card number");
    valid = false;
  } else { clearFieldError(cardNum); }

  if (!/^(0[1-9]|1[0-2])\/\d{2}$/.test(expiry.value)) {
    showFieldError(expiry, "Use MM/YY format");
    valid = false;
  } else {
    const [mm, yy] = expiry.value.split("/").map(Number);
    const now = new Date();
    const expDate = new Date(2000 + yy, mm);
    if (expDate < now) {
      showFieldError(expiry, "Card is expired");
      valid = false;
    } else { clearFieldError(expiry); }
  }

  if (!/^\d{3,4}$/.test(cvv.value)) {
    showFieldError(cvv, "3 or 4 digits");
    valid = false;
  } else { clearFieldError(cvv); }

  if (!cardName.value.trim() || cardName.value.trim().length < 2) {
    showFieldError(cardName, "Cardholder name is required");
    valid = false;
  } else { clearFieldError(cardName); }

  return valid;
}

function formatCardInputs(form) {
  const cardNum = form.querySelector("[name=cardNumber]");
  cardNum.addEventListener("input", () => {
    let val = cardNum.value.replace(/\D/g, "").slice(0, 16);
    cardNum.value = val.replace(/(\d{4})(?=\d)/g, "$1 ");
  });

  const expiry = form.querySelector("[name=expiry]");
  expiry.addEventListener("input", () => {
    let val = expiry.value.replace(/\D/g, "").slice(0, 4);
    if (val.length >= 2) val = val.slice(0, 2) + "/" + val.slice(2);
    expiry.value = val;
  });

  const cvv = form.querySelector("[name=cvv]");
  cvv.addEventListener("input", () => {
    cvv.value = cvv.value.replace(/\D/g, "").slice(0, 4);
  });
}
