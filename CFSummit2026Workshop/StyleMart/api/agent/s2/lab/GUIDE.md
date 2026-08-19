# Session 2: Memory & Preferences

## What You'll Build

After this session, Mira remembers your conversation history (multi-turn coherence) and extracts durable preferences from natural language — your size, color preferences, occasion, and budget. These preferences persist across browser sessions and personalize every future response.

## Story So Far
Mira streams real-time responses and has a configurable persona (S1). But she forgets everything between messages.

## Key Concepts (Read While Instructor Presents)

- **Chat memory (messageWindowChatMemory):** Keeps the last N messages in a sliding window. The agent manages insertion automatically — you do not push messages manually.
- **systemMessage():** Sets the system prompt in the agent's memory. Call it ONCE at agent creation. Calling it per-turn stacks duplicate copies.
- **Preference extraction:** A separate LLM call (not the chat agent) that reads the user's message, identifies preference fields (occasion, topSize, jeansSize, colors, budget), and returns a JSON struct.
- **Bare-value binding (Rule 7):** When Mira asks "What size?" and the user replies just "M", the extraction uses the assistant's last question to bind the value to the correct field.
- **PreferenceValidator:** Whitelists which keys from the loaded preferences get injected into the prompt (strips internal envelope keys like userId, updatedAt).

## Your Workspace

**Files you will edit:**
- [`StyleMart/api/agent/s2/lab/AgentService.cfc`](AgentService.cfc) — 3 TODOs (memory + model + agent)
- [`StyleMart/api/agent/s2/lab/ChatService.cfc`](ChatService.cfc) — 6 TODOs (preference extraction + prompt)
- [`StyleMart/api/agent/s2/lab/Memory.cfc`](Memory.cfc) — 2 TODOs

**Read-only reference:**
- [`StyleMart/api/agent/s2/ref/ChatService.cfc`](../ref/ChatService.cfc)
- [`StyleMart/api/agent/s2/ref/Memory.cfc`](../ref/Memory.cfc)
- [`StyleMart/api/agent/s2/config/ai.properties`](../config/ai.properties)
- [`StyleMart/api/agent/s2/config/system-prompt.txt`](../config/system-prompt.txt)

## The "Lab Fails, Ref Works" Beat

Before you write code:
1. Toggle to **Lab** mode. Send "I wear size M" then "what size did I say?" — no memory, or empty response.
2. Toggle to **Ref** mode. Same messages — Mira remembers "M" and preferences persist.
3. **Your job:** Make Lab work like Ref by filling 11 TODOs across 2 files.

## Warm Up: Scratchpad (5 minutes)

Open [`scratchpad.cfm`](scratchpad.cfm) in your browser. No UI — just `writeOutput()` results.

```
http://localhost:8500/CFSummit2026Workshop/StyleMart/api/agent/s2/lab/scratchpad.cfm
```

**What to observe:**

**Part 1 — Shared Chat Memory:**
- Turn 1: "My name is Alice and I love ColdFusion." — agent acknowledges.
- Turn 2: "What is my name and what do I love?" — agent recalls both (memory works).
- Turn 3: "Suggest a project idea based on what I love." — agent references earlier context.

This is `CHATMEMORY: { MAXMESSAGES: 10 }` — the agent keeps 10 messages in a sliding window.

**Part 2 — Per-User Isolation:**
- Alice says her color is blue. Bob says his city is Paris.
- Alice asks "What is my favorite color?" → gets "blue" (not Paris).
- Bob asks "What is my favorite city?" → gets "Paris" (not blue).

This is `PERUSER: true` + the second argument to `.chat(prompt, userId)`.

**Try these experiments yourself (edit scratchpad.cfm):**

| Experiment | What to change | What you'll see |
|-----------|---------------|-----------------|
| Kill memory | Comment out `CHATMEMORY: { MAXMESSAGES: 10 }` (remove it from the agent config) | Turn 2 fails — agent can't recall Alice's name. Proves memory is the difference. |
| Shrink window | Change `MAXMESSAGES: 10` → `MAXMESSAGES: 1` | Turn 3 forgets Turn 1 (only last message kept). |
| Remove PERUSER | Set `PERUSER: false` or remove it | Alice sees Bob's data — no isolation. |
| Add system prompt | Add `chatAgent.systemMessage("You are a pirate. Respond in pirate speak.")` after agent creation | All responses in pirate voice — system prompt shapes personality. |
| Temperature 0 | Change `TEMPERATURE: 0.7` → `TEMPERATURE: 0.0` | Run twice — identical output. Deterministic. |

The memory and per-user isolation patterns in this scratchpad are the SAME patterns your TODOs will wire into the chat assistant — `AgentService.cfc` builds this exact config, `ChatService.cfc` calls `.chat(prompt, userId)` with the real user ID.

## Catching Up

If you are starting fresh:
1. Toggle to Ref mode — verify multi-turn memory works
2. Copy `s1/ref/ChatService.cfc` → `s1/lab/ChatService.cfc` to have S1 complete

## Step-by-Step Instructions

### Step 1: Build the CHATMEMORY config

**File:** [`api/agent/s2/lab/AgentService.cfc`](AgentService.cfc)
**Find:** [`// TODO-S2-1`](AgentService.cfc) — `var memoryConfig = "" /* TODO-S2-1 */;`

**What this does:** Tells the agent to keep a sliding window of messages for multi-turn coherence.

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

**Save the file.**

---

### Step 2: Build the ChatModel

**File:** [`api/agent/s2/lab/AgentService.cfc`](AgentService.cfc)
**Find:** [`// TODO-S2-2`](AgentService.cfc) — `var model = "" /* TODO-S2-2 */;`

**What this does:** Creates the LLM connection (same pattern as S1).

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

**Save the file.**

---

### Step 3: Create the agent with memory and set system prompt

**File:** [`api/agent/s2/lab/AgentService.cfc`](AgentService.cfc)
**Find:** [`// TODO-S2-3`](AgentService.cfc) — `var sessionAgent = "" /* TODO-S2-3 */;`

**What this does:** Wraps the model with streaming + chat memory, then sets the system prompt ONCE.

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

**Save the file. Verify:** Send "hi" then "what did I just say?" Mira should reference your previous message (multi-turn memory works).

---

### Step 4: Extract preferences from user text

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc)
**Find:** [`// TODO-S2-4`](ChatService.cfc) — `var extracted = {} /* TODO-S2-4 */;`

**What this does:** Calls a separate LLM to find preference data (size, colors, occasion, budget) in the user's message.

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

**Save the file.**

---

### Step 5: Persist extracted preferences

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc)
**Find:** [`// TODO-S2-5`](ChatService.cfc)

**What this does:** Saves new preference fields to the database and emits a trace event so you can see what was extracted.

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

**Save the file.**

---

### Step 6: Load full preferences with error handling

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc)
**Find:** [`// TODO-S2-6`](ChatService.cfc) — `var prefs = {} /* TODO-S2-6 */;`

**What this does:** Loads all saved preferences. If the stored JSON is corrupt, emits an error event and falls back to empty.

**Code to write:**
```cfml
var prefs = memory.loadPrefs( request.userId );
if ( structKeyExists(prefs, "_corrupt") ) {
  emitter.emit( "error", {
    "type":  "preferences.store-unreachable",
    "title": "Preferences temporarily unavailable",
    "detail": "Couldn't load your preferences"
      & " — let's recapture your trip details.",
    "rule":  "store-unreachable"
  } );
  emitter.emit( "preferences.invalid",
    { "rule": "schema-mismatch" } );
  prefs = {};
}
```

**Save the file.**

---

### Step 7: Whitelist preference keys

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc)
**Find:** [`// TODO-S2-7`](ChatService.cfc) — `var cleanPrefs = {} /* TODO-S2-7 */;`

**What this does:** Strips internal keys (userId, updatedAt) and keeps only schema-defined preference fields before injecting into the prompt.

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

**Save the file.**

---

### Step 8: Compose the per-turn prompt

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc)
**Find:** [`// TODO-S2-8`](ChatService.cfc) — `var fullPrompt = "" /* TODO-S2-8 */;`

**What this does:** Combines known preferences and user text into the prompt the agent sees.

**Code to write:**
```cfml
var fullPrompt =
  "Known preferences: "
  & serializeJSON( cleanPrefs )
  & chr(10) & chr(10)
  & "User: " & userText;
```

**Save the file.**

---

### Step 9: Emit memory event and invoke agent

**File:** [`api/agent/s2/lab/ChatService.cfc`](ChatService.cfc)
**Find:** [`// TODO-S2-9`](ChatService.cfc)

**What this does:** Sends the prompt to the LLM with per-user memory isolation.

**Code to write:**
```cfml
emitter.emit( "memory.read",
  { "messages": "managed-by-agent" } );
bundle.agent.chat(
  fullPrompt, request.userId );
```

**Save the file. Verify:** Send "I like navy and black, size M". In the trace panel, you should see `preference.persist` with colors and topSize fields.

---

### Step 10: Build the extraction prompt (Memory.cfc)

**File:** [`api/agent/s2/lab/Memory.cfc`](Memory.cfc)
**Find:** [`// TODO-S2-10`](Memory.cfc) — `var extractionPrompt = "" /* TODO-S2-10 */;`

**What this does:** The extraction prompt tells a separate LLM call exactly how to identify and extract preferences. It includes the schema, 8 numbered rules, and 7 worked examples.

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

**Save the file.**

---

### Step 11: Call model and get response

**File:** [`api/agent/s2/lab/Memory.cfc`](Memory.cfc)
**Find:** [`// TODO-S2-11`](Memory.cfc) — `var raw = "" /* TODO-S2-11 */;`

**What this does:** Invokes the LLM with the extraction prompt and captures the JSON response.

**Code to write:**
```cfml
var response =
  arguments.model.chat( extractionPrompt );
var raw = response.message ?: "";
```

**Save the file. Verify:** Send "my budget is 300". In the trace panel, you should see `preference.persist` with `budget: 300`.

---

## Try It Out

| What to type in chat | What you should see | Why it works |
|---------------------|--------------------|--------------| 
| "I need outfits for a London trip" | Mira acknowledges the trip context | Extraction maps "London trip" → occasion: "casual" |
| "I wear size M and like navy and black" | `preference.persist` in trace with topSize, colors | Multiple fields extracted in one message |
| "what size did I say?" | "M" — Mira remembers | Chat memory keeps 20 messages in context |
| (close browser, reopen, new session) | savedPrefs shows occasion, topSize, colors | Preferences stored in DB, survive sessions |

## Experiments (Core Learning Activity)

### E1 — Multi-Turn Coherence
Send 3 messages in sequence: "hi", "I need outfits for a London trip", "what did I just tell you?" Mira should reference the London trip. This proves the 20-message window works.

### E2 — Bare Value Binding (Rule 7)
Wait for Mira to ask "What size do you usually wear?" then reply just "M". Check trace — `preference.persist` should show `topSize: "M"`. The extraction prompt uses assistant context to bind bare values.

### E3 — Temperature Effect on Extraction
Change `temperature` in `ai.properties` to `0.0`. Send "I like navy and black, budget around 300". Check trace — extraction should be perfectly reliable. Change to `1.3` — extraction may hallucinate extra fields or miss values. Lesson: extraction calls benefit from low temperature.
**Restore:** Temperature back to `0.5`

### E4 — Memory Window Behavior
Change `maxMessages` in `ai.properties` from `20` to `2`. Have a 4-message conversation. Notice Mira forgets messages 1-2 by message 4 (only last 2 in context). Lesson: window size trades cost against coherence.
**Restore:** maxMessages back to `20`

### E5 — Persistence Verification
Send "my budget is 500". Close the browser entirely. Reopen. Start a new session. Check the session response `savedPrefs` — budget=500 should persist (stored in DB, not session memory).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Mira does not remember previous messages | Check TODO-S2-1 (memoryConfig) and TODO-S2-3 (CHATMEMORY in agent config) |
| No preference.persist event in trace | Check TODO-S2-4 (Memory instantiation) and TODO-S2-10 (extraction prompt) |
| Model produces repeated/confused text | systemMessage() called per-turn. Ensure it is only in AgentService. |
| "Known preferences: {}" always | Check TODO-S2-6 and S2-7 — loadPrefs and whitelist must both work |
| Database error in server log | Verify demo-shopper-001 exists in users table |

## Frequently Asked Questions

| Question | Answer |
|----------|--------|
| Why call systemMessage() only once? | It appends to memory. Per-turn calls stack N copies, filling the context window and confusing the model. |
| Why is extraction a separate LLM call? | The chat agent focuses on conversation. Extraction needs a specialized schema-aware prompt. Mixing them degrades both. |
| Can the model overwrite my preferences? | Yes, by design. "Actually I prefer L now" overwrites topSize. Preferences evolve with the user. |
| What if extraction returns bad JSON? | The code catches parse errors and returns empty `{}`. No preferences saved that turn; conversation continues normally. |
| Where are preferences stored? | In the `user_preferences` database table. Chat memory is session-scoped (in CF's memory provider). Two different stores. |

## What's Next

Mira remembers you and knows your preferences. But ask "show me sneakers" — she invents product names. She cannot access our real catalog. Session 3 gives her tools to search products, manage your cart, and look up orders.
