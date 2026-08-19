// tests/store.test.js
import { test } from "node:test";
import assert from "node:assert/strict";
import { createStore } from "../assets/js/store.js";

test("subscribers receive updates when state changes", () => {
  const store = createStore({ count: 0 });
  let seen = null;
  store.subscribe((s) => { seen = s.count; });
  store.set({ count: 5 });
  assert.equal(seen, 5);
});

test("update merges partial state", () => {
  const store = createStore({ a: 1, b: 2 });
  store.update((s) => ({ b: s.b + 1 }));
  assert.deepEqual(store.get(), { a: 1, b: 3 });
});

test("unsubscribe stops further updates", () => {
  const store = createStore({ n: 0 });
  let count = 0;
  const off = store.subscribe(() => count++);
  store.set({ n: 1 });
  off();
  store.set({ n: 2 });
  assert.equal(count, 2); // initial call + one update
});
