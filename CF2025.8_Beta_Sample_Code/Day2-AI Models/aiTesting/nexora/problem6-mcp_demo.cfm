<!---
    Nexora — Problem 7: MCP Tool Integration
    agent() + systemMessage() + CHATMEMORY + TOOLS:[{CFC:SupportTool}, {MCPCLIENT:[mcpClient]}]

    Order lookup uses SupportTool CFC directly.
    Escalation goes through MCP → TicketTool.cfc → cfmail → real email.

    API mode: ?api=1 (POST, returns JSON)
              ?api=1&reset=1 (POST, resets session agent)
--->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            if (structKeyExists(url, "reset")) {
                structDelete(session, "nexoraMcpAI_v2");
                apiPayload = {}; apiPayload["success"] = true; apiPayload["reset"] = true;
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            cfparam(name="form.question", default="");
            if (!len(trim(form.question))) {
                apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Please enter a question.";
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            if (!isDefined("session.nexoraMcpAI_v2")) {
                lock scope="session" type="exclusive" timeout="60" {
                    if (!isDefined("session.nexoraMcpAI_v2")) {

                        chatModel = ChatModel({
                            PROVIDER    : application.provider,
                            APIKEY      : application.apiKey,
                            MODELNAME   : application.modelName,
                            TEMPERATURE : 0.3,
                            MAXTOKENS   : 500
                        });

                        scriptDir    = getDirectoryFromPath(cgi.SCRIPT_NAME);
                        mcpServerUrl = "http://" & cgi.SERVER_NAME & ":" & cgi.SERVER_PORT &
                                       scriptDir & "mcp/server.cfm";

                        mcpClient = McpClient({
                            transport:             { type: "HTTP", URL: mcpServerUrl },
                            clientInfo:            { name: "nexora-mcp-client", version: "1.0.0" },
                            initializationTimeout: 30,
                            requestTimeout:        30
                        });

                        // TOOLS array: CFC path (dot-delimited) + MCPCLIENT object
                        aiAgent = agent({
                            CHATMODEL  : chatModel,
                            CHATMEMORY : { MAXMESSAGES: javacast("int", 20) },
                            TOOLS      : [
                                { CFC: "aiTesting.nexora.SupportTool" },
                                { MCPCLIENT: [mcpClient] }
                            ]
                        });

                        aiAgent.systemMessage(
                            "You are Nexora's friendly customer support assistant." & chr(10) &
                            "TOOLS you have:" & chr(10) &
                            "- getOrderStatus: look up real order data by order ID. NEVER guess — always call this tool for order questions." & chr(10) &
                            "- fileTicket: file a HIGH-PRIORITY escalation ticket via MCP and send an email notification. " &
                            "  Use when the customer explicitly asks to escalate, is very frustrated, or asks to speak with a manager. " &
                            "  Pass a clear summary of the issue and the order ID if one was mentioned." & chr(10) &
                            "If asked about competitor products, say: 'I can only help with Nexora products.' " &
                            "Be concise, warm, and solution-focused. Remember all context shared in this conversation."
                        );

                        session.nexoraMcpAI_v2 = aiAgent;
                    }
                }
            }

            lock scope="session" type="exclusive" timeout="60" {
                response = session.nexoraMcpAI_v2.chat(form.question);

                // Tool round-trip loop: execute tool calls and feed results back.
                // Max 3 rounds to guard against infinite loops.
                supportTool = new SupportTool();
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
                                    toolResult = supportTool.getOrderStatus(args.orderId ?: args.orderid ?: ""); break;
                                case "escalateissue":
                                    toolResult = supportTool.escalateIssue(args.summary ?: "", args.orderId ?: args.orderid ?: ""); break;
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
                    response = session.nexoraMcpAI_v2.chat(
                        "Here are the tool results:" & chr(10) &
                        toolResultsStr & chr(10) &
                        "Using ONLY these tool results, provide a complete, helpful answer to the customer. " &
                        "Do NOT say you are looking something up or executing a tool — the results are already here."
                    );
                }
            }
            apiPayload = {}; apiPayload["success"] = true; apiPayload["message"] = response.message ?: "";
            writeOutput(serializeJSON(apiPayload));

        } catch (any e) {
            apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Error: " & e.message & " | " & e.detail;
            writeOutput(serializeJSON(apiPayload));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Problem 7: MCP Integration",
        subtitle    : "Problem 7 — MCP Integration: Ticket Filing via Email",
        activeNav   : "problem6-mcp_demo.cfm",
        apiEndpoint : "problem6-mcp_demo.cfm",
        placeholder : "Ask about an order or try escalating — ##12345, ##99821, ##77654...",
        hasReset    : true,
        pills       : [
            { label: application.modelName, class: "p-blue"   },
            { label: "System Message ✓", class: "p-green"  },
            { label: "Memory ✓",         class: "p-purple" },
            { label: "Direct Tools ✓",   class: "p-orange" },
            { label: "MCP ✓",            class: "p-red"    }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 7 — MCP Integration</h2>
    <div class="info-box"><strong>&#x2713; Solves:</strong> Problem 5 logs escalations to a file — no real action is taken. MCP Integration connects the agent to <strong>external services via the MCP protocol</strong>. Escalation now calls <code>fileTicket()</code> through an HTTP MCP server, which creates a ticket in <code>TicketTool.cfc</code> and sends a real HTML email — all without the main app knowing the implementation details.</div>
    <div class="warn-box"><strong>&#x26A0; Limitations (fixed in Problem 8):</strong> The knowledge base (return policy, shipping info, etc.) is still hardcoded in the system message — injecting ~2 000 tokens on every request regardless of what the customer actually asked. Doesn't scale to large or frequently changing document sets.</div>
    <div style="display:flex;align-items:center;justify-content:center;gap:8px;flex-wrap:wrap;margin:14px auto 0;max-width:560px;">
        <div style="background:var(--surf2);border:1px solid var(--border);border-radius:8px;padding:8px 14px;font-size:12px;text-align:center;">Customer<br><span style="color:var(--muted);font-size:11px">says "escalate"</span></div>
        <div style="color:var(--muted);font-size:18px;">&rarr;</div>
        <div style="background:var(--surf2);border:1px solid var(--border);border-radius:8px;padding:8px 14px;font-size:12px;text-align:center;">agent()<br><span style="color:var(--muted);font-size:11px">decides to call tool</span></div>
        <div style="color:var(--muted);font-size:18px;">&rarr;</div>
        <div style="background:var(--surf2);border:1px solid rgba(188,140,255,.3);border-radius:8px;padding:8px 14px;font-size:12px;text-align:center;color:#bc8cff;">McpClient<br><span style="font-size:11px">HTTP MCP request</span></div>
        <div style="color:var(--muted);font-size:18px;">&rarr;</div>
        <div style="background:var(--surf2);border:1px solid rgba(188,140,255,.3);border-radius:8px;padding:8px 14px;font-size:12px;text-align:center;color:#bc8cff;">TicketTool.cfc<br><span style="font-size:11px">fileTicket() + cfmail</span></div>
        <div style="color:var(--muted);font-size:18px;">&rarr;</div>
        <div style="background:var(--surf2);border:1px solid rgba(63,185,80,.3);border-radius:8px;padding:8px 14px;font-size:12px;text-align:center;color:var(--green);">Email<br><span style="font-size:11px">sent to you</span></div>
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Shows what's solved — direct CFC for orders, MCP for tickets + email</span>
    <span class="chip" onclick="send(this.innerText)">Where is my order #12345?</span>
    <span class="chip" onclick="send(this.innerText)">I want to escalate my issue with order #99821</span>
    <span class="chip" onclick="send(this.innerText)">Order #77654 arrived damaged — I need a manager now!</span>
    <span class="chip-label limits">&#x26A0; Shows the limitation — knowledge hardcoded in system message</span>
    <span class="chip" onclick="send(this.innerText)">Does the warranty cover accidental water damage?</span>
    <span class="chip" onclick="send(this.innerText)">Can I return a digital download that won't install?</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Problem 7: MCP added — fileTicket() now goes through MCP protocol + sends email</span>
<span class="cm">// (purple = new lines vs Problem 4)</span>

<span class="cm">// MCP tool — ticket filing + email (HTTP MCP protocol)</span>
<span class="diff-add">mcpClient = McpClient({</span>
<span class="diff-add">    transport: { type:"HTTP", URL:"http://localhost:8500/nexora/mcp/server.cfm" },</span>
<span class="diff-add">    clientInfo: { name:"nexora-mcp-client", version:"1.0.0" },</span>
<span class="diff-add">    initializationTimeout:30, requestTimeout:30</span>
<span class="diff-add">});</span>

aiAgent = <span class="fn">agent</span>({
    CHATMODEL  : chatModel,
    CHATMEMORY : { MAXMESSAGES: <span class="kw">20</span> },
    TOOLS      : [
        { CFC: <span class="str">"SupportTool"</span> },
<span class="diff-add">        { MCPCLIENT: [mcpClient] }</span>
    ]
});

<span class="cm">// When customer asks to escalate:
//   AI calls fileTicket() through MCP → TicketTool.cfc on the server
//   TicketTool.cfc runs cfmail → sends HTML email notification
//   Returns ticket ID + confirmation message to the customer</span></cfsavecontent>

<cfinclude template="_ui.cfm">
