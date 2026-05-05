<!--- Nexora — Chapter 3: Chat Memory — agent() + systemMessage() + CHATMEMORY, session-persisted --->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfscript>
        try {
            if ( structKeyExists(url, "reset") ) {
                structDelete(session, "acmeCh3AI");
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

            if ( !isDefined("session.acmeCh3AI") ) {
                lock scope="session" type="exclusive" timeout="60" {
                    if ( !isDefined("session.acmeCh3AI") ) {

                        chatModel = ChatModel({
                            PROVIDER    : application.provider,
                            APIKEY      : application.apiKey,
                            MODELNAME   : application.modelName,
                            TEMPERATURE : 0.3,
                            MAXTOKENS   : 400
                        });

                        aiAgent = agent({
                            CHATMODEL  : chatModel,
                            CHATMEMORY : { MAXMESSAGES: 20 }
                        });

                        aiAgent.systemMessage(
                            "You are Nexora's friendly customer support assistant. " &
                            "Only answer questions related to Nexora products, orders, and policies. " &
                            "If asked about competitors, say: 'I can only help with Nexora products.' " &
                            "Remember details the customer shares (like order numbers) throughout the conversation. " &
                            "Be concise and helpful."
                        );

                        session.acmeCh3AI = aiAgent;
                    }
                }
            }

            lock scope="session" type="exclusive" timeout="30" {
                response = session.acmeCh3AI.chat( form.question );
            }
            apiPayload = {}; apiPayload["success"] = true; apiPayload["message"] = response.message ?: "";
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
        title       : "Chapter 3: Chat Memory",
        subtitle    : "Chapter 3 — Chat Memory with CHATMEMORY",
        activeNav   : "problem3-chatmemory_demo.cfm",
        apiEndpoint : "problem3-chatmemory_demo.cfm",
        placeholder : "Try: 'My order is ##12345' then ask about it again...",
        hasReset    : true,
        pills       : [
            { label: application.modelName, class: "p-blue"   },
            { label: "System Message ✓", class: "p-green"  },
            { label: "Memory ✓",         class: "p-purple" }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 3 — Chat Memory with CHATMEMORY</h2>
    <p>The agent is created once per session and reused. <code>CHATMEMORY</code> keeps a sliding window of prior messages so the AI has full conversational context on every turn.</p>
    <div class="info-box">
        <strong>&#x2713; Solves:</strong>
        AI forgot everything between messages — each turn was a blank slate.<br>
        Session-cached agent with <code>CHATMEMORY</code> retains context across the full conversation.<br>
        Tell it your order number — reference it 5 messages later and it still knows.
    </div>
    <div class="warn-box">
        <strong>&#x26A0; Limitations (fixed in Problem 4):</strong>
        No live data — AI still can't look up real order status, only what you tell it.<br>
        No PII protection — sensitive data in responses goes out unfiltered.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Shows what's solved — send these two in order</span>
    <span class="chip" onclick="send(this.innerText)">My order #12345 hasn't arrived yet</span>
    <span class="chip" onclick="send(this.innerText)">What was that order number I just told you?</span>
    <span class="chip-label limits">&#x26A0; Shows the limitation — no live data, no PII guardrail</span>
    <span class="chip" onclick="send(this.innerText)">Look up the live status of order #12345 right now</span>
    <span class="chip" onclick="send(this.innerText)">My credit card is 4111-1111-1111-1111, please note it for my file</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Chapter 3: agent() + CHATMEMORY — memory persists in session</span>
<span class="cm">// (new lines highlighted vs Chapter 2)</span>

<span class="kw">if</span> ( !isDefined(<span class="str">"session.acmeCh3AI"</span>) ) {
    chatModel = <span class="fn">ChatModel</span>({
        PROVIDER    : <span class="str">"anthropic"</span>,
        APIKEY      : application.anthropicKey,
        MODELNAME   : <span class="str">"claude-sonnet-4-5"</span>,
        TEMPERATURE : <span class="kw">0.3</span>,
        MAXTOKENS   : <span class="kw">400</span>
    });

    aiAgent = <span class="fn">agent</span>({
        CHATMODEL  : chatModel,
<span class="diff-add">        CHATMEMORY : { MAXMESSAGES: 20 }</span>
    });

    aiAgent.<span class="fn">systemMessage</span>(
        <span class="str">"You are Nexora's friendly customer support assistant. "</span> &
        <span class="str">"Only answer questions related to Nexora products, orders, and policies. "</span> &
<span class="diff-add">        "Remember details the customer shares throughout the conversation. " &</span>
        <span class="str">"Be concise and helpful."</span>
    );

<span class="diff-add">    session.acmeCh3AI = aiAgent;</span>  <span class="cm">// ← stored once, reused every turn</span>
}

<span class="cm">// Same call — but now the agent carries full history</span>
response = session.acmeCh3AI.<span class="fn">chat</span>( form.question );
<span class="cm">// CHATMEMORY automatically stores every user + AI turn
// MAXMESSAGES:20 keeps the last 20 messages in context window
// Session stores the agent so memory survives page reloads
// → Full App adds tools, PII guardrail, and policy documents</span></cfsavecontent>

<cfinclude template="_ui.cfm">
