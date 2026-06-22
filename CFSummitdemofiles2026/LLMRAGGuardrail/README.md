# LLMRAGGuardrail

LLMRAGGuardrail, branded in the UI as OnboardIQ, is a ColdFusion 2025 AI demo for employee onboarding. It shows how RAG and guardrails change the behavior of a local LLM assistant.

The app answers onboarding questions from local Markdown policy documents, displays retrieved source chunks, and lets the presenter toggle RAG and guardrails on or off.

## Setup

Open:

```text
http://localhost:8500/CFSummit2026/demos/LLMRAGGuardrail/
```

Requirements:

- Adobe ColdFusion 2025 or compatible runtime with ColdFusion AI features.
- Ollama running at `http://localhost:11434`.
- Ollama models:

```bash
ollama pull llama3.2
ollama pull nomic-embed-text
ollama serve
```

No cloud API key or keystore entry is required. This demo is configured for local Ollama.

## How It Works

`Application.cfc` maps `/onboardrag` to `components/`, enables sessions, and initializes:

- Ollama chat settings
- Ollama embedding settings
- onboarding steps shown in the left rail
- an answer schema used when guardrails are enabled
- an in-memory vector store reference
- ingestion status
- session metrics and chat history

On each request, `onRequestStart()` calls `refreshAiConfig()` and `maybeAutoIngest()`. If the vector store is not ready, the app attempts to ingest the onboarding corpus.

Request flow:

1. `index.cfm` loads the three-panel UI.
2. `assets/app.js` calls `api/status.cfm` to get onboarding steps, metrics, model status, and ingest status.
3. `OnboardingService.ensureIngested()` checks Ollama, chunks documents from `data/onboarding/`, creates a ColdFusion `VectorStore()`, and adds chunks with `addAll()`.
4. The user asks a question through `api/ask.cfm`.
5. `OnboardingService.ask()` validates the request, stores selected-step state in the session, and retrieves relevant onboarding chunks when RAG is enabled.
6. With guardrails on, a dedicated local-model inference step classifies the employee's intent using the question, current onboarding step, and retrieved context.
7. Refused requests stop before answer generation. Allowed requests are passed to the answer model with the guardrail decision already established.
8. The service requests a structured JSON answer using `application.answerSchema`.
9. The response is normalized, session metrics are updated, and the UI renders answer, guardrail decision, trace, source chunks, and history.

ColdFusion features used include `Application.cfc`, CFC components, `application` and `session` scopes, `lock`, `cfhttp` to call Ollama directly for guarded JSON fallback, `getHttpRequestData()`, `serializeJSON()`, `deserializeJSON()`, `directoryList()`, `fileRead()`, `VectorStore()`, `ChatModel()`, `Agent()`, and `getAIService()` fallback handling.

## RAG Corpus

Documents live in `data/onboarding/`:

- `benefits-and-time-off.md`
- `it-access-and-security.md`
- `manager-team-and-first-project.md`
- `paperwork-and-employment.md`
- `training-compliance-and-conduct.md`

The chunker splits Markdown by headings and preserves metadata such as source, section, chunk index, and optional `stepIds` metadata.

## Guardrail Behavior

When guardrails are on:

- the system prompt restricts the assistant to onboarding topics
- the refusal decision is made by a context-aware local-model classifier, not a substring list
- retrieval happens before classification so relevant onboarding content can inform the decision
- legitimate defensive compliance questions, such as how to report phishing, are allowed when their intent is to follow company policy
- a structured response schema is requested
- off-topic, harmful, and sensitive people-data requests are refused before answer generation
- allowed onboarding questions are not marked as bad when RAG is off, but company-specific answers are withheld because the local knowledge base is unavailable
- the answer model does not independently reclassify a request that the input guardrail allowed
- responses include refusal state, confidence, suggested questions, and guardrail reason

When guardrails are off, the model is allowed to answer more generally. When both RAG and guardrails are off, the app sends the user's question directly to Ollama without local policy context.

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `api/status.cfm` | GET | Return app status, steps, metrics, model state, and ingest state. |
| `api/ingest.cfm` | POST | Force or request corpus ingestion. |
| `api/ask.cfm` | POST | Ask the onboarding assistant a question. |
| `api/reset.cfm` | POST | Clear vector store reference, metrics, and session history. |

Ask payload example:

```json
{
  "question": "How much vacation do I get?",
  "stepId": "benefits-enrollment",
  "ragEnabled": true,
  "guardrailsEnabled": true
}
```

## Troubleshooting

- Status says Ollama is unavailable: start Ollama and confirm `/api/tags` responds.
- Ingestion waits or fails: pull `nomic-embed-text`.
- Chat fails: pull `llama3.2`.
- Policy answers are withheld: turn RAG on or ask a question covered by retrieved onboarding context.
- Reset and reingest from the Trace tab if the in-memory vector store was cleared.
