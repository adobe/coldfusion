# Fast-Track Rescue Guide

If you fall behind or get stuck, use these copy-paste blocks to catch up to any session checkpoint. Each block fills all TODOs for that session so you can continue to the next.

---

## Before Anything: Run Setup

If ANY session gives "datasource not found" or REST 404 errors:

Open: `http://localhost:8500/CFSummit2026Workshop/StyleMart/setup/setup.cfm`

All 5 lines should show `[ok]`. This registers databases and REST services after a CF restart.

---

## Session 1: Hello, ChatModel

**Checkpoint:** Streaming chat works in Lab mode.

**Note:** Streamer.cfc is pre-built scaffold — you do NOT edit it. Only ChatService.cfc has TODOs.

### Rescue — ChatService.cfc (3 TODOs)

**File:** `api/agent/s1/lab/ChatService.cfc`

Replace TODO-S1-4 (`var model = ""`) with:
```cfml
var modelArgs = {
  PROVIDER:    cfg.provider,
  APIKEY:      cfg.apiKey,
  MODELNAME:   cfg.modelName,
  TEMPERATURE: cfg.temperature,
  TOPP:        cfg.topP,
  TOPK:        cfg.topK,
  MAXTOKENS:   cfg.maxTokens
};
if ( structKeyExists(cfg, "baseUrl") && len(trim(cfg.baseUrl)) ) {
  modelArgs.BASEURL = cfg.baseUrl;
}
var model = ChatModel( modelArgs );
```

Replace TODO-S1-5 (`var sessionAgent = ""`) with:
```cfml
var sessionAgent = agent( {
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC
} );
```

Replace TODO-S1-6 (`local.fullPrompt = ""`) with:
```cfml
local.fullPrompt = local.cfg.systemPrompt & chr(10) & chr(10) & "User: " & userText;
```

Replace TODO-S1-7 (`/* TODO-S1-7 */`) with:
```cfml
local.bundle.agent.chat( local.fullPrompt );
```

---

## Session 2: Memory & Preferences

**Checkpoint:** Multi-turn coherence + preference extraction + persistence.

### Rescue — ChatService.cfc (9 TODOs)

**File:** `api/agent/s2/lab/ChatService.cfc`

#### TODO-S2-1: Build CHATMEMORY config

Replace `var memoryConfig = "" /* TODO-S2-1 */;` with:
```cfml
var memoryConfig = {
  TYPE:        cfg.chatMemory.type,
  MAXMESSAGES: cfg.chatMemory.maxMessages ?: 20,
  PERUSER:     cfg.chatMemory.perUser ?: true
};
if ( cfg.chatMemory.type == "tokenWindowChatMemory" ) {
  memoryConfig.MAXTOKENS = cfg.chatMemory.maxTokens;
  structDelete( memoryConfig, "MAXMESSAGES" );
}
if ( len( cfg.chatMemory.persistentStore ?: "" ) ) {
  memoryConfig.PERSISTENTSTORE = cfg.chatMemory.persistentStore;
}
```

#### TODO-S2-2: Build ChatModel

Replace `var model = "" /* TODO-S2-2 */;` with:
```cfml
var modelArgs = {
  PROVIDER:    cfg.provider,
  APIKEY:      cfg.apiKey,
  MODELNAME:   cfg.modelName,
  TEMPERATURE: cfg.temperature,
  TOPP:        cfg.topP,
  TOPK:        cfg.topK,
  MAXTOKENS:   cfg.maxTokens
};
if ( structKeyExists(cfg, "baseUrl") && len(trim(cfg.baseUrl)) ) {
  modelArgs.BASEURL = cfg.baseUrl;
}
var model = ChatModel( modelArgs );
```

#### TODO-S2-3: Create agent with memory

Replace `var sessionAgent = "" /* TODO-S2-3 */;` with:
```cfml
var sessionAgent = agent( {
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC,
  CHATMEMORY:       memoryConfig
} );
sessionAgent.systemMessage( cfg.systemPrompt, arguments.userId );
```

#### TODO-S2-4: Extract preferences

Replace `var extracted = {} /* TODO-S2-4 */;` with:
```cfml
var memory        = new api.agent.s2.lab.Memory();
var lastAssistant = getLastAssistantText( request.sessionId );
var extracted     = memory.extractPrefs( userText, local.model, request.userId, lastAssistant );
```

#### TODO-S2-5: Persist extracted prefs

Replace `/* TODO-S2-5 */` with:
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

#### TODO-S2-6: Load full prefs

Replace `var prefs = {} /* TODO-S2-6 */;` with:
```cfml
var prefs = memory.loadPrefs( request.userId );
if ( structKeyExists(prefs, "_corrupt") ) {
  emitter.emit( "error", {
    "type":   "preferences.store-unreachable",
    "title":  "Preferences temporarily unavailable",
    "detail": "Couldn't load your preferences — let's recapture your trip details.",
    "rule":   "store-unreachable"
  } );
  emitter.emit( "preferences.invalid", { "rule": "schema-mismatch" } );
  prefs = {};
}
```

#### TODO-S2-7: Whitelist envelope keys

Replace `var cleanPrefs = {} /* TODO-S2-7 */;` with:
```cfml
var validator    = new api.agent.s2.lab.PreferenceValidator( request.userId );
var schemaFields = validator.describeFields();
var cleanPrefs   = {};
for ( var field in listToArray( schemaFields, "," ) ) {
  var key = trim( listFirst( field, " " ) );
  if ( structKeyExists( prefs, key ) ) cleanPrefs[ key ] = prefs[ key ];
}
```

#### TODO-S2-8: Compose per-turn prompt

Replace `var fullPrompt = "" /* TODO-S2-8 */;` with:
```cfml
var fullPrompt = "Known preferences: " & serializeJSON( cleanPrefs )
              & chr(10) & chr(10) & "User: " & userText;
```

#### TODO-S2-9: Invoke the agent

Replace `/* TODO-S2-9 */` with:
```cfml
emitter.emit( "memory.read", { "messages": "managed-by-agent" } );
local.bundle.agent.chat( fullPrompt, request.userId );
```

---

### Rescue — Memory.cfc (2 TODOs)

**File:** `api/agent/s2/lab/Memory.cfc`

#### TODO-S2-10: Build extraction prompt

Replace `var extractionPrompt = "" /* TODO-S2-10 */;` with:
```cfml
var extractionPrompt =
    'You are a preference extraction engine.

      Your task is to extract and update user preferences from the latest user message.

      Schema:
      {
        "occasion": ["work","casual","wedding","beach","gym","date","party"],
        "topSize": ["XS","S","M","L","XL","XXL"],
        "jeansSize": "2 digit number",
        "colors": ["color names"],
        "budget": "number"
      }

      Rules:
      1. Extract only information explicitly stated or strongly implied in the latest message.
      2. Do not guess values.
      3. Return only fields that can be inferred from the message.
      4. If no schema field is mentioned, return {}.
      5. For colors, normalize to lowercase.
      6. If the message contains an event or use-case that maps to an occasion, map it:
        - office, meeting, interview -> work
        - vacation, sightseeing, london trip, travel -> casual
        - wedding, marriage -> wedding
        - beach, resort -> beach
        - workout, running -> gym
        - date night -> date
        - clubbing, celebration -> party
      7. CONTEXTUAL REPLY: When an "Assistant just asked" line is shown below and the
         latest user message is a bare value (just a number, a single word, or a short
         phrase with no field name), map that value to the field the assistant just asked
         about. e.g. asked about budget + reply "455" -> {"budget":455}; asked about size
         + reply "M" -> {"topSize":"M"}; asked about jeans size + reply "32" -> {"jeansSize":"32"}.
         This rule applies ONLY when the assistant explicitly asked for that field; never
         infer a field from a bare value without that question.
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
      ? chr(10) & 'Assistant just asked: "' & trim(arguments.assistantContext) & '"'
      : "" )
& chr(10) & "User text: " & arguments.userText;
```

#### TODO-S2-11: Call model and harvest JSON

Replace `var raw = "" /* TODO-S2-11 */;` with:
```cfml
var response = arguments.model.chat( extractionPrompt );
var raw      = response.message ?: "";
```

---

### Nuclear option (S2)

If you are completely stuck on S2, copy these files:
- `api/agent/s2/ref/ChatService.cfc` -> `api/agent/s2/lab/ChatService.cfc`
- `api/agent/s2/ref/Memory.cfc` -> `api/agent/s2/lab/Memory.cfc`

Then find-and-replace `s2.ref` with `s2.lab` in both files.

---

## Session 3: CFC Tools

**Checkpoint:** Tool calls appear in trace panel, product cards render.

**File:** `api/agent/s3/lab/ChatService.cfc`

Replace TODO-S3-1 (`var toolsConfig = []`) with:
```cfml
var toolsConfig = cfg.tools ?: [];
```

Replace TODO-S3-2 (`var sessionAgent = ""`) with:
```cfml
var sessionAgent = agent( {
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC,
  CHATMEMORY:       memoryConfig,
  TOOLS:            toolsConfig
} );
sessionAgent.systemMessage( cfg.systemPrompt, arguments.userId );
```

---

## Session 4: MCP

**Checkpoint:** Weather and logistics MCP calls work.

**File:** `api/agent/s4/lab/AgentFactory.cfc`

Replace TODO-S4-1 (`var mcpClients = []`) with:
```cfml
var mcpClients = getOrCreateMcpClients(cfg);
```

Replace TODO-S4-2 (`var toolsConfig = []`) with:
```cfml
var toolsConfig = buildToolsConfig(cfg, mcpClients);
```

Replace TODO-S4-3 (`var sessionAgent = ""`) with:
```cfml
var sessionAgent = agent({
  CHATMODEL:        model,
  STREAMINGHANDLER: STREAMER_CFC,
  CHATMEMORY:       memoryConfig,
  TOOLS:            toolsConfig
});
sessionAgent.systemMessage(cfg.systemPrompt, arguments.userId);
```

---

## Session 5: RAG

**Checkpoint:** Retrieval events in trace, citation chips in UI.

### init-rag.cfm

**File:** `api/agent/s5/lab/init-rag.cfm`

Replace TODO-S5-4 (`vs = ""`) with:
```cfml
vs = VectorStore({
  provider: ragCfg.vectorStoreProvider ?: "INMEMORY",
  embeddingModel: embeddingConfig
});
```

Replace TODO-S5-5 zone with:
```cfml
future = docService.ingestAsync(segments, vs);
arrayAppend(server.stylemart.ragFuturesLab, future);
```

### AgentFactory.cfc

**File:** `api/agent/s5/lab/AgentFactory.cfc`

Replace TODO-S5-1 (`var contentRetrievers = []`) with:
```cfml
var contentRetrievers = [];
if (structKeyExists(stores, "policy")) {
  arrayAppend(contentRetrievers, { vectorStore: stores.policy, maxResults: 6, minScore: 0.4, description: "Store policies: returns, exchanges, care instructions" });
}
if (structKeyExists(stores, "catalog")) {
  arrayAppend(contentRetrievers, { vectorStore: stores.catalog, maxResults: 3, minScore: 0.6, description: "Product catalog: descriptions, materials, features" });
}
if (structKeyExists(stores, "reviews")) {
  arrayAppend(contentRetrievers, { vectorStore: stores.reviews, maxResults: 3, minScore: 0.6, description: "Customer reviews: fit, quality, sentiment" });
}
if (structKeyExists(stores, "orders")) {
  arrayAppend(contentRetrievers, { vectorStore: stores.orders, maxResults: 2, minScore: 0.5, description: "Order history context" });
}
```

Replace TODO-S5-2 (`var contentInjector = {}`) with:
```cfml
var contentInjector = {
  promptTemplate: ragCfg.contentInjectorTemplate ?: ("Context: {{contents}}" & chr(10) & "Question: {{userMessage}}"),
  metadataKeys: ["file_name"]
};
```

Replace TODO-S5-3 (`return {}`) with:
```cfml
return {
  queryRouter: { type: "languageModel", contentRetrievers: contentRetrievers, routingModel: arguments.model },
  contentInjector: contentInjector
};
```

---

## Session 6: Guardrails + Generated Assets

**Checkpoint:** Guardrail violations fire on test messages.

### Phase A: Wiring

#### TODO-S6-1: Wire guardrail paths into agent config

**File:** `api/agent/s6/lab/AgentFactory.cfc`

Replace the `/* TODO-S6-1 */` zone with:
```cfml
if (isArray(arguments.cfg.guardrails.input ?: [])) {
  arguments.agentConfig.INPUTGUARDRAILS = arguments.cfg.guardrails.input.map((p) => expandPath(base & p));
}
if (isArray(arguments.cfg.guardrails.output ?: [])) {
  arguments.agentConfig.OUTPUTGUARDRAILS = arguments.cfg.guardrails.output.map((p) => expandPath(base & p));
}
```

---

### Phase B: Input Guardrails

#### TODO-S6-2: DiscountFabricationGuard

**File:** `api/agent/s6/lab/guardrails/input/DiscountFabricationGuard.cfc`

Replace the `/* TODO-S6-2 */` zone with:
```cfml
var hit = reFindNoCase( "\b\d{1,2}\s*%?\s*(off|discount)\b", msg ) > 0;
if ( !hit ) {
  var KEYWORDS = [
    "apply a discount", "give me a discount", "promo code", "make it cheaper",
    "discount code", "knock off"
  ];
  for ( var k in KEYWORDS ) {
    if ( findNoCase( k, msg ) ) { hit = true; break; }
  }
}
if ( !hit && findNoCase( "apply", msg ) && findNoCase( "discount", msg ) ) hit = true;

if ( hit ) {
  var offers = getEligibleCouponsText( request.userId ?: "" );
  out.result  = "fatal";
  out.message = "I can't apply discounts that aren't in our coupon catalog."
              & ( len( offers ) ? " Your current eligible offers are: " & offers & "." : "" );
}
```

#### TODO-S6-3: PromptInjectionGuard

**File:** `api/agent/s6/lab/guardrails/input/PromptInjectionGuard.cfc`

Replace the `/* TODO-S6-3 */` zone with:
```cfml
var PHRASES = [
  "ignore previous instructions", "you are now", "reveal your system prompt",
  "disregard your guidelines", "forget all rules", "ignore your guidelines",
  "act as if", "pretend you are"
];
for ( var p in PHRASES ) {
  if ( findNoCase( p, msg ) ) {
    out.result  = "fatal";
    out.message = "I can only follow my normal StyleMart shopping instructions.";
    break;
  }
}
```

#### TODO-S6-4: CartBypassGuard

**File:** `api/agent/s6/lab/guardrails/input/CartBypassGuard.cfc`

Replace the `/* TODO-S6-4 */` zone with:
```cfml
var PHRASES = [
  "add it without asking", "skip confirmation", "just buy it",
  "bypass the confirm", "bypass confirmation", "no confirmation",
  "skip the confirm", "without confirming", "without asking"
];
for ( var p in PHRASES ) {
  if ( findNoCase( p, msg ) ) {
    out.result  = "fatal";
    out.message = "Cart changes always need your confirmation. Tell me what to add and I'll show the confirm panel.";
    break;
  }
}
```

---

### Phase C: Output Guardrails

#### TODO-S6-5: FitGuaranteeGuard

**File:** `api/agent/s6/lab/guardrails/output/FitGuaranteeGuard.cfc`

Replace the `/* TODO-S6-5 */` zone with:
```cfml
var hit = reFindNoCase( "\bguarantees?\s+(a\s+)?(perfect|exact|ideal)\s+fit\b", msg ) > 0;
if ( !hit ) {
  var KEYWORDS = [
    "guaranteed to fit", "perfect fit", "will fit perfectly", "guarantees a perfect"
  ];
  for ( var k in KEYWORDS ) {
    if ( findNoCase( k, msg ) ) { hit = true; break; }
  }
}

if ( hit ) {
  out.result          = "failure";
  out.message         = "Fit guarantees aren't supported; answer from review evidence instead.";
  out.repromptMessage = "Re-answer using only retrieved review evidence "
                      & "(e.g. 'reviewers report comfortable fit, true to size'). "
                      & "Never promise a perfect or guaranteed fit.";
}
```

#### TODO-S6-6: FakeDiscountGuard

**File:** `api/agent/s6/lab/guardrails/output/FakeDiscountGuard.cfc`

Replace the `/* TODO-S6-6 */` zone with:
```cfml
var hit = reFindNoCase( "\b\d{1,2}\s*%\s*(off|discount|savings)\b", msg ) > 0;
if ( !hit ) {
  var KEYWORDS = [
    "today only", "limited time", "lowest price ever", "while supplies last",
    "deal of the year", "flash sale"
  ];
  for ( var k in KEYWORDS ) {
    if ( findNoCase( k, msg ) ) { hit = true; break; }
  }
}

if ( hit ) {
  out.result          = "failure";
  out.message         = "Discount language must reference real, eligible coupons only.";
  out.repromptMessage = "Re-answer referencing ONLY the shopper's real eligible coupons "
                      & "(from getEligibleCoupons). Do not invent promotions, percentages, "
                      & "or urgency phrases like 'today only' or 'limited time'.";
}
```

#### TODO-S6-7: PiiLeakGuard

**File:** `api/agent/s6/lab/guardrails/output/PiiLeakGuard.cfc`

Replace the `/* TODO-S6-7 */` zone with:
```cfml
var leaked = reFindNoCase( "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", msg ) > 0
          || reFindNoCase( "\b\+?\d[\d .-]{7,}\d\b", msg ) > 0
          || reFindNoCase( "\b(?:\d[ -]*?){13,16}\b", msg ) > 0;

if ( leaked ) {
  out.result  = "fatal";
  out.message = "I can't include personal contact or payment details in this message.";
}
```

#### TODO-S6-8: MisleadingScarcityGuard

**File:** `api/agent/s6/lab/guardrails/output/MisleadingScarcityGuard.cfc`

Replace the `/* TODO-S6-8 */` zone with:
```cfml
var hit = reFindNoCase( "\bonly\s+\d+\s+left\b", msg ) > 0;
if ( !hit ) {
  var SCARCITY_PHRASES = [
    "limited time", "while supplies last", "today only",
    "going fast", "act fast", "selling out", "few remaining",
    "hurry", "last chance"
  ];
  for ( var p in SCARCITY_PHRASES ) {
    if ( findNoCase( p, msg ) ) { hit = true; break; }
  }
}

if ( hit ) {
  out.result          = "failure";
  out.message         = "Upsell copy used misleading scarcity/urgency language.";
  out.repromptMessage = "Rewrite the add-on pitch WITHOUT any urgency or scarcity claims "
                      & "(no 'limited time', 'only N left', 'selling fast', etc.). "
                      & "Justify each pick only with review evidence, weather, or saved preferences.";
}
```

---

### Phase D: Generated Assets

#### TODO-S6-9a: RecoveryEmailService — Load context

**File:** `api/agent/s6/lab/RecoveryEmailService.cfc`

Replace `local.context = {} /* TODO-S6-9a */;` with:
```cfml
local.context = {
  userId:          arguments.userId,
  cartId:          arguments.cartId,
  sessionId:       arguments.sessionId,
  preferences:     l1Get("/commerce/users/" & arguments.userId & "/preferences"),
  cart:            l1Get("/commerce/carts/" & arguments.cartId),
  eligibleCoupons: tryMcp("cf-commerce","getEligibleCoupons",{userId:arguments.userId}, []),
  weather:         tryMcp("ext-weather","getForecast",{city:""}, "")
};
```

#### TODO-S6-9b: RecoveryEmailService — Render prompt

Replace `local.fullPrompt = "" /* TODO-S6-9b */;` with:
```cfml
var promptTemplate = fileRead( expandPath( local.cfg.recoveryEmail.promptTemplateFile ) );
local.fullPrompt = renderTemplate( promptTemplate, local.context );
```

#### TODO-S6-9c: RecoveryEmailService — Invoke agent

Replace `return {} /* TODO-S6-9c */;` with:
```cfml
request.guardrailResults = [];
var raw     = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
var parsed  = parseModelJson( raw.message );
var results = normalizeGuardrailResults( request.guardrailResults );
var asset   = assembleAsset( parsed, local.context, results );
return persistAsset( asset, results );
```

---

#### TODO-S6-10a: LandingSectionService — Load context

**File:** `api/agent/s6/lab/LandingSectionService.cfc`

Replace `local.context = {} /* TODO-S6-10a */;` with:
```cfml
var prefs = l1Get("/commerce/users/" & arguments.userId & "/preferences");
var cartData = l1Get("/commerce/carts/" & arguments.cartId);
var verified = []; var swaps = [];
for ( var item in cartData.items ?: [] ) {
  var inv = tryMcp("cf-commerce","getInventory",{productId:item.productId},{});
  if ( isStockAvailable(inv) ) arrayAppend(verified, item);
  else                          arrayAppend(swaps, suggestSwap(item, inv));
}
local.context = {
  userId: arguments.userId, cartId: arguments.cartId, sessionId: arguments.sessionId,
  preferences: prefs,
  cart:        { items: verified, itemIds: verified.map((i)=>i.productId) },
  outOfStockSwaps: swaps,
  tripContext: { city: prefs.tripCity ?: "", month: monthAsName(now()),
                 forecast: tryMcp("ext-weather","getForecast",{city:prefs.tripCity ?: ""},"") }
};
```

#### TODO-S6-10b: LandingSectionService — Render prompt

Replace `local.fullPrompt = "" /* TODO-S6-10b */;` with:
```cfml
var promptTemplate = fileRead( expandPath( local.cfg.landingSection.promptTemplateFile ) );
local.fullPrompt = renderTemplate( promptTemplate, local.context );
```

#### TODO-S6-10c: LandingSectionService — Invoke agent

Replace `return {} /* TODO-S6-10c */;` with:
```cfml
request.guardrailResults = [];
var raw     = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
var parsed  = parseModelJson( isStruct(raw) ? raw.message ?: "" : toString(raw) );
var results = normalizeGuardrailResults( request.guardrailResults );
var asset   = assembleLandingAsset( parsed, local.context, results );
return persistAsset( asset, results );
```

---

#### TODO-S6-11a: UpsellPitchService — Build candidate pool

**File:** `api/agent/s6/lab/UpsellPitchService.cfc`

Replace `local.context = {} /* TODO-S6-11a */;` with:
```cfml
var prefs     = l1Get("/commerce/users/" & arguments.userId & "/preferences");
var cartData  = l1Get("/commerce/carts/" & arguments.cartId);
var inCartIds = [];
for ( var ci in ( cartData.items ?: [] ) ) {
  if ( len( ci.productId ?: "" ) ) arrayAppend( inCartIds, ci.productId );
}
var poolRaw   = l1Get("/commerce/products?category=accessories&pageSize=20");
var pool      = (poolRaw.items ?: [])
                  .filter( (p) => !arrayFindNoCase(inCartIds, p.productId) )
                  .filter( (p) => (p.reviewCount ?: 0) > 0 );
var candidates = [];
for ( var p in pool ) {
  if ( arrayLen(candidates) >= 6 ) break;
  var inv = tryMcp("cf-commerce","getInventory",{productId:p.productId},{});
  if ( isStockAvailable(inv) ) arrayAppend(candidates, p);
}
local.context = {
  userId: arguments.userId, cartId: arguments.cartId, sessionId: arguments.sessionId,
  cart: cartData, cartItems: cartData.items ?: [], cartItemIds: inCartIds,
  candidates: candidates,
  tripContext: { city: prefs.tripCity ?: "", forecast: tryMcp("ext-weather","getForecast",{city:prefs.tripCity ?: ""},"") }
};
```

#### TODO-S6-11b: UpsellPitchService — Render prompt

Replace `local.fullPrompt = "" /* TODO-S6-11b */;` with:
```cfml
var promptTemplate = fileRead( expandPath( local.cfg.upsellPitch.promptTemplateFile ) );
local.fullPrompt = renderTemplate( promptTemplate, local.context );
```

#### TODO-S6-11c: UpsellPitchService — Invoke agent

Replace `return {} /* TODO-S6-11c */;` with:
```cfml
request.guardrailResults = [];
var raw       = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
var parsed    = parseModelJson( isStruct(raw) ? raw.message ?: "" : toString(raw) );
var validated = enforceCandidatePool( parsed, local.context.candidates );
var results   = normalizeGuardrailResults( request.guardrailResults );
var asset     = assembleUpsellAsset( validated, local.context, results );
return persistAsset( asset, results );
```

---

### Nuclear option (S6)

Copy the entire `api/agent/s6/ref/` directory contents over `api/agent/s6/lab/`. Then find-and-replace `s6.ref` with `s6.lab` in all files.

---

## Last Resort (Any Session)

If you are completely stuck on session N:
1. Toggle to **Ref mode** — verify the reference works
2. Copy the entire contents of `sN/ref/` over `sN/lab/`
3. Find-and-replace `sN.ref` -> `sN.lab` in the copied files
4. Continue to session N+1

This ensures your lab environment matches the expected state for the next session.
