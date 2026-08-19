<cfscript>
exp = val(url.exp ?: 1);
msg = url.msg ?: "suggest a winter outfit for a casual weekend";


// ========== EXP 1: Basic Chat ==========
if (exp == 1) {
  model = ChatModel({
                      PROVIDER:"openai", 
                      MODELNAME:"gpt-4o-mini", 
                      APIKEY:application.OPENAI_API_KEY, 
                      TEMPERATURE:0.2, 
                      MAXTOKENS:800
                      });

  systemPrompt = "You are Mira, the StyleMart shopping assistant.
                  Be friendly and short - three sentences max.
                  Recommend products only when the shopper asks.
                  Never invent prices, stock numbers, or product names.
                  If you do not know, say you do not know.";
                  fullPrompt = systemPrompt & "
                  User: " & msg;


  result = model.chat(fullPrompt);

  writeOutput("<b>Prompt:</b> " & fullPrompt & "<br><br>");

  writeDump(var=result, label="Experiment 1: Your First AI Call (msg=" & msg & ")");
  abort;
}

// ========== EXP 2: Two Temperatures ==========
if (exp == 2) {

  temperature1 = 0.2
  temperature2 = 1.0

  model1 = ChatModel({
                        PROVIDER:"openai", 
                        MODELNAME:"gpt-4o-mini", 
                        APIKEY:application.OPENAI_API_KEY, 
                        TEMPERATURE:temperature1, 
                        MAXTOKENS:200
                      });

  model2 = ChatModel({
                        PROVIDER:"openai", 
                        MODELNAME:"gpt-4o-mini", 
                        APIKEY:application.OPENAI_API_KEY, 
                        TEMPERATURE:temperature2, 
                        MAXTOKENS:200
                      });

  prompt1 = msg;
  prompt2 = msg;

  for (i = 1; i <= 2; i++) {
    r1 = model1.chat(prompt1);
    writeOutput("<b>Prompt:</b> " & prompt1 & "<br><br>");
    writeDump(var=r1, label="Temperature " & temperature1 & " (conservative)");
  }

  for (i = 1; i <= 2; i++) {
    r2 = model2.chat(prompt2);
    writeOutput("<b>Prompt:</b> " & prompt2 & "<br><br>");
    writeDump(var=r2, label="Temperature " & temperature2 & " (creative)");
  }
  abort;
}

// ========== EXP 3: Persona Swap ==========
if (exp == 3) {
  miraPrompt = "You are Mira, the StyleMart shopping assistant.
                Be friendly and short - three sentences max.
                Never invent prices.
                If you do not know, say you do not know.";

  luxuryPrompt = "You are a luxury concierge at StyleMart.
                  Speak with quiet confidence. Reference fabric and provenance.
                  Two sentences max. Never invent prices.";

  model = ChatModel({
                      PROVIDER:"openai", 
                      MODELNAME:"gpt-4o-mini", 
                      APIKEY:application.OPENAI_API_KEY, 
                      TEMPERATURE:0.7, 
                      MAXTOKENS:300});


  agent = agent({chatmodel = model})

  agent.systemMessage(miraPrompt)

  r1 = agent.chat(msg);
  writeOutput("<b>Prompt:</b> " & msg & "<br><br>");
  writeDump(var=r1, label="Mira (casual)");


 agent.systemMessage(luxuryPrompt)

  r2 = agent.chat(msg);
  writeOutput("<b>Prompt:</b> " & msg & "<br><br>");
  writeDump(var=r2, label="Luxury Concierge");
  abort;
}

// ========== EXP 4: AgentService (Production Pattern) ==========
if (exp == 4) {
  agentSvc = new api.agent.s1.ref.AgentService();
  myAgent = agentSvc.getOrCreateAgent("scratchpad-" & hash(CGI.REMOTE_ADDR), false);
  systemPrompt = fileRead(expandPath("/api/agent/s1/config/system-prompt.txt"));

  myAgent.systemMessage(systemPrompt)
  result = myAgent.chat(msg);

  writeOutput("<b>Prompt:</b> " & msg & "<br><br>");
  writeDump(var=result, label="Experiment 4: via AgentService (msg=" & msg & ")");
  abort;
}

// ========== EXP 5: Hallucination Demo ==========
if (exp == 5) {
  safePrompt = "You are Mira, the StyleMart shopping assistant.
                Be friendly and short - three sentences max.
                Recommend products only when asked.
                Never invent prices, stock numbers, or product names.
                If you do not know, say you do not know.";

  unsafePrompt = "You are Mira, the StyleMart shopping assistant.
                  Be friendly and short - three sentences max.
                  Recommend products only when asked.";

  question = "What's the fabric composition of the navy travel blazer, and can it be machine-washed?";
  
  model = ChatModel({PROVIDER:"openai", 
                      MODELNAME:"gpt-4o-mini", 
                      APIKEY:application.OPENAI_API_KEY, 
                      TEMPERATURE:0.0, 
                      MAXTOKENS:300
                      });

  fullSafe = safePrompt & "User: " & question;
  fullUnsafe = unsafePrompt & "User: " & question;

  r1 = model.chat(fullSafe);
  writeOutput("<b>Prompt:</b> " & fullSafe & "<br><br>");
  writeDump(var=r1, label="WITH safety rules (F4+F5) - should REFUSE");

  r2 = model.chat(fullUnsafe);
  writeOutput("<b>Prompt:</b> " & fullUnsafe & "<br><br>");
  writeDump(var=r2, label="WITHOUT safety rules - will HALLUCINATE");
  abort;
}
</cfscript>
