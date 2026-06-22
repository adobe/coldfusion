# CFSummit API Keystore

The keystore is a local, self-initializing Adobe ColdFusion demo app for storing API keys used by the other demos. It exists for conference/demo convenience only. It is unauthenticated by design and should not be exposed publicly or used as a production secret manager.

## Setup

Open:

```text
http://localhost:8500/CFSummit2026/demos/keystore/
```

On first request, `Application.cfc` initializes storage under `keystore/data/`:

- Apache Derby embedded database: `data/derby/keystoredb`
- AES master key file: `data/keystore-master.key`

Both are intentional runtime artifacts for this demo. Keep the database and master key together if you need to move saved encrypted demo keys to another machine.

## Storage And Encryption

`components/KeystoreService.cfc` manages all persistence through Java JDBC:

- JDBC URL: `jdbc:derby:<app-local-path>`
- Driver: `org.apache.derby.jdbc.EmbeddedDriver`
- Table: `api_keys`
- Secret encryption: Java `javax.crypto.Cipher` using `AES/GCM/NoPadding`
- Master key: generated 128-bit AES key, Base64-encoded in `data/keystore-master.key`
- IV: 12 random bytes per saved value
- Authentication tag: 128-bit GCM tag
- Fingerprint: SHA-256 hash of the cleaned secret value
- Display hint: masked value only, never the full key

The database stores encrypted values and IVs. The list endpoint returns metadata, hints, fingerprints, and retrieval counts but not raw secret values.

## Required Demo Key IDs

| Key ID | Used By | Purpose |
| --- | --- | --- |
| `openaiapi_donuts` | `VectorStoreRag` | OpenAI chat and embeddings for the donut RAG demo. |
| `openaiapi_codereview` | `CodeReviewLocal` | OpenAI reviews and cloud embeddings. |
| `anthropicapi_codereview` | `CodeReviewLocal` | Anthropic review model option. |
| `openaiapi_inventoryai` | `MCPToolLLM` | OpenAI model option for inventory MCP demo. |
| `anthropicapi_inventoryai` | `MCPToolLLM` | Anthropic model option for inventory MCP demo. |

`CFCase` and `LLMRAGGuardrail` use local Ollama and do not require keystore entries.

## UI Workflow

1. `index.cfm` bootstraps the database and lists saved public key metadata.
2. The user enters a display name, unique ID, API key value, and optional notes.
3. `assets/app.js` posts JSON to `api/keys.cfm`.
4. `KeystoreService.saveKey()` normalizes the key ID, encrypts the value, stores metadata, and returns a public key record.
5. Other demo apps call `KeystoreService.getKey()` through the shared `/keystore` component mapping.

The frontend uses plain HTML, CSS, and vanilla JavaScript.

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `api/status.cfm` | GET | Bootstrap storage and return database status. |
| `api/keys.cfm` | GET | List public metadata for stored keys. |
| `api/keys.cfm` | POST/PUT/PATCH | Add or replace a key with JSON. |
| `api/key.cfm?id=<keyId>` | GET/POST | Return the decrypted value for local demo apps. |
| `api/delete.cfm` | POST | Delete a key by ID. |

Save payload example:

```json
{
  "keyId": "openaiapi_donuts",
  "name": "OpenAI Donut Demo",
  "apiKey": "...",
  "notes": "Used by VectorStoreRag"
}
```

Lookup response includes both `apiKey` and `value` for compatibility with the demos.

## Security Notes

- No authentication is implemented.
- Decrypted keys are available through `api/key.cfm`.
- This is suitable only for local demo use.
- Production systems should use managed secret storage, authentication, authorization, audit logging, and network controls.
