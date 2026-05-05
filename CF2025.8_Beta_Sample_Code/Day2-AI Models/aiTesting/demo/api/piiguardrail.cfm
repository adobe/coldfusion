<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        data   = deserializeJSON(toString(getHTTPRequestData().content));
        text   = data.text     ?: "";
        action = data.action   ?: "validate";

        if (action == "demo") {
            provider = data.provider ?: "anthropic";
            switch (provider) {
                case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
                case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
                default:          apiKey = application.openaiKey;    modelName = application.openaiModel;
            }

            chatModel = ChatModel({ PROVIDER:provider, APIKEY:apiKey, MODELNAME:modelName, maxTokens:2000,seed=10 });
            demoPrompt = data.prompt ?: "Write a brief customer record. Include a name, email address, and some contact details.";

            // OUTPUTGUARDRAILS takes an array of absolute CFC file paths.
            // The agent runs each guardrail's validate() on LLM output automatically
            // BEFORE returning the response. No manual validate() call needed.
            // When guardrail blocks, it throws an exception.
            piiGuardrailPath = expandPath("/aiTesting/demo/g.cfc");
            aiService = agent({
                CHATMODEL:        chatModel,
                OUTPUTGUARDRAILS: [piiGuardrailPath]
            });

            t0 = getTickCount();
            finalText = "";
            guardrailBlocked = false;
            guardrailMsg = "";
            try {
                resp = aiService.chat(demoPrompt);
                finalText = resp.message ?: "";
            } catch (any gErr) {
                guardrailBlocked = true;
                guardrailMsg = gErr.message;
            }
            elapsed = getTickCount() - t0;

            // Also get the raw text for side-by-side comparison in the UI:
            // run a separate chatModel.chat() without guardrail to show "before"
            rawResp = chatModel.chat(demoPrompt);
            rawText = rawResp.message ?: "";

            if (guardrailBlocked) {
                outcome = "blocked";
                finalText = guardrailMsg;
            } else if (rawText neq finalText) {
                outcome = "redacted";
            } else {
                outcome = "passed";
            }

            writeOutput(serializeJSON({
                success:   true,
                action:    "demo",
                rawText:   rawText,
                finalText: finalText,
                outcome:   outcome,
                elapsed:   elapsed
            }));

        } else {
            if (!len(trim(text))) {
                writeOutput(serializeJSON({ success: false, error: "Text is required." }));
                return;
            }

            // Direct validation — still useful for the "validate text" UI panel
            guard = createObject("component", "aiTesting.demo.g");
            gr    = guard.validate(text);

            if (gr.result == "failure") {
                writeOutput(serializeJSON({ success:true, outcome:"blocked", errorMessage:gr.message, originalText:text }));
            } else if (gr.result == "successWith") {
                writeOutput(serializeJSON({ success:true, outcome:"redacted", finalText:gr.repromptMessage, originalText:text }));
            } else {
                writeOutput(serializeJSON({ success:true, outcome:"passed", finalText:text, originalText:text }));
            }
        }

    } catch (any e) {
        writeOutput(serializeJSON({ success: false, error: e.message ?: e.type ?: "Unknown server error", detail: e.detail ?: "" }));
    }
</cfscript>
