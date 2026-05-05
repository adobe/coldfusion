<cfcontent type="application/json" reset="true">
<cfparam name="form.question"  default="">
<cfparam name="form.sessionId" default="">

<cfscript>
try {

    if (!len(trim(form.question))) {
        apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Please enter a question.";
        writeOutput(serializeJSON(apiPayload));
        return;
    }

    // ── Session-cached AI agent (initialize once per session) ────────────
    if (!isDefined("session.nexoraFullAI4")) {
        lock scope="session" type="exclusive" timeout="120" {
            if (!isDefined("session.nexoraFullAI4")) {

                chatModel = ChatModel({
                    PROVIDER     : application.provider,
                    APIKEY       : application.apiKey,
                    MODELNAME    : application.modelName,
                    TEMPERATURE  : 0.3,
                    MAXTOKENS    : 1500,
                    LOGREQUESTS  : true,
                    LOGRESPONSES : true
                });

                // ── MCP Client → TicketTool (escalation + email) ─────────
                toolsArr = [ { CFC: "aiTesting.nexora.SupportTool" } ];
                try {
                    scriptDir    = getDirectoryFromPath(cgi.SCRIPT_NAME);
                    mcpServerUrl = "http://" & cgi.SERVER_NAME & ":" & cgi.SERVER_PORT &
                                   scriptDir & "mcp/server.cfm";
                    mcpClient = McpClient({
                        transport:             { type: "HTTP", URL: mcpServerUrl },
                        clientInfo:            { name: "nexora-full-app-client", version: "1.0.0" },
                        initializationTimeout: 30,
                        requestTimeout:        30
                    });
                    arrayAppend(toolsArr, { MCPCLIENT: [mcpClient] });
                    writeLog(text="INIT | MCP client connected to " & mcpServerUrl, type="information", file="nexora");
                } catch (any mcpErr) {
                    writeLog(text="INIT | MCP client failed — " & mcpErr.message & ". Continuing without MCP.", type="warning", file="nexora");
                }

                // ── RAG — ingest policy docs into vector store once ──────
                docsPath = expandPath("docs/policies/");
                ragBot = simpleRAG(docsPath, chatModel, {
                    chunkSize:    800,
                    chunkOverlap: 150,
                    vectorStore: {
                        provider:       "INMEMORY",
                        embeddingModel: {
                            provider:  application.embedProvider,
                            modelName: application.embedModelName,
                            apiKey:    application.embedApiKey
                        }
                    }
                });
                ragBot.ingest();

                // ── Agent with ALL features ──────────────────────────────
                aiSvc = agent({
                    CHATMODEL        : chatModel,
                    CHATMEMORY       : { MAXMESSAGES: javacast("int", 20) },
                    TOOLS            : toolsArr,
                    OUTPUTGUARDRAILS : [expandPath("PiiGuardrail.cfc")]
                });

                aiSvc.systemMessage(
                    "You are Nexora's helpful and friendly support assistant." & chr(10) &
                    "TOOLS you have:" & chr(10) &
                    "- getOrderStatus: look up real order data by order ID. NEVER guess — always call this tool." & chr(10) &
                    "- fileTicket: ALWAYS use this tool for ANY escalation. It files a HIGH-PRIORITY ticket AND sends " &
                    "  an email notification to the support team. Use when customer asks to escalate, is frustrated, " &
                    "  mentions damaged items, or asks to speak with a manager. Pass a clear summary and the order ID." & chr(10) &
                    "IMPORTANT: For escalations, ALWAYS use fileTicket — never use escalateIssue." & chr(10) &
                    "For policy questions (returns, warranty, shipping, digital products), answer from your knowledge. " &
                    "If asked about competitor products, say: 'I can only help with Nexora products.' " & chr(10) &
                    "Be concise (2-4 sentences). Be warm and solution-focused."
                );

                session.nexoraFullAI4 = { agent: aiSvc, rag: ragBot };
                writeLog(text="INIT | Full AI agent initialized successfully", type="information", file="nexora");
            }
        }
    }

    // ── Route: agent (tools/MCP) vs RAG ────────────────────────────────
    // Agent-first: if the question mentions an order, escalation, identity,
    // or memory recall, send it to the agent which has tools + MCP.
    // Only pure policy questions (no order/escalation) go to RAG.
    q = trim(form.question);

    needsAgent = false;
    if (reFindNoCase("##\d{3,}", q) || reFindNoCase("order\s", q))        needsAgent = true;
    if (reFindNoCase("escalat|speak.*(manager|supervisor)|frustrated", q)) needsAgent = true;
    if (reFindNoCase("who are you|what can you|competitor|amazon|apple", q)) needsAgent = true;
    if (reFindNoCase("my name|remember|carrier|tracking", q))              needsAgent = true;
    if (reFindNoCase("ticket|file.*ticket|support.*ticket", q))            needsAgent = true;
    if (reFindNoCase("email.*(account|order)|account.*email", q))          needsAgent = true;
    if (reFindNoCase("card \d|ssn|\d{3}-\d{2}-\d{4}|\d{4}-\d{4}", q))     needsAgent = true;

    if (needsAgent) {
        // ── Agent path: tools + MCP for orders, escalation, identity ─────
        lock scope="session" type="exclusive" timeout="60" {
            response = session.nexoraFullAI4.agent.chat(q);
        }

        maxToolRounds = 3;
        for (round = 1; round <= maxToolRounds; round++) {
            rawRequests = response.toolExecutionRequests ?: [];
            toolRequests = [];
            for (req in rawRequests) { arrayAppend(toolRequests, req); }
            if (arrayLen(toolRequests) == 0) break;

            toolResultsStr = "";
            for (req in toolRequests) {
                nm = lCase(req.name ?: "");
                rawArgs = req.arguments ?: {};
                args = isSimpleValue(rawArgs) ? deserializeJSON(rawArgs) : rawArgs;
                try {
                    switch (nm) {
                        case "getorderstatus":
                            toolResult = new SupportTool().getOrderStatus(args.orderId ?: args.orderid ?: ""); break;
                        case "escalateissue":
                            toolResult = new SupportTool().escalateIssue(args.summary ?: "", args.orderId ?: args.orderid ?: ""); break;
                        case "fileticket":
                            toolResult = new TicketTool().fileTicket(
                                args.summary  ?: "escalation request",
                                args.orderId  ?: args.orderid ?: "",
                                args.priority ?: "high"
                            ); break;
                        default:
                            toolResult = "Unknown tool: " & nm;
                    }
                } catch (any te) { toolResult = "Tool error: " & te.message; }
                toolResultsStr &= "Tool " & (req.name ?: "") & " returned: " & toolResult & chr(10);
            }
            lock scope="session" type="exclusive" timeout="60" {
                response = session.nexoraFullAI4.agent.chat(
                    "Here are the tool results:" & chr(10) &
                    toolResultsStr & chr(10) &
                    "Using ONLY these tool results, provide a complete, helpful answer to the customer. " &
                    "Do NOT say you are looking something up or executing a tool — the results are already here."
                );
            }
        }

        message = response.message ?: "I'm sorry, I wasn't able to generate a response. Please try again.";
    } else {
        // ── RAG path: pure policy questions ──────────────────────────────
        lock scope="session" type="exclusive" timeout="60" {
            answer = session.nexoraFullAI4.rag.ask(q);
        }
        message = isSimpleValue(answer) ? answer : (answer.message ?: answer.toString());
    }

    // ── PII Guardrail (secondary check for RAG responses too) ────────────
    guardResult = new PiiGuardrail().validate(message);
    if (guardResult.result eq "successWith") {
        message = guardResult.repromptMessage;
    } else if (guardResult.result eq "failure") {
        message = "I'm sorry, I'm unable to display that response as it may contain sensitive personal information.";
        writeLog( text="GUARDRAIL_BLOCKED | " & (guardResult.message ?: ""), type="warning", file="nexora" );
    }

    // ── Background: log structured intent ────────────────────────────────
    thread name="intent_#createUUID()#" q=form.question {
        try {
            im = ChatModel({ PROVIDER: application.provider, APIKEY: application.apiKey, MODELNAME: application.modelName });
            ir = im.chat(
                "Extract intent from this customer support message. " &
                "Reply with only a JSON object: { ""intent"": string (order_status|return_request|policy_question|escalation|general), " &
                """orderId"": string, ""sentiment"": string (positive|neutral|frustrated|angry) }. " &
                "Message: " & attributes.q
            );
            writeLog( text="INTENT | " & (ir.message ?: ""), type="information", file="nexora" );
        } catch (any ie) {
            writeLog( text="INTENT_ERR | " & ie.message, type="warning", file="nexora" );
        }
    }

    apiPayload = {}; apiPayload["success"] = true; apiPayload["message"] = message;
    writeOutput(serializeJSON(apiPayload));

} catch (any e) {
    writeLog( text="CHAT_ERR | " & e.message & " | " & e.detail, type="error", file="nexora" );
    apiPayload = {};
    apiPayload["success"] = false;
    apiPayload["message"] = "Error: " & e.message & " | " & e.detail;
    writeOutput(serializeJSON(apiPayload));
}
</cfscript>
