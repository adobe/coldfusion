# Session 1: Hello, ChatModel

## What You'll Build

After this session, Mira (your AI shopping assistant) streams real-time responses to the chat panel. You connect ColdFusion 2025 to an LLM provider, configure the model's personality and behavior via config files, and explore how temperature, token limits, and system prompt rules control output.

## Key Concepts (Read While Instructor Presents)

- **ChatModel()**: A native ColdFusion 2025 function that creates a connection to an LLM provider (OpenAI, Anthropic, Gemini, Ollama). Takes a struct with PROVIDER, APIKEY, MODELNAME, TEMPERATURE, and other sampling parameters.
- **agent()**: Wraps a ChatModel with orchestration features — streaming callbacks, memory, tools. You always need a ChatModel inside an agent.
- **Server-Sent Events (SSE)**: A standard HTTP mechanism where the server pushes data to the browser over a single connection. No WebSockets required.
- **System prompt as control surface**: The system prompt has named rules (persona, format, behavior, honesty, fallback). Each can be individually removed to observe behavioral changes.
- **Config hot-reload**: Edit `ai.properties`, save, send next message — changes take effect immediately (no restart needed).

## Your Workspace

**Files you will edit:**
- [`StyleMart/api/agent/s1/lab/AgentService.cfc`](AgentService.cfc#L1) — 1 TODO (model + agent creation)
- [`StyleMart/api/agent/s1/lab/ChatService.cfc`](ChatService.cfc#L1) — 3 TODOs (compose prompt, invoke streaming, invoke sync)

**Scaffold (pre-built, do not edit):**
- [`StyleMart/api/agent/s1/lab/Streamer.cfc`](Streamer.cfc#L1) — handles SSE streaming bridge automatically

**Read-only reference:**
- [`StyleMart/api/agent/s1/ref/ChatService.cfc`](../ref/ChatService.cfc#L1) — complete working version
- [`StyleMart/api/agent/s1/config/system-prompt.txt`](../config/system-prompt.txt#L1) — default Mira persona

**Persona variants (for experiments):**
- [`system-prompt-luxury.txt`](../config/system-prompt-luxury.txt#L1) — luxury concierge voice
- [`system-prompt-90s.txt`](../config/system-prompt-90s.txt#L1) — 90s skater character (Reggie)
- [`system-prompt-no-f4.txt`](../config/system-prompt-no-f4.txt#L1) — removes honesty rules (for hallucination demo)

## The "Lab Fails, Ref Works" Beat

Before you write any code:
1. Toggle to **Lab** mode. Send "Hi Mira!" — nothing happens (empty/timeout). This is correct.
2. Toggle to **Ref** mode. Send "Hi Mira!" — tokens stream instantly.
3. **Your job:** Make Lab work like Ref by filling 3 TODOs.

## Warm Up: Scratchpad (5 minutes)

Open [`scratchpad.cfm`](scratchpad.cfm) in your browser. It uses only `writeDump()` — no UI.

```
http://localhost:8500/CFSummit2026Workshop/StyleMart/api/agent/s1/lab/scratchpad.cfm
```

Add `?exp=1` through `?exp=5` to run experiments. Add `?msg=your text` to change the input.

1. **Your First AI Call** — send a prompt, get a response. Change `?msg=` to ask anything.
2. **Two Temperatures** — same prompt at 0.2 vs 1.5. See how creativity changes.
3. **Persona Swap** — same prompt through Mira vs luxury concierge. Brand voice = one string.
4. **AgentService** — the same service your TODOs will wire into ChatService.cfc.

Notice: no REST routing, no SSE, no streaming — just raw `ChatModel()` and `agent()`. The TODOs you fill next wire these same calls into the full application.

## Catching Up

If you need Lab working immediately: copy [`s1/ref/AgentService.cfc`](../ref/AgentService.cfc#L1) into `s1/lab/AgentService.cfc` and [`s1/ref/ChatService.cfc`](../ref/ChatService.cfc#L1) into `s1/lab/ChatService.cfc`.

## Step-by-Step Instructions

### Step 1: Create the ChatModel and agent

**File:** [`api/agent/s1/lab/AgentService.cfc`](AgentService.cfc#L36)
**Find:** `var agentConfig = {}` inside the `TODO-S1-1` block (line 36–54)

**What this does:** Creates a ChatModel connected to OpenAI and wraps it in an agent with streaming. The struct keys must be UPPERCASE.

**Code to write:**
```cfml
var agentConfig = {
  CHATMODEL: ChatModel({
    PROVIDER:    cfg.provider,
    MODELNAME:   cfg.modelName,
    APIKEY:      application.OPENAI_API_KEY,
    TEMPERATURE: cfg.temperature,
    TOPP:        cfg.topP,
    TOPK:        cfg.topK,
    MAXTOKENS:   cfg.maxTokens
  })
};
```

> **About caching:** Above your TODO zone, `getOrCreateAgent` builds a `cacheKey` from a hash of every parameter that affects behavior (sessionId + streaming + provider + modelName + temperature + topP + topK + maxTokens) and stores agents in `application.s1Agents`. If you change anything in `ai.properties`, the fingerprint changes — the old entry is evicted and a fresh agent is built on the next call. The streaming handler attachment + final `agent(agentConfig)` are wired in below the TODO zone.

Compare with: [`ref/AgentService.cfc:36-50`](../ref/AgentService.cfc#L36)

**Save the file.**

---

### Step 2: Apply the system prompt

**File:** [`api/agent/s1/lab/ChatService.cfc`](ChatService.cfc#L46)
**Find:** the `TODO-S1-2` block inside the `try` (line 46–60)

**What this does:** Loads `ai.properties` fresh and pushes the system prompt onto the agent via `systemMessage()`. S1 has no chat memory, so calling it per turn is harmless — it just sets the persona for this call. (Session 2 introduces memory; you'll move this call to agent-creation time then.)

**Code to write:**
```cfml
var cfg = new AgentService().loadConfig();
sessionAgent.systemMessage( cfg.systemPrompt );
```

Compare with: [`ref/ChatService.cfc:24-25`](../ref/ChatService.cfc#L24)

**Save the file.**

---

### Step 3: Invoke the agent — streaming branch (TODO-S1-3)

**File:** [`api/agent/s1/lab/ChatService.cfc`](ChatService.cfc#L62)

Just above your TODO zone, `sendMessage` has a single hardcoded line:

```cfml
var streaming = true;
```

That flag drives a branch below your TODO zone. The streaming branch needs ONE call.

**What this does:** `sessionAgent.chat(userText)` returns IMMEDIATELY in streaming mode — tokens arrive asynchronously via `Streamer` callbacks, which enqueue them onto `server.stylemart.streams`. `bridge.poll()` (already wired in below) drains that queue out to the SSE response. The system prompt was already attached in Step 2, so we only pass the user message here.

**Code to write** (inside the `if ( streaming )` block, between `bridge.activate(...)` and `bridge.poll(...)`):
```cfml
sessionAgent.chat( userText );
```

---

### Step 4: Invoke the agent — synchronous branch (TODO-S1-4)

**File:** [`api/agent/s1/lab/ChatService.cfc`](ChatService.cfc#L71)

The `else` branch is the fully synchronous fallback. `chat()` here BLOCKS until the model finishes and returns the full response struct in one go — no callbacks, no queue. The wiring below your line emits the whole reply as a single `model.delta` and closes out with `done`.

**Code to write** (the first line inside the `else` block, before `emitter.emit(...)`):
```cfml
var resp = sessionAgent.chat( userText );
```

> Both branches end up emitting `model.delta` events the trace panel renders the same way — streaming sends many small ones, sync sends one big one. The `streaming` value is also passed to `getOrCreateAgent(sessionId, streaming)`, so the cache differentiates streaming vs sync agents (different `STREAMINGHANDLER` wiring).
>
> **Try it after both TODOs are filled:** flip `var streaming = true;` to `false`, save, re-send a message. Streaming gives many `model.delta` events that visually grow word-by-word; sync gives a single `model.delta` containing the whole reply at once. Flip it back to `true` when you're done.

**Save the file. Verify:** Toggle to Lab mode. Send "Hi Mira!" You should see tokens streaming word-by-word. In the trace panel: `model.start` → multiple `model.delta` → `done`.

---

## Baseline Transcript (Proof It Works)

Once your 4 TODOs are filled, verify with these 4 exchanges:

| You send | Mira responds (paraphrased) | What it proves |
|----------|---------------------------|----------------|
| "Hi Mira!" | "Hey! I'm Mira, your StyleMart stylist. How can I help?" | F1 persona rule works |
| "Suggest a winter outfit for a casual weekend" | Generic outfit suggestion (no specific products) | F3 behavior — recommends only when asked |
| "What's the fabric composition of the navy travel blazer?" | "I don't have that information right now" | F4 honesty rule — refuses to invent |
| "What did I just say?" | Confused/generic response (no memory) | S1 is stateless — motivation for S2 |

The last exchange reveals S1's limitation: no memory between turns. Session 2 fixes this.

---

## Experiments (Core Learning Activity)

These experiments teach cause-and-effect between configuration and model behavior. They are NOT optional.

### Understanding the System Prompt

The default [`system-prompt.txt`](../config/system-prompt.txt#L1) has 5 rules:
- **F1 (persona):** "You are Mira, the StyleMart shopping assistant"
- **F2 (format):** "Be friendly and short — three sentences max"
- **F3 (behavior):** "Recommend products only when the shopper asks"
- **F4 (honesty):** "Never invent prices, stock numbers, or product names" *(some variants omit this)*
- **F5 (fallback):** "If you do not know, say you do not know"

Each rule can be removed individually by switching to a different prompt file.

---

### E1 — Temperature Too Low (Deterministic)

**Edit:** [`ai.properties`](../config/ai.properties#L10) → change `"temperature"` to `0.0`
**Send:** "Suggest a winter outfit for a casual weekend" — send it THREE times
**Observe:** Identical (or nearly identical) responses each time
**Lesson:** `temperature=0` is nearly deterministic. Useful for testing and audits. Deadly for user engagement.
**Restore:** Change temperature back to `0.7`

---

### E2 — Temperature Too High (Off-Brand)

**Edit:** [`ai.properties`](../config/ai.properties#L10) → change `"temperature"` to `1.5`
**Send:** "Suggest a winter outfit for a casual weekend"
**Observe:** Florid, emoji-heavy, or off-brand response. May include hallucinated product names.
**Lesson:** `temperature=1.5` on most models produces off-brand outputs. Brand voice locks live in the 0.2–0.5 range.
**Restore:** Change temperature back to `0.7`

---

### E3 — maxTokens Too Tight (Truncation)

**Edit:** [`ai.properties`](../config/ai.properties#L13) → change `"maxTokens"` to `30`
**Send:** "Suggest a winter outfit for a casual weekend"
**Observe:** Response cuts off mid-sentence
**Lesson:** Always test minimum maxTokens against your longest expected response. Truncated responses destroy user trust.
**Restore:** Change maxTokens back to `800`

---

### E4 — The Hallucination Demo (MOST IMPORTANT)

This experiment sets up the entire motivation for Session 6 (Guardrails).

**Setup:** Set `"temperature"` to `0.0` in [`ai.properties`](../config/ai.properties#L10) (deterministic, removes randomness as a variable)

**Run 1 (control — honesty rule active):**
- Verify `"systemPromptFile"` in [`ai.properties`](../config/ai.properties#L16) points to `system-prompt.txt` (the default, which has F4)
- Send: "What's the fabric composition of the navy travel blazer, and can it be machine-washed?"
- **Expected:** Mira refuses — "I don't have that specific information"

**Run 2 (experiment — honesty rule removed):**
- Edit [`ai.properties`](../config/ai.properties#L16): change `"systemPromptFile"` to `"/api/agent/s1/config/system-prompt-no-f4.txt"`
- Send the SAME message
- **Expected:** Mira confidently invents details — "80% merino wool, 20% polyamide, machine-washable on cold"

**Lesson:** System prompt rules are polite requests, not enforcement. The model TRIES to comply but can be tricked or misconfigured. Session 6 Guardrails are the only reliable mechanism.

**Important:** Change the `systemPromptFile` PATH in ai.properties — do NOT hand-edit system-prompt.txt directly.

**Restore:** Change `"systemPromptFile"` back to `"/api/agent/s1/config/system-prompt.txt"`

---

### E5 — Provider Swap (Watch Instructor)

The instructor demonstrates on the projector:
- Same prompt, different provider (shows that only `provider` + `modelName` + `apiKey` change)
- Code is identical — provider portability is one struct edit

You watch this demo. No action needed on your machine.

---

### E6 — Combo (Multiple Knobs at Once)

**Edit:** [`ai.properties`](../config/ai.properties#L1):
- `"temperature"` → `1.2` (line 10)
- `"maxTokens"` → `60` (line 13)
- `"systemPromptFile"` → `"/api/agent/s1/config/system-prompt-luxury.txt"` (line 16)

**Send:** "Suggest a winter outfit for a casual weekend"
**Observe:** Luxury concierge persona responds — but response truncates mid-sentence
**Lesson:** Multiple constraints compound. Token budgets must account for the persona's verbosity style.

**Restore:** Revert all three changes back to defaults (`0.7`, `800`, `system-prompt.txt`)

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| No events in trace panel after saving | Check you edited [`s1/lab/ChatService.cfc`](ChatService.cfc#L1) (not ref/). Compare character-by-character. |
| Chat spinner never stops | The Streamer is pre-built and should work. Check that [TODO-S1-1](AgentService.cfc#L36) (agent creation) is correct. |
| "Variable MODEL is undefined" | [Step 1](AgentService.cfc#L36) incomplete or has a syntax error. Verify the entire modelArgs block. |
| "Incorrect syntax: struct of attributes" | The `agent()` call is inside another struct. Make sure [Step 1](AgentService.cfc#L36) is standalone. |
| Config change has no effect | Did you save [`ai.properties`](../config/ai.properties#L1)? Config is read fresh per session — no restart needed. |
| E4: Model still refuses after removing F4 | Verify you changed the `systemPromptFile` path. Check that [`system-prompt-no-f4.txt`](../config/system-prompt-no-f4.txt#L1) exists. |

## Frequently Asked Questions

| Question | Answer |
|----------|--------|
| Why do I only edit one file? | The Streamer (SSE plumbing) is pre-built scaffold. This workshop focuses on AI agent development, not HTTP streaming infrastructure. |
| Why does config hot-reload work? | `loadConfig()` reads ai.properties on every call. The cache key is a hash of every behavior-affecting param, so changing one in ai.properties produces a new fingerprint — the old cached agent is evicted and a fresh one is built on the next message. No session reset needed. |
| What does temperature actually do? | Controls randomness. 0.0 = deterministic. 0.3-0.5 = reliable but varied (production sweet spot). 1.0+ = creative/unpredictable. |
| What is the difference between ChatModel() and agent()? | `ChatModel()` creates the LLM connection. `agent()` wraps it with orchestration (streaming, memory, tools). You always need a ChatModel inside an agent. |
| Why does the model invent facts in E4? | Without F4 (the honesty rule), the model has no instruction to refuse. It generates plausible-sounding text from training data. This is hallucination. |
| Can I use Claude or Gemini? | Yes. Change `provider` and `modelName` in [`ai.properties`](../config/ai.properties#L1). No code change needed. |

## What's Next

Mira responds — but she forgot what you said 10 seconds ago. Send "I wear size M" then "what size did I say?" She does not know. Session 2 gives her memory and durable preference extraction.
