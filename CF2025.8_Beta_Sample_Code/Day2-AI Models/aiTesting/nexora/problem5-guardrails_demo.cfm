<!--- Nexora — Problem 5: GuardRails — OUTPUTGUARDRAIL:[PiiGuardrail] blocks SSNs/cards, redacts emails --->
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

            piiGuardrail = createObject("component", "PiiGuardrail");

            aiAgent = agent({
                CHATMODEL       : chatModel,
                CHATMEMORY      : { MAXMESSAGES: javacast("int", 20) },
                TOOLS           : [ { CFC: "SupportTool" } ],
                OUTPUTGUARDRAILS : [getDirectoryFromPath(getCurrentTemplatePath()) & "PiiGuardrail.cfc"]
            });

            aiAgent.systemMessage(
                "You are Nexora's friendly customer support assistant. " &
                "Only answer questions related to Nexora products, orders, and policies. " &
                "You have tools available: " &
                "Use getOrderStatus to look up real order data — ALWAYS call this tool for any order status question, NEVER guess. " &
                "Use escalateIssue when the customer explicitly asks to escalate or is very frustrated. " &
                "If asked about competitors, say: 'I can only help with Nexora products.' " &
                "Support contact details: email support@nexora.com, returns at returns@nexora.com, warranty claims at warranty@nexora.com. " &
                "When customers ask how to contact us, include the relevant email address in your response. " &
                "Be concise and helpful."
            );

            response = aiAgent.chat( form.question );

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
                            default:
                                toolResult = "Unknown tool: " & nm;
                        }
                    } catch (any te) { toolResult = "Tool error: " & te.message; }
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

            guardResult = piiGuardrail.validate(msg);
            if (guardResult.result eq "successWith") {
                msg = guardResult.repromptMessage;
            } else if (guardResult.result eq "failure") {
                msg = "I'm sorry, I'm unable to display that response as it may contain sensitive information.";
            }

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
        title       : "Problem 5: GuardRails",
        subtitle    : "Problem 5 — GuardRails: PII Protection with OUTPUTGUARDRAIL",
        activeNav   : "problem5-guardrails_demo.cfm",
        apiEndpoint : "problem5-guardrails_demo.cfm",
        placeholder : "Try asking the AI to repeat a SSN, credit card, or email in its reply...",
        hasReset    : true,
        pills       : [
            { label: application.modelName, class: "p-blue"   },
            { label: "System Message ✓", class: "p-green"  },
            { label: "Memory ✓",         class: "p-purple" },
            { label: "Tools ✓",          class: "p-orange" },
            { label: "GuardRails ✓",     class: "p-red"    }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 5 — GuardRails (OUTPUTGUARDRAIL)</h2>
    <p>Every AI response passes through <strong>PiiGuardrail.cfc</strong> before it reaches the customer. The guardrail validates, redacts, or blocks the response based on configurable rules.</p>
    <div class="info-box">
        <strong>&#x2713; Solves:</strong>
        AI responses could contain sensitive data (SSNs, card numbers, emails) with no protection.<br>
        <code>OUTPUTGUARDRAIL</code> intercepts every response — SSNs/cards blocked, emails redacted.<br>
        Guardrail logic is a plain CFC: easy to extend with custom rules (profanity, brand compliance, etc.).<br>
        Try asking the AI to repeat a fake SSN (123-45-6789) or card (4111-1111-1111-1111) in its reply.
    </div>
    <div class="warn-box">
        <strong>&#x26A0; Limitations (fixed in Problem 6):</strong>
        Escalation still only writes a log entry — no real ticket or email sent to support team.<br>
        Knowledge base is hardcoded in the system message — doesn't scale to large document sets.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Guardrail: email redacted — tool returns account email, AI includes it in response</span>
    <span class="chip" onclick="send(this.innerText)">What email is on my account for order #12345?</span>
    <span class="chip" onclick="send(this.innerText)">What email address did I use for order #99821?</span>
    <span class="chip" onclick="send(this.innerText)">Can you confirm the contact email for order #77654?</span>
    <span class="chip-label solved">&#x2713; Guardrail: response blocked — AI echoes PII in escalation confirmation</span>
    <span class="chip" onclick="send(this.innerText)">Escalate my billing issue — my account verification number is 987-65-4321</span>
    <span class="chip" onclick="send(this.innerText)">I was charged twice on card 4111-1111-1111-1111 for order #12345 — escalate this now</span>
    <span class="chip-label limits">&#x26A0; Shows the limitation — escalation is log-only, no real ticket or email</span>
    <span class="chip" onclick="send(this.innerText)">I demand this be escalated to management — I've been waiting 3 weeks!</span>
    <span class="chip" onclick="send(this.innerText)">Where is my order #99821?</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Problem 5: OUTPUTGUARDRAIL added — validates AI response before customer sees it</span>
<span class="cm">// (red = new lines vs Problem 4)</span>

supportTool = <span class="fn">createObject</span>(<span class="str">"component"</span>, <span class="str">"SupportTool"</span>);

<span class="diff-add">// Guardrail CFC — validate() is called on every AI response</span>
<span class="diff-add">piiGuardrail = createObject("component", "PiiGuardrail");</span>

aiAgent = <span class="fn">agent</span>({
    CHATMODEL       : chatModel,
    CHATMEMORY      : { MAXMESSAGES: <span class="kw">20</span> },
    TOOLS           : [ supportTool ],
<span class="diff-add">    OUTPUTGUARDRAIL : piiGuardrail   // ← the one new line</span>
});

<span class="cm">// PiiGuardrail.validate(output) is called automatically on every response:
//   { success: true }              → pass through unchanged
//   { successWith: redactedText }  → return modified version
//   { success: false, errorMessage } → block — return error to customer</span>

<span class="diff-add">// Example: AI says "SSN: 123-45-6789" → validate() returns { success:false }</span>
<span class="diff-add">// Customer sees: "Response blocked: contains a Social Security Number pattern."</span>
<span class="diff-add">// Example: AI says "Email: sarah@example.com" → { successWith: "[protected]@example.com" }</span></cfsavecontent>

<cfinclude template="_ui.cfm">
