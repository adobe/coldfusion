import { api, API_CONFIG } from "../api.js";
import { appStore } from "../store.js";

export function initLogin() {
  const loginForm = document.getElementById("login-form");
  const registerForm = document.getElementById("register-form");
  if (!loginForm || !registerForm) return;

  // Toggle between forms
  document.querySelectorAll("[data-show]").forEach((link) => {
    link.addEventListener("click", (e) => {
      e.preventDefault();
      const target = link.dataset.show;
      loginForm.classList.toggle("auth-form--hidden", target !== "login");
      registerForm.classList.toggle("auth-form--hidden", target !== "register");
      clearErrors();
    });
  });

  // Login
  loginForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const username = loginForm.querySelector("[name=username]").value.trim();
    const password = loginForm.querySelector("[name=password]").value;
    const errEl = document.getElementById("login-error");
    errEl.textContent = "";

    if (!username || !password) {
      errEl.textContent = "Username and password are required.";
      return;
    }

    const btn = loginForm.querySelector("button[type=submit]");
    btn.disabled = true;
    btn.textContent = "Signing in...";

    try {
      const result = await api.login(username, password);
      API_CONFIG.shopperId = result.userId;
      appStore.set({ shopperId: result.userId });
      sessionStorage.setItem("stylemart.authenticated", "true");
      const next = new URLSearchParams(location.search).get("next");
      window.location.href = next || "index.cfm";
    } catch (err) {
      if (err.code === "invalid_credentials") {
        errEl.textContent = "Invalid username or password.";
      } else if (err.code === "validation_failed") {
        errEl.textContent = err.detail || "Please check your inputs.";
      } else {
        errEl.textContent = "Something went wrong. Please try again.";
      }
    } finally {
      btn.disabled = false;
      btn.textContent = "Sign in";
    }
  });

  // Register
  registerForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const username = registerForm.querySelector("[name=username]").value.trim();
    const displayName = registerForm.querySelector("[name=displayName]").value.trim();
    const email = registerForm.querySelector("[name=email]").value.trim();
    const password = registerForm.querySelector("[name=password]").value;
    const errEl = document.getElementById("register-error");
    errEl.textContent = "";

    if (!username || !password || !displayName) {
      errEl.textContent = "Username, display name, and password are required.";
      return;
    }

    if (password.length < 8) {
      errEl.textContent = "Password must be at least 8 characters.";
      return;
    }
    if (!/[a-zA-Z]/.test(password) || !/[0-9]/.test(password)) {
      errEl.textContent = "Password must contain at least 1 letter and 1 digit.";
      return;
    }

    const btn = registerForm.querySelector("button[type=submit]");
    btn.disabled = true;
    btn.textContent = "Creating account...";

    try {
      await api.register({ username, password, displayName, email: email || undefined });
      // Per contract: session is NOT auto-established after register — show login
      loginForm.classList.remove("auth-form--hidden");
      registerForm.classList.add("auth-form--hidden");
      const successEl = document.getElementById("login-error");
      successEl.textContent = "Account created! Sign in with your new credentials.";
      successEl.classList.add("auth-error--success");
    } catch (err) {
      if (err.code === "username_taken") {
        errEl.textContent = "That username is already taken.";
      } else if (err.code === "validation_failed") {
        errEl.textContent = err.detail || "Please check your inputs.";
      } else {
        errEl.textContent = "Something went wrong. Please try again.";
      }
    } finally {
      btn.disabled = false;
      btn.textContent = "Create account";
    }
  });
}

function clearErrors() {
  document.querySelectorAll(".auth-error").forEach((el) => {
    el.textContent = "";
    el.classList.remove("auth-error--success");
  });
}
