<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");

    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        rawBody = toString(getHTTPRequestData().content);
        data    = deserializeJSON(rawBody);

        mode         = data.mode         ?: "compare";
        prompt       = data.prompt       ?: "Write a short story about a treasure hunt.";
        useGuardrail = data.useGuardrail ?: true;
        provider     = data.provider     ?: "anthropic";

        switch (provider) {
            case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
            case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
            default:          apiKey = application.openaiKey;    modelName = application.openaiModel; provider = "openai";
        }

        chatModel = ChatModel({
            PROVIDER:    provider,
            APIKEY:      apiKey,
            MODELNAME:   modelName,
            maxTokens:   300,
            temperature: 0.7
        });

        safeSystemMsg = "You are a helpful assistant with strict content guidelines. "
            & "You must refuse requests for violence, harmful content, or anything illegal. "
            & "Keep responses family-friendly and professional. "
            & "If a request violates these guidelines, politely decline and explain why.";

        // Guardrail CFC paths — INPUTGUARDRAILS and OUTPUTGUARDRAILS take
        // arrays of absolute CFC file paths (use expandPath())
        piiGuardrailPath = expandPath("/aiTesting/demo/g.cfc");

        providerNotes = {
            "mistral":   "Guardrails: systemMessage() + OUTPUTGUARDRAILS with PiiGuardrail. Mistral also supports a native safePrompt flag.",
            "openai":    "Guardrails: systemMessage() + OUTPUTGUARDRAILS with PiiGuardrail. OpenAI also has a built-in Moderation API.",
            "anthropic": "Guardrails: systemMessage() + OUTPUTGUARDRAILS with PiiGuardrail. Anthropic Claude has Constitutional AI built-in."
        };

        if (mode == "compare") {
            // SAFE: agent() with systemMessage + OUTPUTGUARDRAILS
            safeAgent = agent({
                CHATMODEL:        chatModel,
                OUTPUTGUARDRAILS: [piiGuardrailPath]
            });
            safeAgent.systemMessage(safeSystemMsg);
            safeMsg = "";
            t0Safe  = getTickCount();
            try {
                rSafe   = safeAgent.chat(prompt);
                safeMsg = rSafe.message ?: "";
            } catch (any gErr) {
                safeMsg = "[BLOCKED by guardrail] " & gErr.message;
            }
            elSafe  = getTickCount() - t0Safe;

            // UNSAFE: agent() without systemMessage or guardrails
            unsafeAgent = agent({ CHATMODEL: chatModel });
            t0Un    = getTickCount();
            rUnsafe = unsafeAgent.chat(prompt);
            elUnsafe = getTickCount() - t0Un;

            result = {
                success:  true,
                mode:     "compare",
                provider: provider,
                prompt:   prompt,
                note:     providerNotes[provider] ?: "",
                safe: {
                    guardrailActive: true,
                    systemMessage:   safeSystemMsg,
                    message:         safeMsg,
                    elapsed:         elSafe
                },
                unsafe: {
                    guardrailActive: false,
                    systemMessage:   "(none)",
                    message:         rUnsafe.message ?: "",
                    elapsed:         elUnsafe
                }
            };

        } else {
            agentConfig = { CHATMODEL: chatModel };
            if (useGuardrail) {
                agentConfig["OUTPUTGUARDRAILS"] = [piiGuardrailPath];
            }
            aiService = agent(agentConfig);
            if (useGuardrail) {
                aiService.systemMessage(safeSystemMsg);
            }

            singleMsg = "";
            t0 = getTickCount();
            try {
                r  = aiService.chat(prompt);
                singleMsg = r.message ?: "";
            } catch (any gErr) {
                singleMsg = "[BLOCKED by guardrail] " & gErr.message;
            }
            el = getTickCount() - t0;

            result = {
                success:         true,
                mode:            "single",
                provider:        provider,
                guardrailActive: useGuardrail,
                systemMessage:   (useGuardrail ? safeSystemMsg : "(none)"),
                message:         singleMsg,
                elapsed:         el,
                note:            providerNotes[provider] ?: ""
            };
        }

    } catch (any e) {
        result = { success: false, error: e.message ?: e.type ?: "Unknown server error", detail: e.detail ?: "" };
    }

    writeOutput(serializeJSON(result));
</cfscript>
