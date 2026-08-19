// assets/js/shell-controls.js
// Column resizers (drag-to-resize between storefront/chat and chat/trace)
// + chat minimize toggle. State persists across reloads via localStorage.

const STORAGE_KEY = "stylemart.shell.cols";

export function initShellControls() {
  const shell = document.querySelector(".app-shell");
  if (!shell) return;

  restoreState(shell);

  shell.querySelectorAll(".resizer").forEach((handle) => {
    handle.addEventListener("mousedown",  (e) => startResize(e, handle, shell));
    handle.addEventListener("touchstart", (e) => startResize(e, handle, shell), { passive: false });
    handle.addEventListener("dblclick",   () => resetColumn(handle, shell));
    handle.addEventListener("keydown",    (e) => keyboardResize(e, handle, shell));
  });

  const minBtn = document.querySelector("[data-chat-minimize]");
  if (minBtn) {
    minBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      toggleMinimize(shell, minBtn);
    });
  }

  // Click anywhere on a minimized chat column to restore.
  shell.querySelector(".app-shell__chat")?.addEventListener("click", (e) => {
    if (!shell.classList.contains("app-shell--chat-min")) return;
    if (e.target.closest("[data-chat-minimize]")) return;
    toggleMinimize(shell, minBtn);
  });

  // Trace minimize
  const traceMinBtn = document.querySelector("[data-trace-minimize]");
  if (traceMinBtn) {
    traceMinBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      toggleTraceMinimize(shell, traceMinBtn);
    });
  }

  // Click anywhere on a minimized trace to restore.
  shell.querySelector(".app-shell__trace")?.addEventListener("click", (e) => {
    if (!shell.classList.contains("app-shell--trace-min")) return;
    if (e.target.closest("[data-trace-minimize]")) return;
    toggleTraceMinimize(shell, traceMinBtn);
  });
}

// --- Resize ---------------------------------------------------------------

function startResize(e, handle, shell) {
  // Skip if disabled (e.g. left resizer when chat is minimized).
  if (handle.classList.contains("resizing")) return;
  if (handle.dataset.resize === "chat" && shell.classList.contains("app-shell--chat-min")) return;

  e.preventDefault();
  const which   = handle.dataset.resize;            // "chat" | "trace"
  const cssVar  = which === "chat" ? "--col-chat" : "--col-trace";
  const minVar  = which === "chat" ? "--col-chat-min" : "--col-trace-min";
  const maxVar  = which === "chat" ? "--col-chat-max" : "--col-trace-max";

  const startX  = pointerX(e);
  const startW  = parsePx(shell, cssVar) || (which === "chat" ? 360 : 420);
  const minW    = parsePx(shell, minVar) || 200;
  const maxW    = parsePx(shell, maxVar) || 700;

  handle.classList.add("resizing");
  document.body.style.cursor = "col-resize";
  document.body.style.userSelect = "none";

  function onMove(ev) {
    const delta = pointerX(ev) - startX;
    // Drag right shrinks the right-side column; drag left grows it.
    const next = clamp(startW - delta, minW, maxW);
    shell.style.setProperty(cssVar, `${next}px`);
  }
  function onUp() {
    document.removeEventListener("mousemove",  onMove);
    document.removeEventListener("touchmove",  onMove);
    document.removeEventListener("mouseup",    onUp);
    document.removeEventListener("touchend",   onUp);
    document.removeEventListener("touchcancel", onUp);
    document.body.style.cursor = "";
    document.body.style.userSelect = "";
    handle.classList.remove("resizing");
    persist(shell);
  }

  document.addEventListener("mousemove",  onMove);
  document.addEventListener("touchmove",  onMove, { passive: false });
  document.addEventListener("mouseup",    onUp);
  document.addEventListener("touchend",   onUp);
  document.addEventListener("touchcancel", onUp);
}

function resetColumn(handle, shell) {
  // Double-click resets the column to its default width.
  const which  = handle.dataset.resize;
  const cssVar = which === "chat" ? "--col-chat" : "--col-trace";
  const def    = which === "chat" ? 360 : 420;
  shell.style.setProperty(cssVar, `${def}px`);
  persist(shell);
}

function keyboardResize(e, handle, shell) {
  if (e.key !== "ArrowLeft" && e.key !== "ArrowRight") return;
  e.preventDefault();
  const which  = handle.dataset.resize;
  const cssVar = which === "chat" ? "--col-chat" : "--col-trace";
  const minW   = parsePx(shell, which === "chat" ? "--col-chat-min" : "--col-trace-min") || 200;
  const maxW   = parsePx(shell, which === "chat" ? "--col-chat-max" : "--col-trace-max") || 700;
  const cur    = parsePx(shell, cssVar) || 360;
  const step   = e.shiftKey ? 40 : 10;
  // Arrow Left grows the right column (less to its left); Arrow Right shrinks it.
  const next   = clamp(cur + (e.key === "ArrowLeft" ? step : -step), minW, maxW);
  shell.style.setProperty(cssVar, `${next}px`);
  persist(shell);
}

// --- Minimize -------------------------------------------------------------

function toggleMinimize(shell, btn) {
  const now = shell.classList.toggle("app-shell--chat-min");
  if (btn) {
    btn.setAttribute("aria-label", now ? "Restore chat" : "Minimize chat");
    btn.setAttribute("title",      now ? "Restore" : "Minimize");
  }
  persist(shell);
}

function toggleTraceMinimize(shell, btn) {
  const now = shell.classList.toggle("app-shell--trace-min");
  if (btn) {
    btn.setAttribute("aria-label", now ? "Restore trace" : "Minimize trace");
    btn.setAttribute("title",      now ? "Restore" : "Minimize");
  }
  persist(shell);
}

// --- Persistence ----------------------------------------------------------

function persist(shell) {
  const state = {
    chat:     parsePx(shell, "--col-chat")  || 360,
    trace:    parsePx(shell, "--col-trace") || 420,
    chatMin:  shell.classList.contains("app-shell--chat-min"),
    traceMin: shell.classList.contains("app-shell--trace-min"),
  };
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (_) { /* private mode */ }
}

function restoreState(shell) {
  let saved;
  try { saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null"); } catch (_) { saved = null; }
  if (!saved) return;
  if (saved.chat)  shell.style.setProperty("--col-chat",  `${saved.chat}px`);
  if (saved.trace) shell.style.setProperty("--col-trace", `${saved.trace}px`);
  if (saved.chatMin) shell.classList.add("app-shell--chat-min");
  if (saved.traceMin) shell.classList.add("app-shell--trace-min");
}

// --- Helpers --------------------------------------------------------------

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }

function parsePx(el, varName) {
  const raw = getComputedStyle(el).getPropertyValue(varName).trim();
  if (!raw) return 0;
  const n = parseFloat(raw);
  return Number.isFinite(n) ? n : 0;
}

function pointerX(e) {
  return e.touches && e.touches[0] ? e.touches[0].clientX : e.clientX;
}
