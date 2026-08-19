// assets/js/main.js
import { installMocks } from "./mock/index.js";
import { API_CONFIG, api } from "./api.js";
import { appStore } from "./store.js";
import { initChat } from "./chat.js";
import { initTrace } from "./trace.js";
import { initShellControls } from "./shell-controls.js";
import { initThemeSwitcher } from "./theme-switcher.js";
import { initCompareListeners } from "./components/product-card.js";
import { initSearchBar } from "./components/search-bar.js";

if (API_CONFIG.mode === "mock") installMocks();

const page = document.body.dataset.page;
const pageBoot = {
  home: () => import("./pages/home.js").then((m) => m.initHome()),
  plp:  () => import("./pages/plp.js").then((m) => m.initPLP()),
  pdp:  () => import("./pages/pdp.js").then((m) => m.initPDP()),
  compare: () => import("./pages/compare.js").then((m) => m.initCompare()),
  cart: () => import("./pages/cart.js").then((m) => m.initCart()),
  "email-preview": () => import("./pages/email-preview.js").then((m) => m.initEmailPreview()),
  "capsule": () => import("./pages/capsule.js").then((m) => m.initCapsule()),
  "checkout": () => import("./pages/checkout.js").then((m) => m.initCheckout()),
  "orders": () => import("./pages/orders.js").then((m) => m.initOrders()),
  "order-detail": () => import("./pages/order-detail.js").then((m) => m.initOrderDetail()),
  "search": () => import("./pages/search.js").then((m) => m.initSearch()),
  "category": () => import("./pages/category.js").then((m) => m.initCategory()),
  "account": () => import("./pages/account.js").then((m) => m.initAccount()),
  "login": () => import("./pages/login.js").then((m) => m.initLogin()),
};

// Pages that require authentication — show login modal if not logged in
const AUTH_REQUIRED_PAGES = ["checkout", "orders", "order-detail", "account"];

function onAuthenticated(session) {
  const userId = session.userId || (session.user && session.user.userId);
  const displayName = session.displayName || (session.user && session.user.displayName) || "";
  API_CONFIG.shopperId = userId;
  appStore.set({ shopperId: userId, authenticated: true });
  sessionStorage.setItem("stylemart.authenticated", "true");
  // A real login supersedes any recovery-email identity carried in this tab.
  try { sessionStorage.removeItem("stylemart.resumeShopperId"); } catch (_) {}
  document.querySelectorAll(".auth-only").forEach(el => el.style.display = "");
  document.querySelectorAll(".anon-only").forEach(el => el.style.display = "none");
  document.querySelector(".app-shell")?.classList.add("app-shell--authed");
  const nameEl = document.querySelector("[data-user-name]");
  if (nameEl && displayName) nameEl.textContent = displayName.split(" ")[0];
}

// Boot the app: check session, then initialize
api.getSession().then((session) => {
  let resumeId = null;
  if (session.authenticated) {
    onAuthenticated(session);
  } else {
    // Logged out, but if the shopper followed a recovery-email "Resume Cart" link
    // earlier this tab session, keep acting as that shopper so cart.cfm / checkout
    // reflect their real cart instead of the demo cart. (capsule.js sets this.)
    try { resumeId = sessionStorage.getItem("stylemart.resumeShopperId"); } catch (_) {}
    if (resumeId) {
      API_CONFIG.shopperId = resumeId;
      appStore.set({ shopperId: resumeId });
    }
  }

  // Show login modal for protected pages when not authenticated
  if (!session.authenticated && AUTH_REQUIRED_PAGES.includes(page)) {
    showAuthModal(() => {
      // After successful login on a protected page, reload to init the page properly
      location.reload();
    }, () => {
      // On dismiss (Esc / backdrop click), go back to previous page
      if (history.length > 1) history.back();
      else location.href = "index.cfm";
    });
    return;
  }

  if (pageBoot[page]) pageBoot[page]();

  if (session.authenticated) {
    initChat();
    initTrace();
    refreshCartBadge();
  } else if (resumeId) {
    // Recovery-resumed shopper: show their real cart badge even while logged out.
    refreshCartBadge();
  }

  initShellControls();
  initThemeSwitcher();
  initCompareListeners();
  initSearchBar();
}).catch(() => {
  if (pageBoot[page]) pageBoot[page]();
  initShellControls();
  initThemeSwitcher();
  initCompareListeners();
  initSearchBar();
});

// --- Auth modal logic ---
function showAuthModal(onSuccess, onDismiss) {
  const modal = document.getElementById("auth-modal");
  if (!modal) return;
  modal.setAttribute("aria-hidden", "false");

  const loginForm = modal.querySelector("#login-form");
  const registerForm = modal.querySelector("#register-form");

  // Toggle forms
  modal.querySelectorAll("[data-show]").forEach(link => {
    link.addEventListener("click", (e) => {
      e.preventDefault();
      const target = link.dataset.show;
      loginForm.classList.toggle("auth-form--hidden", target !== "login");
      registerForm.classList.toggle("auth-form--hidden", target !== "register");
      modal.querySelectorAll(".auth-error").forEach(el => { el.textContent = ""; el.classList.remove("auth-error--success"); });
    });
  });

  // Close handlers
  function closeModal() {
    modal.setAttribute("aria-hidden", "true");
    modal.querySelectorAll(".auth-error").forEach(el => { el.textContent = ""; el.classList.remove("auth-error--success"); });
  }
  function dismissModal() {
    closeModal();
    if (onDismiss) onDismiss();
  }
  modal.querySelectorAll("[data-auth-close]").forEach(el => el.addEventListener("click", dismissModal));
  document.addEventListener("keydown", function escHandler(e) {
    if (e.key === "Escape" && modal.getAttribute("aria-hidden") === "false") {
      dismissModal();
      document.removeEventListener("keydown", escHandler);
    }
  });

  // Login submit
  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const username = loginForm.querySelector("[name=username]").value.trim();
    const password = loginForm.querySelector("[name=password]").value;
    const errEl = modal.querySelector("#login-error");
    errEl.textContent = "";
    if (!username || !password) { errEl.textContent = "Username and password are required."; return; }

    const btn = loginForm.querySelector("button[type=submit]");
    btn.disabled = true; btn.textContent = "Signing in...";
    try {
      const result = await api.login(username, password);
      onAuthenticated(result);
      closeModal();
      initChat();
      initTrace();
      refreshCartBadge();
      if (onSuccess) onSuccess();
    } catch (err) {
      errEl.textContent = err.code === "invalid_credentials" ? "Invalid username or password."
        : err.code === "validation_failed" ? (err.detail || "Please check your inputs.")
        : "Something went wrong. Please try again.";
    } finally { btn.disabled = false; btn.textContent = "Sign in"; }
  });

  // Register submit
  registerForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const username = registerForm.querySelector("[name=username]").value.trim();
    const displayName = registerForm.querySelector("[name=displayName]").value.trim();
    const email = registerForm.querySelector("[name=email]").value.trim();
    const password = registerForm.querySelector("[name=password]").value;
    const errEl = modal.querySelector("#register-error");
    errEl.textContent = "";
    if (!username || !password || !displayName) { errEl.textContent = "Username, display name, and password are required."; return; }
    if (password.length < 8) { errEl.textContent = "Password must be at least 8 characters."; return; }
    if (!/[a-zA-Z]/.test(password) || !/[0-9]/.test(password)) { errEl.textContent = "Password must contain at least 1 letter and 1 digit."; return; }

    const btn = registerForm.querySelector("button[type=submit]");
    btn.disabled = true; btn.textContent = "Creating account...";
    try {
      await api.register({ username, password, displayName, email: email || undefined });
      loginForm.classList.remove("auth-form--hidden");
      registerForm.classList.add("auth-form--hidden");
      const successEl = modal.querySelector("#login-error");
      successEl.textContent = "Account created! Sign in with your new credentials.";
      successEl.classList.add("auth-error--success");
    } catch (err) {
      errEl.textContent = err.code === "username_taken" ? "That username is already taken."
        : err.code === "validation_failed" ? (err.detail || "Please check your inputs.")
        : "Something went wrong. Please try again.";
    } finally { btn.disabled = false; btn.textContent = "Create account"; }
  });
}

// Export for use by other modules (header sign-in link)
export { showAuthModal };

document.querySelector("[data-toggle-trace]")?.addEventListener("click", () => {
  document.querySelector(".app-shell")?.classList.toggle("app-shell--trace-open");
});

// Logout button — always sign out cleanly. (The recovery email is reached via the
// cart's "I'll finish this later" button, not logout.)
document.querySelector("[data-logout]")?.addEventListener("click", () => {
  api.logout().then(() => {
    sessionStorage.removeItem("stylemart.authenticated");
    // Full sign-out clears any recovery-email identity too.
    try { sessionStorage.removeItem("stylemart.resumeShopperId"); } catch (_) {}
    location.reload();
  });
});

// Header sign-in link opens modal
document.querySelector(".anon-only[href='login.cfm']")?.addEventListener("click", (e) => {
  e.preventDefault();
  showAuthModal();
});

console.log("[StyleMart] UI bootstrap — page:", page, "mode:", API_CONFIG.mode);

if (new URLSearchParams(location.search).get("demo") === "london") {
  import("./demo.js").then((m) => m.runLondonDemo());
}

/** Refresh the header cart badge from the API. Exported for use by other modules. */
export function refreshCartBadge(showToast = false) {
  api.getCartSummary().then(summary => {
    if (summary.cartId) appStore.set({ cartId: summary.cartId });
    const badge = document.querySelector("[data-cart-count]");
    if (!badge) return;
    const prev = parseInt(badge.textContent) || 0;
    const count = summary.itemCount;

    if (count === 0) {
      badge.style.display = "none";
    } else {
      badge.style.display = "";
      badge.textContent = count;
      if (count > prev) {
        badge.classList.remove("cart-badge--bump");
        void badge.offsetWidth;
        badge.classList.add("cart-badge--bump");
      }
    }

    if (showToast && count > prev) {
      showAddedToast();
    }
  }).catch(() => {});
}
window.refreshCartBadge = refreshCartBadge;

function showAddedToast() {
  let toast = document.querySelector("[data-cart-toast]");
  if (toast) toast.remove();

  toast = document.createElement("div");
  toast.className = "cart-toast";
  toast.setAttribute("data-cart-toast", "");
  toast.innerHTML = `
    <span class="cart-toast__text">Added to bag</span>
    <a href="cart.cfm" class="cart-toast__link">View bag</a>
    <a href="checkout.cfm" class="cart-toast__link cart-toast__link--primary">Checkout</a>
  `;
  document.body.appendChild(toast);

  setTimeout(() => { toast.classList.add("cart-toast--visible"); }, 10);
  setTimeout(() => {
    toast.classList.remove("cart-toast--visible");
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}
