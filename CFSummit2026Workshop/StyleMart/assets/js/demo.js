// assets/js/demo.js
import { api } from "./api.js";
import { appStore } from "./store.js";

const DEMO_PROMPT =
  "I'm traveling to London for a 5-day tech conference in November. " +
  "I need a smart-casual capsule wardrobe, comfortable walking shoes, and a jacket. " +
  "Keep it under $500. I prefer neutral colors, easy-care fabrics, size M tops, " +
  "size 32 jeans, and shoes that are comfortable for walking.";

export async function runLondonDemo() {
  const input = document.querySelector("[data-chat-form] input[name=text]");
  const form  = document.querySelector("[data-chat-form]");
  if (!input || !form) return;

  // Wait until chat session is open.
  await new Promise((resolve) => {
    if (appStore.get().sessionId) return resolve();
    const off = appStore.subscribe((s) => { if (s.sessionId) { off(); resolve(); } });
  });

  input.value = DEMO_PROMPT;
  form.dispatchEvent(new Event("submit", { cancelable: true, bubbles: true }));
}
