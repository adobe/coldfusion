# CF Cases

CF Cases is a browser-based mystery game engine built with Adobe ColdFusion, static HTML/CSS/JavaScript, JSON scenario files, local Ollama models, and ColdFusion AI features. Players choose a case, move through rooms, inspect objects, uncover clues, ask IRIS for help or a spoiler-light hint, and make an accusation when the evidence supports it.

The demo is intentionally data-driven. Case content lives in `json/`, room art lives in `img/<case-folder>/`, and ColdFusion components own loading, validation, command parsing, state management, vector memory, guardrails, and AI responses.

## Setup

Open the app through ColdFusion:

```text
http://localhost:8500/CFSummit2026/demos/CFCase/
```

Requirements:

- Adobe ColdFusion 2025 or a compatible runtime with `ChatModel()` and `VectorStore()`.
- Session management enabled.
- Ollama running at `http://localhost:11434`.
- Ollama models:

```bash
ollama pull llama3.2
ollama pull nomic-embed-text
ollama serve
```

No cloud API key is required. This project does not read from the `keystore` app; it uses local Ollama only.

Useful query parameters:

- `?reload=1` reinitializes application-level state.
- `?debug=1` includes parser prompts, vector hits, and other debugging details in API responses.

## How It Works

`Application.cfc` names the app `CFCaseMysteryEngine`, enables sessions, maps `/cfc`, and initializes:

- `application.caseRoot`
- `application.scenarioCache`
- `application.caseAiStrict`
- `application.caseUseAiParserFallback`

The frontend in `index.cfm` and `assets/js/game.js` renders state and sends JSON requests. It does not contain the game rules.

Request flow:

1. The browser calls `api/scenarios.cfm` to list valid JSON scenarios from `json/`.
2. `ScenarioService.cfc` uses `directoryList()`, `fileRead()`, `deserializeJson()`, and validation helpers to load scenarios and cache them in `application.scenarioCache`.
3. Starting a case posts to `api/start.cfm`; `GameStateService.cfc` creates `session.game`.
4. `VectorMemoryService.cfc` creates an in-memory ColdFusion `VectorStore()` using Ollama embeddings and indexes the starting room as discovered memory.
5. Player commands post to `api/action.cfm`.
6. `GameEngineService.cfc` runs input guardrails, builds a safe parser context, parses the command, mutates session state, indexes newly discovered rooms/objects/clues, and returns safe state.
7. If the command asks IRIS a question, `IrisService.cfc` searches discovered vector memory, builds a prompt from safe state plus retrieved snippets, calls `AiService.cfc`, and checks output guardrails before returning the answer. The `hint` command uses `progression.criticalPathClues` to find the next missing core clue and asks IRIS to phrase a gentle nudge toward an allowed room, visible object, or action without exposing the clue itself.

ColdFusion features used include `Application.cfc`, CFC services, `application` scope, `session` scope, `createObject()`, `cfcontent`, `getHttpRequestData()`, `serializeJson()`, `deserializeJson()`, `directoryList()`, `fileRead()`, `fileExists()`, Java interop for portable paths, `ChatModel()`, and `VectorStore()`.

## AI, RAG, And Guardrails

- LLM: `AiService.cfc` wraps `ChatModel({ provider: "ollama", modelName: "llama3.2" })`.
- Vector memory: `VectorMemoryService.cfc` wraps `VectorStore()` with Ollama `nomic-embed-text`.
- RAG behavior: only discovered rooms, objects, and clues are indexed and retrieved for IRIS.
- Guardrails: `GuardrailService.cfc` blocks prompt-injection, spoiler, raw JSON, state mutation, and off-topic requests.
- Output filtering: before a case is solved, IRIS responses are blocked if they reveal the culprit, undiscovered clue titles, or hidden object names.

This is a pragmatic demo guardrail layer, not a production security boundary.

## Scenario Model

Each scenario JSON file usually defines:

- `scenarioId`, `title`, `subtitle`, `genre`, `tone`, and `introText`
- `startingRoom`
- `rooms` with exits, visible objects, hidden objects, and `imageFile`
- `objects` with aliases, location, visibility, portability, and interaction definitions
- `clues`
- `suspects`
- `solution`
- `progression.criticalPathClues` for IRIS hint targeting
- `endingText`
- `guardrails`

The frontend receives only safe state: current public room data, visible objects, inventory, discovered clues, public suspect data, exits, and solved status.

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `api/scenarios.cfm` | GET | List and validate scenario files. |
| `api/start.cfm` | POST | Start a session for a selected scenario file. |
| `api/action.cfm` | POST | Execute a player command. |
| `api/state.cfm` | GET | Return safe state for the current session. |
| `api/reset.cfm` | POST/GET | Clear `session.game`. |

## Project Structure

```text
Application.cfc
index.cfm
api/
assets/
cfc/
img/
json/
```

The `img/missingsock/room_garage.png` and `img/missingsock/room_guest_room.png` images were generated to satisfy existing scenario references in `json/missingsock.json`.

## Troubleshooting

- No scenarios appear: check that valid `.json` files exist in `json/`.
- Room image missing: verify the room `imageFile` exists under `img/<assetFolder>/`.
- IRIS fails: confirm Ollama is running and both models are pulled.
- Scenario edits do not appear: use `?reload=1`.
- Parser behavior is odd: update deterministic parsing in `CommandParserService.cfc` before relying on AI fallback.
