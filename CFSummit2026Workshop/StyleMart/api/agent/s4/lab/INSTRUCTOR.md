# Session 4: MCP (Model Context Protocol) — Instructor Guide

## Overview
- **Duration:** 60 minutes
- **Learning objectives:**
  - Add external capabilities via MCP (Model Context Protocol) clients
  - Understand the difference between local CFC tools and protocol-based MCP tools
  - Configure application-scoped MCP client pools (expensive handshake, initialize once)
  - Observe `mcp.call` / `mcp.result` events in the trace panel
- **Prerequisites:** S3 complete (CFC tools working)
- **Wow moment:** Ask "I need an outfit for a conference in Las Vegas" — live weather data comes back (temperature, conditions) and Mira recommends breathable fabrics based on actual forecast

## Pre-Session Checklist
- S3 Lab mode works (tool.call events visible)
- Weather JAR exists: `externalservices/weather/live/target/mcp-weather-stdio-server.jar`
- Prologics MCP endpoint responds: `http://localhost:8500/CFSummit2026Workshop/externalservices/prologics/mcp/prologics-mcp-server.cfm`
- S4 config `ai.lab.properties` has valid tool and MCP paths

## Story So Far
Mira streams responses, remembers context, extracts preferences, and uses 7 CFC tools to search products, manage carts, and look up orders. But she cannot check weather for travel recommendations or track shipments.

## Teaching Flow (Timeline)

### [0:00–0:10] — Concept Introduction

**Key points:**
- MCP = Model Context Protocol — a standard for connecting LLMs to external capabilities
- CFC tools run in-process (same JVM). MCP tools communicate over a protocol (stdio or HTTP) with external services in any language.
- Two transports: stdio (launches a subprocess, communicates over stdin/stdout) and HTTP (SSE-based remote endpoint)
- MCP clients are APPLICATION-scoped because handshake is expensive (~10-15s for JVM cold start)
- S4 config uses `.properties` format (key=value) loaded via `getPropertyFile()` — not JSON

**The 3 MCP servers:**
1. `weather-live` — Java JAR via stdio. Tools: getWeatherForecastByCity, getWeatherForecastByLocation, getAlerts
2. `prologics-logistics` — CFML MCP via HTTP. Tools: trackShipment, getDeliveryEta

**Talking points:**
- "MCP is like USB for AI — a standard plug that works with any compatible server, regardless of language."
- "The weather service is a Java JAR. The logistics service is pure CFML. Both connect via the same MCP protocol. The model does not know or care what language they use."
- "First weather call takes ~10-15 seconds (JVM cold start). This is normal. Subsequent calls are fast."

**Common misconceptions:**
- "MCP replaces CFC tools" — No. They coexist. MCP adds EXTERNAL capabilities; CFC tools handle local operations. The tools array combines both.
- "Each session starts a new MCP connection" — No. MCP clients are application-scoped. The handshake cost is paid once per CF server lifetime.
- "S4 uses JSON config like S3" — No. S4 uses `.properties` format loaded via `getPropertyFile()`.

### [0:10–0:25] — Hands-On Coding

---

#### TODO-S4-1: Initialize MCP client pool

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc#L20)
**Find:** [`// TODO-S4-1`](AgentService.cfc#L25)

**What to explain:** "MCP clients are expensive to create (JVM startup, network handshake). We create them once in application scope and reuse across sessions. The helper method `getOrCreateMcpClients` handles the double-check locking pattern."

**Code to write:**
```cfml
var mcpClients = getOrCreateMcpClients(cfg);
```

---

#### TODO-S4-2: Build the TOOLS array with MCP first

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc#L27)
**Find:** [`// TODO-S4-2`](AgentService.cfc#L32)

**What to explain:** "The tools array has two parts: MCP clients (as a single struct with key MCPCLIENT) go FIRST, then local CFC tools from config. The helper `buildToolsConfig` handles this shape."

**Code to write:**
```cfml
var toolsConfig = buildToolsConfig(
  cfg, mcpClients
);
```

---

#### TODO-S4-3: Assemble the agent

**File:** [`api/agent/s4/lab/AgentService.cfc`](AgentService.cfc#L34)
**Find:** [`// TODO-S4-3`](AgentService.cfc#L45)

**What to explain:** "Same pattern as S3 — model, streaming, memory, tools — but now tools includes MCP capabilities. System prompt includes weather and logistics extensions."

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

**Checkpoint:** "Save. Send 'what is the weather in Las Vegas?' in Lab mode. The first call takes 10-15 seconds (JVM cold start). Watch for `mcp.call` in the trace panel. Thumbs-up when you see weather data in the response."

---

### [0:25–0:50] — Experiments & Exploration

**Experiment 1 — Weather-driven recommendations:**
Send "I need an outfit for a conference in Las Vegas next week". Watch: weather MCP fires → temperature returned → Mira recommends breathable fabrics suitable for desert climate.

**Experiment 2 — Logistics tracking:**
Send "show me my past orders" (getOrderHistory CFC tool fires), then "where is my last order?" Watch: trackShipment MCP fires → delivery status and ETA returned.

**Experiment 3 — MCP + CFC tool interaction:**
Send "I need a light jacket for my Las Vegas trip". Watch: weather MCP → searchCatalog CFC in sequence.

**Experiment 4 — Trace panel MCP events:**
Compare `tool.call`/`tool.result` (CFC) vs `mcp.call`/`mcp.result` (MCP) in the trace panel. Note the different event types.

**Experiment 5 — Cold start demonstration:**
Reset the session. First weather call: ~10-15s. Second call: <1s. Explain JVM cold-start vs. warm-path performance.

**"What happens if..." provocations:**
- "What if the weather service is down?" (Agent catches error, falls back to general advice)
- "What if you ask about a city not in the coordinates table?" (Model may use getWeatherForecastByCity directly)

### [0:50–1:00] — Wrap-up

**Key takeaway:** MCP extends the agent with external capabilities from any language or service. Application-scoped clients pay the handshake cost once. CFC tools and MCP tools coexist in the same tools array — the model calls whichever is appropriate.

**Bridge to next session:** "Mira has weather, logistics, and product tools. But ask 'what is your return policy?' — she cannot answer (not in the catalog DB). Ask 'do reviewers say this jacket runs small?' — she does not know (no review data). Session 5 adds RAG: vector-search over policies, reviews, and catalog descriptions."

**Lunch break reminder.**

## Troubleshooting Guide

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| First weather call hangs >30s | JVM cold start is slow on this machine | Wait up to 30s. If it times out, check that the JAR path in mcp-servers-template.json is correct |
| "MCPClient is not a function" | CF AI module not enabled | Check CF Admin → AI settings |
| No mcp.call events | TODO-S4-1 incomplete or MCP clients empty | Check that getOrCreateMcpClients returns non-empty array |
| "Cannot find file mcp-servers.json" | Template resolution failed | Check mcp-servers-template.json exists in config/ directory |
| Weather returns error | Network issue or JAR crash | Check `externalservices/weather/live/logs/mcp-weather-live.log` |
| REST endpoint returns 404 | REST services not registered | Re-run [setup.cfm](../../setup/setup.cfm) |
| "Datasource not found" error | Datasource not registered | Re-run [setup.cfm](../../setup/setup.cfm) |

## Behind-Attendee Protocol
- **Signal:** No mcp.call events after sending weather query
- **30-second intervention:** "Check TODO-S4-1 — do you have `var mcpClients = getOrCreateMcpClients(cfg);`?"
- **Rescue:** Copy lines 17-27 from `s4/ref/AgentService.cfc` into the lab TODO zone
- **Last resort:** Toggle to ref mode

## Questions They Will Ask (With Answers)

**Conceptual questions:**

| Question | Answer |
|----------|--------|
| Why is MCP client application-scoped? | The stdio transport (weather JAR) starts a JVM with a TCP handshake. This takes 10-15 seconds. Doing it per-request would make every chat response take 15+ seconds. Application scope means we pay the cost once. |
| What is the difference between MCP tools and CFC tools? | CFC tools run in-process (same JVM). MCP tools communicate over a protocol (stdio or HTTP) with external services. MCP is a standard — any MCP-compatible server works, regardless of language. |
| Why does the first weather call take so long? | The weather MCP server is a Java JAR. First call launches the JVM (~10s). Subsequent calls are fast (<1s) because the process stays running. Same as Lambda cold-start. |

**Technical questions:**

| Question | Answer |
|----------|--------|
| Why .properties format for S4? | Demonstrates that CF2025's `getPropertyFile()` handles AI config natively. Real enterprise apps often use .properties (Java ecosystem). Also shows the AI primitives are config-format-agnostic. |
| Can I add my own MCP server? | Yes. Add an entry to `mcp-servers-template.json` with transport type (stdio or http), command/url, and env vars. The agent discovers all tools from all registered MCP servers automatically. |
| What if the MCP server crashes? | The agent catches MCP errors gracefully. The conversation continues without that data. On next request, the client may reconnect or fail gracefully. |
| Why does the code check `if (!isArray(mcpClients))`? | MCPClient() may return a single object or an array depending on how many servers are configured. The code normalizes to always be an array. |

**Production questions:**

| Question | Answer |
|----------|--------|
| How do I handle MCP server health checks? | Implement a heartbeat endpoint on your MCP server. In production, wrap the client pool with a circuit breaker pattern — skip unhealthy servers. |
| Can MCP tools access user credentials? | Yes, via the env/config passed at initialization. The workshop passes no credentials; production would inject auth tokens into the MCP server config. |

## Verification Checklist

1. Lab mode: send "what is the weather in New York?"
2. **Trace:** `mcp.call` (weather tool) → `mcp.result` (temperature/conditions)
3. Send "I need an outfit for a conference in Las Vegas"
4. **Expected:** Weather check fires, then searchCatalog for appropriate clothing
5. Send "where is my last order?"
6. **Expected:** getOrderHistory (CFC) → trackShipment (MCP) → delivery status
