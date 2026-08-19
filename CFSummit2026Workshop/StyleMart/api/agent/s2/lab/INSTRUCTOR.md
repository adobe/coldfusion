# Session 2: Memory & Preferences — Instructor Guide

## Overview
- **Duration:** 60 minutes
- **Learning objectives:**
  - Enable multi-turn coherence via `messageWindowChatMemory`
  - Extract structured preferences from natural language using a separate LLM call
  - Persist preferences durably and inject them into subsequent prompts
  - Understand the systemMessage() once-only pattern
- **Prerequisites:** S1 complete (streaming chat works in Lab mode)
- **Wow moment:** Tell Mira "I wear size M" then ask "what size did I say?" — she remembers. Then close the browser, reopen, and preferences persist.

## Pre-Session Checklist
- Verify S1 Lab mode works (send "hi", get streaming response)
- Database `user_preferences` table exists (seeded by AMI)
- `demo-shopper-001` user exists in `users` table

## Story So Far
Mira can stream responses and swap personas via config. But she has no memory between messages and cannot remember anything you tell her about your preferences.

## Teaching Flow (Timeline)

### [0:00–0:10] — Concept Introduction

**Key points:**
- Two types of memory: chat memory (multi-turn context, session-scoped) and durable preferences (survives browser close, stored in DB)
- `messageWindowChatMemory`: keeps the last N messages in a sliding window. The agent handles insertion automatically.
- `systemMessage()` MUST be called ONCE at agent creation. Calling it per-turn stacks N copies in memory.
- Preference extraction uses a SEPARATE LLM call — not the chat agent. It runs before the conversation turn.
- The extraction prompt is the heart of S2: schema + numbered rules + worked examples.

**Talking points:**
- "In S1, every turn was independent. The model did not know what you said before. Now we add a memory window — the last 20 messages stay in context."
- "But memory alone is not enough. If you tell Mira your size is M, that fact needs to persist across sessions. We extract it with a focused LLM call and store it in the database."
- "Show Ref mode: say 'I wear size M', then 'what size did I say?' — she remembers. Now say 'I like navy and black'. Look at the trace panel — you see a `preference.persist` event."

**Common misconceptions:**
- "systemMessage() sets the prompt per turn" — No. It appends to memory. Calling it per-turn stacks N copies, confusing the model. Call it ONCE at agent creation.
- "Chat memory and preference memory are the same thing" — No. Chat memory is the sliding window (20 messages, session-scoped). Preferences are durable facts extracted and stored in the database.
- "The extraction happens during the chat" — No. It is a separate, synchronous LLM call that runs BEFORE the chat turn. The chat agent never sees the extraction prompt.

### [0:10–0:15] — Scratchpad Exploration

**Instructor says:** "Session 1's scratchpad showed you ChatModel. Session 2's shows you memory. Open scratchpad.cfm and add `?exp=1`."

**Note:** Output is raw `writeDump()` — attendees see the full response struct including metadata and token counts. No styled HTML.

**Guide attendees through:**
1. **Experiment 1** — "Three messages. The third asks 'what's my name and color?' Watch..." [response shows both] "One config line: CHATMEMORY. That's multi-turn coherence."
2. **Experiment 2** — "Send 'I wear size M, love navy, budget 200.' Look at the output — structured JSON. The LLM parsed natural language into a schema. That's the entire extraction trick."
3. **Experiment 4** — "Reload the page. See? Preferences are still there. That's durable memory — separate from chat history."

**Teaching beat:** "Experiment 2 showed you the extraction prompt raw. That same prompt lives inside Memory.cfc. Your TODOs wire extractPrefs into the chat loop so it runs on every message automatically."

**Transition:** "Open ChatService.cfc and Memory.cfc. Eleven TODOs across two files. Let's start."

### [0:15–0:55] — Hands-On Coding

**Phase 1: Agent configuration (TODOs S2-1, S2-2, S2-3)**

---

#### TODO-S2-1: Build CHATMEMORY config

**File:** [`api/agent/s2/lab/ChatService.cfc`](AgentService.cfc#L14)
**Find:** [`// TODO-S2-1`](AgentService.cfc#L37)

**Code to write:**
```cfml
var memoryConfig = {
  TYPE:        cfg.chatMemory.type,
  MAXMESSAGES: cfg.chatMemory.maxMessages ?: 20,
  PERUSER:     cfg.chatMemory.perUser ?: true
};
if ( cfg.chatMemory.type
     == "tokenWindowChatMemory" ) {
  memoryConfig.MAXTOKENS =
    cfg.chatMemory.maxTokens;
  structDelete( memoryConfig, "MAXMESSAGES" );
}
if ( len( cfg.chatMemory.persistentStore
          ?: "" ) ) {
  memoryConfig.PERSISTENTSTORE =
    cfg.chatMemory.persistentStore;
}
```

---

#### TODO-S2-2: Build ChatModel

**File:** [`api/agent/s2/lab/ChatService.cfc`](AgentService.cfc#L39)
**Find:** [`// TODO-S2-2`](AgentService.cfc#L50)

**Code to write:**
```cfml
var modelArgs = {
  PROVIDER:    cfg.provider,
  APIKEY:      application.OPENAI_API_KEY,
  MODELNAME:   cfg.modelName,
  TEMPERATURE: cfg.temperature,
  TOPP:        cfg.topP,
  TOPK:        cfg.topK,
  MAXTOKENS:   cfg.maxTokens
};
if ( structKeyExists(cfg, "baseUrl")
     && len(trim(cfg.baseUrl)) ) {
  modelArgs.BASEURL = cfg.baseUrl;
}
var model = ChatModel( modelArgs );
```

---

#### TODO-S2-3: Wrap with agent + set system message ONCE

**File:** [`api/agent/s2/lab/ChatService.cfc`](AgentService.cfc#L52)
**Find:** [`// TODO-S2-3`](AgentService.cfc#L65)

**Code to write:**
```cfml
var sessionAgent = agent( {
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC,
  CHATMEMORY:       memoryConfig
} );
sessionAgent.systemMessage(
  cfg.systemPrompt, arguments.userId
);
```

**Checkpoint:** "Save the file. Open a new session in Lab mode. Send two messages: 'hi' then 'what did I just say?' If memory works, Mira references your previous message. Thumbs-up when you see multi-turn coherence."

---

**Phase 2: Memory-aware turn (TODOs S2-4 through S2-9)**

---

#### TODO-S2-4: Extract preferences

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc#L194)
**Find:** [`// TODO-S2-4`](ChatService.cfc#L121)

**Code to write:**
```cfml
var memory = new api.agent.s2.lab.Memory();
var lastAssistant =
  getLastAssistantText( request.sessionId );
var extracted = memory.extractPrefs(
  userText, local.model,
  request.userId, lastAssistant
);
```

---

#### TODO-S2-5: Persist and emit event

**Find:** [`// TODO-S2-5`](ChatService.cfc#L135)

**Code to write:**
```cfml
if ( !structIsEmpty( extracted ) ) {
  try { memory.savePrefs( request.userId, extracted ); } catch (any e) {}
  emitter.emit( "preference.persist", {
    "fields": structKeyArray( extracted ),
    "values": extracted,
    "userId": request.userId
  } );
}
```

---

#### TODO-S2-6: Load full preferences

**Find:** [`// TODO-S2-6`](ChatService.cfc#L150)

**Code to write:**
```cfml
var prefs = memory.loadPrefs( request.userId );
if ( structKeyExists(prefs, "_corrupt") ) {
  emitter.emit( "error", {
    "type":   "preferences.store-unreachable",
    "title":  "Preferences temporarily unavailable",
    "detail": "Couldn't load your preferences"
              & " — let's recapture your trip details.",
    "rule":   "store-unreachable"
  } );
  emitter.emit( "preferences.invalid",
    { "rule": "schema-mismatch" } );
  prefs = {};
}
```

---

#### TODO-S2-7: Whitelist preferences

**Find:** [`// TODO-S2-7`](ChatService.cfc#L164)

**Code to write:**
```cfml
var validator = new api.agent.s2.lab.PreferenceValidator( request.userId );
var schemaFields = validator.describeFields();
var cleanPrefs = {};
for ( var field in
      listToArray( schemaFields, "," ) ) {
  var key = trim( listFirst( field, " " ) );
  if ( structKeyExists( prefs, key ) )
    cleanPrefs[ key ] = prefs[ key ];
}
```

---

#### TODO-S2-8: Compose per-turn prompt

**Find:** [`// TODO-S2-8`](ChatService.cfc#L174)

**Code to write:**
```cfml
var fullPrompt =
  "Known preferences: "
  & serializeJSON( cleanPrefs )
  & chr(10) & chr(10)
  & "User: " & userText;
```

---

#### TODO-S2-9: Emit memory.read and invoke agent

**Find:** [`// TODO-S2-9`](ChatService.cfc#L184)

**Code to write:**
```cfml
emitter.emit( "memory.read",
  { "messages": "managed-by-agent" } );
bundle.agent.chat(
  fullPrompt, request.userId );
```

**Checkpoint:** "Save the file. Send 'I need outfits for a London trip, I wear size M and like navy'. Check trace panel for `preference.persist` event. Thumbs-up when you see fields extracted."

---

**Phase 3: Extraction prompt (TODOs S2-10, S2-11 in Memory.cfc)**

---

#### TODO-S2-10: Build the extraction prompt

**File:** [`api/agent/s2/lab/Memory.cfc`](Memory.cfc#L33)
**Find:** [`// TODO-S2-10`](Memory.cfc#L44)

**What to explain:** "This prompt is ~80 lines. It defines the schema, 8 numbered rules, and 7 worked examples. Rule 7 is critical — it enables bare-value binding when the assistant just asked about a field."

**Code to write:**
```cfml
var extractionPrompt =
  'You are a preference extraction engine.

Your task is to extract and update user '
& 'preferences from the latest user message.

Schema:
{
  "occasion": ["work","casual","wedding",'
& '"beach","gym","date","party"],
  "topSize": ["XS","S","M","L","XL","XXL"],
  "jeansSize": "2 digit number",
  "colors": ["color names"],
  "budget": "number"
}

Rules:
1. Extract only information explicitly stated '
& 'or strongly implied in the latest message.
2. Do not guess values.
3. Return only fields that can be inferred '
& 'from the message.
4. If no schema field is mentioned, return {}.
5. For colors, normalize to lowercase.
6. If the message contains an event or use-case'
& ' that maps to an occasion, map it:
  - office, meeting, interview -> work
  - vacation, sightseeing, london trip, '
& 'travel -> casual
  - wedding, marriage -> wedding
  - beach, resort -> beach
  - workout, running -> gym
  - date night -> date
  - clubbing, celebration -> party
7. CONTEXTUAL REPLY: When an "Assistant just '
& 'asked" line is shown below and the latest '
& 'user message is a bare value (just a number,'
& ' a single word, or a short phrase with no '
& 'field name), map that value to the field the'
& ' assistant just asked about.
8. Output valid JSON only.

Examples:

Message: "I need outfits for my London trip"
Output:
{
  "occasion": "casual"
}

Message: "My size is M"
Output:
{
  "topSize": "M"
}

Message: "I usually wear 32 jeans"
Output:
{
  "jeansSize": "32"
}

Message: "I like black and navy"
Output:
{
  "colors": ["black","navy"]
}

Message: "Budget is around 5000"
Output:
{
  "budget": 5000
}

Assistant just asked: "What is your budget?"
Message: "455"
Output:
{
  "budget": 455
}

Assistant just asked: "What size do you wear?"
Message: "M"
Output:
{
  "topSize": "M"
}'
& ( len( trim(arguments.assistantContext) )
    ? chr(10) & 'Assistant just asked: "'
      & trim(arguments.assistantContext) & '"'
    : "" )
& chr(10) & "User text: "
& arguments.userText;
```

---

#### TODO-S2-11: Call model and harvest response

**Find:** [`// TODO-S2-11`](Memory.cfc#L52)

**Code to write:**
```cfml
var response =
  arguments.model.chat( extractionPrompt );
var raw = response.message ?: "";
```

**Checkpoint:** "Save Memory.cfc. Send 'my budget is around 300'. Check trace panel for `preference.persist` with `budget: 300`. Close and reopen the browser — preferences should appear in the opening session response."

---

### [0:50–0:55] — Experiments

**Experiment:** Send "M" as a bare reply after Mira asks about size. Check trace panel — `topSize: "M"` should extract (Rule 7 contextual binding).

### [0:55–1:00] — Wrap-up

**Key takeaway:** ColdFusion 2025 provides built-in chat memory for multi-turn coherence. Durable preference extraction uses a separate LLM call with a schema-driven prompt — keeping the chat agent focused on conversation.

**Bridge to next session:** "Mira remembers you and knows your preferences. But when you ask 'show me sneakers' she invents product names. She has no access to our catalog. Session 3 gives her tools to search real products."

## Troubleshooting Guide

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Mira does not remember previous messages | TODO-S2-1 or S2-3 incomplete | Verify CHATMEMORY is in agent config |
| No `preference.persist` in trace | TODO-S2-4 or S2-5 incomplete | Verify Memory() instantiation and extractPrefs call |
| Preferences do not survive browser close | savePrefs failing silently | Check CF log for DB errors; verify demo-shopper-001 exists in users table |
| "Known preferences: {}" always empty | TODO-S2-7 whitelist not working | Verify PreferenceValidator path uses `s2.lab` not `s2.ref` |
| Model produces confused/hybrid outputs | systemMessage called per-turn | Ensure systemMessage is in AgentService ONLY (TODO-S2-3), not in sendMessage |
| REST endpoint returns 404 | REST services not registered | Re-run [setup.cfm](../../setup/setup.cfm) |
| "Datasource not found" error | Datasource not registered | Re-run [setup.cfm](../../setup/setup.cfm) |

## Behind-Attendee Protocol
- **Signal:** No `preference.persist` event after sending "I wear size M"
- **30-second intervention:** "Open Memory.cfc — do you have code in the TODO-S2-10 zone? Is ChatService TODO-S2-4 filled in?"
- **Rescue:** Copy TODO zones from ref/ChatService.cfc and ref/Memory.cfc
- **Last resort:** Toggle to ref mode

## Demo Failure Recovery
- If preference extraction returns empty: model may not parse the prompt correctly. Switch to ref mode for demo, investigate after session.
- If DB error on savePrefs: verify `demo-shopper-001` exists in users table (run `SELECT * FROM users WHERE user_id='demo-shopper-001'`)

## Questions They Will Ask (With Answers)

**Conceptual questions:**

| Question | Answer |
|----------|--------|
| Why call systemMessage() only once? | CF's agent stores system messages in its memory window. Calling it per-turn appends duplicates, filling the context window with N copies of the same prompt — the model gets confused and produces hybrid outputs. |
| Why is preference extraction a separate LLM call? | The chat agent's job is conversation. Extraction needs a focused, schema-aware prompt with worked examples. Mixing them into one call degrades both tasks. Separate concerns = better results. |
| How does the "bare value binding" work? | If the assistant just asked "What is your top size?" and the user replies "M", the extraction prompt sees both the assistant's question and the user's reply. Rule 7 binds "M" to the `topSize` field contextually. |

**Technical questions:**

| Question | Answer |
|----------|--------|
| What if the extraction returns invalid JSON? | Memory.extractPrefs wraps the parse in try/catch. If the model returns non-JSON, the result is an empty struct `{}` — no preferences are saved that turn, but the conversation continues normally. |
| Where are preferences stored? | In the `user_preferences` table (durable, survives browser close). Chat memory (multi-turn context) is in CF's built-in memory provider (session-scoped). Two different stores for two different purposes. |
| Can the model overwrite existing preferences? | Yes — by design. If a user says "actually I prefer size L now," the extraction picks up `topSize: "L"` and savePrefs overwrites the previous value. Preferences evolve. |
| Why does Memory.cfc use model.chat() instead of a tool? | Tools are called BY the model during conversation. Extraction runs BEFORE the conversation turn — it is preprocessing. The model does not know extraction happened; it just sees "Known preferences: {...}" in its prompt. |

**Debugging questions:**

| Question | Answer |
|----------|--------|
| Why does my model produce repeated/confused text? | You are likely calling `systemMessage()` per turn instead of once. Check that the call is in `getOrCreateAgent` (inside the lock block), not in `sendMessage`. |
| Preferences show in trace but not in next turn's prompt | Check TODO-S2-6 (loadPrefs) and TODO-S2-7 (whitelist). The loaded prefs must pass through the validator before injection. |

**Production questions:**

| Question | Answer |
|----------|--------|
| How would you handle preference conflicts? | The workshop uses last-write-wins. In production, you might version preferences, show a confirmation UI, or ask the user to disambiguate. |
| Is one LLM call per turn for extraction expensive? | At ~100 tokens input, it costs fractions of a cent with GPT-4o-mini. The latency (~200ms) is hidden behind the chat response. In high-volume production, you could batch or use a smaller model for extraction. |

## Verification Checklist

1. Lab mode: Send "I need outfits for a London trip, I wear size M and like navy"
2. **Expected trace:** `preference.persist` event with fields: occasion, topSize, colors
3. Send: "what size did I say?"
4. **Expected response:** Mira says "M" (multi-turn memory works)
5. Reload the page, open new session. Check "savedPrefs" in session response includes previous values.
