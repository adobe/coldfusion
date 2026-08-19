# Session 5: RAG (Retrieval-Augmented Generation) — Instructor Guide

## Overview
- **Duration:** 60 minutes
- **Learning objectives:**
  - Build per-corpus vector stores with embedding models
  - Configure a multi-retriever RAG pipeline with query routing
  - Understand content injection templates and how RAG enriches tool results
  - Observe citation chips and retrieval events in the trace panel
- **Prerequisites:** S4 complete (MCP tools working)
- **Wow moment:** Ask "show me sneakers" — product cards appear (tools) AND review sentiment + care tips appear alongside (RAG). The response is visibly richer than S3/S4.

## Pre-Session Checklist
- S4 Lab mode works (weather + logistics MCP responding)
- RAG corpus files exist in `api/agent/s5/data/rag/{policy,catalog,reviews,orders}/`
- OpenAI API key valid (embedding model uses text-embedding-3-small)
- Application start has been triggered (or will trigger on first request)

## Story So Far
Mira streams responses, remembers context and preferences, uses 7 CFC tools for product/cart/order operations, and connects to external MCP services for weather and logistics. But she cannot answer policy questions or provide review insights because that data is in documents, not the database.

## Teaching Flow (Timeline)

### [0:00–0:10] — Concept Introduction

**Key points:**
- RAG = Retrieval-Augmented Generation. The model gets relevant document chunks injected into its context before generating a response.
- 4 corpora: policy (returns/exchanges), catalog (product descriptions), reviews (customer sentiment), orders (order context)
- Each corpus gets its own VectorStore with tuned retrieval parameters (maxResults, minScore)
- A "languageModel" query router decides WHICH corpus to search based on the user's message
- The contentInjectorTemplate tells the model to ENRICH responses (use RAG + tools together, not RAG instead of tools)
- Citation chips: when `metadataKeys: ["file_name"]` is set, the UI shows which source file contributed to the answer

**Talking points:**
- "Until now, Mira could only answer questions backed by database queries (tools) or external APIs (MCP). But 'what is your return policy?' lives in a PDF. 'Do reviewers say this runs small?' lives in review documents. RAG makes those answerable."
- "The key insight: RAG ENRICHES tool results, it does not replace them. 'Show me sneakers' still calls searchCatalog for product cards. RAG adds review highlights and care tips alongside."

**Common misconceptions:**
- "RAG replaces tools" — No. Tools provide live, structured data (prices, inventory). RAG provides contextual enrichment (policies, reviews, descriptions). They work in tandem.
- "One big vector store is better" — No. Separate stores per corpus allow different tuning: policy needs high recall (do not miss relevant rules), catalog needs precision (do not inject wrong products).
- "You need to re-embed every time the app restarts" — In this workshop yes (in-memory store). Production would use a persistent vector store.

### [0:10–0:35] — Hands-On Coding

**Two files:** AgentService.cfc (3 TODOs) and init-rag.cfm (2 TODOs)

---

#### TODO-S5-1: Create VectorStore (init-rag.cfm)

**File:** [`api/agent/s5/lab/init-rag.cfm`](init-rag.cfm#L64)
**Find:** [`// TODO-S5-1`](init-rag.cfm#L71)

**What to explain:** "Each corpus gets its own VectorStore. The embedding model converts text chunks into vectors for similarity search. We use INMEMORY for the workshop (fast, no external dependency)."

**Code to write:**
```cfml
vs = VectorStore({
  provider:
    ragCfg.vectorStoreProvider ?: "INMEMORY",
  embeddingModel: embeddingConfig
});
```

---

#### TODO-S5-2: Ingest documents asynchronously

**File:** [`api/agent/s5/lab/init-rag.cfm`](init-rag.cfm#L73)
**Find:** [`// TODO-S5-2`](init-rag.cfm#L78)

**What to explain:** "Ingestion converts document chunks into embeddings and stores them in the VectorStore. We do it async so the application starts quickly. The poller below flips ragReady when all futures complete."

**Code to write:**
```cfml
future = docService.ingestAsync(segments, vs);
arrayAppend(
  server.stylemart.ragFuturesLab, future
);
```

**Checkpoint:** "Save init-rag.cfm. Restart the application (or make any request to trigger onApplicationStart). Check the server log for '[S5-RAG] Ingesting ... segments' messages."

---

#### TODO-S5-3: Build contentRetrievers array (AgentService.cfc)

**File:** [`api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L134)
**Find:** [`// TODO-S5-3`](AgentService.cfc#L150)

**What to explain:** "Each retriever targets one corpus. The description field is what the query router reads to decide which corpus to search. Tunings: policy gets high recall (maxResults=6, minScore=0.4), catalog/reviews need precision (maxResults=3, minScore=0.6)."

**Code to write:**
```cfml
if (structKeyExists(stores, "policy")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.policy,
    maxResults: 6, minScore: 0.4,
    description: "Store policies: returns, "
      & "exchanges, care instructions"
  });
}
if (structKeyExists(stores, "catalog")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.catalog,
    maxResults: 3, minScore: 0.6,
    description: "Product catalog: "
      & "descriptions, materials, features"
  });
}
if (structKeyExists(stores, "reviews")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.reviews,
    maxResults: 3, minScore: 0.6,
    description: "Customer reviews: "
      & "fit, quality, sentiment"
  });
}
if (structKeyExists(stores, "orders")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.orders,
    maxResults: 2, minScore: 0.5,
    description: "Order history context"
  });
}
```

---

#### TODO-S5-4: Build contentInjector

**File:** [`api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L152)
**Find:** [`// TODO-S5-4`](AgentService.cfc#L164)

**Code to write:**
```cfml
var contentInjector = {
  promptTemplate:
    ragCfg.contentInjectorTemplate
    ?: ("Context: {{contents}}" & chr(10)
       & "Question: {{userMessage}}"),
  metadataKeys: ["file_name"]
};
```

---

#### TODO-S5-5: Assemble retrievalAugmentor

**File:** [`api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L164)
**Find:** [`// TODO-S5-5`](AgentService.cfc#L177)

**Code to write:**
```cfml
return {
  queryRouter: {
    type: "languageModel",
    contentRetrievers: contentRetrievers,
    routingModel: arguments.model
  },
  contentInjector: contentInjector
};
```

**Checkpoint:** "Save. Send 'what is your return policy?' in Lab mode. You should see `retrieval.start` and `retrieval.hit` events in the trace panel, plus policy information in the response with citation chips."

---

### [0:35–0:50] — Experiments & Exploration

**Experiment 1 — RAG + Tools together:**
Send "show me sneakers". Observe: searchCatalog returns product cards AND RAG injects review sentiment. Response mentions both specific products and what reviewers say about them.

**Experiment 2 — Policy query:**
Send "what is your return policy for worn items?" Observe: policy corpus returns relevant chunks, citation chips show source files.

**Experiment 3 — Review insights:**
Send "do customers say the wool blazer runs large?" Observe: reviews corpus searched, specific reviewer quotes surfaced.

**Experiment 4 — Corpus routing:**
Send different queries and watch which corpus the router selects in the trace panel:
- "return policy" → policy corpus
- "blazer materials" → catalog corpus
- "customer opinions on fit" → reviews corpus

### [0:50–1:00] — Wrap-up

**Key takeaway:** RAG enriches the model's responses with relevant document chunks retrieved via vector similarity search. A query router intelligently selects which corpus to search, and content injection templates tell the model to combine RAG context with tool results — not replace them.

**Bridge to next session:** "Mira now has the full stack: streaming, memory, tools, MCP, and RAG. But what stops her from promising a 'guaranteed perfect fit'? What stops her from inventing a 90% discount? Nothing — yet. Session 6 adds guardrails: input/output validators that enforce safety rules the model cannot bypass."

## Troubleshooting Guide

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No retrieval events in trace | RAG not initialized (vector stores empty) | Check server log for "[S5-RAG]" messages. May need application restart. |
| "ragVectorStoresLab is undefined" | init-rag.cfm did not run | Trigger application restart or hit any S5 endpoint |
| buildRagAugmentor returns null | stores empty or ragCfg.enabled is false | Check ai.lab.json has `"rag": {"enabled": true, ...}` |
| Citation chips do not appear | metadataKeys not set | Verify TODO-S5-4 includes `metadataKeys: ["file_name"]` |
| Embedding errors | Invalid API key or model name | Check ai.lab.json apiKey and ragCfg.embeddingModel |
| REST endpoint returns 404 | REST services not registered | Re-run [setup.cfm](../../setup/setup.cfm) |
| "Datasource not found" error | Datasource not registered | Re-run [setup.cfm](../../setup/setup.cfm) |

## Questions They Will Ask (With Answers)

**Conceptual questions:**

| Question | Answer |
|----------|--------|
| Why 4 separate vector stores instead of one? | Different corpora need different tuning. Policy needs high recall (do not miss relevant rules). Catalog needs precision (do not inject wrong products). The query router decides WHICH store to search per message. |
| How does the query router decide which corpus? | Type "languageModel" means the LLM reads the user's message and corpus descriptions, then picks the most relevant. "show me sneakers" → catalog. "return policy?" → policy. |
| What is the contentInjectorTemplate for? | It defines HOW retrieved chunks appear in the model's prompt. Our template says "ENRICH your responses — combine with tool results." Without it, the model might ignore tool results and only use RAG. |

**Technical questions:**

| Question | Answer |
|----------|--------|
| Why are minScore thresholds different? | Policy (0.4) is loose — missing a relevant policy is worse than including a slightly-off one. Catalog/reviews (0.6) are stricter — injecting wrong product info is confusing. Tuning is empirical. |
| Do I need to re-index when corpus files change? | Yes. The in-memory store is built at application start. Restart CF (or hit a reload endpoint) to pick up changes. Production would use a persistent store with incremental updates. |
| What are citation chips? | UI badges showing source files (e.g., "returns-policy.pdf"). They come from `metadataKeys: ["file_name"]` — the retriever attaches file_name metadata to each chunk. |
| How is RAG different from putting everything in the system prompt? | System prompt has a token limit (~4K-8K useful). RAG retrieves only relevant chunks per query from potentially millions of documents. Targeted injection, not brute-force stuffing. |

**Production questions:**

| Question | Answer |
|----------|--------|
| What vector store would you use in production? | Pinecone, Weaviate, pgvector, or Qdrant. CF2025 supports pluggable providers. The INMEMORY store is for demos; production needs persistence and horizontal scaling. |
| How do you handle stale embeddings? | Implement a reindexing pipeline triggered by content updates. Track document versions and only re-embed changed documents. |

## Verification Checklist

1. Lab mode: send "what is your return policy?"
2. **Trace:** `retrieval.start` → `retrieval.hit` events, citation chips in response
3. Send "show me sneakers" 
4. **Expected:** Product cards (tools) + review/care insights (RAG) in same response
5. Send "do customers say the wool blazer fits true to size?"
6. **Expected:** Reviews corpus searched, specific sentiment surfaced
