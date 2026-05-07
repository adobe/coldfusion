# CF 2025.8 Beta Sample Code

This repository contains hands-on sample projects used across the ColdFusion 2025.8 beta sessions.  
The folders are organized by day/topic and include slide decks, runnable `.cfm` demos, helper CFCs, and supporting datasets.

## Folder Overview

### `Day2-AI Models`
- Focus: Core AI features in CF 2025 using `ChatModel()`, `agent()`, tools, memory, guardrails, streaming, RAG, and MCP.
- Main areas:
  - `aiTesting/demo/` - single-page feature showcase with API endpoints for each AI capability.
  - `aiTesting/nexora/` - end-to-end support-assistant style app ("Nexora") with progressive problem demos:
    - chat, system message, memory, tools, guardrails, streaming, MCP, RAG, observability.
- Includes sample policy/docs text files and tool CFCs (`EcommerceTool.cfc`, `FinancialTool.cfc`, etc.) used by agents.

### `Day3-Model Context Protocol`
- Focus: Deep dive into MCP server/client features in ColdFusion.
- Main area: `demoApp/`
  - `index.html` - tabbed "MCP Feature Explorer" UI.
  - `api/*.cfm` - endpoint demos for tools, resources, prompts, logging, sampling, elicitation, roots, and misc server controls.
  - `mcpServer/cf/` - ColdFusion MCP server examples for prompts/resources/tools.
- Good reference for learning how to wire MCP clients with advanced capabilities and server-side controls.

### `Day4-VectorStores and RAG`
- Focus: Retrieval-Augmented Generation patterns with ColdFusion primitives.
- Includes a detailed local readme: `Day4-VectorStores and RAG/README.md`.
- Main area: `demos/`
  - `Application.cfc` - environment-driven config for models, embeddings, and vector stores.
  - `runners/` - focused `*-init.cfm` demos (simple RAG, advanced retrieval, guardrails, ETL/lazy load).
  - `Documents/` and `Corpus/` - ingestion data for retrieval scenarios.
  - `docs/` - explainers shown by the demo UI.
- Demonstrates both quick-start and advanced composition patterns (`simpleRAG()`, `agent()`, `documentService()`, `vectorStore()`).

### `Day5-CFB Extension Webinar`
- Focus: CFB extension workflows, cloud/AI helper snippets, and dockerized webinar setup.
- Main areas:
  - `DemoProject/WebinarDocker/` - Docker + compose setup and sample app deployment files.
  - `DemoProject/CodeAssistDemo/` - code assist examples across AI, storage, filesystem, and RAG.
  - `DemoProject/TestDepricated/` - deprecation behavior samples.
- Includes presentation deck and a short local note in `Readme.md`.

### `Day5-Performance Monitoring Toolset`
- Focus: Building AI applications while visualizing behavior in PMT (Performance Monitoring Toolset).
- Main area: `Demo/`
  - step-by-step progression from single model call to full agent orchestration (`step1` through `step8`).
  - paired "problem" scenarios (`step2a`, `step3a`, `step6a`) to illustrate bottlenecks and tuning impact.
  - `helpers/` - guardrails and domain helper services.
  - `mcp/` - fast and slow MCP server variants for comparison.
  - `data/` - baby-care domain documents for ingestion/retrieval and async load tests.
- Useful for understanding observability and performance trade-offs in AI-heavy CF apps.

### `Day7-Language and Feature Enhancements`
- Focus: Non-AI language/runtime enhancements plus selected AI examples.
- Includes a detailed local readme: `Day7-Language and Feature Enhancements/README.md`.
- Covers:
  - async patterns (`asyncAllOf`, `asyncAnyOf`, timeout controls),
  - native sets and set operations,
  - Java interop and callback patterns,
  - expression/literal enhancements,
  - exception routing,
  - QoQ operator behavior,
  - MCP, RAG, and vector database sample pages.

## Quick Start

1. Deploy this folder under your ColdFusion web root (or map it as a web-accessible project path).
2. Open each day folder and run the primary entry page (`index.cfm` or `index.html`) where present.
3. Review each day's local readme (Day4 and Day7 especially) for detailed setup and dependencies.

## Notes

- Several demos rely on external services (for example OpenAI/Ollama, vector databases, MCP endpoints).  
- Keep credentials in environment/runtime configuration, not in source files.  
- Some folders are intentionally "workshop style" and include both good and intentionally problematic examples for learning/comparison.
