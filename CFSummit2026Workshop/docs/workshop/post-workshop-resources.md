# Post-Workshop Resources

## What You Built

Over 6 sessions, you built **Mira** — a production-quality AI shopping assistant using ColdFusion 2025's native AI primitives:

| Session | Capability | CF2025 Primitive |
|---------|-----------|-----------------|
| S1 | Streaming chat | `ChatModel()` + `agent()` + Streamer CFC |
| S2 | Multi-turn memory + preferences | `CHATMEMORY` + `model.chat()` extraction |
| S3 | Tool calling (7 CFC tools) | `TOOLS` array in agent config |
| S4 | External capabilities (MCP) | `MCPClient()` + stdio/HTTP transports |
| S5 | Document retrieval (RAG) | `VectorStore()` + `retrievalAugmentor` |
| S6 | Safety guardrails | `INPUTGUARDRAILS` + `OUTPUTGUARDRAILS` |

---

## Swap LLM Provider

ColdFusion 2025 supports multiple providers with a one-line config change:

### OpenAI (workshop default)
```json
{
  "provider": "openAi",
  "modelName": "gpt-4o-mini",
  "apiKey": "sk-..."
}
```

### Anthropic (Claude)
```json
{
  "provider": "anthropic",
  "modelName": "claude-sonnet-4-20250514",
  "apiKey": "sk-ant-..."
}
```

### Google Gemini
```json
{
  "provider": "gemini",
  "modelName": "gemini-2.0-flash",
  "apiKey": "AIza..."
}
```

### Ollama (Local/Self-Hosted)
```json
{
  "provider": "ollama",
  "modelName": "llama3.1:8b",
  "apiKey": "",
  "baseUrl": "http://localhost:11434"
}
```

**No code changes needed.** Edit `ai.json` (or `ai.lab.json`), save, and the next message uses the new provider.

---

## Deploy StyleMart to Production

### Key differences from workshop:

| Workshop | Production |
|----------|-----------|
| In-memory vector store | Persistent store (Pinecone, pgvector, Qdrant) |
| API key in config file | Environment variables or CF credential store |
| Single-user AMI | Multi-tenant with auth |
| Application-scoped agents | Session-scoped with TTL eviction |
| In-memory chat memory | Redis-backed persistent memory |
| No rate limiting | Rate limiting per user/session |

### Deployment checklist:
1. Move API keys to environment variables or CF Admin credential store
2. Replace INMEMORY vector store with a persistent provider
3. Add authentication (CF's built-in `cflogin` or OAuth)
4. Configure Redis for chat memory persistence
5. Add session TTL and agent eviction policies
6. Set up monitoring for LLM costs (token usage)
7. Add request rate limiting on the REST endpoints
8. Configure HTTPS for all external API calls
9. Set up log rotation for MCP and RAG logs

---

## ColdFusion 2025 AI Documentation

### Official Resources
- **ColdFusion 2025 AI Developer Guide:** Available in CF Admin → Documentation
- **AI BIF Reference:** `ChatModel()`, `agent()`, `MCPClient()`, `VectorStore()`, `documentService()`
- **CF2025 Release Notes:** New AI module features and configuration options

### Key Documentation Topics
- Chat memory providers and configuration
- Tool CFC annotation reference
- MCP server configuration format
- Vector store provider options
- Guardrail CFC contract specification
- Streaming handler callback signatures

---

## Workshop Repository

### Getting the code
The complete workshop repository (with all sessions, lab and ref code) is available at the URL provided by your instructor.

### Branch structure
- `main` — complete workshop with all sessions working
- `rebuild/session-ladder` — progressive build (each commit adds one session)

### Running locally
1. Install ColdFusion 2025 with the AI module enabled
2. Clone the repository into your CF webroot
3. Run the database seed scripts (`db/mysql/seed/00_seed_run_all.sql`)
4. Update API keys in each session's config file
5. Access at `http://localhost:8500/CFSummit2026Workshop/StyleMart/`

---

## Community & Learning

### ColdFusion Community
- **Adobe ColdFusion Community Portal:** Official forums and knowledge base
- **CF Slack:** Real-time community chat
- **CFCasts:** Video tutorials and courses
- **Adobe Developer Blog:** ColdFusion updates and tutorials

### AI/LLM Learning
- **MCP Specification:** The official Model Context Protocol standard
- **OpenAI Cookbook:** Patterns for tool use, RAG, and guardrails
- **LangChain Concepts:** Many CF2025 AI patterns mirror LangChain (content retrievers, query routers, memory windows)

### Conference Resources
- **CFSummit:** Annual ColdFusion conference
- **Adobe MAX:** Broader Adobe technology conference
- **Into the Box:** CFML community conference

---

## Extend Your Project

### Ideas for next steps:

1. **Add a new tool:** Create a CFC that calls an external API (shipping calculator, size recommendation engine). Add it to the tools array.

2. **Build a custom MCP server:** Write a CFML MCP server that exposes your business logic to any MCP-compatible agent.

3. **Add a new guardrail:** Implement a competitor-mention guard, a profanity filter, or an AI-based toxicity classifier.

4. **Expand RAG corpora:** Add FAQ documents, sizing guides, or user manuals to the vector store.

5. **Multi-language support:** Add system prompt variants for Spanish, French, Japanese — swap via config.

6. **Analytics dashboard:** Build a page that queries `agent_traces` and `guardrail_events` to show usage patterns, popular tools, and violation rates.

7. **A/B test personas:** Use the system prompt variants (Mira, Reggie, Luxury) with real users and measure engagement differences.

---

## Thank You

Thank you for attending the CFSummit 2026 AI Workshop. You now have hands-on experience with every major AI capability in ColdFusion 2025. The patterns you learned — streaming, memory, tools, MCP, RAG, and guardrails — apply to any AI agent application, not just e-commerce.

Build something great.
