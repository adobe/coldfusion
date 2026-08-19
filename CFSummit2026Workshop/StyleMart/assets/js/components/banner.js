// assets/js/components/banner.js
export function showBanner({ kind = "warn", text, durationMs = 4000 } = {}) {
  let host = document.querySelector("[data-banner-host]");
  if (!host) {
    host = document.createElement("div");
    host.setAttribute("data-banner-host", "");
    host.className = "banner-host";
    document.body.appendChild(host);
  }
  const el = document.createElement("div");
  el.className = `banner banner--${kind}`;
  el.textContent = text;
  host.appendChild(el);
  if (durationMs) setTimeout(() => el.remove(), durationMs);
  return () => el.remove();
}
