<cfscript>
exp = val(url.exp ?: 0);
msg = url.msg ?: "";

// ========== MENU ==========
if (exp == 0) {
  writeOutput("S2 SCRATCHPAD - Explore Memory & Preferences<br>");
  writeOutput("  ?exp=1  The Agent Remembers (multi-turn)<br>");
  writeOutput("  ?exp=2  LLM as Structured Parser<br>");
  writeOutput("  ?exp=3  AgentService (production memory)<br>");
  writeOutput("  ?exp=4  Preferences That Survive<br>");
  writeOutput("  ?exp=5  Memory Window Eviction<br>");
  abort;
}

// ========== EXP 1: Multi-Turn Memory ==========
if (exp == 1) {
  msg1 = url.msg1 ?: "My name is Jordan";
  msg2 = url.msg2 ?: "I love navy blue and wear size M";
  msg3 = url.msg3 ?: "What's my name, favorite color, and size?";
  model = ChatModel({PROVIDER:"openai", MODELNAME:"gpt-4o-mini", APIKEY:application.OPENAI_API_KEY, TEMPERATURE:0.5, MAXTOKENS:800});
  myAgent = agent({CHATMODEL:model, CHATMEMORY:{TYPE:"messageWindowChatMemory", MAXMESSAGES:10, PERUSER:false}});
  myAgent.systemMessage("You are Mira, the StyleMart shopping assistant. Be concise.");
  r1 = myAgent.chat(msg1);
  r2 = myAgent.chat(msg2);
  r3 = myAgent.chat(msg3);
  writeOutput("<b>Turn 1:</b> " & msg1 & "<br>");
  writeDump(var=r1, label="Response 1");
  writeOutput("<br><b>Turn 2:</b> " & msg2 & "<br>");
  writeDump(var=r2, label="Response 2");
  writeOutput("<br><b>Turn 3:</b> " & msg3 & "<br>");
  writeDump(var=r3, label="Response 3");
  abort;
}

// ========== EXP 2: Preference Extraction ==========
if (exp == 2) {
  if (!len(msg)) msg = "I wear size M, love navy and black, budget around 200";
  model = ChatModel({PROVIDER:"openai", MODELNAME:"gpt-4o-mini", APIKEY:application.OPENAI_API_KEY, TEMPERATURE:0.0, MAXTOKENS:300});
  extractionPrompt = "You are a preference extraction engine. Return ONLY valid JSON.
Schema: {""occasion"":[""work"",""casual"",""wedding"",""beach"",""gym"",""date"",""party""],""topSize"":[""XS"",""S"",""M"",""L"",""XL"",""XXL""],""jeansSize"":""number"",""colors"":[""color names""],""budget"":""number""}
Rules: 1. Extract only explicitly stated info. 2. Do not guess. 3. If nothing, return {}. 4. colors = lowercase array.
Message: """ & msg & """";
  result = model.chat(extractionPrompt);
  raw = result.message ?: "";
  parsed = {};
  try { parsed = deserializeJSON(raw); } catch (any e) { parsed = {"_parseError": e.message, "_raw": raw}; }
  writeOutput("<b>Prompt:</b> " & msg & "<br><br>");
  writeDump(var=raw, label="Raw LLM output");
  writeDump(var=parsed, label="Parsed preferences from: " & msg);
  abort;
}

// ========== EXP 3: AgentService (Production Memory) ==========
if (exp == 3) {
  if (!len(msg)) msg = "I want something casual for the weekend";
  if (structKeyExists(url, "reset")) {
    new api.agent.s2.ref.AgentService().evict("scratchpad-session-s2");
    writeOutput("Session evicted. Reload without &reset.");
    abort;
  }
  agentSvc = new api.agent.s2.ref.AgentService();
  bundle = agentSvc.getOrCreateAgent("scratchpad-session-s2", "scratchpad-user");
  fullPrompt = "Known preferences: {}
User: " & msg;
  result = bundle.model.chat(fullPrompt);
  writeOutput("<b>Prompt:</b> " & fullPrompt & "<br><br>");
  writeDump(var=result, label="AgentService response (msg=" & msg & ")");
  abort;
}

// ========== EXP 4: Persistent Preferences ==========
if (exp == 4) {
  memory = new api.agent.s2.ref.Memory();
  if (structKeyExists(url, "reset")) {
    memory.deletePrefs("scratchpad-user");
    writeOutput("Preferences cleared. Reload without &reset.");
    abort;
  }
  agentSvc = new api.agent.s2.ref.AgentService();
  bundle = agentSvc.getOrCreateAgent("scratchpad-pref", "scratchpad-user");
  beforePrefs = memory.loadPrefs("scratchpad-user");
  if (structKeyExists(beforePrefs, "_corrupt")) beforePrefs = {};
  extracted = {};
  if (len(msg)) {
    extracted = memory.extractPrefs(msg, bundle.model, "scratchpad-user", "");
    if (!structIsEmpty(extracted)) {
      try { memory.savePrefs("scratchpad-user", extracted); } catch (any e) {}
    }
  }
  afterPrefs = memory.loadPrefs("scratchpad-user");
  if (structKeyExists(afterPrefs, "_corrupt")) afterPrefs = {};
  if (len(msg)) {
    writeOutput("<b>Prompt:</b> " & msg & "<br><br>");
  }
  writeDump(var=beforePrefs, label="BEFORE preferences");
  if (!structIsEmpty(extracted)) writeDump(var=extracted, label="Extracted this turn from: " & msg);
  writeDump(var=afterPrefs, label="AFTER preferences (reload page without &msg to verify persistence)");
  abort;
}

// ========== EXP 5: Memory Window Eviction ==========
if (exp == 5) {
  model = ChatModel({PROVIDER:"openai", MODELNAME:"gpt-4o-mini", APIKEY:application.OPENAI_API_KEY, TEMPERATURE:0.5, MAXTOKENS:800});
  myAgent = agent({CHATMODEL:model, CHATMEMORY:{TYPE:"messageWindowChatMemory", MAXMESSAGES:3, PERUSER:false}});
  myAgent.systemMessage("You are Mira. Be concise. Always answer directly.");
  messages = ["Remember this secret code: ALPHA-7","My favorite color is purple","I like pizza for dinner","The weather is nice today","What was my secret code from the first message?"];
  for (i = 1; i <= arrayLen(messages); i++) {
    result = myAgent.chat(messages[i]);
    writeOutput("<b>Turn " & i & ":</b> " & messages[i] & "<br>");
    writeDump(var=result.message ?: "", label="Response " & i);
    writeOutput("<br>");
  }
  writeOutput("<br>--- MAXMESSAGES=3: Agent should have FORGOTTEN the secret code by turn 5 ---");
  abort;
}
</cfscript>
