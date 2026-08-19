// assets/js/components/confirm-gate.js

export function ConfirmationGate({ pendingActionId, kind, summary, expiresAt, onConfirm, onDecline }) {
  const verb = kind === "cart-remove" ? "remove" : "add";
  const wrap = document.createElement("div");
  wrap.className = "confirm-gate";
  wrap.innerHTML = `
    <div class="confirm-gate__body">
      <strong>The assistant wants to ${verb} ${summary.itemCount} item${summary.itemCount === 1 ? "" : "s"}</strong>
      <span class="confirm-gate__sub">$${summary.subtotal.toFixed(2)} · expires in <span data-countdown>—</span></span>
    </div>
    <div class="confirm-gate__actions">
      <button class="btn-primary" data-confirm>Confirm</button>
      <button class="btn-secondary" data-decline>Decline</button>
    </div>
  `;

  const tick = () => {
    const ms = new Date(expiresAt).getTime() - Date.now();
    if (ms <= 0) {
      wrap.querySelector("[data-countdown]").textContent = "expired";
      wrap.classList.add("confirm-gate--expired");
      wrap.querySelectorAll("button").forEach((b) => (b.disabled = true));
      return;
    }
    const m = Math.floor(ms / 60000), s = Math.floor((ms % 60000) / 1000);
    wrap.querySelector("[data-countdown]").textContent = `${m}:${String(s).padStart(2, "0")}`;
  };
  tick();
  const timer = setInterval(tick, 1000);

  wrap.querySelector("[data-confirm]").addEventListener("click", () => {
    clearInterval(timer); onConfirm?.(pendingActionId);
  });
  wrap.querySelector("[data-decline]").addEventListener("click", () => {
    clearInterval(timer); onDecline?.(pendingActionId);
  });

  return wrap;
}
