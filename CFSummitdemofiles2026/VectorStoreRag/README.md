# VectorStoreRag

VectorStoreRag, branded as Glaze Against The Machine, is a donut-shop RAG demo. It ingests menu text files into a ColdFusion in-memory vector store, retrieves relevant menu chunks for customer questions, and asks an OpenAI chat model to answer only from the retrieved context.

## Setup

Open:

```text
http://localhost:8500/CFSummit2026/demos/VectorStoreRag/
```

Add this key in the sibling `../keystore` app:

| Key ID | Used For |
| --- | --- |
| `openaiapi_donuts` | OpenAI chat and `text-embedding-3-small` embeddings. |

After adding or updating the key, reload application state:

```text
?reloadApp=1
```

No SQL datasource is required. The vector store is in-memory and must be re-ingested after application restart or reset.

## How It Works

`Application.cfc` maps `/keystore` to the sibling keystore components and initializes:

- the OpenAI keystore key ID
- OpenAI chat config for `gpt-4o-mini`
- embedding model `text-embedding-3-small`
- vector dimension `1536`
- an in-memory vector client reference
- ingestion status

Workflow:

1. The user opens `bootstrap.cfm`.
2. The page lists `.txt` data files from `data/`.
3. The user selects a menu and clicks ingest.
4. `api/ingest.cfm` reads the selected file with `fileRead()`, splits records, extracts fields such as `Name`, `Category`, and `Available`, and creates vector items with metadata.
5. A ColdFusion `VectorStore()` is created with OpenAI embeddings and a generated collection name.
6. Records are added with `vectorStore.addAll()` and stored in `application.vectorClient`.
7. The user opens `search.cfm` and asks a question.
8. `api/search.cfm` embeds the question, searches the vector store, filters results to the currently ingested menu, and builds context blocks.
9. A ColdFusion `ChatModel()` and `Agent()` answer from the retrieved menu context.

ColdFusion features used include `Application.cfc`, CFC mapping to the keystore app, `application` scope, `getHttpRequestData()`, `serializeJSON()`, `deserializeJSON()`, `directoryList()`, `fileRead()`, `lock`, `VectorStore()`, `ChatModel()`, `Agent()`, and `getAIService()` fallback handling.

## Data Files

The demo ships with:

- `data/donut_catalog_rag_demo.txt`
- `data/ai_friendly_donut_flavors_100.txt`

Both are legitimate demo corpora. Add more `.txt` files to `data/` and ingest them from `bootstrap.cfm`.

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `api/ingest.cfm` | POST | Ingest the selected menu into the vector store. |
| `api/search.cfm` | POST | Retrieve menu chunks and answer a customer question. |
| `api/reset.cfm` | POST | Clear the current vector store and ingestion status. |

## Prompting And Grounding

`api/search.cfm` uses a system prompt that tells the model:

- answer as the Glaze Against The Machine menu assistant
- answer only from provided donut menu context
- say the menu does not include the information when context is missing
- keep answers concise
- mention specific donut names when useful

The UI shows retrieved source chunks so the presenter can explain the RAG path.

## Troubleshooting

- API key missing: add `openaiapi_donuts` in the keystore and reload.
- Search says to stock the case first: open `bootstrap.cfm` and ingest a menu.
- Answers refer to the wrong menu: reset, choose the desired data file, and ingest again.
- State disappeared: the vector store is in-memory and must be reloaded after app restart.
