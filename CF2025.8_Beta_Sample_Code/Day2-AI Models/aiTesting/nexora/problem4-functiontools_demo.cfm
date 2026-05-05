<!--- Nexora — Chapter 4: Function Tools — agent() + TOOLS:[SupportTool], AI calls CFC methods --->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            if ( structKeyExists(url, "reset") ) {
                apiPayload = {}; apiPayload["success"] = true; apiPayload["reset"] = true;
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            cfparam(name="form.question", default="");
            if ( !len(trim(form.question)) ) {
                apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Please enter a question.";
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            chatModel = ChatModel({
                PROVIDER    : application.provider,
                APIKEY      : application.apiKey,
                MODELNAME   : application.modelName,
                TEMPERATURE : 0.3,
                MAXTOKENS   : 1500
            });

            aiAgent = agent({
                CHATMODEL  : chatModel,
                CHATMEMORY : { MAXMESSAGES: javacast("int", 20) },
                TOOLS      : [ { CFC: "SupportTool" } ]
            });

            aiAgent.systemMessage(
                "You are Nexora's friendly customer support assistant. " &
                "Only answer questions related to Nexora products, orders, and policies. " &
                "You have tools available: " &
                "Use getOrderStatus to look up real order data — ALWAYS call this tool for any order status question, NEVER guess. " &
                "Use escalateIssue when the customer explicitly asks to escalate, is very frustrated, or asks to speak with a manager. " &
                "If asked about competitors, say: 'I can only help with Nexora products.' " &
                "Be concise and helpful."
            );

            response = aiAgent.chat( form.question );

            // Tool round-trip loop: LLM may request tools on first call.
            // We execute them, feed results back, and check again (max 3 rounds
            // to guard against infinite loops).
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
                                toolResult = supportTool.getOrderStatus(args.orderId ?: args.orderid ?: "");
                                break;
                            case "escalateissue":
                                toolResult = supportTool.escalateIssue(args.summary ?: "", args.orderId ?: args.orderid ?: "");
                                break;
                            default:
                                toolResult = "Unknown tool: " & nm;
                        }
                    } catch (any te) {
                        toolResult = "Tool error: " & te.message;
                    }
                    toolResultsStr &= "Tool " & (req.name ?: "") & " returned: " & toolResult & chr(10);
                }

                response = aiAgent.chat(
                    "Here are the tool results:" & chr(10) &
                    toolResultsStr & chr(10) &
                    "Using ONLY these tool results, provide a complete, helpful answer to the customer. " &
                    "Do NOT say you are looking something up or executing a tool — the results are already here."
                );
            }

            msg = response.message ?: "";
            apiPayload = {}; apiPayload["success"] = true; apiPayload["message"] = msg;
            writeOutput(serializeJSON(apiPayload));

        } catch (any e) {
            apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Error: " & e.message;
            writeOutput(serializeJSON(apiPayload));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Chapter 4: Function Tools",
        subtitle    : "Chapter 4 — Function Tools with TOOLS:[SupportTool]",
        activeNav   : "problem4-functiontools_demo.cfm",
        apiEndpoint : "problem4-functiontools_demo.cfm",
        placeholder : "Ask about an order — try ##12345, ##77654, or ##11111...",
        hasReset    : true,
        pills       : [
            { label: application.modelName, class: "p-blue"   },
            { label: "System Message ✓", class: "p-green"  },
            { label: "Memory ✓",         class: "p-purple" },
            { label: "Tools ✓",          class: "p-orange" }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 4 — Function Tools (AI calls CFC methods)</h2>
    <p>The AI automatically calls your ColdFusion CFC methods to fetch live data. No routing code — the LLM reads each method's docblock and decides when to call it.</p>
    <div class="info-box">
        <strong>&#x2713; Solves:</strong>
        AI could only answer from knowledge — it couldn't look up real order data.<br>
        <code>TOOLS:[supportTool]</code> exposes <code>getOrderStatus()</code> and <code>escalateIssue()</code> directly to the LLM.<br>
        AI decides when to call a tool — no if/else routing needed.<br>
        Try: #12345 (Shipped), #99821 (Processing), #77654 (Delivered), #11111 (Out for Delivery)
    </div>
    <div class="warn-box">
        <strong>&#x26A0; Limitations (fixed in Problem 5):</strong>
        No PII protection — ask for the account email and it shows unredacted.<br>
        Escalation only writes a log entry — no real ticket or email sent.<br>
        No external tool integrations — tools are limited to local CFC methods.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Shows what's solved — real order lookups via CFC tool</span>
    <span class="chip" onclick="send(this.innerText)">Where is my order #12345?</span>
    <span class="chip" onclick="send(this.innerText)">What's the status of order #99821?</span>
    <span class="chip" onclick="send(this.innerText)">Has order #77654 been delivered?</span>
    <span class="chip" onclick="send(this.innerText)">Will order #11111 arrive today?</span>
    <span class="chip" onclick="send(this.innerText)">What happened to my order #55432?</span>
    <span class="chip-label limits">&#x26A0; Shows the limitation — email exposed unredacted, no PII guardrail yet</span>
    <span class="chip" onclick="send(this.innerText)">What email is on my account for order #12345?</span>
    <span class="chip" onclick="send(this.innerText)">What email address did I use for order #99821?</span>
    <span class="chip" onclick="send(this.innerText)">I am furious — escalate this to a manager right now!</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Chapter 4: TOOLS added — AI calls your CFC methods</span>
<span class="cm">// (new lines highlighted vs Chapter 3)</span>

<span class="cm">// The tool CFC — methods the AI can call</span>
<span class="diff-add">supportTool = createObject("component", "SupportTool");</span>

aiAgent = <span class="fn">agent</span>({
    CHATMODEL  : chatModel,
    CHATMEMORY : { MAXMESSAGES: <span class="kw">20</span> },
<span class="diff-add">    TOOLS      : [ supportTool ]    // ← the one new line</span>
});

aiAgent.<span class="fn">systemMessage</span>(
    <span class="str">"You are Nexora's support assistant. "</span> &
<span class="diff-add">    "Use getOrderStatus to look up real order data — never guess. " &</span>
<span class="diff-add">    "Use escalateIssue when customer asks to escalate. " &</span>
    <span class="str">"Be concise and helpful."</span>
);

response = session.acmeCh4AI.<span class="fn">chat</span>( form.question );
<span class="cm">// AI now calls getOrderStatus("12345") automatically
// Returns real tracking data from SupportTool.cfc
// AI calls escalateIssue() when customer is frustrated
// → Full App adds PII guardrail on top of this</span></cfsavecontent>

<cfinclude template="_ui.cfm">
