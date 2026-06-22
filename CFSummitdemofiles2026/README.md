# Adobe ColdFusion 2025 AI Demos

This folder contains local demo applications for ColdFusion Summit 2026. The demos show how Adobe ColdFusion 2025 can connect LLMs, vector search, RAG, guardrails, MCP tools, SQL data, session state, and secure demo-time API key storage.

Open the launcher:

```text
http://localhost:8500/CFSummit2026/demos/
```

## Shared Setup

Most demos assume they are running under:

```text
C:\ColdFusion2025alpha\cfusion\wwwroot\CFSummit2026\demos
```

The cloud-backed demos read API keys from the local `keystore` app. Add keys at:

```text
http://localhost:8500/CFSummit2026/demos/keystore/
```

Local Ollama demos expect:

```bash
ollama pull llama3.2
ollama pull nomic-embed-text
ollama serve
```

CAIROI tracing is optional for participant demos. Demo apps look for a local CAIROI SDK via `CAIROI_ROOT`, `CAIROI_SDK_ROOT`, webroot `/CAIROI` or `/cairoi`, or sibling-of-demos CAIROI folders. If no SDK is present, they use `shared/cairoi-compat` so demo workflows continue without trace links.

## Project Matrix

| Project | Theme | Technical Focus | AI Features | Setup Notes |
| --- | --- | --- | --- | --- |
| `keystore` | Local demo key storage | Embedded Derby plus AES-GCM encryption | None directly | Stores keys for other demos. Demo-only and unauthenticated. |
| `MCPToolLLM` | Inventory assistant | ColdFusion MCP tools over SQL Server data | MCP, LLM, tool routing | Needs DSN `cfsummit26_inventory` and keys `openaiapi_inventoryai` or `anthropicapi_inventoryai`. |
| `CodeReviewLocal` | AI code review | Standards corpus plus file browser | RAG, LLM, vector search | Needs standards ingestion; cloud keys or Ollama. |
| `LLMRAGGuardrail` | Employee onboarding assistant | Local policy RAG with visible controls | RAG, LLM, guardrails, schema output | Uses local Ollama only. No keystore key required. |
| `VectorStoreRag` | Donut shop menu assistant | Text-file ingestion and retrieved menu answers | Vector store, embeddings, RAG, LLM | Needs key `openaiapi_donuts`. |
| `CFCase` | Mystery game engine | Stateful scenario engine with AI helper | LLM, vector memory, guardrails | Uses local Ollama only. No keystore key required. |

## Keystore Details

`keystore` is included so the demos do not keep provider API keys in source files. It is for demo purposes only.

How it works:

- Creates an app-local Apache Derby database under `keystore/data/derby/keystoredb`.
- Creates a generated 128-bit AES master key at `keystore/data/keystore-master.key`.
- Encrypts saved values with Java `AES/GCM/NoPadding`.
- Stores encrypted values, IVs, fingerprints, masked hints, notes, and retrieval metadata in Derby.
- Exposes a simple vanilla JavaScript UI plus JSON endpoints for local demo apps.
- Provides no authentication or authorization.

Intentional keystore runtime files:

- `keystore/data/keystore-master.key`
- `keystore/data/derby/keystoredb/`

Those files are not stray provider API keys. They are the keystore's local encryption material and embedded database.

## Key IDs

| Key ID | Demo |
| --- | --- |
| `openaiapi_donuts` | `VectorStoreRag` |
| `openaiapi_codereview` | `CodeReviewLocal` |
| `anthropicapi_codereview` | `CodeReviewLocal` |
| `openaiapi_inventoryai` | `MCPToolLLM` |
| `anthropicapi_inventoryai` | `MCPToolLLM` |

## Request Workflows

`MCPToolLLM`: browser chat -> `api/chat.cfm` -> LLM tool selection with `ChatModel()`/`Agent()` -> `MCPClient()` -> `mcp/server.cfm` -> `MCPServer()` -> `InventoryDatabaseToolV3.cfc` -> `InventoryService.cfc` -> SQL Server -> LLM summary.

`CodeReviewLocal`: browse a file -> choose security, modern CF, or performance review -> auto-clear the active vector store -> ingest that mode's standards document with `VectorStore().addAll()` -> retrieve standards with `VectorStore.search()` -> prompt selected LLM with code and citations -> normalized review findings.

`LLMRAGGuardrail`: status auto-ingests Markdown onboarding docs -> user asks a question -> optional deterministic guardrails -> optional RAG retrieval -> guarded or plain LLM answer -> session metrics and trace.

`VectorStoreRag`: choose menu text file -> parse records -> add chunks to `VectorStore()` -> retrieve matching menu items -> `ChatModel()` and `Agent()` answer only from retrieved context.

`CFCase`: choose scenario -> load JSON and session state -> command parser resolves player input -> game engine mutates safe state -> discovered facts are indexed into vector memory -> IRIS answers from discovered-only context with guardrails.

## Demo User Tracking

The root launcher requires attendees to sign in with name, email, and company before launching a demo. Tracking is stored in a self-creating Derby database at `usertracking/data/derby/trackingdb`.

Recorded data includes login time, last activity time, demo launch clicks, CF Cases mystery starts, and CF Cases solved events. The tracking session and the demo application sessions time out after 10 minutes of inactivity, and active demo requests refresh the shared tracking session. The launcher also has a `Demo reset` button for clearing the current attendee tracking cookie between users.

An unlinked dashboard is available at:

```text
http://localhost:8500/CFSummit2026/demos/usertracking/
```

The `usertracking/data/derby/trackingdb` files are intentional durable demo tracking state.

## Artifact And Secret Policy

- Do not add API key files to project folders.
- API key values should be entered through `keystore` and read through `KeystoreService.cfc`.
- Do not commit `.env`, `.pem`, `.p12`, `.jks`, `.bak`, `.old`, `.tmp`, `.DS_Store`, or `Thumbs.db` files.
- The included image assets, screenshots, sample code, Markdown corpora, and text data files are legitimate demo assets.
- The keystore Derby database and master key are intentional local demo runtime artifacts.

## Project READMEs

Each project folder has its own canonical `README.md` with setup, workflows, ColdFusion features, AI features, endpoints, and troubleshooting notes.
