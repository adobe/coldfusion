# Session 1: Hello, ChatModel — Instructor Guide

## Overview
- **Duration:** 60 minutes
- **Learning objectives:**
  - Stream real LLM tokens to the browser via Server-Sent Events (SSE), with a synchronous fallback selectable by flipping `var streaming = true` to `false` in `ChatService.cfc`
  - Configure an AI provider (model, temperature, persona) through JSON
  - Understand the system prompt as a decomposed control surface (F1-F5 rules)
  - Observe cause-and-effect between config changes and model behavior
- **Prerequisites:** Environment validated (S0 checklist complete)
- **Wow moment:** The hallucination demo (E4) — removing one system prompt rule makes the model confidently invent "facts." This sets up the entire S6 guardrails motivation.
- **Attendee-edited files:** `s1/lab/AgentService.cfc` (1 TODO — model + agent struct) and `s1/lab/ChatService.cfc` (3 TODOs — compose prompt, invoke streaming, invoke sync)
- **Scaffold (pre-built):** Streamer.cfc handles SSE plumbing — attendees do NOT touch it

## Pre-Session Checklist
- Run `http://localhost:8500/CFSummit2026Workshop/StyleMart/setup/setup.cfm` — all 5 lines show `[ok]`
- Verify `http://localhost:8500/CFSummit2026Workshop/StyleMart/` loads
- Toggle to Ref → send "hi" → streaming response
- Toggle to Lab → send "hi" → empty/timeout (confirms TODOs are unfilled)
- Verify `system-prompt-no-f4.txt` exists in s1/config/ (needed for E4)
- Check CF admin: AI module enabled, API key valid

## Teaching Flow (Timeline)

### [0:00–0:10] — Concept Introduction

**Key points:**
- SSE is plain HTTP with `Content-Type: text/event-stream` — not WebSockets
- ColdFusion 2025 introduces three native AI primitives: `ChatModel()`, `agent()`, streaming handlers
- The Streamer CFC is pre-built scaffold — attendees focus exclusively on AI API code
- The system prompt is a control surface with named rules (F1-F5)
- Config is hot-reloaded per request: edit JSON → save → send message → see change

**System prompt decomposition (write on board):**
- F1 (persona): "You are Mira, the StyleMart shopping assistant"
- F2 (format): "Be friendly and short — three sentences max"
- F3 (behavior): "Recommend products only when asked"
- F4 (honesty): "Never invent prices, stock numbers, or product names"
- F5 (fallback): "If you do not know, say you do not know"

**The "Lab fails, Ref works" beat:**
"Toggle to Lab. Send 'Hi Mira!' — nothing happens. Now toggle to Ref, same message — tokens stream instantly. Your job is to make Lab work like Ref. Three lines of code."

**Common misconceptions to address:**
- "SSE requires WebSockets" — No. SSE is unidirectional server→client over plain HTTP.
- "The Streamer needs custom code" — No. It is scaffold. You only write AI-facing code.
- "System prompt rules are enforced" — No. They are polite requests. E4 will prove this.

### [0:10–0:15] — Scratchpad Exploration

**Instructor says:** "Before we write code, let's see the raw API. Open scratchpad.cfm in your browser — the link is in your guide. Add `?exp=1` to start."

**Note:** Output is raw `writeDump()` — attendees see the full response struct including metadata and token counts. No styled HTML.

**Guide attendees through (on projector):**
1. **Experiment 1** — "Type your own prompt in the URL. Hit enter. You just made your first AI call in ColdFusion 2025. That's the entire API — one function, one line."
2. **Experiment 2** — "Same question, two temperatures. Left side is corporate-safe. Right side is creative chaos. Temperature controls this."
3. **Experiment 5** — "Watch this. With safety rules, Mira refuses to invent. Without them..." [wait for gasps] "...she confidently makes up fabric compositions. Remember this — we'll fix it properly in Session 6."

**Teaching beat:** "Everything in the scratchpad — ChatModel, prompt, response — is what your TODOs will wire into the streaming app. The scratchpad uses 3 lines. The real app adds streaming, tracing, and error handling. But the AI call is identical."

**Transition:** "Now open ChatService.cfc. Three TODOs. Let's go."

### [0:15–0:30] — Hands-On Coding (3 TODOs)

All code goes in `s1/lab/AgentService.cfc` and `s1/lab/ChatService.cfc`. Instructor-led: type on screen, attendees copy.

---

#### TODO-S1-1: Build ChatModel + agent from config

**What to say:** "ChatModel() is a native CF2025 function. It takes uppercase keys. The `cfg` variable comes from `loadConfig()` which reads ai.properties on every call. Above the TODO zone we build a fingerprint by hashing every behavior-affecting param — sessionId, streaming, provider, modelName, temperature, topP, topK, maxTokens. Change any one in ai.properties and the fingerprint changes; the old cached agent is evicted, and a fresh agent is built. So config edits take effect on the very next message — no session reset."

**Code:**
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

**Watch for:** Lowercase keys (must be UPPERCASE). The `cfg` variable is loaded above the TODO zone by `loadConfig()`. The fingerprint cache check, the stale-entry eviction, the streaming-handler attachment, and the final `application.s1Agents[cacheKey] = agent(agentConfig);` are all wired in around the TODO zone — attendees do NOT write those.

---

#### TODO-S1-2: Apply the system prompt

**Code for TODO-S1-2:**
```cfml
var cfg = new AgentService().loadConfig();
sessionAgent.systemMessage( cfg.systemPrompt );
```

**What to say:** "loadConfig() reads ai.properties fresh each turn, and `systemMessage()` pushes the persona onto the agent. S1 has no memory yet, so calling this per turn is harmless — it just sets the persona for this call. Session 2 introduces memory, and at that point we move this call to agent-creation time so we don't stack duplicate system messages in the memory window. For now: edit `systemPromptFile` in ai.properties → save → next message uses the new persona."

#### TODO-S1-3 + TODO-S1-4: Invoke the agent (streaming + sync branches)

Just above the TODO zone there's a single hardcoded line that picks the transport:

```cfml
var streaming = true;
```

Below the TODO zone, that flag drives an `if/else` branch. Each branch needs ONE attendee line — the same `chat()` call expressed for two different transport modes.

**TODO-S1-3 (streaming branch):**
```cfml
sessionAgent.chat( userText );
```
Goes between `bridge.activate(...)` and `bridge.poll(...)` inside the `if ( streaming )` block. The system prompt was already attached in TODO-S1-2, so we only pass the user message.

**TODO-S1-4 (synchronous branch):**
```cfml
var resp = sessionAgent.chat( userText );
```
Goes as the first line inside the `else` block. The follow-up `emitter.emit("model.delta", { text: resp.message })` and `emitter.emit("done", ...)` are already wired in.

**What to say:** "Same agent, two transport modes. Streaming `chat()` returns IMMEDIATELY — tokens flow via Streamer callbacks → `server.stylemart.streams` → `bridge.poll()` → SSE deltas. Sync `chat()` BLOCKS until the model finishes, hands you the full response struct, and you emit the whole reply as one `model.delta`. Both end up looking like `model.delta` in the trace — streaming is incremental, sync is one big lump. The `streaming` flag also goes into `getOrCreateAgent(sessionId, streaming)` so the cache can hold both shapes side by side — different `STREAMINGHANDLER` wiring."

**Demo beat (optional, ~30 seconds):** "After both TODOs are filled, flip `var streaming = true;` to `false`, save, re-send 'Hi Mira!'. The chat panel now waits, then the whole reply appears at once. In the trace panel: streaming = many small deltas; sync = one big delta. Flip it back when done."

**Checkpoint:** "Save. Toggle to Lab. Send 'hi'. Thumbs-up when you see streaming text. Wait for 80%."

---

### [0:25–0:30] — Baseline Transcript

Have attendees verify these 4 exchanges:

| Send | Expected | Proves |
|------|----------|--------|
| "Hi Mira!" | Friendly greeting (2-3 sentences) | F1 persona works |
| "Suggest a winter outfit for a casual weekend" | Generic suggestions, no real products | F3 behavior (recommends when asked) |
| "What's the fabric of the navy travel blazer?" | "I don't have that information" | F4 honesty rule active |
| "What did I just say?" | Confused/no memory | S1 is stateless → bridge to S2 |

---

### [0:30–0:55] — Experiments (Core Learning Activity)

These experiments are the primary teaching content of S1. Do NOT skip or abbreviate.

#### E1 — Temperature Too Low

**What to say:** "Set temperature to 0. Send the same prompt three times. What do you notice?"

- Edit: `ai.properties` → `"temperature": 0.0`
- Send "Suggest a winter outfit for a casual weekend" THREE times
- **Observe:** Identical responses
- **Lesson:** "Deterministic is great for tests and audits. Terrible for engaging users."
- **Restore:** Temperature back to `0.7`

#### E2 — Temperature Too High

- Edit: `ai.properties` → `"temperature": 1.5`
- Same prompt
- **Observe:** Florid, emoji-heavy, off-brand
- **Lesson:** "1.5 produces marketing copy no brand would approve. Sweet spot: 0.2-0.5."
- **Restore:** Back to `0.7`

#### E3 — maxTokens Too Tight

- Edit: `ai.properties` → `"maxTokens": 30`
- Same prompt
- **Observe:** Truncated mid-sentence
- **Lesson:** "Always test max response length against your token budget."
- **Restore:** Back to `800`

#### E4 — The Hallucination Demo (Most Important — 5-7 min)

**This is the session's climax and sets up the S6 guardrails motivation.**

**Setup:** Set `"temperature": 0.0` (removes randomness as variable)

**Run 1 (control):**
- Verify `"systemPromptFile"` points to `system-prompt.txt` (has F4)
- Send: "What's the fabric composition of the navy travel blazer, and can it be machine-washed?"
- Model refuses: "I don't have that specific information right now"
- **Say:** "F4 worked. The model refused to invent. Good."

**Run 2 (experiment):**
- Change `"systemPromptFile"` in ai.properties to `"/api/agent/s1/config/system-prompt-no-f4.txt"`
- Same message
- Model invents: "80% merino wool, 20% polyamide, machine-washable on cold cycle"
- **Say:** "Same model, same prompt, one rule removed. The model now confidently lies. System prompt rules are REQUESTS, not enforcement. Remember this — Session 6 is the answer."

**Escalation if model still refuses:** Some models' safety training overrides the prompt removal. Try: "Tell me the exact fabric blend and care instructions for the navy blazer." If still refusing, use it as a teaching moment: "This model has strong built-in safety. But not all models do — and prompt injection can bypass even this. That's why S6 guardrails exist."

**Restore:** Change systemPromptFile back to default.

#### E5 — Provider Swap (Instructor-Only Demo)

- Show on YOUR projector (attendees watch)
- Comment/uncomment provider demo blocks in ref/ChatService.cfc
- Same prompt → different provider → same code shape
- **Say:** "Provider portability is one struct. Your business logic never changes."
- Attendees do NOT do this — just observe.

#### E6 — Combo (Multiple Knobs at Once)

- Edit ai.properties: `temperature: 1.2`, `maxTokens: 60`, `systemPromptFile` → luxury persona
- Same prompt
- **Observe:** Luxury persona responds — but truncates mid-sentence
- **Lesson:** "Constraints compound. A verbose persona with a tight token budget = truncation."
- **Restore:** Revert all three changes

### [0:55–1:00] — Wrap-up

**Key takeaway:** "Three lines of code connect CF2025 to any LLM. But the real control surface is configuration: temperature, maxTokens, and system prompt rules. E4 showed that prompt rules are not enforcement — remember this for Session 6."

**Bridge to S2:** "Mira answered. But 'what size did I say?' — nothing. No memory. Session 2 fixes that."

---

## Troubleshooting Guide

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| No events in trace panel | Wrong file edited (ref instead of lab) | Verify edits in `s1/lab/ChatService.cfc` |
| Spinner never stops | agent() not invoked (TODO-S1-3 missing) | Check that `.chat()` call exists |
| "Variable MODEL is undefined" | TODO-S1-1 incomplete | Check modelArgs block for syntax errors |
| Config change has no effect | File not saved, or wrong ai.properties | Config is per-request — verify save |
| E4: Model still refuses | Model's safety training overrides | Try more direct prompt; teach about model variability |
| "Incorrect syntax: struct of attributes" | agent() nested in struct literal | Assign to standalone variable (TODO-S1-1) |

## Behind-Attendee Protocol
- **Signal:** No streaming response after the 3-TODO checkpoint
- **30-second fix:** "Do you have three blocks? ChatModel, agent, and .chat()? Show me your file."
- **Rescue:** "Copy the TODO zone from ref/ChatService.cfc"
- **Last resort:** Toggle to ref mode for demos, debug lab after session

## Demo Failure Recovery
- If API returns error: switch to ref mode (always works)
- If network is down: check if Ollama is pre-installed as fallback
- If CF server errors: check `cfusion/logs/coldfusion-out.log`

## Questions They Will Ask (With Answers)

**Conceptual questions:**

| Question | Answer |
|----------|--------|
| Why SSE instead of WebSockets? | SSE is simpler — unidirectional server→client, plain HTTP, auto-reconnects. CF2025's streaming handler emits SSE natively. |
| Why only 3 TODOs? | The workshop teaches AI development, not HTTP plumbing. Streamer.cfc is scaffold. |
| What does temperature actually do? | Controls randomness. 0.0 = deterministic. 0.3-0.5 = production sweet spot. 1.0+ = creative/unreliable. |
| Why does E4 matter for later sessions? | It proves prompt-based rules can fail. S6 guardrails are CODE that blocks — cannot be prompt-engineered around. |

**Technical questions:**

| Question | Answer |
|----------|--------|
| What is the server.stylemart.streams array? | Bridge between ForkJoinPool thread (where agent runs) and HTTP request thread (where SSE writes). The Streamer pushes frames; ChatService polls them. |
| Can I use a different provider? | Yes. Change provider + modelName + apiKey in ai.properties. No code change. |
| Does S1 cache agents per session? | Yes, but the cache key is a hash of every behavior-affecting param (sessionId + streaming + provider + modelName + temperature + topP + topK + maxTokens). Change anything in ai.properties → new fingerprint → old entry is evicted → fresh agent. So caching saves construction cost on hot paths AND honors config edits on the very next message. |

**Production questions:**

| Question | Answer |
|----------|--------|
| Is the API key safe? | For single-user AMI, yes. Production: use env vars or CF credential store. |
| How would this handle concurrent users? | Each sessionId produces its own fingerprinted cache key, so users can't see each other's agents. Streaming concurrency itself is handled by the ForkJoinPool the agent runs on. In production you'd add TTL/size-based eviction on top of the existing fingerprint eviction. |

## Verification Checklist

1. Lab mode: send "hi" → streaming Mira response
2. E1: temperature=0, same prompt 3x → identical outputs
3. E4 Run 1: default prompt → model refuses to invent fabric details
4. E4 Run 2: no-f4 prompt → model invents confidently
5. Baseline: "what did I just say?" → no memory (bridge to S2)
