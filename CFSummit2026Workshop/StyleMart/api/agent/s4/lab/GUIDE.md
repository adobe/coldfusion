# Session 4: MCP (Model Context Protocol)

## What You'll Build

After this session, Mira connects to external services via MCP: a live weather forecast (Java-based) and a logistics tracker (CFML-based). She uses weather data to recommend climate-appropriate clothing and tracks your shipments in real time.

## Story So Far
Mira streams responses (S1), remembers context and preferences (S2), and uses 7 CFC tools to search products, manage carts, and look up orders (S3). But she cannot check weather or track shipments.

## Key Concepts (Read While Instructor Presents)

- **MCP (Model Context Protocol):** A standard protocol for connecting LLMs to external capabilities. Like USB for AI — any compatible server works regardless of language.
- **CFC tools vs. MCP tools:** CFC tools run in the same JVM. MCP tools communicate over a protocol with external processes (stdio or HTTP).
- **Application-scoped clients:** MCP handshake is expensive (10-15 seconds for JVM cold start). Clients are created ONCE and reused across all sessions.
- **Two transports:** stdio (launches subprocess, communicates via stdin/stdout) and HTTP (SSE-based remote endpoint).
- **Config format:** S4 uses `.properties` files (key=value pairs) loaded via `getPropertyFile()` — NOT JSON.

**MCP servers available:**
1. **weather-live** — Java JAR, stdio transport. Tools: getWeatherForecastByCity, getWeatherForecastByLocation, getAlerts
2. **prologics-logistics** — CFML, HTTP transport. Tools: trackShipment, getDeliveryEta

## Your Workspace

**Files you will edit:**
- [`StyleMart/api/agent/s4/lab/AgentService.cfc`](AgentService.cfc) — 4 TODOs

**Read-only reference:**
- [`StyleMart/api/agent/s4/ref/AgentService.cfc`](../ref/AgentService.cfc)
- [`StyleMart/api/agent/s4/config/ai.lab.properties`](../config/ai.lab.properties)
- [`StyleMart/api/agent/s4/config/mcp-servers.json`](../config/mcp-servers.json)
- [`StyleMart/api/agent/s4/config/system-prompt.txt`](../config/system-prompt.txt) (+ weather extension)

**MCP servers (external services):**
- [`externalservices/prologics/mcp/prologics-mcp-server.cfm`](../../../../../externalservices/prologics/mcp/prologics-mcp-server.cfm) — logistics MCP server (tools + prompts, BasicAuth)
- [`externalservices/prologics/config/logistics-shipment-status-prompt.txt`](../../../../../externalservices/prologics/config/logistics-shipment-status-prompt.txt) — server-hosted prompt template
- [`StyleMart/api/agent/s4/config/mcp-servers.json`](../config/mcp-servers.json) — resolved runtime config (auto-generated from template)

## Warm Up: Scratchpad (5 minutes)

Open [`scratchpad/mcpclient.cfm`](scratchpad/mcpclient.cfm) in your browser. It uses only `writeDump()` — no UI.

```
http://localhost:8501/CFSummit2026Workshop/StyleMart/api/agent/s4/lab/scratchpad/mcpclient.cfm
```

This scratchpad demonstrates three MCP features: **tools**, **capabilities**, and **prompts**.

### Server side ([`scratchpad/mcpserver.cfm`](scratchpad/mcpserver.cfm))

The `MCPServer()` config declares:

- **`capabilities`** — tells clients which features this server supports:
  ```cfml
  capabilities: { tools: true, prompts: true, resources: false }
  ```
  Clients use `isPromptsSupported()` / `isToolsSupported()` to check before calling.

- **`tools`** — array of `{cfc: "dot.path"}` entries. CF introspects each CFC's `remote` methods and registers them as callable tools. The method `hint` becomes the tool description for the LLM.

- **`prompts`** — array of reusable prompt templates. Each has a `name`, `description`, `arguments[]`, and a `template` string with `{placeholder}` tokens that get substituted when a client calls `getPrompt()`.

### Client side ([`scratchpad/mcpclient.cfm`](scratchpad/mcpclient.cfm))

The client demonstrates three API calls:

1. **`listTools()`** — discovers available tools from the server
2. **`callTool({name, arguments})`** — invokes `getShipmentStatus` with an orderId
3. **`getPrompt({name, arguments})`** — fetches the `shipment_delay_notice` prompt template with arguments substituted, returns a rendered messages array

Change `orderId` to `ord_002` or `ord_003` to see different shipment statuses.
Change `orderId` and  `reason` to see different prompts.


---

## How MCP Calls Flow (Shipment Status Example)

```
User: "where is my last order?"
        │
        ▼
┌───────────────────────────────────┐
│  agent.chat(prompt)               │
│    → LLM calls trackShipment      │
└───────────────┬───────────────────┘
                │
                ▼
┌───────────────────────────────────┐
│  MCPClient                        │
│    → HTTP POST to prologics URL   │
│    → Basic auth header attached   │
└───────────────┬───────────────────┘
                │
                ▼
┌───────────────────────────────────┐
│  prologics-mcp-server.cfm        │
│    → validates credentials        │
│    → ShipmentTool.trackShipment() │
│    → returns shipment JSON        │
└───────────────┬───────────────────┘
                │
                ▼
┌───────────────────────────────────┐
│  LLM receives tool result         │
│    → generates reply → streams    │
└───────────────────────────────────┘
```

---

## The "Lab Fails, Ref Works" Beat

Before you write code:
1. Toggle to **Lab** mode. Send "what is the weather in Las Vegas?" — no weather data, no `mcp.call` in trace.
2. Toggle to **Ref** mode. Same message (first call takes ~10-15s) — live weather data returns, trace shows `mcp.call` → `mcp.result`.
3. **Your job:** Make Lab work like Ref by filling 3 TODOs.

## Catching Up

If you are starting fresh or fell behind:
1. Toggle to Ref mode — verify MCP works (send "what is the weather in Las Vegas?")
2. For S3 catch-up: copy `s3/ref/ChatService.cfc` → `s3/lab/ChatService.cfc`

## Step-by-Step Instructions

### Step 1: Initialize the MCP client pool

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc)
**Find:** `// TODO-S4-1` — `var mcpClients = [] /* TODO-S4-1 */;`

**What this does:** Gets or creates application-scoped MCP clients. The helper handles the expensive initialization (JVM startup, network handshake) once and caches the result.

**Code to write:**
```cfml
var mcpClients = getOrCreateMcpClients(cfg);
```

**Save the file.**

---

### Step 2: Build the TOOLS array with MCP clients

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc)
**Find:** `// TODO-S4-2` — `var toolsConfig = [] /* TODO-S4-2 */;`

**What this does:** Combines MCP tools (external) and CFC tools (local) into a single array. MCP clients go first as a `{MCPCLIENT: [...]}` entry, then local CFC tools from config.

**Code to write:**
```cfml
var toolsConfig = buildToolsConfig(
  cfg, mcpClients
);
```

**Save the file.**

---

### Step 3: Assemble the agent with all capabilities

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc)
**Find:** `// TODO-S4-3` — `var sessionAgent = "" /* TODO-S4-3 */;`

**What this does:** Creates the agent with model, streaming, memory, and combined tools (CFC + MCP). Sets the system prompt which includes weather and logistics guidance extensions.

**Code to write:**
```cfml
var sessionAgent = agent({
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC,
  CHATMEMORY:       memoryConfig,
  TOOLS:            toolsConfig
});
sessionAgent.systemMessage(
  cfg.systemPrompt, arguments.userId
);
```

**Save the file.**

---

### Step 4: Create the MCPClient from config

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc)
**Find:** `// TODO-S4-4` — `application.s4McpClients = [] /* TODO-S4-4 */;`

**What this does:** Bulk-loads all MCP servers declared in `mcp-servers.json` (weather via stdio, prologics via HTTP with BasicAuth). The `configFile` option reads the JSON and initializes one client per server entry.

**Code to write:**
```cfml
application.s4McpClients = MCPClient({
  configFile: mcpConfigPath,
  initializationTimeout: 40,
  requestTimeout: 20
});
```

**Save the file. Verify:** Send "what is the weather in Las Vegas?" in Lab mode. The first call takes 10-15 seconds (JVM cold start — this is normal). You should see `mcp.call` in the trace panel, then weather data in the response.

---

## Try It Out

| What to type in chat | What you should see | Why it works |
|---------------------|--------------------|--------------| 
| "what is the weather in Las Vegas?" | Temperature and conditions | weather-live MCP returns forecast |
| "I need an outfit for a conference in Las Vegas" | Weather check then product recommendations for hot climate | System prompt tells Mira to check weather before recommending |
| "show me my past orders" | Order history list | getOrderHistory CFC tool (same as S3) |
| "where is my last order?" | Shipment tracking status and ETA | trackShipment + getDeliveryEta MCP tools |

**Note:** The first weather call takes 10-15 seconds (Java JVM starting up). Subsequent calls are fast (<1 second).

## Experiments (Core Learning Activity)

### E1 — Weather-Driven Recommendations (The Main Event)
Send: "I'm in Las Vegas next Monday for three days, what should I pack?"
**Expected trace:** `mcp.call(weather/getWeatherForecast)` → weather result → `tool.call(searchCatalog)` → product cards.
**Expected response:** Temperature-aware recommendations ("Las Vegas looks 38°C and dry — try a breathable linen shirt, lightweight chinos, and sunglasses").

### E2 — Before/After Comparison
Without MCP (S3), the same "Las Vegas trip" prompt gave generic suggestions with no weather awareness. Now the model checks REAL forecast data first. The trace panel shows the difference: `mcp.call(weather)` appears before any product search.

### E3 — Logistics Tracking
Send: "show me my past orders" (getOrderHistory CFC fires), then "where is my last order?"
**Expected:** `mcp.call(trackShipment)` → shipping status, carrier, estimated delivery date.

### E4 — Cold Start vs. Warm Path
The first weather call took 10-15 seconds (JVM cold start). Send another weather query now — it should respond in <1 second. This demonstrates why MCP clients are application-scoped (pay startup cost once).

### E5 — Trace Panel Comparison
Compare CFC tool events (`tool.call`/`tool.result`) with MCP events (`mcp.call`/`mcp.result`). Note the different event type prefixes. Both are "tools" from the model's perspective, but the trace distinguishes local from external.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Weather call hangs for >30 seconds | JVM cold start is slow. Wait up to 30s. If timeout, check JAR path in mcp-servers-template.json. |
| No mcp.call events in trace | Check TODO-S4-1 — verify `getOrCreateMcpClients(cfg)` is called. |
| "MCPClient is not a function" error | CF AI module may not be enabled. Ask instructor for help. |
| Weather works but logistics does not | Check that prologics MCP endpoint is running. Toggle to Ref to compare. |
| CFC tools (search, cart) stopped working | Verify TODO-S4-2 uses `buildToolsConfig(cfg, mcpClients)` which includes BOTH MCP and CFC tools. |

## Frequently Asked Questions

| Question | Answer |
|----------|--------|
| Why does the first weather call take so long? | The weather MCP server is a Java JAR. First call launches the JVM (~10s). Subsequent calls are fast (<1s) because the process stays running. |
| What is the difference between MCP and CFC tools? | CFC tools run in the same JVM (fast, local). MCP tools communicate over a protocol with external services in any language (Java, Python, CFML). MCP is a standard. |
| Why .properties format instead of JSON? | Demonstrates that CF2025 supports multiple config formats. Real enterprise apps often use .properties (Java ecosystem). The AI primitives are format-agnostic. |
| Can I add my own MCP server? | Yes. Add an entry to `mcp-servers-template.json` with transport type, command/url, and env vars. The agent discovers all tools from all registered servers automatically. |
| What happens if an MCP server crashes? | The agent catches errors gracefully. The conversation continues without that data. The model falls back to general advice. |
| Why are MCP clients application-scoped? | The handshake (especially stdio JVM launch) is expensive. Application scope means the cost is paid once per CF server lifetime, not per-request. |
| What are the {{PORT}} and {{WEBROOT}} in the template? | Placeholders resolved at runtime by `resolveMcpConfig()`. This makes the config portable across different machines/environments. |

## What's Next

Mira has tools (CFC) and external capabilities (MCP). But ask "what is your return policy?" — she cannot answer (not in the database). Ask "do reviewers say this runs small?" — she does not know. Session 5 adds RAG: vector search over policies, reviews, and catalog descriptions for context-enriched responses.
