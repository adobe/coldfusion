# ColdFusion Language Webinar — Sample Demos

A collection of interactive demo applications showcasing the latest ColdFusion features — from AI-powered NLP and vector databases to modern language constructs, native data structures, and async programming.

---

## Prerequisites

- **ColdFusion Server** — A running ColdFusion instance (2025+ or a local dev build).
- The `webinar/` folder must be deployed under the ColdFusion web root (e.g. `<cfusion-install>/wwwroot/webinar/`).
- Additional prerequisites per category are noted below.

## How to Run

1. **Start the ColdFusion server** if it is not already running.

2. **Open the landing page** in a browser:

   ```
   http://localhost:8500/webinar/index.cfm
   ```

   (Adjust host and port to match your ColdFusion server configuration.)

3. The landing page provides clickable cards for every demo, grouped by category. Click any card to run that demo in a new tab.

4. Individual demos can also be accessed directly by URL (paths listed below).

---

## File Structure

```
webinar/
├── index.cfm                       # Landing page — card grid linking to all demos
│
├── BIF/                            # Built-in Function demos
│   ├── directoryCreate.cfm         # DirectoryCreate with createPath & ignoreExists
│   ├── fileMismatch.cfm            # FileMismatch — byte-level file comparison
│   ├── fileReadLines.cfm           # FileReadLines — line-range file reading
│   ├── testfiles/                  # Sample log files for fileMismatch demo
│   └── logfiles/                   # Sample log file for fileReadLines demo
│
├── asyncdemos/                     # Async & Concurrency demos
│   ├── asyncAllOf.cfm              # asyncAllOf — wait for all futures
│   ├── asyncAnyOf.cfm              # asyncAnyOf — first future wins
│   ├── thenCombine.cfm             # thenCombine — merge two futures
│   ├── completeOnTimeout.cfm       # completeOnTimeout — fallback on slow tasks
│   └── orTimeout.cfm               # orTimeout — cancel on deadline
│
├── bifcallback/                    # NLP & Callback demos
│   ├── reviews.cfm                 # Sentiment analysis with OpenNLP
│   ├── entityrecognition.cfm       # Named Entity Recognition with OpenNLP
│   ├── udfcallback.cfm             # UDF callbacks with java{} block
│   └── models/opennlp/             # OpenNLP model binaries (must be provided)
│
├── exception/                      # Custom Exception Handling demos
│   ├── Application.cfc             # Registers typed exception handlers
│   ├── customexception.cfm         # Throw and catch custom exceptions
│   ├── errhandler.cfm              # Triggers typed exception routing
│   ├── eType1Page.cfm              # Handler for etype1 exceptions
│   └── eType2Page.cfm              # Handler for etype2 exceptions
│
├── javainterop/                    # Java Interop demos
│   ├── index.cfm                   # Java Streams with Predicates (Dynamic Proxy + Lambda)
│   └── pred.cfc                    # CFC implementing java.util.function.Predicate
│
├── literals/                       # Language Literals & Expression demos
│   ├── Application.cfc             # Enables null support & case-preserving keys
│   ├── complexexp.cfm              # Complex expressions, ternary chains, inline closures
│   └── functionchaining.cfm        # Fluent struct/array chaining with inline literals
│
├── mcp/                            # Model Context Protocol (MCP) demos
│   ├── Application.cfc             # MCP app config
│   ├── mathsMCPServer.cfm          # MCP Server — exposes tools for AI agents
│   ├── clientcopy.cfm              # MCP Client — connects to and calls MCP tools
│   └── weatherTool.cfc             # Weather tool CFC (getCurrentWeather, getForecast, getTemperature)
│
├── qoq/                            # Query of Queries demos
│   └── opeval.cfm                  # Operator evaluation in QoQ expressions
│
├── rag/                            # Retrieval-Augmented Generation demos
│   ├── simplerag.cfm               # Full SimpleRAG pipeline (ingest, ask, chat, memory)
│   └── minimalrag.cfm              # Minimal RAG — stripped-down retrieve-then-generate
│
├── sets/                           # Native Set data type demos
│   ├── basic.cfm                   # Set basics — add, delete, has, size, clear
│   ├── advanced.cfm                # Union, intersection, difference, symmetricDifference
│   ├── performance.cfm             # Set vs Array lookup benchmark (100K items)
│   ├── ecommerce.cfm               # E-commerce product filtering with Sets
│   └── friendsuggestion.cfm        # Social friend suggestion engine with Sets
│
└── vectordatabases/                # Vector Database demos
    └── query.cfm                   # In-memory vector store: ingest, search, comparison matrix
```

---

## Demo Details by Category

### 1. AI & Machine Learning

#### Sentiment Analysis — Review Classifier

| | |
|---|---|
| **File** | `bifcallback/reviews.cfm` |
| **URL** | `/webinar/bifcallback/reviews.cfm` |
| **What it does** | Analyzes customer reviews using Apache OpenNLP. Classifies text as positive, negative, or neutral with confidence scores. Includes an interactive form to submit your own reviews. |
| **Features demonstrated** | `java{}` block (inline Java class), `arrayMap()` with Java `Function`, OpenNLP tokenization & POS tagging |
| **Prerequisites** | (1) Place `opennlp-tools-2.3.0.jar` in `<cfusion-install>/lib/` and restart the server. (2) OpenNLP model files must be placed at `bifcallback/models/opennlp/`: `en-token.bin`, `en-pos-maxent.bin` |

#### Named Entity Recognition (NER)

| | |
|---|---|
| **File** | `bifcallback/entityrecognition.cfm` |
| **URL** | `/webinar/bifcallback/entityrecognition.cfm` |
| **What it does** | Extracts persons, locations, and organizations from text using OpenNLP NER models. Includes an interactive form and pre-loaded sample texts. |
| **Features demonstrated** | `java{}` block, `arrayMap()` with Java `Function`, multi-model NER pipeline |
| **Prerequisites** | (1) Place `opennlp-tools-2.3.0.jar` in `<cfusion-install>/lib/` and restart the server. (2) OpenNLP model files at `bifcallback/models/opennlp/`: `en-token.bin`, `en-ner-person.bin`, `en-ner-location.bin`, `en-ner-organization.bin` |

#### Vector Database — Semantic Search

| | |
|---|---|
| **File** | `vectordatabases/query.cfm` |
| **URL** | `/webinar/vectordatabases/query.cfm` |
| **What it does** | Ingests 8 documents into an in-memory vector store, runs 4 semantic queries, ranks results by similarity score, and builds a cross-query comparison matrix. |
| **Features demonstrated** | `VectorStore()`, `.addAll()`, `.search()` with topK and minScore, semantic similarity scoring |
| **Prerequisites** | Ollama running locally (`http://127.0.0.1:11434`) with the `all-minilm:latest` embedding model pulled |

#### Retrieval-Augmented Generation (RAG)

| | |
|---|---|
| **Files** | `rag/simplerag.cfm` (comprehensive), `rag/minimalrag.cfm` (minimal) |
| **URL** | `/webinar/rag/simplerag.cfm` |
| **What it does** | Full RAG pipeline: creates test documents, ingests them into a vector store, demonstrates stateless `ask()` vs stateful `chat()` with memory, and compares both side-by-side. |
| **Features demonstrated** | `SimpleRag()`, `ChatModel()`, `VectorStore()`, `.ingest()`, `.ask()`, `.chat()`, `.getConfiguration()`, `.getStatistics()` |
| **Prerequisites** | Ollama running locally with `all-minilm` model; OpenAI API key configured in the script for the chat model |
| **Note** | These demos are currently commented out in `index.cfm`. Uncomment the cards to enable them. |

#### MCP Server & Client

| | |
|---|---|
| **Files** | `mcp/mathsMCPServer.cfm` (server), `mcp/clientcopy.cfm` (client), `mcp/weatherTool.cfc` (tool) |
| **URL** | `/webinar/mcp/clientcopy.cfm` (client connects to the server) |
| **What it does** | The server exposes weather tools (`getCurrentWeather`, `getForecast`, `getTemperature`) via the Model Context Protocol. The client connects over HTTP transport and calls tools. |
| **Features demonstrated** | `createMCPServer()`, `CreateMCPClient()`, MCP tool discovery, `.callTool()` |
| **Note** | Currently commented out in `index.cfm`. Uncomment to enable. |

---

### 2. Language Features

#### Complex Expressions & Ternary Chains

| | |
|---|---|
| **File** | `literals/complexexp.cfm` |
| **URL** | `/webinar/literals/complexexp.cfm` |
| **What it does** | Demonstrates environment-specific logger creation using chained ternary expressions with inline closure definitions. Creates production/staging/development loggers dynamically. |
| **Features demonstrated** | `param` with ternary `? :` chains, inline closures `() =>`, `function()` expressions |

#### Function Chaining on Literals

| | |
|---|---|
| **File** | `literals/functionchaining.cfm` |
| **URL** | `/webinar/literals/functionchaining.cfm` |
| **What it does** | Chains `.append()` and `.map()` calls directly on struct and array literals. Demonstrates deep nested struct access on inline literals and nested array indexing with chaining. |
| **Features demonstrated** | Literal chaining `{ foo:'bar'}.append({...}).map(...)`, deep key access `{...}.app["database"]`, nested array access `[...][2].append(...)` |

#### Java Interop — Streams & Predicates

| | |
|---|---|
| **File** | `javainterop/index.cfm` + `javainterop/pred.cfc` |
| **URL** | `/webinar/javainterop/index.cfm` |
| **What it does** | Filters a list using Java Streams in two ways: (1) a CFC implementing `java.util.function.Predicate` via `createDynamicProxy`, and (2) a CFML lambda passed directly to `.filter()`. |
| **Features demonstrated** | `createDynamicProxy()`, `component implements="java:..."`, Java `Stream.filter().collect()`, CFML lambda `=>` interop |

#### UDF Callbacks with java{} Block

| | |
|---|---|
| **File** | `bifcallback/udfcallback.cfm` |
| **URL** | `/webinar/bifcallback/udfcallback.cfm` |
| **What it does** | Defines a `NumericPredicate` Java class inline using the `java{}` block. Uses it with `arrayFilter()` to filter numeric values from a mixed string array. |
| **Features demonstrated** | `java{}` block, inline Java class implementing `Predicate`, `arrayFilter()` with Java object |

#### Custom Exception Handling

| | |
|---|---|
| **Files** | `exception/Application.cfc`, `customexception.cfm`, `errhandler.cfm`, `eType1Page.cfm`, `eType2Page.cfm` |
| **URL** | `/webinar/exception/customexception.cfm` (basic), `/webinar/exception/errhandler.cfm` (typed routing) |
| **What it does** | Demonstrates typed exception handling. `Application.cfc` registers two `cferror` handlers mapped to different exception types. Throwing an `etype2` exception routes to `eType2Page.cfm`, while `etype1` routes to `eType1Page.cfm`. |
| **Features demonstrated** | `throw(type="...")`, `cferror(type="exception", exception="...", template="...")`, exception-type routing |

---

### 3. Built-in Functions (BIFs)

#### FileMismatch — Log Drift Detector

| | |
|---|---|
| **File** | `BIF/fileMismatch.cfm` |
| **URL** | `/webinar/BIF/fileMismatch.cfm` |
| **What it does** | Compares a "known-good" backup log against the current log byte-by-byte using `FileMismatch()`. Pinpoints the exact byte position and line number where files diverge, then renders a side-by-side context view and full diff summary. |
| **Features demonstrated** | `FileMismatch()`, `getFileInfo()`, `fileRead()`, line-by-line diff rendering |
| **Prerequisites** | Sample log files must exist at `BIF/testfiles/server_log_backup.txt` and `BIF/testfiles/server_log_current.txt` |

#### FileReadLines

| | |
|---|---|
| **File** | `BIF/fileReadLines.cfm` |
| **URL** | `/webinar/BIF/fileReadLines.cfm` |
| **What it does** | Reads specific lines from a log file using `FileReadLines()` with start line and count parameters. |
| **Features demonstrated** | `FileReadLines(file, startLine, count)` |
| **Prerequisites** | A sample log file at `BIF/logfiles/sample_log.txt` |

#### DirectoryCreate

| | |
|---|---|
| **File** | `BIF/directoryCreate.cfm` |
| **URL** | `/webinar/BIF/directoryCreate.cfm` |
| **What it does** | Creates a nested directory structure in one call using `createPath=true` and `ignoreExists=true` options. Verifies by listing the created structure. |
| **Features demonstrated** | `DirectoryCreate(path, createPath, ignoreExists)`, `DirectoryList()` |

---

### 4. Sets & Data Structures

#### Set Basics

| | |
|---|---|
| **File** | `sets/basic.cfm` |
| **URL** | `/webinar/sets/basic.cfm` |
| **What it does** | Demonstrates core Set operations: creating a set, adding elements (including closures), automatic deduplication, `has()` membership check, `delete()`, `clear()`, and `size()`. |
| **Features demonstrated** | `setNew()`, `.add()`, `.delete()`, `.has()`, `.size()`, `.clear()` |

#### Advanced Set Operations

| | |
|---|---|
| **File** | `sets/advanced.cfm` |
| **URL** | `/webinar/sets/advanced.cfm` |
| **What it does** | Performs set algebra: union, intersection, difference, and symmetric difference on ordered sets. Also demonstrates creating a Set from an array for automatic deduplication. |
| **Features demonstrated** | `setNew("ordered")`, `setUnion()`, `setIntersection()`, `SetDifference()`, `setSymmetricDifference()`, `setNew(array)`, `.ToArray()` |

#### Set Performance Benchmarks

| | |
|---|---|
| **File** | `sets/performance.cfm` |
| **URL** | `/webinar/sets/performance.cfm` |
| **What it does** | Benchmarks Set vs Array for deduplicating 100,000 random values. Array uses `arrayFind()` (O(n) per lookup), while Set uses `.add()` (O(1)). Reports the speedup factor. |
| **Features demonstrated** | `SetNew()`, `.add()` vs `arrayFind()` + `arrayAppend()`, performance comparison |

#### E-Commerce — Set Use Case

| | |
|---|---|
| **File** | `sets/ecommerce.cfm` |
| **URL** | `/webinar/sets/ecommerce.cfm` |
| **What it does** | Models product feature catalogs (wireless, bluetooth, USB-C) as Sets. Finds products with both wireless AND bluetooth (intersection), wireless but not bluetooth (difference), wireless OR USB-C (union), and checks for disjoint categories. |
| **Features demonstrated** | `SetNew(array)`, `setIntersection()`, `setDifference()`, `setUnion()`, `setIsDisjointFrom()` |

#### Friend Suggestion Engine

| | |
|---|---|
| **File** | `sets/friendsuggestion.cfm` |
| **URL** | `/webinar/sets/friendsuggestion.cfm` |
| **What it does** | Implements a social network friend-of-a-friend suggestion algorithm. Uses union to collect all friends-of-friends, then difference to remove existing friends. Ranks suggestions by mutual friend count. |
| **Features demonstrated** | `SetNew()`, `.add()`, `setUnion()`, `setDifference()`, `.has()`, `setToList()` |

---

### 5. Async & Concurrency

#### asyncAllOf — Wait for All Futures

| | |
|---|---|
| **File** | `asyncdemos/asyncAllOf.cfm` |
| **URL** | `/webinar/asyncdemos/asyncAllOf.cfm` |
| **What it does** | Spawns 3 parallel futures (profile data, activity data, notifications) with different sleep times. Uses `asyncAllOf()` to wait for all to complete. Reports each task's thread and timing, plus total elapsed time. |
| **Features demonstrated** | `runAsync()`, arrow functions `() =>`, `asyncAllOf()`, `.get()`, `Thread.currentThread().getName()` |

#### asyncAnyOf — First Future Wins

| | |
|---|---|
| **File** | `asyncdemos/asyncAnyOf.cfm` |
| **URL** | `/webinar/asyncdemos/asyncAnyOf.cfm` |
| **What it does** | Races 3 data sources (local cache 50ms, Redis 10ms, database 500ms). `asyncAnyOf()` returns whichever completes first. Demonstrates the "fastest source wins" pattern. |
| **Features demonstrated** | `runAsync()`, `asyncAnyOf()`, `.get()`, race pattern |

#### thenCombine — Merge Two Futures

| | |
|---|---|
| **File** | `asyncdemos/thenCombine.cfm` |
| **URL** | `/webinar/asyncdemos/thenCombine.cfm` |
| **What it does** | Fetches product price (300ms) and user discount (200ms) in parallel. `thenCombine()` merges both results into a final discounted price. Shows thread names for each stage. |
| **Features demonstrated** | `runAsync()`, `.thenCombine(otherFuture, combinerFunction)`, `.get()` |

#### completeOnTimeout — Graceful Fallback

| | |
|---|---|
| **File** | `asyncdemos/completeOnTimeout.cfm` |
| **URL** | `/webinar/asyncdemos/completeOnTimeout.cfm` |
| **What it does** | A slow task (1000ms) is given a 500ms timeout. If it doesn't complete in time, `completeOnTimeout()` substitutes a default fallback value instead of throwing an error. |
| **Features demonstrated** | `runAsync()`, `.completeOnTimeout(defaultValue, timeoutMs)`, `.get()`, graceful degradation |

#### orTimeout — Fail Fast with Exception

| | |
|---|---|
| **File** | `asyncdemos/orTimeout.cfm` |
| **URL** | `/webinar/asyncdemos/orTimeout.cfm` |
| **What it does** | Two tests: (1) a 2000ms task with 1000ms timeout — throws a timeout exception, and (2) a 500ms task with 1000ms timeout — completes successfully. Demonstrates hard deadline enforcement. |
| **Features demonstrated** | `runAsync()`, `.orTimeout(timeoutMs)`, `.get()`, `try/catch` timeout handling |

---

### 6. Query of Queries

#### Operator Evaluation in QoQ

| | |
|---|---|
| **File** | `qoq/opeval.cfm` |
| **URL** | `/webinar/qoq/opeval.cfm` |
| **What it does** | Creates an in-memory query with numeric columns and runs a QoQ that performs arithmetic (`qtyOnHand - qty1 - qty2`) in the SELECT clause. |
| **Features demonstrated** | `queryNew()`, `queryAddRow()`, `querySetCell()`, `<cfquery dbtype="query">`, arithmetic in QoQ SELECT |

---

## External Dependencies Summary

| Demo | Dependency | Setup |
|---|---|---|
| Sentiment Analysis, NER | Apache OpenNLP JAR + models | Place `opennlp-tools-2.3.0.jar` in `<cfusion-install>/lib/` (restart required). Download `.bin` model files to `bifcallback/models/opennlp/` |
| Vector Database | Ollama + `all-minilm` model | `ollama pull all-minilm:latest`, run on `localhost:11434` |
| RAG demos | Ollama + OpenAI API key | Ollama for embeddings, OpenAI API key in script for chat model |
| MCP demos | None (self-contained server) | Server and client run on the same ColdFusion instance |
| All other demos | None | Fully self-contained, no external dependencies |

---

## Quick Reference — ColdFusion BIFs Demonstrated

| Category | Functions |
|---|---|
| **Async** | `runAsync()`, `asyncAllOf()`, `asyncAnyOf()`, `.then()`, `.thenCombine()`, `.get()`, `.completeOnTimeout()`, `.orTimeout()` |
| **Sets** | `setNew()`, `.add()`, `.delete()`, `.has()`, `.size()`, `.clear()`, `setUnion()`, `setIntersection()`, `SetDifference()`, `setSymmetricDifference()`, `setIsDisjointFrom()`, `setToList()`, `.ToArray()` |
| **File I/O** | `FileMismatch()`, `FileReadLines()`, `DirectoryCreate()`, `DirectoryList()`, `getFileInfo()`, `fileRead()` |
| **Java Interop** | `java{}` block, `createDynamicProxy()`, `component implements="java:..."`, Java Stream API |
| **AI/ML** | `VectorStore()`, `.addAll()`, `.search()`, `SimpleRag()`, `ChatModel()`, `.ingest()`, `.ask()`, `.chat()` |
| **MCP** | `createMCPServer()`, `CreateMCPClient()`, `.callTool()`, `McpServerCapabilitiesBuilder()` |
| **Query** | `queryNew()`, `queryAddRow()`, `querySetCell()`, `<cfquery dbtype="query">` |
| **Language** | Ternary chains, inline closures, function chaining on literals, arrow functions `=>`, `cferror()`, `throw()` |
