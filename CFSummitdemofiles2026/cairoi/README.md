# CAIROI Tracker

CAIROI Tracker is a ColdFusion AI Return On Investment tracker. It is an MVP observability framework for tracing, recording, and visualizing AI usage in Adobe ColdFusion applications.

The MVP is wrapper-based. It does not magically intercept all AI calls. Developers intentionally use the CAIROI SDK wrappers or manually record spans.

## What It Tracks

- Applications, environments, workflows, traces, and spans
- LLM, agent, RAG, MCP, vector, embedding, guardrail, and custom operation types
- Provider, model, latency, status, token counts, and estimated cost
- Prompt and response hashes plus character counts
- Privacy-safe metadata such as route, feature, collection name, topK, tool name, and result counts

## What It Does Not Track

- Direct `ChatModel()`, `Agent()`, `MCPClient()`, or `VectorStore()` calls outside the SDK
- Raw prompts, raw responses, source documents, retrieved chunks, reviewed code, tool argument values, API keys, bearer tokens, or authorization headers
- Exact provider billing quirks or provider invoice reconciliation
- User/admin authentication, RBAC, WebSocket streaming, CORS hardening, or OpenTelemetry export

## Privacy Model

CAIROI is privacy-safe by default:

- User IDs and session IDs are hashed by the SDK.
- Prompts and responses are hashed and counted, not stored.
- Metadata is sanitized and skips sensitive key names such as `password`, `secret`, `token`, `apiKey`, `authorization`, `prompt`, `response`, `content`, `document`, and `chunk`.
- API keys are stored as SHA-256 hashes only.

## Deployment URL

The conference collector is intended to live at:

```text
https://adobecoldfusion.com/cairoi/
```

Useful deployed endpoints:

```text
https://adobecoldfusion.com/cairoi/api/health.cfm
https://adobecoldfusion.com/cairoi/api/telemetry.cfm
https://adobecoldfusion.com/cairoi/dashboard/index.cfm
https://adobecoldfusion.com/cairoi/admin/setup.cfm
```

Laptop demos should send server-side `cfhttp` telemetry to:

```text
https://adobecoldfusion.com/cairoi/api/telemetry.cfm
```

The telemetry API accepts either `X-CAIROI-API-Key` or `Authorization: Bearer <key>`.

## Setup

CAIROI is self-contained and uses an embedded Apache Derby database. No ColdFusion Administrator datasource is required.

```text
cairoi/data/derby/cairoi
```

When copying CAIROI to a server, you can omit `cairoi/data/derby/` to start with a fresh database. If you do copy an existing Derby database, stop the ColdFusion application first so Derby is not holding a live `db.lck` file.

Bootstrap at the deployed URL:

1. Visit `https://adobecoldfusion.com/cairoi/admin/setup.cfm`.
2. Click **Run Setup**.
3. Confirm the embedded Derby tables exist.
4. Open `https://adobecoldfusion.com/cairoi/dashboard/index.cfm`.

The setup page seeds local-only development telemetry keys for the conference demos:

```text
demo-app: cairoi-dev-key
inventory-ai: cairoi-inventory-dev-key
cfcase: cairoi-cfcase-dev-key
onboardiq: cairoi-onboardiq-dev-key
donut-rag: cairoi-donut-rag-dev-key
code-review-local: cairoi-code-review-dev-key
```

Only SHA-256 hashes are stored. Replace these before production use.

## SDK Usage

```cfml
cairoi = new cairoi.sdk.Cairoi({
    appId = "demo-app",
    environment = "dev",
    collectorUrl = "https://adobecoldfusion.com/cairoi/api/telemetry.cfm",
    apiKey = application.cairoiDevApiKey,
    failSilently = true,
    asyncTelemetry = true,
    durableTelemetry = true,
    telemetryQueueDir = expandPath("./data/cairoi-telemetry-queue")
});

trace = cairoi.startTrace(
    workflowName = "simple_chat",
    userId = session.userId ?: "",
    sessionId = session.sessionId ?: "",
    metadata = { route = cgi.script_name }
);

chat = cairoi.createChatModel({
    provider = "openai",
    modelName = "gpt-5-nano",
    apiKey = application.openAiApiKey
});

response = chat.chat(
    prompt = "Explain CAIROI in one sentence.",
    trace = trace,
    metadata = { feature = "basic-chat" }
);

trace.finish(status = "success");
```

## Async Durable Telemetry

SDK telemetry is async and durable by default. `trace.finish()` and `recordSpan()` write a small sanitized JSON payload to a local queue directory, start a background flush worker, and return without waiting for `cfhttp`.

This is intended for conference demos and unreliable Wi-Fi:

- Demo users do not wait on the telemetry collector.
- Network failures are silent when `failSilently = true`.
- API keys are not written to queue files.
- Failed sends are retried with backoff.
- Exhausted or invalid queue files are moved to a `dead-letter` folder.

For three laptops sending to a cloud CAIROI server, configure each laptop SDK with the cloud collector URL:

```cfml
cairoi = new cairoi.sdk.Cairoi({
    appId = "inventory-ai",
    environment = "conference",
    collectorUrl = "https://adobecoldfusion.com/cairoi/api/telemetry.cfm",
    apiKey = "replace-with-this-laptop-app-key",
    failSilently = true,
    asyncTelemetry = true,
    durableTelemetry = true,
    telemetryQueueDir = expandPath("./data/cairoi-telemetry-queue"),
    telemetryTimeout = 2
});
```

Server-side `cfhttp` posts do not require CORS. CAIROI still handles `OPTIONS` preflight for allowed browser origins if browser JavaScript calls the cloud APIs directly.

## Manual Spans

```cfml
trace = cairoi.startTrace(workflowName = "custom_workflow");
span = trace.startSpan("custom", "Custom operation", "", { feature = "demo" });

try {
    // Run work here.
    span.finish({
        status = "success",
        inputTokens = 100,
        outputTokens = 50,
        totalTokens = 150,
        inputTokenSource = "estimated",
        outputTokenSource = "estimated",
        totalTokenSource = "estimated"
    });
    trace.finish("success");
} catch (any e) {
    span.finish({ status = "error", errorType = e.type, errorMessage = e.message });
    trace.finish("error");
}
```

## Examples

- `/examples/simple-chat.cfm`: tracked `ChatModel().chat()` usage. Enter a provider key for the request or use local Ollama configuration.
- `/examples/rag-demo.cfm`: mocked RAG trace shape with retrieval, vector search, context assembly, and generation.
- `/examples/mcp-demo.cfm`: mocked agent plus MCP tool trace shape.
- `/examples/vector-helper-demo.cfm`: mocked vector add/search telemetry shape.

## Model Pricing

Costs are estimates based on `cairoi_model_prices`.

Formula:

```text
(inputTokens / 1,000,000 * input_cost_per_1m)
+ (outputTokens / 1,000,000 * output_cost_per_1m)
```

Edit prices at:

```text
https://adobecoldfusion.com/cairoi/admin/prices.cfm
```

Seed data is placeholder pricing and must be reviewed before real reporting.

## Dashboard

The dashboard uses Chart.js from CDN and the local JSON endpoints:

- `/api/dashboard.cfm?action=summary`
- `/api/dashboard.cfm?action=timeseries&bucket=hour`
- `/api/dashboard.cfm?action=breakdown&by=model`
- `/api/traces.cfm?traceId=<id>`
- `/api/prices.cfm`
- `/api/health.cfm`

## Known Limitations

1. CAIROI does not magically intercept AI calls.
2. Developers must use the SDK wrappers or manually record spans.
3. Token counts depend on provider metadata when available.
4. Missing token metadata is estimated as `ceiling(character_count / 4)`.
5. Cost is estimated using the local pricing table.
6. Prompt and response text are not stored.
7. RAG internals may require manual spans depending on the app.
8. JavaScript SDK is not part of the MVP.
9. Dashboard design is intentionally basic.
10. Pricing seed data may be placeholder and must be reviewed.

## First Conversion Targets

After the framework examples work, convert demos in this order:

1. Simple Chat Demo
2. Donut RAG Demo
3. Inventory MCP Demo
4. Code Review Demo

For those conversions, keep source documents, retrieved chunks, MCP argument values, and reviewed code out of telemetry.
