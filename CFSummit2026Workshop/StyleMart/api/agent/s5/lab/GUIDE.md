# Session 5: RAG (Retrieval-Augmented Generation)

## What You'll Build

After this session, Mira answers questions from documents — return policies, product care instructions, and customer_reviews.csv. She retrieves relevant chunks via vector similarity search and enriches her tool-based responses with contextual insights and citation chips.

## Story So Far
Mira streams responses (S1), remembers context and preferences (S2), uses CFC tools for products/cart/orders (S3), and connects to MCP for weather and logistics (S4). But she cannot answer "what is your return policy?" or "do reviewers say this runs small?" because that data lives in documents.

## Key Concepts (Read While Instructor Presents)

- **RAG (Retrieval-Augmented Generation):** Before the model generates a response, relevant document chunks are retrieved from a vector store and injected into the prompt.
- **Vector store:** Stores document chunks as embeddings (numerical vectors). Similarity search finds chunks relevant to the user's query.
- **Embedding model:** Converts text into vectors (text-embedding-3-small). Similar meanings produce similar vectors.
- **Query router (languageModel type):** The LLM itself reads the user's message and decides WHICH corpus to search.
- **Content injector template:** Tells the model HOW to use the retrieved context — enrich tool results, do not replace them.
- **Citation chips:** UI badges showing which source file contributed to the answer. Enabled by `metadataKeys: ["file_name"]`.

**4 corpora:**
- **policy/** — return policies, exchanges, care instructions (high recall: maxResults=6, minScore=0.4)
- **catalog/** — product descriptions, materials (precision: maxResults=3, minScore=0.6)
- **reviews/** — customer review sentiment (precision: maxResults=3, minScore=0.6)
- **orders/** — order history context (maxResults=2, minScore=0.5)

## Your Workspace

**Files you will edit:**
- [`StyleMart/api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L1) — 3 TODOs (RAG pipeline)
- [`StyleMart/api/agent/s5/lab/init-rag.cfm`](init-rag.cfm#L1) — 2 TODOs (vector store creation + ingestion)
- [`StyleMart/api/agent/s5/lab/scratchpad.cfm`](scratchpad.cfm#L1) — standalone simpleRAG() sandbox (no TODOs — ready to run and experiment)

**Read-only reference:**
- [`StyleMart/api/agent/s5/ref/AgentService.cfc`](../ref/AgentService.cfc#L1)
- [`StyleMart/api/agent/s5/ref/init-rag.cfm`](../ref/init-rag.cfm#L1)
- [`StyleMart/api/agent/s5/config/ai.lab.json`](../config/ai.lab.json#L38) (rag config at line 38)
- `StyleMart/api/agent/s5/data/rag/` (corpus source files)

## Instructor Demo: Why RAG? (5 min)

Before writing any code, the instructor will demonstrate the difference RAG makes. Follow along by toggling between sessions yourself.

### The Hallucination Problem

Switch to **S4 Ref** (or S5 Lab — both lack RAG). Ask these questions and note the responses:

| Question | Without RAG (S4 Ref) | What's wrong |
|----------|---------------------|--------------|
| "What is your return policy for sale items?" | Deflects — "check StyleMart's website" or vague guess | Can't answer. No access to policy documents. |
| "Can the wool blazer be machine washed?" | Asks for product ID or gives generic advice | Can't answer. No care guide documents available. |
| "What if I bought something at 40% off?" | Deflects to customer service or guesses wrong | Can't answer the 40% final-sale threshold rule. |

**Key observation:** Without RAG, the model either deflects ("check with customer service") or guesses. It has no access to your actual policy documents, so it cannot give specific, correct answers.

### The RAG Fix

Now switch to **S5 Ref**. Ask the same questions:

| Question | With RAG (S5 Ref) | What's different |
|----------|-------------------|-----------------|
| "What is your return policy for sale items?" | Specific policy with citation chips | Answer cites `StyleMart Returns & Exchange Policy` — grounded in a real document |
| "Can the wool blazer be machine washed?" | "Yes — cold cycle, mesh bag" + citation | Sourced from `StyleMart Wool & Delicate Fabric Care Guide` — verifiable |
| "What if I bought something at 40% off?" | "Items 40%+ off are final sale" | Sourced from `StyleMart Returns & Exchange Policy` — correct |

**Check the response:** Citation chips (small badges like `StyleMart Returns & Exchange Policy`) appear on the answer — this is the proof that the answer is grounded in your actual documents, not hallucinated.

### The Takeaway

| | Without RAG | With RAG |
|---|---|---|
| Source | Model's training data (stale, generic) | Your actual documents (current, specific) |
| Verifiable? | No — no citations | Yes — citation chips show source |
| Traceable? | No — no citations | Yes — citation chips show source file on every answer |
| Hallucination risk | High — model invents plausible answers | Low — answers grounded in retrieved chunks |

---

## The "Lab Fails, Ref Works" Beat

Before writing code, establish what S5 Lab **cannot** do yet. These questions test knowledge that lives ONLY in policy documents — no tool can answer them.

### Baseline: Ask S5 Lab (before your changes)

Send these in S5 Lab mode and note what you get:

| Question | Expected without RAG | Why tools can't help |
|----------|---------------------|---------------------|
| "I bought a jacket at 45% off and it doesn't fit. Can I return it?" | Deflects ("check with customer service") or vague guess | No tool queries return policies. Model has no policy documents. |
| "My chest is 39 inches — what size for a slim fit shirt?" | Generic — "M or L" without source, or deflects | No tool has the size chart measurements or fit guide rules. |
| "I received a damaged blazer. What do I do?" | Vague — "contact customer service" | No tool knows the 48-hour window or no-shipping-required rule. |

**Check the response:** No citation chips appear. The model either deflects or guesses — it has no access to the policy documents.

### Verify with S5 Ref

Now toggle to **S5 Ref** and ask the same questions:

| Question | Expected with RAG | Proof it's real |
|----------|-------------------|-----------------|
| "I bought a jacket at 45% off and it doesn't fit. Can I return it?" | "Items at 40%+ off are final sale — no returns or exchanges." | Citation chip: `StyleMart Returns & Exchange Policy` |
| "My chest is 39 inches — what size for a slim fit shirt?" | "Men's M (38-40 chest). Slim fit tip: size up if between sizes." | Citation chip: `StyleMart Size Guide — Tops & Outerwear` |
| "I received a damaged blazer. What do I do?" | "Contact us within 48 hours for immediate replacement. No return shipping required." | Citation chip: `StyleMart Returns & Exchange Policy` |

**Check the response:** Citation chips appear on each answer (e.g., `StyleMart Returns & Exchange Policy`, `StyleMart Size Guide — Tops & Outerwear`). This confirms the answer is sourced from your documents.

### Your job

Make Lab work like Ref by filling 5 TODOs across 2 files. After completing all steps, come back to these same 3 questions and verify you get the RAG-grounded answers with citation chips.

## Catching Up

If you are starting fresh or fell behind:
1. Toggle to Ref mode — verify RAG works (send "what is your return policy?", see policy info + citation chips)
2. For S4 catch-up: copy `s4/ref/AgentService.cfc` → `s4/lab/AgentService.cfc`

## Quick Start: RAG in 5 Lines (Scratchpad)

Before diving into the full multi-corpus agent wiring, try the simplest possible RAG — a single file that loads policy documents and answers questions with **zero agent setup**. The scratchpad uses its own `application.simpleRagBot` object (separate VectorStore, separate ChatModel) — it does NOT interfere with your lab agent pipeline.

**File:** [`api/agent/s5/lab/scratchpad.cfm`](scratchpad.cfm#L1)

**Run it:** Open in your browser:
http://localhost:8500/CFSummit2026Workshop/StyleMart/api/agent/s5/lab/scratchpad.cfm

**What it does:**
1. Creates a `ChatModel` and `VectorStore` (lines 20-42)
2. Calls `simpleRAG(policyDir, chatModel, options)` — one function that loads, chunks, embeds, and stores documents (line 31)
3. Calls `.ingest()` to process the docs (line 45)
4. Asks 3 questions and displays answers with `chat()` (lines 58-62)

**Key takeaway:** `simpleRAG()` is the "batteries-included" shortcut — great for prototypes. The full agent pipeline (Steps 1-5 below) gives you multi-corpus routing, tuned retrieval, and citation chips.

**Experiment:** Edit the `questions` array (line 55) — try replacing with your own questions:
```cfml
questions = [
    "How many days do I have to return a worn item?",
    "Can I tumble-dry a cashmere sweater?",
    "I'm 6'2 with a 34 waist — what jeans size?",
    "Are gift cards refundable?",
    "What temperature should I iron linen at?"
];
```

---

## Step-by-Step Instructions

### Step 1: Create VectorStore for each corpus

**File:** [`api/agent/s5/lab/init-rag.cfm`](init-rag.cfm#L64)
**Find:** [`// TODO-S5-1`](init-rag.cfm#L71) — `vs = "" /* TODO-S5-1 */;`

**What this does:** Creates an in-memory vector store for a corpus. The embedding model converts text chunks into vectors for similarity search.

**Code to write:**
```cfml
vs = VectorStore({
  provider:
    ragCfg.vectorStoreProvider ?: "INMEMORY",
  embeddingModel: embeddingConfig
});
```

**Save the file.**

---

### Step 2: Ingest documents asynchronously

**File:** [`api/agent/s5/lab/init-rag.cfm`](init-rag.cfm#L73)
**Find:** [`// TODO-S5-2`](init-rag.cfm#L78)

**What this does:** Converts document segments into embeddings and stores them in the vector store. Runs asynchronously so the application starts quickly.

**Code to write:**
```cfml
future = docService.ingestAsync(segments, vs);
arrayAppend(
  server.stylemart.ragFuturesLab, future
);
```

**Save the file.**

---

---

### Step 3: Build contentRetrievers array

**File:** [`api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L134)
**Find:** [`// TODO-S5-3`](AgentService.cfc#L150) — `var contentRetrievers = [] /* TODO-S5-3 */;`

**What this does:** Creates one retriever entry per corpus. Each has its own tuned parameters and a description that the query router reads to decide which corpus to search.

**Code to write:**
```cfml
if (structKeyExists(stores, "policy")) {
  arrayAppend(contentRetrievers, {
    vectorStore: stores.policy,
    maxResults: 6, minScore: 0.4,
    description: "Store policies: return policy, "
      & "exchange policy, refund timelines, "
      & "sale item restrictions, size guides, "
      & "clothing care instructions, "
      & "washing guidelines"
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

**Save the file.**

---

### Step 4: Build the contentInjector

**File:** [`api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L154)
**Find:** [`// TODO-S5-4`](AgentService.cfc#L164) — `var contentInjector = {} /* TODO-S5-4 */;`

**What this does:** Defines how retrieved chunks are presented to the model. The template tells it to ENRICH responses (combine RAG with tools). metadataKeys enables citation chips in the UI.

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

**Save the file.**

---

### Step 5: Assemble the retrievalAugmentor

**File:** [`api/agent/s5/lab/AgentService.cfc`](AgentService.cfc#L166)
**Find:** [`// TODO-S5-5`](AgentService.cfc#L177) — `return {} /* TODO-S5-5 */;`

**What this does:** Returns the complete RAG configuration struct. The queryRouter with type "languageModel" means the LLM decides which corpus to search per query.

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

**Save the file.**

### Restart the application

All 5 TODOs are complete. Restart the application so `init-rag.cfm` creates vector stores (Steps 1-2) and new chat sessions pick up the RAG augmentor (Steps 3-5).

**How to restart:** Add `?reload=true` to the agent API register page:
```
http://localhost:8500/CFSummit2026Workshop/StyleMart/api/agent/register.cfm?reload=true
```
> **Important:** The reload must hit the API application (under `api/agent/`), not `index.cfm`. The RAG bootstrap runs in the API's `onApplicationStart()`, which is a separate CF application from the UI.

Wait ~10 seconds for ingestion to complete, then **open a new chat session** (click "New Chat" or refresh).

**Verify:** Send "what is your return policy?" in Lab mode. The response should include specific policy details with a citation (e.g., `StyleMart Returns & Exchange Policy`).

> **Troubleshooting:** If you get answers without citations, the agent was built before the vector stores were ready. Click "New Chat" to create a fresh session — existing sessions cache the agent object from when they were created. Also check your ColdFusion logs for `[S5-RAG] Ingesting policy async:` messages — if you see `Bootstrap complete — 0 total segments`, your TODO-S5-1 or TODO-S5-2 code isn't running correctly.

---

## Try It Out

First, re-run your baseline queries from the "Lab Fails" section above. They should now produce specific, cited answers.

Then try these additional queries that demonstrate RAG enriching tool responses:

| What to type in chat | What you should see | What's new vs. S3/S4 |
|---------------------|--------------------|-----------------------|
| "I bought a jacket at 45% off. Can I return it?" | "Final sale — no returns" + citation chip (`StyleMart Returns & Exchange Policy`) | RAG-only answer. No tool involved. |
| "Can I machine wash the wool blazer?" | "Yes — cold/delicate 30C, mesh bag, tumble dry 10 min max" + citation (`StyleMart Wool & Delicate Fabric Care Guide`) | Specific procedure from document, not a generic guess. |
| "My chest is 39 inches, what size in slim fit?" | "Men's M (38-40 chest). Slim fit: size up if between sizes." + citation (`StyleMart Size Guide — Tops & Outerwear`) | Size chart + fit rules from document. |
| "show me sneakers" | Product cards + review/care enrichment | Tools provide cards; RAG may inject care tips or review context alongside. |
| "how should I care for linen clothing?" | Specific instructions: gentle cycle, cold/lukewarm, no tumble dry + citation (`StyleMart General Garment Care Instructions`) | Document procedure, not product-level one-liner. |
| "How long until I get my refund?" | "5-7 business days processing + 3-5 for credit card" + citation | Specific timeline from policy. Without RAG: vague "a few business days." |

## Experiments (Core Learning Activity)

### E1 — RAG vs. Tools: What Answers Come From Where?

Send these queries in sequence. The real signal is **what appears in the response**: tool-generated product cards vs. RAG-sourced text with citation chips.

| Query | Tool events? | Citation chips? | Source of answer |
|-------|-------------|-----------------|-----------------|
| "show me shirts" | `tool.call(searchCatalog)` → `tool.result` | Maybe (care/review enrichment) | Tools (product cards) + optional RAG context |
| "what do customers say about the white crew neck?" | `tool.call(GetProductReviews)` → `tool.result` | No — tool has the data | Tool — reviews are in the database |
| "can I return it if I wore it once?" | None | Yes (`StyleMart Returns & Exchange Policy`) | RAG only — policy says "unworn, unwashed, tags attached" |
| "how do I measure my chest for sizing?" | None | Yes (`StyleMart Size Guide — Tops & Outerwear`) | RAG only — size guide has measurement instructions |

**Key insight:** Reviews and product details come from TOOLS (database). Policies, care guides, and size charts come from RAG (documents). The proof is citation chips — when the answer draws from a document, you'll see the source filename cited. The model seamlessly combines both.

### E2 — Query Router in Action

The router decides internally which corpus to search — you can't see the routing decision directly in the trace, but you CAN see the result: citation chips name the source file, which tells you which corpus was selected.

Send different queries and check which file appears in the citation:
- "what is your return policy for worn items?" → citation: `StyleMart Returns & Exchange Policy` (policy corpus)
- "what size is a 36-inch chest?" → citation: `StyleMart Size Guide — Tops & Outerwear` (policy corpus)
- "tell me about blazer materials" → may use catalog corpus or tools
- "what do customers say about fit?" → may cite `customer_reviews.csv` or use GetProductReviews tool
- "show me my recent orders" → tool (getOrderHistory) — no citation expected

### E3 — The Hallucination Fix (Re-run Baseline)

Re-send your 3 baseline queries from earlier. Compare your notes:

| Query | Before (no RAG) | After (RAG) | Difference |
|-------|-----------------|-------------|-----------|
| "45% off jacket, can I return?" | Deflected or guessed wrong | "Final sale" (correct, cited) | Grounded in document |
| "Chest 39 inches, slim fit size?" | Vague "M or L" or deflected | "M (38-40 chest). Slim fit: size up if between sizes." (cited) | Specific guidance from size chart |
| "Damaged blazer, what do I do?" | Generic "contact support" | "48 hours, immediate replacement, free return" (cited) | Actionable detail from policy |

### E4 — Citation Chips Deep-Dive

Send "What are all the rules about returning sale items?" Expected: detailed answer citing `StyleMart Returns & Exchange Policy`. Hover over the citation chip to see which document section contributed. This is the trust mechanism — users can verify claims.

### E5 — RAG + Tools Together

Send "show me wool jackets and tell me how to care for them". Watch for:
1. **Trace → Tools section:** `tool.call(searchCatalog)` fires → product cards appear
2. **Response:** Specific care instructions with citation chip (`StyleMart Wool & Delicate Fabric Care Guide`)

The response should show product cards (from tools) AND specific care instructions (from RAG), in one turn. This is richer than S3/S4 which could only show products.

### E6 — Edge Cases

- "Can I put the blazer in the dryer?" → tests concept bridging ("dryer" maps to "tumble dry on low heat for no more than 10 minutes")
- "What if I bought something at 39% off?" → tests boundary condition (39% < 40%, so standard return policy applies — not final sale)
- "I need to iron my silk blouse" → tests specific care rule ("iron on low heat while slightly damp, use pressing cloth")

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No citation chips on responses | Vector stores not initialized. Restart the application to trigger init-rag.cfm. Check server log for "[S5-RAG]" messages. |
| "ragVectorStoresLab is undefined" | init-rag.cfm did not run. Any request should trigger onApplicationStart. |
| Citation chips do not appear in UI | Verify TODO-S5-4 includes `metadataKeys: ["file_name"]` |
| buildRagAugmentor returns null | Check ai.lab.json has `"rag": {"enabled": true}` and stores are populated |
| Embedding errors | Check that the API key in ai.lab.json is valid (embeddings use the same key) |

## Frequently Asked Questions

| Question | Answer |
|----------|--------|
| Why 4 separate vector stores? | Different corpora need different tuning. Policy needs high recall (do not miss relevant rules). Catalog needs precision (do not inject wrong products). Separate stores allow independent tuning. |
| How does the query router choose? | The LLM reads the user's message and each corpus description, then picks the most relevant. It is an extra LLM call but very fast (~100ms). |
| What is the contentInjectorTemplate for? | It tells the model how to use retrieved context. Our template says "enrich your responses alongside tool results." Without it, the model might ignore tools when RAG provides context. |
| Do I need to re-index when files change? | Yes. The in-memory store is built at app start. Restart CF to pick up changes. Production would use persistent stores with incremental updates. |
| What are citation chips? | UI badges showing source filenames (e.g., "StyleMart Returns & Exchange Policy"). Enabled by metadataKeys. They build user trust by showing where information came from. |
| How is RAG different from a big system prompt? | System prompts have token limits. RAG retrieves only relevant chunks per query from thousands of documents. Targeted injection vs. brute-force prompt stuffing. |

## What's Next

Mira has the full capability stack: streaming, memory, tools, MCP, and RAG. But nothing stops her from promising a "guaranteed perfect fit" or inventing a discount. Session 6 adds guardrails — input/output validators that enforce safety rules the model cannot bypass through prompt engineering.
