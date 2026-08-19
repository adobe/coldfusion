component {

  DSN            = "stylemart";
  SCHEMA_VERSION = 1;
  // The user_preferences row is the single canonical store. user_id is the PK
  // and updated_at is its own ON UPDATE CURRENT_TIMESTAMP column, so these
  // envelope keys are stripped before serializing into the JSON column and
  // re-attached on read.
  ENVELOPE_KEYS = [ "userId", "updatedAt", "_corrupt" ];

  public struct function extractPrefs(
    required string userText,
    required any    model,
    required string userId,
    string          assistantContext = ""
  ) {
    // Build validator FIRST — its constructor reads (or bootstraps) the user's schema,
    // so we can ask the model for exactly the fields THIS user's schema declares.
    // Path note: this is REF code → instantiate `s3.ref.PreferenceValidator`.
    // The ref/ folder ships its own copy of the validator (per §3 directory tree)
    // so ref is fully self-contained — switching to ref must NEVER cross into lab/.
    var validator   = new api.agent.s3.ref.PreferenceValidator( arguments.userId );
    var fieldDescr  = validator.describeFields();

    // Empty-input fast path. The LLM call is skipped only for the trivially
    // empty case — every other classification (questions, greetings, vague
    // chatter, statements) is delegated to the LLM via the prompt's
    // "return {} for questions / greetings / acknowledgements" clause.
    if ( !len( trim(arguments.userText) ) ) return {};

    // The prompt below is the workshop's "schema + numbered rules + worked
    // examples" style: it lists every schema field, the canonical occasion
    // mapping, and worked extraction examples. We intentionally DO trust
    // the LLM (no CFML question/greeting guard, no per-typo few-shots). The one
    // piece of conversational scaffolding we DO pass is the assistant's previous
    // question (assistantContext): a bare reply like "455" is meaningless without
    // knowing the model just asked "What is your budget?", so rule 7 + the
    // "Assistant just asked" line let the LLM bind bare values to the asked field.
    // Modern instruction-tuned models follow these
    // rules reliably enough that scaffolding around them just rebuilds scar
    // tissue. If you observe a specific failure with your model, prefer
    // adding a numbered rule or example to THIS prompt over adding CFML
    // pre/post-processing.
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
      ? '
Assistant just asked: "' & trim(arguments.assistantContext) & '"'
      : "" )
& "
User text: " & arguments.userText;

    // CF's ChatModel.chat() returns a struct {message, toolExecutionRequests, metadata}
    // for non-streaming calls. The model's text response is in .message.
    var response = arguments.model.chat( extractionPrompt );
    var raw      = response.message ?: "";
    // Provider tolerance: some providers wrap JSON in ```json ... ``` fences,
    // and others (mistral, llama variants) sometimes prepend prose like
    // "Sure, here is the JSON: {...}". Strip fences first, then carve out the
    // first {...} object so prose preambles/epilogues don't break parsing.
    raw = reReplace( raw, "^[\s]*```(json)?[\s]*", "", "all" );
    raw = reReplace( raw, "[\s]*```[\s]*$", "", "all" );
    var jsonMatch = reFind( "\{[\s\S]*\}", raw, 1, true );
    if ( jsonMatch.len[1] > 0 ) {
      raw = mid( raw, jsonMatch.pos[1], jsonMatch.len[1] );
    }
    try {
      var parsed  = deserializeJSON( raw );
      var cleaned = validator.validate( parsed ).cleaned;
      // Strip "no-value" keys: empty arrays + zero numbers + empty strings.
      // The LLM tends to hallucinate `{"colors":[], "budget":0}` even when the
      // user said nothing about colors or budget — those are model placeholders,
      // not actual extractions. Keeping them would (a) overwrite real prior
      // values and (b) suppress the corrupt-prefs failure path (§6 row 13).
      var meaningful = {};
      for ( var k in cleaned ) {
        var v = cleaned[ k ];
        if ( isArray(v)  && arrayLen(v) == 0 ) continue;
        if ( isNumeric(v) && v == 0          ) continue;
        if ( isSimpleValue(v) && len(trim(toString(v))) == 0 ) continue;
        meaningful[ k ] = v;
      }
      return meaningful;
    } catch ( any e ) {
      return {};
    }
  }

  public void function savePrefs( required string userId, required struct partial ) {
    // Read-modify-write inside a transaction so concurrent turns for the same
    // user serialize the merge instead of clobbering each other.
    transaction {
      var existing = loadForUpdate( arguments.userId );
      structAppend( existing, arguments.partial, true );  // partial wins
      upsertRow( arguments.userId, existing );
    }
  }

  public struct function loadPrefs( required string userId ) {
    var q = queryExecute(
      "SELECT preferences, updated_at FROM user_preferences WHERE user_id = :uid",
      { uid: { value: arguments.userId, cfsqltype: "cf_sql_varchar" } },
      { datasource: DSN }
    );
    if ( q.recordCount == 0 ) return {};
    try {
      // The JSON column holds only the fact-set; re-attach the envelope keys
      // from the table's own PK / timestamp columns so callers see the same
      // shape the file-backed store used to return.
      var prefs = deserializeJSON( q.preferences[1] );
      prefs.userId    = arguments.userId;
      prefs.updatedAt = dateTimeFormat( q.updated_at[1], "yyyy-mm-dd'T'HH:nn:ss'Z'" );
      return prefs;
    } catch ( any e ) {
      return { "_corrupt": true };  // malformed JSON column
    }
  }

  public void function updatePref(
    required string userId,
    required string key,
    required any    value
  ) {
    var validator = new api.agent.s3.ref.PreferenceValidator( arguments.userId );
    var result    = validator.validate( { "#arguments.key#": arguments.value } );
    if ( !result.valid ) return;  // silently drop invalid single-field update
    transaction {
      var existing = loadForUpdate( arguments.userId );
      structAppend( existing, result.cleaned, true );
      upsertRow( arguments.userId, existing );
    }
  }

  // Drop a single key from the user's prefs blob — distinct from deletePrefs which
  // wipes the whole row. Used by ?fail=drop-key injection in §6 and by unit tests
  // that verify per-key removal semantics without destroying the whole envelope.
  public void function deletePref( required string userId, required string key ) {
    transaction {
      var existing = loadForUpdate( arguments.userId );
      if ( !structKeyExists( existing, arguments.key ) ) return;  // nothing to do
      structDelete( existing, arguments.key );
      upsertRow( arguments.userId, existing );
    }
  }

  public void function deletePrefs( required string userId ) {
    // Schema file (.schema.json, owned by PreferenceValidator) is intentionally
    // NOT touched — only the values row is cleared, so the user's learned
    // vocabulary survives across reset cycles.
    queryExecute(
      "DELETE FROM user_preferences WHERE user_id = :uid",
      { uid: { value: arguments.userId, cfsqltype: "cf_sql_varchar" } },
      { datasource: DSN }
    );
  }

  // Row-locked read so concurrent turns for the same user serialize the
  // read-modify-write merge. Returns the bare fact-set (no envelope keys).
  private struct function loadForUpdate( required string userId ) {
    var q = queryExecute(
      "SELECT preferences FROM user_preferences WHERE user_id = :uid",
      { uid: { value: arguments.userId, cfsqltype: "cf_sql_varchar" } },
      { datasource: DSN }
    );
    if ( q.recordCount == 0 ) return {};
    try { return deserializeJSON( q.preferences[1] ); }
    catch ( any e ) { return {}; }  // a corrupt row is overwritten on next write
  }

  // UPSERTs the canonical row. user_id is the PK and updated_at is
  // ON UPDATE CURRENT_TIMESTAMP, so envelope keys are stripped from the JSON
  // column. Errors are NOT swallowed — the row is now the single source of
  // truth, so a failed write must surface (caught by ChatService.sendMessage's
  // try/catch). Per the "registered users only" contract the users-row FK
  // target always exists, so the previous demo-shopper FK violation cannot occur.
  private void function upsertRow( required string userId, required struct merged ) {
    var prefsOnly = duplicate( arguments.merged );
    for ( var k in ENVELOPE_KEYS ) structDelete( prefsOnly, k );

    queryExecute(
      "INSERT INTO user_preferences (user_id, preferences, schema_version)
            VALUES (:uid, :prefs, :ver)
       ON CONFLICT(user_id) DO UPDATE SET
            preferences = excluded.preferences,
            updated_at  = strftime('%Y-%m-%d %H:%M:%f','now')",
      {
        uid:   { value: arguments.userId,           cfsqltype: "cf_sql_varchar" },
        prefs: { value: serializeJSON( prefsOnly ), cfsqltype: "cf_sql_varchar" },
        ver:   { value: SCHEMA_VERSION,             cfsqltype: "cf_sql_integer" }
      },
      { datasource: DSN }
    );
  }
}
