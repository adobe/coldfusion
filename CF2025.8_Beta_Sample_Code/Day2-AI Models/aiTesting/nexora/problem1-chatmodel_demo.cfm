<!--- Nexora — Chapter 1: Basic Chat — just ChatModel(), no system message, no memory --->
<cfif structKeyExists(url, "api")>
    <cfcontent type="application/json" reset="true">
    <cfparam name="form.question" default="">
    <cfscript>
        try {
            if ( !len(trim(form.question)) ) {
                apiPayload = {}; apiPayload["success"] = false; apiPayload["message"] = "Please enter a question.";
                writeOutput(serializeJSON(apiPayload));
                return;
            }

            chatModel = ChatModel({
                PROVIDER    : application.provider,
                APIKEY      : application.apiKey,
                MODELNAME   : application.modelName,
                TEMPERATURE : 0.4,
                MAXTOKENS   : 300
            });

            aiAgent  = agent({ CHATMODEL: chatModel });
            response = aiAgent.chat( form.question );
            msg = response.message ?: "";

            apiPayload = {}; apiPayload["success"] = true; apiPayload["message"] = msg;
            writeOutput(serializeJSON(apiPayload));

        } catch (any e) {
            apiPayload = {}; 
            apiPayload["success"] = false; 
            apiPayload["message"] = "Error: " & e.message & " | Detail: " & e.detail & " | Type: " & e.type;
            writeOutput(serializeJSON(apiPayload));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Chapter 1: Basic Chat",
        subtitle    : "Chapter 1 — Basic Chat with ChatModel()",
        activeNav   : "problem1-chatmodel_demo.cfm",
        apiEndpoint : "problem1-chatmodel_demo.cfm",
        placeholder : "Ask anything (note: no identity constraints yet)...",
        hasReset    : false,
        pills       : [
            { label: application.modelName, class: "p-blue"  },
            { label: "No Memory",      class: "p-muted" },
            { label: "No System Msg",  class: "p-muted" }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 1 — Basic Chat with ChatModel()</h2>
    <p>Replace a 50-line rule-based if/else chatbot with 3 lines of <code>ChatModel()</code>. The AI understands natural language and handles any phrasing — no keyword matching needed.</p>
    <div class="info-box">
        <strong>&#x2713; Solves:</strong>
        Rigid keyword routing breaks on any unexpected phrasing.<br>
        <code>ChatModel()</code> handles language variation naturally — no rules to maintain.<br>
        Works for any question type without code changes.
    </div>
    <div class="warn-box">
        <strong>&#x26A0; Limitations (fixed in Problem 2):</strong>
        No identity — AI doesn't know it works for Nexora, answers competitor questions freely.<br>
        No memory — forgets the entire conversation between messages.<br>
        No live data — can't look up real order status.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Shows what's solved — understands free-form phrasing</span>
    <span class="chip" onclick="send(this.innerText)">My item broke the first time I used it!</span>
    <span class="chip" onclick="send(this.innerText)">I've been charged twice for the same thing</span>
    <span class="chip-label limits">&#x26A0; Shows the limitation — no identity, no scope enforcement</span>
    <span class="chip" onclick="send(this.innerText)">My parcel hasn't showed up — what should I do?</span>
    <span class="chip" onclick="send(this.innerText)">Write me a poem about a dog</span>
    <span class="chip" onclick="send(this.innerText)">Tell me about Amazon's return policy</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Chapter 1: 3 lines replace 50 lines of if/else</span>
<span class="fn">chatModel</span> = <span class="fn">ChatModel</span>({
    PROVIDER    : <span class="str">"anthropic"</span>,
    APIKEY      : application.anthropicKey,
    MODELNAME   : <span class="str">"claude-sonnet-4-5"</span>,
    TEMPERATURE : <span class="kw">0.4</span>,
    MAXTOKENS   : <span class="kw">300</span>
});

aiAgent  = <span class="fn">agent</span>({ CHATMODEL: chatModel });
response = aiAgent.<span class="fn">chat</span>( form.question );
<span class="cm">// response.message = AI reply
// No system message — AI doesn't know it's Nexora
// No memory — each call is independent
// → Chapter 2 adds systemMessage() to fix identity
// → Chapter 3 adds CHATMEMORY to fix memory</span></cfsavecontent>

<cfinclude template="_ui.cfm">
