# MCPToolLLM

MCPToolLLM, branded in the UI as InventoryAI, demonstrates ColdFusion MCP tool use with an LLM. The user asks natural-language inventory questions, an LLM chooses an MCP tool, ColdFusion executes the tool against SQL Server inventory data, and the LLM summarizes the structured result.

## Setup

Open:

```text
http://localhost:8500/CFSummit2026/demos/MCPToolLLM/
```

Required ColdFusion features:

- `MCPServer()`
- `MCPClient()`
- `ChatModel()`
- `Agent()`
- `queryExecute()`
- Optional CAIROI SDK, discovered from `CAIROI_ROOT`, `CAIROI_SDK_ROOT`, webroot `/CAIROI`, or the built-in compatibility SDK

Required keystore entries in `../keystore`:

| Key ID | Used For |
| --- | --- |
| `openaiapi_inventoryai` | OpenAI `gpt-4o-mini` model option. |
| `anthropicapi_inventoryai` | Anthropic Claude Haiku model option. |

After adding or updating keys, reload the app with:

```text
?reloadApp=1
```

## Database Setup

Create a ColdFusion datasource named:

```text
cfsummit26_inventory
```

The demo queries SQL Server table:

```text
[inventory].[dbo].[inventory_items]
```

Expected columns:

```text
item_id
item_name
sku
category
warehouse
quantity_on_hand
reorder_threshold
reorder_quantity
stock_status
lead_time_days
supplier
unit_cost
last_ordered_date
notes
created_at
updated_at
```

No SQL setup script is included in this folder. The README documents the required DSN and table shape so the demo can point at the prepared Summit inventory database.

## How It Works

`Application.cfc` maps `/mcpinventory` to `components/` and `/keystore` to the sibling keystore components. It initializes:

- `application.inventoryDatasource = "cfsummit26_inventory"`
- the MCP endpoint at `mcp/server.cfm`
- the MCP tool provider `mcpinventory.InventoryDatabaseToolV3`
- OpenAI and Anthropic model options from keystore values
- an MCP server with one tool provider CFC

Request flow:

1. `index.cfm` loads the chat and inventory UI.
2. `assets/app.js` calls `api/models.cfm` and `api/inventory.cfm` to populate model and inventory state.
3. A chat request posts to `api/chat.cfm`.
4. `api/chat.cfm` discovers tools through `MCPClient().listTools()`.
5. The selected `ChatModel()` and `Agent()` prompt the LLM to choose exactly one MCP tool and arguments.
6. `MCPClient().callTool()` sends the call to `mcp/server.cfm`.
7. `mcp/server.cfm` delegates to `application.mcpServer.handleRequest()`.
8. `InventoryDatabaseToolV3.cfc` exposes remote tool functions such as `findItems`, `getLowStockItems`, `getItemBySku`, `recommendReorders`, and `createReorderRequest`.
9. `InventoryService.cfc` uses parameterized `queryExecute()` calls against the configured datasource.
10. `api/chat.cfm` sends the structured tool result back through the LLM for a concise answer.
11. When the CAIROI SDK is available, CAIROI records one `inventory_mcp_chat` trace with tool discovery, agent routing, MCP call, and answer synthesis spans.

ColdFusion features used include `Application.cfc`, CFC mappings, `application` and `session` scopes, `getHttpRequestData()`, `serializeJSON()`, `deserializeJSON()`, `MCPServer()`, `MCPClient()`, `ChatModel()`, `Agent()`, remote CFC methods, and `queryExecute()` with named parameters.

## CAIROI Tracking

The inventory workflow uses the CAIROI SDK with app ID:

```text
inventory-ai
```

The conference setup sends telemetry to the hosted CAIROI collector:

```text
https://adobecoldfusion.com/cairoi/api/telemetry.cfm
```

The hosted collector must have the `inventory-ai` app and the dev-only telemetry key `cairoi-inventory-dev-key` seeded for telemetry links to appear. If the SDK is not available locally, the demo runs in compatibility mode without tracing.

Tracked operations include:

- `mcp.list_tools`
- `agent.chat`
- `mcp.call_tool`
- `llm.chat`

Raw user questions, raw LLM responses, MCP tool argument values, and tool result payloads are not stored in CAIROI. The InventoryAI chat response includes a link to the hosted trace detail page.

When the full SDK is available, telemetry delivery is async and durable. InventoryAI queues sanitized telemetry locally at:

```text
MCPToolLLM/data/cairoi-telemetry-queue
```

The request path does not wait for CAIROI `cfhttp` calls. If the collector is slow or unreachable, demo users still get their inventory answer while the background queue retries silently.

## MCP Tools

`components/InventoryDatabaseToolV3.cfc` publishes these tools:

| Tool | Purpose |
| --- | --- |
| `findItems` | Search inventory by natural language text, warehouse, category, or status. |
| `getLowStockItems` | Return items at or below reorder point. |
| `getItemBySku` | Fetch one item by SKU. |
| `recommendReorders` | Recommend reorder quantities for low inventory. |
| `createReorderRequest` | Create a demo reorder request response. |

The UI also shows MCP and SQL trace details so the presenter can explain how tool calls become database queries.

## API Endpoints

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `api/models.cfm` | GET/POST | List or select configured LLMs. |
| `api/inventory.cfm` | GET | Query inventory data for the UI. |
| `api/chat.cfm` | POST | Run LLM tool routing, MCP tool call, and answer summarization. |
| `api/bootstrap.cfm` | GET | Check datasource availability and inventory stats. |
| `mcp/server.cfm` | POST | ColdFusion MCP HTTP server endpoint. |

## Troubleshooting

- Model options are disabled: add the required keystore key IDs.
- Chat fails before tool use: confirm the selected model key is configured.
- OpenAI calls fail with an authentication error: replace the expired `openaiapi_inventoryai` keystore value. The failed call should still appear as an error trace in CAIROI.
- MCP server unavailable: verify ColdFusion supports `MCPServer()` and reload app state.
- Datasource errors: confirm `cfsummit26_inventory` exists and can query `[inventory].[dbo].[inventory_items]`.
- Empty answers: verify the inventory table contains matching rows.
