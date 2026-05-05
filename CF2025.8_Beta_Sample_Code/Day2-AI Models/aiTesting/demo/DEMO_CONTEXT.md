# ColdFusion 2025 AI Features Demo — Context File
**Purpose:** Resume context in another Claude instance / create PPT slides  
**Last updated:** April 2026  
**Demo URL:** http://localhost:8500/aiTesting/demo/index.cfm

---

## What This Is

A single-page interactive webinar demo showcasing all ColdFusion 2025 AI features.  
Split into two files: `index.cfm` (core CF logic overview) and `ui.cfm` (all HTML/CSS/JS).

---

## Demo Tabs (in order)

| # | Tab | Icon | What it demonstrates |
|---|-----|------|----------------------|
| 1 | ChatModelConfig | ⚙️ | `ChatModel()` — provider, model, temperature, maxTokens, responseFormat |
| 2 | FunctionTool | 🔧 | `agent()` with tool CFCs — LLM calls real functions |
| 3 | ChatMemory | 💬 | `agent()` with `CHATMEMORY` — multi-turn conversation |
| 4 | Guardrails | 🛡️ | System prompt safety + PII code-level guardrail via agent() API |
| 5 | RAG | 📚 | Retrieval-Augmented Generation — keyword search over local docs |
| 6 | Streaming | ⚡ | `cfthread` + poll + typewriter effect |
| 7 | MCP | 🔌 | MCP server tool integration |

---

## CF 2025 AI API — Key Facts

### Two main functions
```cfml
// 1. Simple chat — no tools, no memory
chatModel = ChatModel({ PROVIDER:"openai", APIKEY:apiKey, MODELNAME:"gpt-4o-mini" });
response  = chatModel.chat("your prompt");

// 2. Agent — tools, memory, streaming, guardrails
aiSvc    = agent({ CHATMODEL:chatModel, TOOLS:[{CFC:"MyTool"}], CHATMEMORY:{ MAXMESSAGES:20 } });
response = aiSvc.chat("your prompt");
```

### Tool registration rules
```cfml
// CORRECT — CFC path string (dot-delimited, relative from wwwroot)
TOOLS: [{ CFC: "aiTesting.demo.tools.EcommerceTool" }]

// CORRECT — MCP client (MCPCLIENT takes an array of client objects)
TOOLS: [{ MCPCLIENT: [mcpClientObj] }]

// CORRECT — mixed CFC + MCP
TOOLS: [{ CFC: "aiTesting.demo.tools.EcommerceTool" }, { MCPCLIENT: [mcpClient] }]

// WRONG — CFC object (do NOT use createObject)
TOOLS: [createObject("component", "aiTesting.demo.tools.EcommerceTool")]
```

### Tool CFC requirements
- All tool methods MUST be `remote`
- Each method MUST have a comment block with `@hint`, `@param`, `@return`
- This metadata is sent to the LLM so it decides which tool to call and with what arguments
- Verify by enabling `logRequests` / `logResponse` in ChatModel config — the tool schema appears in the request

### Guardrails via agent() API
```cfml
// CORRECT — INPUTGUARDRAILS and OUTPUTGUARDRAILS take arrays of absolute CFC file paths
// Use expandPath() to resolve paths
piiPath = expandPath("/aiTesting/demo/PiiGuardrail.cfc");
aiSvc = agent({
    CHATMODEL:        chatModel,
    OUTPUTGUARDRAILS: [piiPath]
});
aiSvc.systemMessage("Refuse harmful, illegal, or inappropriate requests.");
response = aiSvc.chat(prompt);
// Output guardrail validate() runs automatically before returning
// If guardrail blocks, an exception is thrown

// WRONG — manual validate() call (don't do this)
resp = chatModel.chat(prompt);
guard = createObject("component", "PiiGuardrail");
gr = guard.validate(resp.message); // <-- anti-pattern
```

### Supported providers
| Provider | PROVIDER value | Notes |
|----------|---------------|-------|
| OpenAI | `"openai"` | gpt-4o-mini, gpt-4o, etc. |
| Anthropic | `"anthropic"` | claude-sonnet-4-6 |
| Mistral | `"mistral"` | mistral-large-latest |
| Azure OpenAI | `"azureopenai"` | Needs ENDPOINT too |
| Ollama | `"ollama"` | Local models |

### Critical gotchas discovered
1. **`response.toolExecutionRequests` is a Java List** — `arrayLen()` returns 0. Must iterate with `for...in` + `arrayAppend()` into a real CF array.
2. **CF `serializeJSON` uppercases all keys** — `SUCCESS`, `MESSAGE`, `TOOLCOUNT`. JS must lowercase them (`lcKeys()` helper).
3. **Tool CFCs must have `remote` methods with hint/param metadata** — CF sends this to the LLM. Without `remote`, methods are not discoverable.
4. **Pass CFC paths as `{CFC:"dotted.path"}`, not CFC objects** — `createObject("component",...)` does NOT work in the tools array.
5. **Guardrails belong in agent() config** — use `OUTPUTGUARDRAILS:[expandPath("/path/to/Guardrail.cfc")]` (array of absolute CFC file paths), NOT manual post-hoc `validate()` calls. When a guardrail blocks, it throws an exception.
6. **`STREAMINGHANDLER` goes in `agent()`, NOT `ChatModel()`** — putting it in ChatModel throws "Unknown Field".
7. **`cfwebsocket` tag removed in CF 2025** — not available.

---

## File Structure

```
/aiTesting/demo/
├── Application.cfc          # Isolated app: API keys, session config
├── index.cfm                # Core CF logic overview + cfinclude of ui.cfm
├── ui.cfm                   # Full interactive UI — HTML, CSS, JavaScript (all 8 tabs)
├── PiiGuardrail.cfc         # PII detection/redaction guardrail (validate function)
├── tools/
│   ├── EcommerceTool.cfc    # e-commerce tool — remote methods with @mcpTool metadata
│   └── FinancialTool.cfc    # finance tool — remote methods with @mcpTool metadata
├── StreamHandler2.cfc       # Streaming callbacks for agent() STREAMINGHANDLER (writeLog-based)
├── docs/                    # RAG knowledge base documents (.txt / .md)
├── mcp/
│   └── server.cfm           # MCP server exposing EcommerceTool + FinancialTool
└── api/
    ├── modelconfig.cfm      # Tab 1: ChatModel.chat() direct
    ├── functiontool.cfm     # Tab 2: agent() with {CFC:"EcommerceTool"}/{CFC:"FinancialTool"}
    ├── chatmemory.cfm       # Tab 3: agent() with CHATMEMORY
    ├── guardrails.cfm       # Tab 4: system prompt safety
    ├── piiguardrail.cfm     # Tab 4: PII guardrail via agent() OUTPUTGUARDRAILS API
    ├── rag.cfm              # Tab 5: RAG (ingest / ask / status)
    ├── streaming.cfm        # Tab 6: cfthread + ChatModel.chat()
    ├── stream_poll.cfm      # Tab 6: returns application.streamBuffer + streamDone
    └── mcp.cfm              # Tab 7: agent() with {mcpClient: mcpClient}
```

---

## Tab Details

### Tab 1 — ChatModelConfig
- **API:** `api/modelconfig.cfm` — uses `ChatModel().chat()` directly
- **Controls:** provider, model, temperature slider, maxTokens, responseFormat (text/JSON)

### Tab 2 — FunctionTool
- **API:** `api/functiontool.cfm` — uses `agent()` with `{CFC:"path"}` tools
- **Toolsets:** ecommerce (EcommerceTool), financial (FinancialTool), or both
- **Tool CFCs have `remote` methods** with `@hint`, `@param`, `@return` metadata
- agent() handles tool execution automatically — no manual 2-turn hack

### Tab 3 — ChatMemory
- **API:** `api/chatmemory.cfm` — `agent()` with `CHATMEMORY`

### Tab 4 — Guardrails
- **Two sections:**
  1. **System Prompt Guardrail** (`api/guardrails.cfm`) — safety instructions via `systemMessage()` + `OUTPUTGUARDRAILS` with PiiGuardrail
  2. **PII Guardrail** (`api/piiguardrail.cfm`) — uses `OUTPUTGUARDRAILS:[expandPath("/aiTesting/demo/PiiGuardrail.cfc")]` in agent() API

### Tab 5 — RAG
- **API:** `api/rag.cfm` — 3 actions: `status`, `ingest`, `ask`

### Tab 6 — Streaming
- **API:** `api/streaming.cfm` + `api/stream_poll.cfm`
- Uses `agent()` with `STREAMINGHANDLER: "aiTesting.demo.StreamHandler2"`
- `StreamHandler2.cfc` has `onPartialResponse()`, `onCompleteResponse()`, `onError()` callbacks
- **CF 2025 bug**: callbacks run on Java ForkJoinPool threads where CF scopes are null — only `writeLog()` works
- Tokens are written to `demo-stream2.log`, `stream_poll.cfm` parses the log to reconstruct the buffer
- Tokens buffered in `application.streamBuffer`, browser polls `stream_poll.cfm`

### Tab 7 — MCP
- **API:** `api/mcp.cfm` — `agent()` with `{MCPCLIENT: [mcpClient]}` in TOOLS

---

## How to Resume in Another Claude Instance

Paste the following into a new Claude chat:

> I'm building a ColdFusion 2025 AI features webinar demo. The demo is at `/Applications/ColdFusion2025/cfusion/wwwroot/aiTesting/demo/`. It's a 7-tab single-page app covering ChatModelConfig, FunctionTool, ChatMemory, Guardrails, RAG, Streaming, and MCP. The full context is in `/Applications/ColdFusion2025/cfusion/wwwroot/aiTesting/demo/DEMO_CONTEXT.md`. Please read that file first.
