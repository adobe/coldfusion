// assets/js/store.js — minimal pub/sub store.

export function createStore(initial = {}) {
  let state = { ...initial };
  const subs = new Set();

  function get() { return state; }

  function set(next) {
    state = { ...state, ...next };
    subs.forEach((fn) => fn(state));
  }

  function update(reducer) {
    set(reducer(state));
  }

  function subscribe(fn) {
    subs.add(fn);
    fn(state); // immediate
    return () => subs.delete(fn);
  }

  return { get, set, update, subscribe };
}

// App-wide singleton.
export const appStore = createStore({
  cartCount: 0,
  cartId: "",
  shopperId: "usr_demo_001",
  sessionId: null,
  viewing: "home",
  filter: {},
  productIds: [],
  pendingActionId: null,
  traceEvents: [],
});

export function getUiContext() {
  const s = appStore.get();
  return {
    viewing: s.viewing,
    cartId:  s.cartId,
    filter:  s.filter,
    productIds: s.productIds,
  };
}
