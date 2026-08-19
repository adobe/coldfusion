// assets/js/pages/account.js
import { api } from "../api.js";
import { formatDate } from "../utils/format-date.js";

export async function initAccount() {
  const root = document.querySelector("[data-account-root]");
  if (!root) return;

  try {
    const me = await api.getMe();
    const loyalty = await api.getUserLoyalty(me.userId);

    // Profile section
    const profileEl = root.querySelector("[data-profile-content]");
    profileEl.innerHTML = `
      <dl class="account-dl">
        <dt>Name</dt><dd>${me.displayName}</dd>
        <dt>Email</dt><dd>${me.email}</dd>
        <dt>Member since</dt><dd>${formatDate(me.memberSince)}</dd>
      </dl>
    `;

    // Loyalty section
    const loyaltyEl = root.querySelector("[data-loyalty-content]");
    loyaltyEl.innerHTML = `
      <div class="loyalty-card">
        <div class="loyalty-card__tier">
          <span class="loyalty-card__tier-name">${loyalty.tierName}</span>
        </div>
        <div class="loyalty-card__spend">
          <span>Total spend: <strong>$${loyalty.totalSpend.toFixed(2)}</strong></span>
        </div>
        <div class="loyalty-card__next">
          <span>Next tier: ${loyalty.nextTierId.replace("tier_", "").charAt(0).toUpperCase() + loyalty.nextTierId.replace("tier_", "").slice(1)}</span>
          <span>Spend $${loyalty.spendToNextTier.toFixed(2)} more to upgrade</span>
        </div>
        <div class="loyalty-card__progress">
          <div class="loyalty-card__bar">
            <div class="loyalty-card__fill" style="width:${Math.round((loyalty.totalSpend / (loyalty.totalSpend + loyalty.spendToNextTier)) * 100)}%"></div>
          </div>
        </div>
      </div>
    `;

    // Preferences section
    try {
      const result = await api.getPrefs(me.userId);
      const prefs = result.preferences || result;
      const prefsEl = root.querySelector("[data-prefs-content]");
      const labels = {
        occasion: "Occasion",
        tripLengthDays: "Trip Length",
        climate: "Climate",
        budget: "Budget",
        topSize: "Top Size",
        jeansSize: "Jeans Size",
        shoeSize: "Shoe Size",
        fitPreference: "Fit",
        colors: "Colors",
        fabricPreference: "Fabric",
        dislikes: "Dislikes",
        walkingComfort: "Walking Comfort",
      };
      prefsEl.innerHTML = `
        <dl class="account-dl">
          ${Object.entries(prefs)
            .filter(([k]) => labels[k])
            .map(([k, v]) => {
              const display = Array.isArray(v) ? v.join(", ") : (typeof v === "number" ? (k === "budget" ? `$${v}` : `${v} days`) : v);
              return `<dt>${labels[k]}</dt><dd>${display}</dd>`;
            }).join("")}
        </dl>
      `;
    } catch (_) {
      root.querySelector("[data-prefs-content]").innerHTML = `<p>No preferences saved yet.</p>`;
    }
  } catch (err) {
    root.innerHTML = `<p class="error">Could not load account: ${err.message}</p>`;
  }
}
