# RAG in ColdFusion

A working reference for the **Retrieval-Augmented Generation** primitives shipped with Adobe ColdFusion. The project is a single-page demo that pairs every feature with a side-by-side **Before / After** comparison so the value of each primitive is visible the moment it's enabled.

The same patterns shown here — `simpleRAG()`, `agent()`, `chatModel()`, `vectorStore()`, `documentService()` — are the building blocks you will use in production code.

---

## What you need

The demo is plug-and-play once these are reachable from the ColdFusion process:

- **Adobe ColdFusion** with the AI / RAG feature set enabled.
- **A chat-model provider.** Configured for OpenAI (`gpt-4o-mini`) out of the box; any provider supported by `chatModel()` works with a one-line change.
- **An embedding service.** Ollama with `all-minilm` (384-dim). Required by every demo — the vector store is built around this dimension.
- **A vector database.** Milvus is the default for every demo. Qdrant, Chroma and Pinecone are pre-wired in `Application.cfc` and become available by changing one `provider:` field.

Nothing else is needed locally — the demo is a static set of `.cfm` pages and a sample corpus.

---

## How the project is wired

```
                                     ┌──────────────────────────────┐
   Browser  ◀───── HTML / JS ─────▶  │       demos/index.cfm        │   single-page UI
                                     │  (sidebar · tabs · panels)   │
                                     └──────────────┬───────────────┘
                                                    │  fetch()
                ┌───────────────────────────────────┼───────────────────────────────────┐
                ▼                                   ▼                                   ▼
        runners/<demo>-init.cfm            runners/query.cfm                  runners/retrieve.cfm
        builds the RAG service             routes ask() / chat()              runs the retrieval step
        and stashes it in                  through the right                  in isolation so the UI
        session.demos[id]                  session.demos[id]                  can show retrieved chunks
                │                                   │                                   │
                └─────────────── built on top of these CF primitives ───────────────────┘
                                                    ▼
              chatModel()  ·  vectorStore()  ·  simpleRAG()  ·  agent()  ·  documentService()
                                                    ▼
                       ┌────────────────────┬────────────────────┬───────────────────┐
                       ▼                    ▼                    ▼                   ▼
                 OpenAI / etc.        Embedding model       Vector database     Document corpus
                  (chat LLM)        (Ollama · all-minilm)   (Milvus default)   (demos/Documents)
```

A few details that explain the rest of the codebase:

- `Application.cfc` is the only piece of configuration. It populates `application.openaiKey`, `application.ollamaBaseUrl`, and `application.vectorDB.*` from environment variables, then every runner reads from there.
- Each runner under `runners/` is intentionally small and self-contained — it is meant to be readable as documentation. Open one and the corresponding feature is one screenful of code.
- A demo's lifecycle is: `*-init.cfm` builds the RAG service and stores it under a key in `session.demos[id]`; the UI then drives interaction through `query.cfm?id=…` (chat / ask) and `retrieve.cfm?id=…` (retrieval-only, used by the panels that visualise which chunks the LLM actually saw).
- `?reinit=1` on any URL clears the application scope and re-runs `onApplicationStart` — the supported way to pick up changed env vars or wipe collections between runs.

---

## Configuration

`Application.cfc` reads every secret and every endpoint from JVM system properties first, then OS environment variables, then a clearly labelled placeholder. **No credentials are ever stored in source.**

| Variable | Required | Default | Used for |
|---|---|---|---|
| `OPENAI_API_KEY` | yes | _(placeholder)_ | Authenticates the chat model used by every demo. |
| `OLLAMA_BASE_URL` | no | `http://localhost:11434` | Embedding model service. |
| `MILVUS_URL` | no | `http://localhost:19530` | Default vector store for every demo. |
| `QDRANT_URL`, `QDRANT_API_KEY` | no | `http://localhost:6333` / placeholder | Optional Qdrant backend. |
| `CHROMA_URL`, `CHROMA_DATABASE_NAME`, `CHROMA_TENANT_NAME` | no | localhost defaults | Optional Chroma backend. |
| `PINECONE_API_KEY`, `PINECONE_INDEX` | no | placeholder / `test-rag` | Optional Pinecone backend. |

If `OPENAI_API_KEY` is missing at startup, `Application.cfc` writes a warning to `application.log`. Any LLM call will then fail explicitly rather than silently. Pass values through whichever mechanism your ColdFusion deployment standardises on — `jvm.config`, the OS environment, or your secrets manager.

---

## Feature reference

The UI is grouped into three sections that match the three CF RAG entry points.

### 1 · Simple RAG · `simpleRAG()`

The fastest path from documents to a grounded chatbot. `simpleRAG(source, chatModel, options)` returns an object with `ingest()`, `ask()` and `chat()`.

| Demo | Demonstrates |
|---|---|
| **`ask()` — Stateless** | A naked LLM (Before) vs. the same model grounded in `product-docs.txt` (After). Use for one-shot Q&A and search-style flows. |
| **`chat()` — Multi-Turn** | Same `simpleRAG` instance called via `chat()`. Conversation history is carried forward so short follow-ups keep their referent. |

Source: `runners/basic-ask-init.cfm`, `runners/basic-chat-init.cfm`.

### 2 · Advanced RAG · `agent()`

`agent({ chatModel, ingestion, retrievalAugmentor, inputGuardrails })` exposes every stage of the pipeline so you can compose, override or replace any piece.

| Demo | Demonstrates |
|---|---|
| **Precision Tuning** | Live controls for `splitterType`, `chunkSize`, `maxResults` (top-k) and `minScore` show the recall ↔ noise trade-off in real time. |
| **Transformers** | `documentTransformer` enriches a `Document` *before* splitting; `textSegmentTransformer` enriches a `Segment` *after* splitting. Custom metadata persists with each chunk and is filterable downstream. |
| **Query Routing** | Multiple `vectorStore`s, each with a `description`. A `routingModel` reads the descriptions and dispatches each query to the most relevant store. |
| **Content Retriever** | Loose (`topK=10, minScore=0`) vs. tuned (`topK=3, minScore=0.3`) retrieval, side by side. The retrieval panel renders the chunks the LLM actually saw, with scores. |
| **Aggregator** | Default routing fans out to *every* retriever; `contentAggregator` merges the result lists with a visible source boundary and caps the combined context with `maxTokens`. |
| **Injector** | A custom `promptTemplate` with `{{contents}}` / `{{userMessage}}` placeholders takes full control of the prompt sent to the LLM. `metadataKeys` selects which per-chunk metadata is exposed inside `{{contents}}`. |
| **Guardrails** | `inputGuardrails` is an array of CFC paths. Each CFC implements `validate(userMessage)` and can block a message before it ever reaches the model. `SensitiveDataGuardrail.cfc` ships as a working example. |

Source: `runners/advanced-*.cfm`, `guardrails/SensitiveDataGuardrail.cfc`.

### 3 · Document Service · `documentService()`

A first-class ETL pipeline for documents. `load → transform → split → transformSegments → ingest` are explicit, inspectable steps you can run in any combination — typically as a scheduled ingestion job.

| Demo | Demonstrates |
|---|---|
| **Ingest + Query** | A staged ingestion job populates a vector store on the left; an `agent()` attaches to that same store on the right and answers questions with no re-ingestion. The pattern: ingest once, query from anywhere. |
| **Lazy Load** | `lazyLoad()` returns a streaming iterator (`hasNext()` / `next()`) so corpora too large for memory pipe document-by-document into split + ingest. |

Source: `runners/pipeline-etl-ingest.cfm`, `runners/pipeline-etl-init.cfm`, `runners/pipeline-lazyload.cfm`.

---

## Project layout

```
RAG/
├─ README.md
├─ presentation/RAG_in_ColdFusion.pptx     companion deck
└─ demos/
   ├─ Application.cfc                      env-driven configuration
   ├─ index.cfm                            single-page UI
   ├─ Documents/                           sample product / HR / FAQ corpus
   ├─ Corpus/                              ~50 Wikipedia articles (Lazy-Load demo)
   ├─ guardrails/SensitiveDataGuardrail.cfc
   ├─ runners/                             one .cfm per Before / After pane
   │   ├─ basic-*-init.cfm                 simpleRAG demos
   │   ├─ advanced-*-init.cfm              agent() demos
   │   ├─ pipeline-*.cfm                   documentService demos
   │   ├─ query.cfm                        chat / ask endpoint
   │   ├─ retrieve.cfm                     retrieval-only endpoint
   │   └─ prompt.cfm                       exposes the rendered prompt template
   └─ docs/                                per-feature explainers (rendered by "View Docs")
```

---

## Adapting the demo to your data

- Drop your files into `demos/Documents/` (or any folder you control) and update the `expandPath(...)` argument inside the relevant `*-init.cfm`. The pipeline shape stays the same.
- For large corpora, switch the loader to `documentService().lazyLoad({...})` so memory stays flat regardless of how many files you process.
- To change LLM provider, change `provider` / `modelName` on the `chatModel({...})` call. Nothing else needs to change.
- To change vector store, change `provider` on `vectorStore({...})` and reuse the matching block from `application.vectorDB`.

---

## Operational notes

- The `?reinit=1` URL parameter calls `applicationStop()` and reloads configuration. It is the right escape hatch for development; it should be gated behind authentication or removed in any deployment that's not strictly local.
- `*-init.cfm` runners drop and recreate their collection on every start so each Before / After comparison is reproducible. Adapt that behaviour if you adopt a runner as a starting point for production code.
- `SensitiveDataGuardrail.cfc` is a minimal pattern-match example. Production guardrails should also cover output redaction, jailbreak attempts and policy compliance — `inputGuardrails` accepts an array, so layer them.
- The bundled corpus is sample data. Replace it before reusing the demo against any internal or customer-facing audience.
