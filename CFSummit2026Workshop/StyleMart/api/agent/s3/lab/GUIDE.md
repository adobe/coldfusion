# Session 3: CFC Tools

## What You'll Build

After this session, Mira can search your real product catalog, show product details, compare items, manage your cart, and look up order history. She stops hallucinating product data because she now has tools to access the database directly.

## Story So Far
Mira streams responses (S1), remembers your conversation (20-message window), and extracts durable preferences like size, colors, and occasion (S2). But she invents product names because she has no access to real data.

## Key Concepts (Read While Instructor Presents)

- **CFC tools:** Regular ColdFusion components with public methods. CF2025 instantiates each CFC and makes its methods callable by the LLM.
- **Tool decision ladder:** A section of the system prompt that tells the model WHEN to call WHICH tool. Example: "If user asks to see products → call searchCatalog."
- **Automatic tool loop:** The model decides to call a tool → CF executes the CFC method → result goes back to the model → model writes a natural-language response using that data.
- **Trace events:** `tool.call` shows what the model requested. `tool.result` shows what came back. Watch the trace panel.

**The 7 tools available:**
1. **SearchCatalog** — find products by query/filters
2. **GetProductDetails** — full info for a product by ID
3. **CompareProducts** — side-by-side comparison
4. **GetCart** — current cart contents
5. **GetOrderHistory** — past orders for the user
6. **AddToCart** — add a product (with size/color)
7. **RemoveFromCart** — remove an item from cart

## Your Workspace

**Files you will edit:**
- [`StyleMart/api/agent/s3/lab/AgentService.cfc`](AgentService.cfc#L1) — 2 TODOs (tools + agent wiring)

**Read-only reference:**
- [`StyleMart/api/agent/s3/ref/ChatService.cfc`](../ref/ChatService.cfc#L1)
- [`StyleMart/api/agent/s3/config/ai.lab.properties`](../config/ai.lab.properties#L23) (tools array at line 24)
- [`StyleMart/api/agent/s3/config/system-prompt.txt`](../config/system-prompt.txt#L1) (tool decision ladder)
- `StyleMart/api/agent/s3/lab/tools/*.cfc` (pre-built tool implementations)

## The "Lab Fails, Ref Works" Beat

Before you write code:
1. Toggle to **Lab** mode. Send "show me sneakers" — Mira responds with generic text (no product cards, no tool.call in trace).
2. Toggle to **Ref** mode. Same message — product cards appear, trace shows `tool.call` → `tool.result`.
3. **Your job:** Make Lab work like Ref by filling 2 TODOs.

## Catching Up

If you are starting fresh or fell behind:
1. Toggle to Ref mode — verify tools work (send "show me sneakers", see product cards)
2. Copy `s2/ref/ChatService.cfc` → `s2/lab/ChatService.cfc` and `s2/ref/Memory.cfc` → `s2/lab/Memory.cfc` to catch up on S2

## Step-by-Step Instructions

### Step 1: Build the TOOLS array from config

**File:** [`api/agent/s3/lab/AgentService.cfc`](AgentService.cfc#L15)
**Find:** [`// TODO-S3-1`](AgentService.cfc#L25) — `var toolsConfig = [] /* TODO-S3-1 */;`

**What this does:** Reads the tool CFC paths from the config file. The `ai.lab.properties` already declares all 7 tools as an array of `{cfc: "dot.path"}` objects.

**Code to write:**
```cfml
var toolsConfig = cfg.tools ?: [];
```

**Save the file.**

---

### Step 2: Wire tools into the agent

**File:** [`api/agent/s3/lab/AgentService.cfc`](AgentService.cfc#L27)
**Find:** [`// TODO-S3-2`](AgentService.cfc#L42) — `var sessionAgent = "" /* TODO-S3-2 */;`

**What this does:** Creates the agent with all capabilities: model, streaming, memory, AND tools. Sets the system prompt once (includes the tool decision ladder).

**Code to write:**
```cfml
var sessionAgent = agent( {
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC,
  CHATMEMORY:       memoryConfig,
  TOOLS:            toolsConfig
} );
sessionAgent.systemMessage(
  cfg.systemPrompt, arguments.userId
);
```

**Save the file. Verify:** Send "show me sneakers" in Lab mode. In the trace panel, you should see `tool.call` (searchCatalog) followed by `tool.result`. Product cards should appear in the chat response.

---

## Try It Out

| What to type in chat | What you should see | Why it works |
|---------------------|--------------------|--------------| 
| "show me sneakers" | Product cards with real names/prices | searchCatalog tool queries the database |
| "tell me more about the first one" | Detailed product info (materials, sizes) | getProductDetails tool called |
| "compare the first two products" | Side-by-side comparison table | compareProducts tool called |
| "add the navy one to my cart, size M" | Confirmation message | addToCart tool called |
| "what is in my cart?" | Cart contents with the item you added | getCart tool called |
| "show me my past orders" | Order history list | getOrderHistory tool called |
| "what is the price of the sky blue button down shirt?" | Real price from database ($87.49) | No more hallucination — tool provides real data |

## Experiments (Core Learning Activity)

S3 has only 2 TODOs — coding takes ~10 minutes. The remaining time is for guided experimentation with tool behavior.

### E1 — Search Behavior Cascade
Send these in sequence, watching the trace panel between each:
- "show me shirts" → trace: `tool.call(searchCatalog)` → product cards render
- "tell me more about that first one" → trace: `tool.call(getProductDetails)`
- "compare the first two" → trace: `tool.call(compareProducts)` → comparison table

### E2 — Cart Operations End-to-End
- "add the navy shirt to my cart, size M" → trace: `tool.call(addToCart)`
- "what is in my cart?" → trace: `tool.call(getCart)` → cart contents shown
- "remove the shirt" → trace: `tool.call(removeFromCart)`

### E3 — The Hallucination Fix (Revisit S1 E4)
Send: "What is the price of the sky blue button down shirt?" In S1, the model invented a price. Now: the model calls searchCatalog, finds the real product, returns the REAL price ($87.49) from the database. This is the S3 value proposition.

### E4 — Remove a Tool
Edit `api/agent/s3/config/ai.lab.properties`, remove the "AddToCart" entry from the tools array. Save. Click the **reset** button (↻) in the chat header to create a fresh agent with the new config. Then send "add that to my cart". Observe: Mira says she cannot perform cart actions. Lesson: tool availability is config-driven — no code change needed to enable/disable capabilities.
**Restore:** Add the tool entry back and click reset again.

### E5 — Trace Panel Deep-Dive
Send "show me jackets under $250". Examine the `tool.call` row in the trace panel — it now shows the arguments the model chose (query, category, priceMax, etc.). Compare with your neighbor: do you see the same tool arguments for the same query?

### E6 — Multi-Tool Turn
Send "add the first jacket to my cart and then show me my cart". Watch the trace — the model calls addToCart then getCart in sequence. One user message can trigger multiple tool calls.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No tool.call events in trace panel | Check TODO-S3-1 and TODO-S3-2 are both filled in. TOOLS must be in the agent config. |
| "Cannot find component" error | The CFC path in config does not match the filesystem. Verify `ai.lab.properties` uses `api.agent.s3.lab.tools.SearchCatalog` (not ref). |
| Product cards do not appear | The search returned results but the frontend did not render them. Check that the tool.result payload has product data. Toggle to Ref to compare. |
| Model does not call any tools | System prompt may not be loaded. Check that `systemMessage()` is called with `cfg.systemPrompt` in Step 2. |

## Frequently Asked Questions

| Question | Answer |
|----------|--------|
| How does the model decide which tool to call? | The system prompt has a "tool decision ladder" — explicit rules for when to use each tool. The model follows these instructions. |
| Can I add my own custom tool? | Yes. Create a CFC with public methods, add its dot-path to the tools array in ai.lab.properties. The agent discovers it on next session creation. |
| Why are there 7 tools but I only wrote 2 lines of code? | The tools are pre-built CFCs. You just wire the config array into the agent. CF2025 handles instantiation and method binding automatically. |
| What if the model hallucinates a product ID that does not exist? | The tool CFC queries the database. If the ID does not exist, it returns an empty result. The model then tells the user it could not find that product. |
| Can the model call multiple tools in one turn? | Yes. Complex queries may trigger 2-3 tool calls in sequence. Watch the trace panel — each call/result pair appears in order. |
| Why does addToCart work without confirmation? | Workshop simplification. In production, write operations should use a confirmation gate (pending action → user approval → execution). |

## What's Next

Mira can search products and manage your cart using local CFC tools. But ask "what is the weather in Las Vegas for my trip?" — she cannot answer. Ask "where is my shipment?" — no tracking data. Session 4 adds external capabilities via MCP: a live weather service (Java) and a logistics tracker (CFML).
