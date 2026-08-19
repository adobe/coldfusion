# Session 3: CFC Tools — Instructor Guide

## Overview
- **Duration:** 60 minutes
- **Learning objectives:**
  - Wire pre-built CFC tools into the agent so the LLM can take real actions
  - Understand how CF2025 discovers tool methods from CFC components
  - Observe the tool.call → tool.result event loop in the trace panel
  - See how the system prompt's tool decision ladder guides the model's choices
- **Prerequisites:** S2 complete (memory + preferences working)
- **Wow moment:** First tool call in the trace panel — ask "show me sneakers" and watch searchCatalog fire, returning real product cards from the database

## Pre-Session Checklist
- S2 Lab mode works (send preference, see persist event)
- Product catalog seeded in database (verify: "SELECT count(*) FROM products" returns rows)
- S3 config file `ai.lab.properties` has 7 tool paths listed

## Story So Far
Mira streams responses, remembers conversation context (20-message window), and extracts durable preferences (occasion, size, colors, budget). But she invents product names because she has no access to real data.

## Teaching Flow (Timeline)

### [0:00–0:10] — Concept Introduction

**Key points:**
- CFC tools are regular ColdFusion components with public methods annotated for the LLM
- The `tools` array in config lists CFC dot-paths. CF2025 instantiates each and discovers callable methods automatically.
- The system prompt's "tool decision ladder" guides WHEN the model calls which tool
- Tool execution is automatic: model decides → CF calls the CFC method → result goes back to model → model incorporates it into response
- The trace panel shows `tool.call` (what the model requested) and `tool.result` (what came back)

**The 7 tools:**
1. SearchCatalog — find products by query/filters
2. GetProductDetails — full product info by ID
3. CompareProducts — side-by-side comparison
4. GetCart — current cart contents
5. GetOrderHistory — past orders
6. AddToCart — add a product to cart
7. RemoveFromCart — remove from cart

**Talking points:**
- "In S1, Mira hallucinated a price. Now she can LOOK IT UP. Ask 'what is the price of the sky blue button down shirt?' and she calls searchCatalog, finds the real product, and gives you the actual price ($87.49)."
- "The trace panel is your window into tool behavior. Watch it light up."

**Common misconceptions:**
- "Attendees need to write the tool CFCs" — No. Tools are pre-built. You just wire the array into the agent config.
- "The model always knows which tool to call" — Not always. The decision ladder in the system prompt guides it, but LLMs can make wrong choices. Guardrails (S6) address this.
- "Tools replace the model's response" — No. The model calls a tool, gets data back, then writes a natural language response incorporating that data.

### [0:10–0:20] — Hands-On Coding

---

#### TODO-S3-1: Build the TOOLS array from config

**File:** [`api/agent/s3/lab/ChatService.cfc`](ChatService.cfc#L139)
**Find:** [`// TODO-S3-1`](AgentService.cfc#L25)

**What to explain:** "The config file already lists all 7 tool CFC paths. You just need to read that array and hand it to the agent. One line."

**Code to write:**
```cfml
var toolsConfig = cfg.tools ?: [];
```

**Common mistake:** Wrapping in extra structure. The config already provides the array in the shape CF expects.

---

#### TODO-S3-2: Wire tools into agent and set system prompt

**File:** [`api/agent/s3/lab/ChatService.cfc`](ChatService.cfc#L147)
**Find:** [`// TODO-S3-2`](AgentService.cfc#L42)

**What to explain:** "Same agent pattern as S2, but now with TOOLS. The system prompt includes a tool decision ladder that guides the model."

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

**Checkpoint:** "Save. Send 'show me sneakers' in Lab mode. Watch the trace panel — you should see `tool.call` with searchCatalog, then `tool.result` with product data, then product cards in the chat. Thumbs-up when you see product cards appear."

---

### [0:20–0:50] — Guided Experimentation

This is the exploration-heavy session. Use the remaining time for diverse query experiments.

**Experiment 1 — Search behavior:**
- "show me shirts" → searchCatalog fires
- "tell me more about that first one" → getProductDetails fires
- "compare the first two" → compareProducts fires

**Experiment 2 — Cart operations:**
- "add the navy shirt to my cart" → addToCart fires
- "what is in my cart?" → getCart fires
- "remove the shirt" → removeFromCart fires

**Experiment 3 — Order history:**
- "show me my past orders" → getOrderHistory fires
- "where is my last order?" → (no tracking yet — sets up S4 MCP)

**Experiment 4 — The hallucination test revisited:**
- "what is the price of the sky blue button down shirt?" → Now returns real price ($87.49) from searchCatalog
- Compare with S1 where the model invented a price

**Experiment 5 — Trace panel deep-dive:**
- Open the trace panel and examine a tool.call event payload. Note the tool name, arguments the model chose, and the structured result.
- "Compare your trace panel with your neighbor — do you see the same tool calls for the same queries?"

**"What happens if..." provocations:**
- "What if you remove searchCatalog from the tools array?" (Model cannot find products — reverts to hallucination)
- "What if you ask for a product that does not exist?" (searchCatalog returns empty, model says it could not find anything)
- "What if you ask to add something without specifying size/color?" (Model should ask for clarification)

**Fast-finisher challenge:** Open one of the tool CFCs (e.g., `s3/lab/tools/SearchCatalog.cfc`). Read the SQL query. Try modifying the `pageSize` default or adding a filter condition. See how it changes results.

### [0:50–1:00] — Wrap-up

**Key takeaway:** CFC tools give the LLM access to real data and real actions. You write the tool once as a CFC; the agent decides when to call it based on the system prompt's decision ladder. No hardcoded if/else routing needed.

**Bridge to next session:** "Mira can search products and manage your cart. But ask 'what is the weather in Las Vegas?' — she cannot answer. Ask 'where is my shipment?' — she has no tracking data. Session 4 adds external capabilities via MCP: live weather and logistics tracking."

**Break reminder:** Lunch break after S4.

## Troubleshooting Guide

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No tool.call events in trace | TODO-S3-1 or S3-2 incomplete | Verify TOOLS is in agent config |
| "Cannot find component" error | CFC path in config does not match filesystem | Check ai.lab.properties paths use `s3.lab.tools` prefix |
| Product cards do not render | Frontend expects specific JSON shape from tool | Verify searchCatalog returns properly (toggle to ref to compare) |
| Model calls wrong tool | System prompt decision ladder not loaded | Verify systemMessage is called with cfg.systemPrompt |
| "Variable TOOLSCONFIG is undefined" | TODO-S3-1 has syntax error | Check for missing semicolons or quotes |
| REST endpoint returns 404 | REST services not registered | Re-run [setup.cfm](../../setup/setup.cfm) |
| "Datasource not found" error | Datasource not registered | Re-run [setup.cfm](../../setup/setup.cfm) |

## Behind-Attendee Protocol
- **Signal:** No tool.call events after sending "show me sneakers"
- **30-second intervention:** "Check line ~145 in ChatService.cfc — do you have `var toolsConfig = cfg.tools ?: [];`?"
- **Rescue:** Copy TODO zone from `s3/ref/ChatService.cfc`
- **Last resort:** Toggle to ref mode

## Questions They Will Ask (With Answers)

**Conceptual questions:**

| Question | Answer |
|----------|--------|
| How does the model know WHICH tool to call? | The system prompt contains a "tool decision ladder" — explicit rules like "If user asks to see products → call searchCatalog." The model follows these instructions. |
| What if the model calls the wrong tool? | It happens. The system prompt's decision ladder reduces this, but LLMs are not perfect. In production, you would add guardrails (S6) or confirmation gates for destructive actions. |
| Why do I see tool.call then tool.result? | The agent calls the tool (emits tool.call), the CFC executes and returns data (emits tool.result), then the agent incorporates the result into its response. This loop can repeat (model may call multiple tools per turn). |

**Technical questions:**

| Question | Answer |
|----------|--------|
| Can I add my own custom tool? | Yes. Create a CFC with public functions. Add its dot-path to the `tools` array in ai.lab.properties. The agent discovers it automatically. |
| Why don't attendees write the tool CFCs? | Time constraint (60 min). The learning objective is understanding tool integration, not SQL queries. The pre-built tools are readable for reference. |
| What is the difference between read and write tools? | Read tools (searchCatalog, getProductDetails) just return data. Write tools (addToCart) modify state. In production, write tools might use a confirmation gate. |

**Architecture questions:**

| Question | Answer |
|----------|--------|
| Why put tool paths in config instead of code? | Separation of concerns. Different sessions/environments can have different tool sets without code changes. Lab and ref each have their own tool paths. |
| Can the model call multiple tools in one turn? | Yes. If you ask "add the blue shirt and show me my cart", the model may call addToCart then getCart in sequence. The trace panel shows each call. |

**Production questions:**

| Question | Answer |
|----------|--------|
| How would I prevent the model from calling addToCart without user confirmation? | Add a confirmation gate (pending action → user approves → execute). The workshop simplifies by executing all tools immediately. In production, write tools should require confirmation. |
| What about rate limiting tool calls? | CF2025 does not natively rate-limit tool calls. In production, implement rate limiting in the tool CFC itself or at the API gateway level. |

## Verification Checklist

1. Lab mode: send "show me sneakers"
2. **Trace panel:** `tool.call` (searchCatalog) → `tool.result` (product data)
3. **Chat:** Product cards appear with real product names and prices
4. Send "add the first one to my cart" → `tool.call` (addToCart) in trace
5. Send "what is in my cart?" → `tool.call` (getCart) shows the added item
