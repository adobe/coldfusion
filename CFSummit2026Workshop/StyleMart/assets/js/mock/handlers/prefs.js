// assets/js/mock/handlers/prefs.js

const DEFAULT_PREFS = {
  occasion: "London tech conference",
  tripLengthDays: 5,
  climate: "cool, occasional rain",
  budget: 500,
  topSize: "M",
  jeansSize: "32",
  shoeSize: "9",
  fitPreference: "regular",
  colors: ["black", "navy", "gray", "beige"],
  fabricPreference: "easy-care",
  dislikes: ["bold patterns"],
  walkingComfort: "high",
};

let stored = { ...DEFAULT_PREFS };

export const prefsHandlers = {
  "GET /users/:id/preferences": (_, path) => {
    const userId = path.split("/")[2];
    return { userId, preferences: { ...stored }, updatedAt: "2026-05-23T09:14:00Z", schemaVersion: 1 };
  },
  "PUT /users/:id/preferences": (payload, path) => {
    const userId = path.split("/")[2];
    stored = { ...stored, ...payload };
    return { userId, preferences: { ...stored }, updatedAt: new Date().toISOString(), schemaVersion: 1 };
  },
};
