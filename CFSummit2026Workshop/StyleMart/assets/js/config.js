// assets/js/config.js — version routing for the agent REST app.
// Both session AND mode are LIVE — read the chat-panel controls on each
// property access so flipping the toggle takes effect on the next
// request with no page reload. Selection precedence on first render is
// URL params (?s= , ?mode=) > persisted localStorage > defaults, so the
// last-chosen session and Lab/Ref stay put across page reloads.

const SESSION_STORAGE_KEY = "stylemart.agentRoute.session";
const MODE_STORAGE_KEY    = "stylemart.agentRoute.mode";

const search   = (typeof location !== "undefined" && location.search) || "";
const urlMode  = new URLSearchParams(search).get("mode");
const urlSess  = new URLSearchParams(search).get("s");

function readStored(key) {
  try {
    return (typeof localStorage !== "undefined" && localStorage.getItem(key)) || null;
  } catch (_) {
    return null;
  }
}

function writeStored(key, value) {
  try {
    if (typeof localStorage !== "undefined") localStorage.setItem(key, value);
  } catch (_) {
    /* localStorage unavailable (private mode / quota) — persistence is best-effort */
  }
}

const storedMode = readStored(MODE_STORAGE_KEY);
const storedSess = readStored(SESSION_STORAGE_KEY);

function readMode() {
  if (typeof document === "undefined") return "ref";
  // Legacy <select data-chat-mode> still supported.
  const sel = document.querySelector("select[data-chat-mode]");
  if (sel) return sel.value || "ref";
  // New segmented toggle: button.is-active inside [data-chat-mode-toggle].
  const active = document.querySelector("[data-chat-mode-toggle] .chat__mode-btn.is-active");
  return active?.dataset.mode || "ref";
}

export const AgentRoute = {
  get session() {
    if (typeof document === "undefined") return urlSess || storedSess || "1";
    return document.querySelector("[data-chat-session]")?.value || urlSess || storedSess || "1";
  },
  get mode() {
    return readMode();
  },
};

// Notify listeners (chat.js) that the active route changed so the chat can
// reset and re-open a session against the new session/mode.
function emitRouteChange() {
  if (typeof document === "undefined") return;
  document.dispatchEvent(new CustomEvent("chat:route-change", {
    detail: { session: AgentRoute.session, mode: AgentRoute.mode },
  }));
}

function setMode(mode, { emit = true } = {}) {
  const m = mode === "ref" ? "ref" : "lab";
  const prev = readMode();
  document.querySelectorAll("[data-chat-mode-toggle] .chat__mode-btn").forEach((btn) => {
    const on = btn.dataset.mode === m;
    btn.classList.toggle("is-active", on);
    btn.setAttribute("aria-pressed", on ? "true" : "false");
  });
  const legacy = document.querySelector("select[data-chat-mode]");
  if (legacy) legacy.value = m;
  writeStored(MODE_STORAGE_KEY, m);
  if (emit && m !== prev) emitRouteChange();
}

// Wire up segmented-toggle clicks once the DOM has it.
function wireToggle() {
  const root = document.querySelector("[data-chat-mode-toggle]");
  if (!root || root.dataset.wired) return;
  root.dataset.wired = "1";
  root.addEventListener("click", (e) => {
    const btn = e.target.closest(".chat__mode-btn");
    if (!btn) return;
    setMode(btn.dataset.mode);
  });
}

// Wire the session <select> so switching sessions re-routes the chat too.
function wireSession() {
  const sel = document.querySelector("[data-chat-session]");
  if (!sel || sel.dataset.wired) return;
  sel.dataset.wired = "1";
  sel.addEventListener("change", () => {
    writeStored(SESSION_STORAGE_KEY, sel.value);
    emitRouteChange();
  });
}

// Seed from URL params + wire up the toggle. We try synchronously
// (in case the include is already in the DOM) and again on a microtask.
if (typeof document !== "undefined") {
  const seedSess = urlSess || storedSess;
  const seedMode = urlMode || storedMode;
  const seed = () => {
    if (seedSess) {
      const sel = document.querySelector("[data-chat-session]");
      if (sel) sel.value = seedSess;
    }
    if (seedMode) setMode(seedMode, { emit: false });
    wireToggle();
    wireSession();
  };
  seed();
  if (typeof queueMicrotask === "function") queueMicrotask(seed);
}
