// assets/js/mock/handlers/generated.js
import assets from "../fixtures/assets.json" with { type: "json" };

export const generatedHandlers = {
  "GET /generated/:id": (_, path) => {
    const id = path.split("/").pop();
    const a = assets[id];
    if (!a) throw problem(404, "Asset not found", id);
    return { ...a };
  },
  "POST /generated/recovery-email":   () => ({ ...assets.gen_email_jordan_london }),
  "POST /generated/landing-section":  () => ({ ...assets.gen_landing_jordan_london }),
  "POST /generated/upsell-pitch":     () => ({ ...assets.gen_upsell_jordan_london }),
};

function problem(status, title, detail) {
  const err = new Error(title);
  Object.assign(err, { status, title, detail });
  return err;
}
