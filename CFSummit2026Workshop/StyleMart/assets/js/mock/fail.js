// assets/js/mock/fail.js — reads ?fail=*** flags once at load.

const flags = new Set();
if (typeof location !== "undefined") {
  const params = new URLSearchParams(location.search);
  for (const v of params.getAll("fail")) flags.add(v);
}

export function shouldFail(key) { return flags.has(key); }
export function consumeFail(key) {
  if (flags.has(key)) { flags.delete(key); return true; }
  return false;
}
export function listFails() { return [...flags]; }
