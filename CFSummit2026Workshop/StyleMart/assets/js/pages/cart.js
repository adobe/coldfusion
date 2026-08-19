// assets/js/pages/cart.js
import { api } from "../api.js";
import { appStore } from "../store.js";
import { ConfirmationGate } from "../components/confirm-gate.js";

function getCartId() { return appStore.get().cartId; }

export async function initCart() {
  await refreshCart();

  // Subscribe to pending action set by the chat panel (Task 24+).
  appStore.subscribe(async (s) => {
    const slot = document.querySelector("[data-pending-slot]");
    slot.innerHTML = "";
    if (!s.pendingActionId || !s.pendingSummary) return;
    const gate = ConfirmationGate({
      pendingActionId: s.pendingActionId,
      summary: s.pendingSummary,
      expiresAt: s.pendingExpiresAt,
      onConfirm: async (pid) => {
        await api.decide(getCartId(), pid, "confirm");
        appStore.set({ pendingActionId: null, pendingSummary: null, pendingExpiresAt: null });
        await refreshCart();
      },
      onDecline: async (pid) => {
        await api.decide(getCartId(), pid, "decline");
        appStore.set({ pendingActionId: null, pendingSummary: null, pendingExpiresAt: null });
      },
    });
    slot.appendChild(gate);
  });
}

async function refreshCart() {
  const cart = await api.getMyCart();
  appStore.set({ cartId: cart.cartId });
  const itemsEl = document.querySelector("[data-cart-items]");

  // Group identical variants
  const grouped = [];
  for (const item of cart.items) {
    const existing = grouped.find(g => g.variantId === item.variantId);
    if (existing) {
      existing.quantity += item.quantity;
      existing.lineTotal += item.lineTotal;
      existing.discountAmount += (item.discountAmount || 0);
    } else {
      grouped.push({ ...item, quantity: item.quantity || 1 });
    }
  }

  itemsEl.innerHTML = grouped.length
    ? grouped.map((i) => {
        const variantLabel = [i.color, i.size].filter(Boolean).join(" / ") || i.variantId;
        const hasDiscount = i.discountAmount > 0;
        return `
      <div class="cart-line${i.stale ? ' cart-line--stale' : ''}${!i.inStock ? ' cart-line--oos' : ''}">
        <img src="${i.imageUrl}" alt="" class="cart-line__img">
        <div class="cart-line__body">
          <div class="cart-line__name">${i.name}</div>
          <div class="cart-line__var">${variantLabel}</div>
          ${!i.inStock ? '<div class="cart-line__badge cart-line__badge--oos">Out of stock</div>' : ''}
        </div>
        <div class="cart-line__qty">
          <div class="qty-stepper qty-stepper--sm">
            <button type="button" class="qty-stepper__btn" data-cart-qty-minus="${i.variantId}" aria-label="Decrease">−</button>
            <span class="qty-stepper__val">${i.quantity}</span>
            <button type="button" class="qty-stepper__btn" data-cart-qty-plus="${i.variantId}" aria-label="Increase">+</button>
          </div>
        </div>
        <div class="cart-line__pricing">
          <div class="cart-line__price">$${i.lineTotal.toFixed(2)}</div>
          ${hasDiscount ? `<div class="cart-line__discount">-$${i.discountAmount.toFixed(2)}</div>` : ''}
        </div>
        <button class="icon-btn" data-remove="${i.variantId}" aria-label="Remove">&#x2715;</button>
      </div>`;
      }).join("")
    : `<p class="empty">Your cart is empty.</p>`;

  // Update totals
  document.querySelector("[data-subtotal]").textContent = `$${cart.subtotal.toFixed(2)}`;
  const discountEl = document.querySelector("[data-discount-total]");
  if (discountEl) {
    const discountRow = discountEl.closest(".cart-summary__row");
    if (cart.discountTotal > 0) {
      const couponName = cart.appliedCoupon?.code || "Discount";
      discountRow.querySelector("span:first-child").textContent = `Coupon (${couponName})`;
      discountEl.textContent = `-$${cart.discountTotal.toFixed(2)}`;
      discountRow.style.display = "";
    } else {
      discountRow.style.display = "none";
      discountEl.textContent = "$0.00";
    }
  }
  const totalEl = document.querySelector("[data-cart-total]");
  if (totalEl) totalEl.textContent = `$${cart.total.toFixed(2)}`;

  // Coupon UI
  renderCouponUI(cart);

  const totalQty = grouped.reduce((sum, i) => sum + i.quantity, 0);
  appStore.set({ cartCount: totalQty });
  const badge = document.querySelector("[data-cart-count]");
  if (badge) badge.textContent = totalQty;


  // Disable checkout button when cart is empty
  const checkoutBtn = document.querySelector(".cart__checkout-btn");
  if (checkoutBtn) {
    if (grouped.length === 0) {
      checkoutBtn.classList.add("btn--disabled");
      checkoutBtn.setAttribute("aria-disabled", "true");
      checkoutBtn.addEventListener("click", (e) => { if (!grouped.length) e.preventDefault(); });
    } else {
      checkoutBtn.classList.remove("btn--disabled");
      checkoutBtn.removeAttribute("aria-disabled");
    }
  }

  // The "I'll finish this later" link simulates cart abandonment — it only makes
  // sense with items in the cart, so disable it when empty (mirrors checkout).
  const abandonBtn = document.querySelector("[data-abandon-btn]");
  if (abandonBtn) {
    if (grouped.length === 0) {
      abandonBtn.classList.add("btn--disabled");
      abandonBtn.setAttribute("aria-disabled", "true");
      abandonBtn.addEventListener("click", (e) => { if (!grouped.length) e.preventDefault(); });
    } else {
      abandonBtn.classList.remove("btn--disabled");
      abandonBtn.removeAttribute("aria-disabled");
    }
  }

  // Quantity stepper handlers.
  //
  // The cart REST surface (K5/K6) exposes addItem (POST) and removeItem
  // (DELETE) but not yet a quantity-update endpoint, so the minus button
  // can't just "subtract one". Previously the else-branch also called
  // removeItem, which was the bug: any decrement deleted the entire line.
  // Fix: when qty > 1 we DELETE + re-add at qty-1; when qty == 1 we just
  // DELETE. Buttons disable during the round-trip to prevent double-clicks
  // racing the cart state.
  function lockSteppers(disabled) {
    itemsEl.querySelectorAll("[data-cart-qty-plus],[data-cart-qty-minus]").forEach((b) => {
      b.disabled = disabled;
    });
  }

  itemsEl.querySelectorAll("[data-cart-qty-plus]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const variantId = btn.dataset.cartQtyPlus;
      const item = grouped.find((g) => g.variantId === variantId);
      const max = item?.maxQty ?? 10;
      if (item && item.quantity >= max) return; // already at cap
      lockSteppers(true);
      try {
        await api.addItem(getCartId(), { variantId, quantity: 1 });
        await refreshCart();
      } catch (err) {
        lockSteppers(false);
        alert(`Could not increase quantity: ${err.message}`);
      }
    });
  });

  itemsEl.querySelectorAll("[data-cart-qty-minus]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      const variantId = btn.dataset.cartQtyMinus;
      const item = grouped.find((g) => g.variantId === variantId);
      if (!item) return;
      const newQty = item.quantity - 1;
      lockSteppers(true);
      try {
         if (newQty < 1) {
          await api.removeItem(getCartId(), variantId);
        } else {
          await api.removeItem(getCartId(), variantId);
          await api.addItem(getCartId(), { variantId, quantity: newQty });
        }
        await refreshCart();
      } catch (err) {
        await refreshCart().catch(() => {});
        alert(`Could not decrease quantity: ${err.message}`);
      }
    });
  });

  // Remove button handlers
  itemsEl.querySelectorAll("[data-remove]").forEach((btn) => {
    btn.addEventListener("click", async () => {
      await api.removeItem(getCartId(), btn.dataset.remove);
      await refreshCart();
    });
  });
}

function renderCouponUI(cart) {
  const couponSlot = document.querySelector("[data-coupon-slot]");
  if (!couponSlot) return;

  if (cart.appliedCoupon && typeof cart.appliedCoupon === "object") {
    const coupon = cart.appliedCoupon;
    couponSlot.innerHTML = `
      <div class="coupon-applied">
        <span class="coupon-applied__label">Coupon <strong>${coupon.code}</strong> applied</span>
        <span class="coupon-applied__value">-$${cart.discountTotal.toFixed(2)}</span>
        <button class="btn btn--sm btn--outline" data-remove-coupon>Remove</button>
      </div>`;
    couponSlot.querySelector("[data-remove-coupon]").addEventListener("click", async () => {
      try {
        await api.removeCoupon(getCartId());
        await refreshCart();
      } catch (err) {
        alert(`Could not remove coupon: ${err.message}`);
      }
    });
  } else {
    couponSlot.innerHTML = `
      <button type="button" class="coupon-toggle" data-coupon-toggle>Have a coupon?</button>
      <div class="coupon-input" style="display:none;" data-coupon-form>
        <input type="text" class="input" placeholder="Enter coupon code" data-coupon-code>
        <button class="btn btn--sm" data-apply-coupon>Apply</button>
        <span class="coupon-input__error" data-coupon-error></span>
      </div>`;

    const toggle = couponSlot.querySelector("[data-coupon-toggle]");
    const form = couponSlot.querySelector("[data-coupon-form]");
    toggle.addEventListener("click", () => {
      const visible = form.style.display !== "none";
      form.style.display = visible ? "none" : "flex";
    });

    const applyBtn = couponSlot.querySelector("[data-apply-coupon]");
    const codeInput = couponSlot.querySelector("[data-coupon-code]");
    const errorSpan = couponSlot.querySelector("[data-coupon-error]");

    async function applyCoupon() {
      const code = codeInput.value.trim();
      if (!code) return;
      errorSpan.textContent = "";
      applyBtn.disabled = true;
      applyBtn.textContent = "Applying...";
      try {
        await api.applyCoupon(getCartId(), code);
        await refreshCart();
      } catch (err) {
        errorSpan.textContent = err.title || err.message || "Invalid coupon";
        applyBtn.disabled = false;
        applyBtn.textContent = "Apply";
      }
    }

    applyBtn.addEventListener("click", applyCoupon);
    codeInput.addEventListener("keydown", (e) => {
      if (e.key === "Enter") applyCoupon();
    });
  }
}
