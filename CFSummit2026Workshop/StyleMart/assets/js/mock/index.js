import { registerMockHandlers, __setMockSSE } from "../api.js";
import { prefsHandlers } from "./handlers/prefs.js";
import { productHandlers } from "./handlers/products.js";
import { cartHandlers } from "./handlers/carts.js";
import { orderHandlers } from "./handlers/orders.js";
import { generatedHandlers } from "./handlers/generated.js";
import { inventoryHandlers } from "./handlers/inventory.js";
import { userHandlers } from "./handlers/users.js";
import { mockSSE } from "./sse/stream.js";
import { consumeFail } from "./fail.js";

let chatSessionCounter = 0;
function newSessionId() { return `csn_01H${(++chatSessionCounter).toString().padStart(8, "0")}`; }

const chatHandlers = {
  "POST /chat/sessions": () => {
    const sessionId = newSessionId();
    if (consumeFail("mcp-empty")) {
      console.warn("[mock] mcp-empty flag active — listTools will return 0");
    }
    return { sessionId, startedAt: new Date().toISOString() };
  },
  "POST /chat/sessions/:id/reset": () => ({ ok: true }),
  "GET /chat/sessions/:id/messages": () => ({ items: [] }),
  "GET /chat/sessions/:id/trace": () => ({ items: [] }),
};

export function installMocks() {
  registerMockHandlers({
    ...prefsHandlers,
    ...productHandlers,
    ...cartHandlers,
    ...orderHandlers,
    ...chatHandlers,
    ...generatedHandlers,
    ...inventoryHandlers,
    ...userHandlers,
  });
  __setMockSSE(mockSSE);
}
