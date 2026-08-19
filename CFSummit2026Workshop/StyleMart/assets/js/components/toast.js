// assets/js/components/toast.js
export function toast({ kind = "info", text, durationMs = 3000 } = {}) {
  let host = document.querySelector("[data-toast-host]");
  if (!host) {
    host = document.createElement("div");
    host.setAttribute("data-toast-host", "");
    host.className = "toast-host";
    document.body.appendChild(host);
  }
  const el = document.createElement("div");
  el.className = `toast toast--${kind}`;
  el.textContent = text;
  host.appendChild(el);
  if (durationMs) setTimeout(() => el.remove(), durationMs);
}
