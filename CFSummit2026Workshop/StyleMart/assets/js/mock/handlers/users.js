// assets/js/mock/handlers/users.js
import shoppersData from "../fixtures/shoppers.json" with { type: "json" };

// Active mock user. In live mode this resolves from the CFML session
// (see §4.4 cflogin model in stylemart-api-contract-and-db-schema.md).
// The mock layer ignores credentials and binds to usr_demo_001 by default;
// dev can switch by setting sessionStorage.setItem("stylemart.mock.userId", "usr_demo_003").
function activeUserId() {
  try {
    const override = sessionStorage.getItem("stylemart.mock.userId");
    if (override && shoppersData[override]) return override;
  } catch (_) {}
  return "usr_demo_001";
}

function tierName(tierId) {
  return tierId === "tier_gold" ? "Gold" : tierId === "tier_silver" ? "Silver" : "Bronze";
}

function shape(user, id) {
  return {
    userId: id,
    username: user.username,
    displayName: user.displayName,
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
    loyaltyTierId: user.loyaltyTierId,
    loyaltyTierName: tierName(user.loyaltyTierId),
    memberSince: user.memberSince,
    activeCartId: "crt_demo_jordan",
  };
}

export const userHandlers = {
  "GET /me": () => {
    const id = activeUserId();
    return shape(shoppersData[id], id);
  },

  "GET /users/:id": (_, path) => {
    const id = path.split("/")[2];
    const user = shoppersData[id];
    if (!user) throw problem(404, "User not found", id);
    return shape(user, id);
  },

  // §4.4 cflogin endpoints — mock implementations (no real auth, just shape)
  "GET /auth/session": () => {
    let hasSession = false;
    try { hasSession = !!sessionStorage.getItem("stylemart.mock.userId"); } catch (_) {}
    if (!hasSession) return { authenticated: false };
    const id = activeUserId();
    const user = shoppersData[id];
    return user ? {
      authenticated: true,
      userId: id,
      username: user.username,
      displayName: user.displayName,
      sessionExpiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
    } : { authenticated: false };
  },

  "POST /auth/login": ({ username, password }) => {
    if (!username || !password) {
      const err = problem(422, "Validation failed", "username and password are required");
      err.code = "validation_failed";
      throw err;
    }
    const entry = Object.entries(shoppersData).find(([, u]) => u.username === String(username).toLowerCase());
    if (!entry) {
      const err = problem(401, "Invalid credentials", "username or password is incorrect");
      err.code = "invalid_credentials";
      throw err;
    }
    const [id, user] = entry;
    try { sessionStorage.setItem("stylemart.mock.userId", id); } catch (_) {}
    return {
      userId: id,
      username: user.username,
      displayName: user.displayName,
      loyaltyTierId: user.loyaltyTierId,
      sessionExpiresAt: new Date(Date.now() + 8 * 60 * 60 * 1000).toISOString(),
    };
  },

  "POST /auth/logout": () => {
    try { sessionStorage.removeItem("stylemart.mock.userId"); } catch (_) {}
    return { loggedOut: true };
  },

  "POST /auth/register": ({ username, password, displayName, email }) => {
    if (!username || !password || !displayName) {
      const err = problem(422, "Validation failed", "username, password, and displayName are required");
      err.code = "validation_failed";
      throw err;
    }
    const lower = String(username).toLowerCase();
    if (Object.values(shoppersData).some((u) => u.username === lower)) {
      const err = problem(409, "Username taken", lower);
      err.code = "username_taken";
      throw err;
    }
    // Mock register: returns a synthetic user shape but does not persist
    // (next page reload reverts; the live cflogin backend will persist).
    const id = `usr_demo_${String(Object.keys(shoppersData).length + 1).padStart(3, "0")}`;
    return {
      userId: id,
      username: lower,
      displayName,
      email: email || null,
      loyaltyTierId: "tier_bronze",
      createdAt: new Date().toISOString(),
    };
  },
};

function problem(status, title, detail) {
  const err = new Error(title);
  Object.assign(err, { status, title, detail, type: "about:blank" });
  return err;
}
