<cfscript>


chatModel = ChatModel({ 
    PROVIDER:"anthropic", 
    APIKEY:application.anthropicKey, 
    MODELNAME:application.anthropicModel, 
    maxTokens:2000,
    seed=10 });
            
demoPrompt = "Write a brief customer record. Include a name, email address, and some contact details.";
piiGuardrailPath = expandPath("/aiTesting/demo/g.cfc");
aiService = agent({
                CHATMODEL:        chatModel,
                OUTPUTGUARDRAILS: [piiGuardrailPath]
            });
response=aiService.chat(demoPrompt)
writeDump(response)

</cfscript>