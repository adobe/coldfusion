# ColdFusion 2025 AI Workshop — Cheat Sheet

## Core Function Signatures

### ChatModel()
```cfml
var model = ChatModel({
  PROVIDER:    "openAi",
  APIKEY:      "sk-...",
  MODELNAME:   "gpt-4o-mini",
  TEMPERATURE: 0.5,
  TOPP:        0.9,
  TOPK:        40,
  MAXTOKENS:   800,
  BASEURL:     ""   // omit for cloud providers
});
```

### agent()
```cfml
var myAgent = agent({
  CHATMODEL:          model,
  STREAMINGHANDLER:   "path.to.Streamer",
  CHATMEMORY:         memoryConfig,
  TOOLS:              toolsArray,
  retrievalAugmentor: ragConfig,
  INPUTGUARDRAILS:    ["/abs/path/Guard.cfc"],
  OUTPUTGUARDRAILS:   ["/abs/path/Guard.cfc"]
});
myAgent.systemMessage(promptText, userId);
myAgent.chat(userPrompt, userId);
```

### MCPClient()
```cfml
var clients = MCPClient({
  configFile: "/path/to/mcp-servers.json"
});
if (!isArray(clients)) clients = [clients];
// Add to tools: [{MCPCLIENT: clients}, ...]
```

### VectorStore()
```cfml
var vs = VectorStore({
  provider: "INMEMORY",
  embeddingModel: {
    provider: "openai",
    modelName: "text-embedding-3-small",
    apiKey: "sk-..."
  }
});
```

---

## Config Patterns

### JSON (S1, S2, S3, S5, S6): `ai.json` / `ai.lab.json`
```json
{
  "provider": "openAi",
  "modelName": "gpt-4o-mini",
  "apiKey": "sk-...",
  "temperature": 0.5,
  "maxTokens": 800,
  "chatMemory": {
    "type": "messageWindowChatMemory",
    "maxMessages": 20,
    "perUser": true
  },
  "tools": [{"cfc": "api.agent.sN.lab.tools.X"}],
  "rag": {"enabled": true, "corpora": [...]},
  "guardrails": {
    "input": ["guardrails/input/Guard.cfc"],
    "output": ["guardrails/output/Guard.cfc"]
  }
}
```

### Properties (S4): `ai.lab.properties`
```properties
provider=openai
modelName=gpt-4o-mini
apiKey=sk-...
temperature=0.5
maxTokens=2400
chatMemory.type=messageWindowChatMemory
chatMemory.maxMessages=20
tools=api.agent.s4.lab.tools.SearchCatalog,...
mcpConfigFile=mcp-servers.json
promptExtensions=system-prompt-weather.txt,...
```

---

## CHATMEMORY Config Struct
```cfml
var memoryConfig = {
  TYPE:        "messageWindowChatMemory",
  MAXMESSAGES: 20,
  PERUSER:     true,
  PERSISTENTSTORE: "cacheName"  // optional
};
```

---

## SSE Event Types by Session

| Event | Sessions | Meaning |
|-------|----------|---------|
| `model.start` | S1-S6 | LLM generation starting |
| `model.delta` | S1-S6 | Partial token received |
| `model.end` | S1-S6 | Complete response |
| `done` | S1-S6 | Stream closed |
| `error` | S1-S6 | Error occurred |
| `preference.persist` | S2-S6 | Preferences extracted + saved |
| `memory.read` | S2-S6 | Preferences injected into prompt |
| `memory.write` | S2-S6 | Agent appended to memory |
| `tool.call` | S3-S6 | CFC tool invocation |
| `tool.result` | S3-S6 | CFC tool response |
| `mcp.call` | S4-S6 | MCP tool invocation |
| `mcp.result` | S4-S6 | MCP tool response |
| `retrieval.start` | S5-S6 | RAG query initiated |
| `retrieval.hit` | S5-S6 | RAG chunks found |
| `guardrail.violation` | S6 | Guard triggered |

---

## RAG retrievalAugmentor Struct
```cfml
var ragConfig = {
  queryRouter: {
    type: "languageModel",
    contentRetrievers: [
      {vectorStore: vs, maxResults: 6,
       minScore: 0.4, description: "..."}
    ],
    routingModel: model
  },
  contentInjector: {
    promptTemplate: "Context: {{contents}}"
      & chr(10) & "Question: {{userMessage}}",
    metadataKeys: ["file_name"]
  }
};
```

---

## Guardrail validate() Contract

**Input guard:**
```cfml
public struct function validate(
    required string userMessage) {
  return {
    result: "success"|"failure"|"fatal",
    message: "",
    repromptMessage: ""
  };
}
```

**Output guard:**
```cfml
public struct function validate(
    required string aiMessage) {
  return {
    result: "success"|"failure"|"fatal",
    message: "",
    repromptMessage: ""
  };
}
```

- `success` = pass
- `failure` = recoverable (CF re-prompts using repromptMessage)
- `fatal` = blocked entirely
- **NO `valid` key. NO `severity` key.**

---

## Key Patterns

| Pattern | Where | Rule |
|---------|-------|------|
| `systemMessage()` | S2-S6 | Call ONCE at agent creation, not per turn |
| MCP clients | S4-S6 | Application-scoped (expensive handshake) |
| Tools array | S4-S6 | `[{MCPCLIENT: clients}, {cfc: "..."}]` — MCP first |
| `activeQueueId()` | Streamer | Always check before pushing to stream |
| Preference extraction | S2-S6 | Separate LLM call, runs before chat |
| Config hot-reload | S1 | Edit JSON, next message sees changes |
