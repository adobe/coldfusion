<!---
  ColdFusion 2025 AI Features Demo — Core Logic Overview
  ========================================================
  This file shows the essential CF AI code patterns.
  All HTML/CSS/JS lives in ui.cfm (cfinclude at the bottom).

  CF 2025 AI has two main entry points:
    1. ChatModel()  — simple LLM chat, no tools/memory
    2. agent()      — full AI agent with tools, memory, guardrails, RAG

  ────────────────────────────────────────────────────
  CORE PATTERN 1: ChatModel — Simple LLM Chat
  ────────────────────────────────────────────────────
  chatModel = ChatModel({
      PROVIDER:    "openai",
      APIKEY:      application.openaiKey,
      MODELNAME:   "gpt-4o-mini",
      temperature: 0.7,
      maxTokens:   500
  });
  response = chatModel.chat("Tell me about ColdFusion");
  // response.message = LLM's reply

  ────────────────────────────────────────────────────
  CORE PATTERN 2: agent() + Function Tools (CFC)
  ────────────────────────────────────────────────────
  // Tools are CFC paths (dot-delimited from wwwroot).
  // CFC methods MUST be `remote` with hint/param/return metadata.
  // This metadata is sent to the LLM so it knows what tools exist
  // and when to call them. Verify via logRequests/logResponse in ChatModel config.
  //
  // NOTE: Pass {CFC:"path"} — NOT a CFC object via createObject().

  aiService = agent({
      CHATMODEL: chatModel,
      TOOLS: [
          { CFC: "aiTesting.demo.tools.EcommerceTool" },
          { CFC: "aiTesting.demo.tools.FinancialTool" }
      ]
  });
  response = aiService.chat("Search for ColdFusion software and track order ORD-5002");
  // response.message              = final answer (tools auto-executed)
  // response.toolExecutionRequests = Java List of tool calls made

  ────────────────────────────────────────────────────
  CORE PATTERN 3: agent() + MCP Tools
  ────────────────────────────────────────────────────
  // MCP client connects to any MCP-compliant server (HTTP or stdio).
  // MCPCLIENT takes an array of MCP client objects.

  mcpClient = McpClient({
      transport:  { type:"HTTP", URL:"http://localhost:8500/demo/mcp/server.cfm" },
      clientInfo: { name:"demo-client", version:"1.0.0" }
  });
  aiService = agent({
      CHATMODEL: chatModel,
      TOOLS:     [{ MCPCLIENT: [mcpClient] }]
  });
  response = aiService.chat("Escalate order #99821 — it arrived damaged");

  ────────────────────────────────────────────────────
  CORE PATTERN 4: agent() + Guardrails (via Agent API)
  ────────────────────────────────────────────────────
  // INPUTGUARDRAILS and OUTPUTGUARDRAILS take arrays of absolute CFC file paths.
  // Use expandPath() to resolve. The agent auto-runs each guardrail CFC's
  // validate() method. Output guardrails run on LLM output BEFORE returning.
  // When a guardrail blocks, it throws an exception. Do NOT call validate() manually.

  piiGuardrailPath = expandPath("/aiTesting/demo/g.cfc");
  aiService = agent({
      CHATMODEL:        chatModel,
      OUTPUTGUARDRAILS: [piiGuardrailPath]
  });
  aiService.systemMessage("Refuse harmful, illegal, or inappropriate requests.");
  response = aiService.chat("Write a customer record with contact details");
  // PII automatically blocked/redacted before response.message is returned
  // If guardrail blocks entirely, an exception is thrown

  ────────────────────────────────────────────────────
  CORE PATTERN 5: agent() + ChatMemory
  ────────────────────────────────────────────────────
  aiService = agent({
      CHATMODEL:  chatModel,
      CHATMEMORY: { MAXMESSAGES: javacast("int", 20) }
  });
  aiService.chat("My name is Alice");
  response = aiService.chat("What is my name?");
  // response.message = "Your name is Alice" (remembers context)

  ────────────────────────────────────────────────────
  CORE PATTERN 6: agent() + RAG (Retrieval-Augmented Generation)
  ────────────────────────────────────────────────────
  ragAgent = agent({
      CHATMODEL:  chatModel,
      CHATMEMORY: { MAXMESSAGES: javacast("int", 20) },
      INGESTION: {
          source:       getDirectoryFromPath(getCurrentTemplatePath()) & "docs/",
          chunkSize:    500,
          chunkOverlap: 100,
          embeddingModel: { provider:application.embedProvider, modelName:application.embedModelName, apiKey:application.embedApiKey },
          vectorStoreIngestor: { vectorStore: { provider:"INMEMORY" } }
      }
  });
  ragAgent.ingest();
  response = ragAgent.chat("What is the return policy?");

  ────────────────────────────────────────────────────
  CORE PATTERN 7: agent() + Streaming (STREAMINGHANDLER)
  ────────────────────────────────────────────────────
  // STREAMINGHANDLER takes a dot-delimited CFC path from wwwroot (NOT ChatModel).
  // The handler CFC receives callbacks: onPartialResponse(token),
  // onCompleteResponse(response), onError(error).

  aiService = agent({
      CHATMODEL:        chatModel,
      STREAMINGHANDLER: "aiTesting.demo.StreamHandler2"
  });
  response = aiService.chat("Tell me about ColdFusion");
  // StreamHandler2.onPartialResponse() fires per token -> writeLog()
  // StreamHandler2.onCompleteResponse() fires when done

  ────────────────────────────────────────────────────
  CORE PATTERN 8: Combined — Tools + MCP + Guardrails + Memory
  ────────────────────────────────────────────────────
  // Everything composes in a single agent() call:
  aiService = agent({
      CHATMODEL:  chatModel,
      TOOLS:      [
          { CFC: "aiTesting.demo.tools.EcommerceTool" },
          { MCPCLIENT: [mcpClient] }
      ],
      OUTPUTGUARDRAILS: [expandPath("/aiTesting/demo/g.cfc")],
      CHATMEMORY: { MAXMESSAGES: javacast("int", 20) }
  });
--->

<!--- Serve the full interactive demo UI --->
<cfinclude template="ui.cfm">
