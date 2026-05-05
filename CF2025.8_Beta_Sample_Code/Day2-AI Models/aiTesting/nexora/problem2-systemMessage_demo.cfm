<!--- Nexora — Chapter 2: System Message — agent() + systemMessage(), Nexora identity enforced --->
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

            aiAgent = agent({ CHATMODEL: chatModel, CHATMEMORY: { MAXMESSAGES: 20 } });

            aiAgent.systemMessage(
                "You are Nexora Support, the official customer support assistant for Nexora — an online retail company with the tagline 'Shop Smarter. Ship Faster.'" & chr(10) &
                "STRICT RULES YOU MUST FOLLOW:" & chr(10) &
                "1. IDENTITY: Always identify yourself as 'Nexora Support'. Never say you are an AI, a language model, or ChatGPT." & chr(10) &
                "2. SCOPE: ONLY answer questions about Nexora products, orders, shipping, returns, and policies. Nothing else." & chr(10) &
                "3. COMPETITORS: If the customer mentions Amazon, Walmart, eBay, Shopify, Target, Best Buy, or ANY other company, respond ONLY with: 'I can only help with Nexora products and services. Is there anything Nexora-related I can assist you with?'" & chr(10) &
                "4. OFF-TOPIC: If asked about weather, sports, coding, math, recipes, news, or anything unrelated to Nexora, respond ONLY with: 'I'm Nexora Support — I can only help with Nexora orders, products, and policies. What can I help you with today?'" & chr(10) &
                "5. TONE: Be warm, concise (2-3 sentences max), and professional." & chr(10) &
                "6. NEVER answer general knowledge questions, even if you know the answer."
            );

            response = aiAgent.chat( form.question );
            apiPayload = {}; 
            apiPayload["success"] = true; 
            apiPayload["message"] = response.message ?: "";
            writeOutput(serializeJSON(apiPayload));

        } catch (any e) {
            apiPayload = {}; 
            apiPayload["success"] = false; 
            apiPayload["message"] = "Error: " & e.message;
            writeOutput(serializeJSON(apiPayload));
        }
    </cfscript>
    <cfreturn>
</cfif>

<!--- ── UI Configuration ─────────────────────────────────────────────── --->
<cfscript>
    ui = {
        title       : "Chapter 2: System Message",
        subtitle    : "Chapter 2 — System Message with agent()",
        activeNav   : "problem2-systemMessage_demo.cfm",
        apiEndpoint : "problem2-systemMessage_demo.cfm",
        placeholder : "Ask a question (identity is now constrained to Nexora)...",
        hasReset    : false,
        pills       : [
            { label: application.modelName, class: "p-blue"  },
            { label: "System Message ✓", class: "p-green" },
            { label: "No Memory",        class: "p-muted" }
        ]
    };
</cfscript>

<cfsavecontent variable="ui.welcomeHTML">
    <h2>Problem 2 — System Message with agent() + systemMessage()</h2>
    <p>Give the AI a Nexora identity, behavioral rules, and scope constraints — enforced on every single call. No code changes needed when rules change: just update the system message.</p>
    <div class="info-box">
        <strong>&#x2713; Solves:</strong>
        AI had no identity and answered any question freely.<br>
        <code>systemMessage()</code> enforces brand identity, scope limits, and competitor deflection.<br>
        Rules are centralized in one string — easy to update without touching business logic.
    </div>
    <div class="warn-box">
        <strong>&#x26A0; Limitations (fixed in Problem 3):</strong>
        No memory — each message is a fresh agent with no knowledge of prior turns.<br>
        No live data — AI still can't look up real order status or perform actions.
    </div>
</cfsavecontent>

<cfsavecontent variable="ui.chipsHTML">
    <span class="chip-label solved">&#x2713; Shows what's solved — identity &amp; scope enforcement</span>
    <span class="chip" onclick="send(this.innerText)">Who are you and what company is this?</span>
    <span class="chip" onclick="send(this.innerText)">Tell me about Amazon's prices</span>
    <span class="chip-label limits">&#x26A0; Shows the limitation — no memory, no live data</span>
    <span class="chip" onclick="send(this.innerText)">Where is my order #12345 right now?</span>
    <span class="chip" onclick="send(this.innerText)">What did I say in my last message?</span>
</cfsavecontent>

<cfsavecontent variable="ui.codeHTML"><span class="cm">// Chapter 2: agent() + systemMessage() — adds identity constraints</span>
<span class="cm">// (new lines highlighted vs Chapter 1)</span>

<span class="fn">chatModel</span> = <span class="fn">ChatModel</span>({
    PROVIDER    : <span class="str">"anthropic"</span>,
    APIKEY      : application.anthropicKey,
    MODELNAME   : <span class="str">"claude-sonnet-4-5"</span>,
    TEMPERATURE : <span class="kw">0.3</span>,
    MAXTOKENS   : <span class="kw">400</span>
});

<span class="diff-add">aiAgent = agent({ CHATMODEL: chatModel });</span>

<span class="diff-add">aiAgent.systemMessage(</span>
<span class="diff-add">    "You are Nexora's friendly customer support assistant. " &</span>
<span class="diff-add">    "Only answer questions related to Nexora products, orders, and policies. " &</span>
<span class="diff-add">    "If asked about competitors, say: 'I can only help with Nexora products.' " &</span>
<span class="diff-add">    "If asked off-topic questions, politely redirect. " &</span>
<span class="diff-add">    "Be concise and helpful."</span>
<span class="diff-add">);</span>

response = aiAgent.<span class="fn">chat</span>( form.question );
<span class="cm">// response.message = AI reply — now Nexora-aware
// Identity enforced on EVERY call via system message
// No memory — still creates a fresh agent per request
// → Chapter 3 adds CHATMEMORY to fix memory</span></cfsavecontent>

<cfinclude template="_ui.cfm">
