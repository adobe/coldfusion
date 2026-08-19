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
    // Path note: this is REF code → instantiate `s2.ref.PreferenceValidator`.
    // The ref/ folder ships its own copy of the validator (per §3 directory tree)
    // so ref is fully self-contained — switching to ref must NEVER cross into lab/.
    var validator   = new api.agent.s2.lab.PreferenceValidator( arguments.userId );
    var fieldDescr  = validator.describeFields();

    // Empty-input fast path. The LLM call is skipped only for the trivially
    // empty case — every other classification (questions, greetings, vague
    // chatter, statements) is delegated to the LLM via the prompt's
    // "return {} for questions / greetings / acknowledgements" clause.
    if ( !len( trim(arguments.userText) ) ) return {};

    // ===== ATTENDEE TODO ZONE (LLM-based preference extraction) ===============

    // TODO-S2-10: Build the extraction prompt. Include the schema, numbered rules
    //   (especially rule 7: bare-value-binds-to-just-asked-field when assistantContext
    //   is non-empty), and worked examples. The prompt is the heart of S2 — keep it
    //   declarative + example-driven; do NOT add CFML pre/post-processing scar tissue.
    //   The prompt body is ~100 lines; mirror ref/Memory.cfc.
    //   At the end, append the "Assistant just asked:" context (only when non-empty)
    //   and the user text:
    //       & ( len( trim(arguments.assistantContext) )
    //             ? "[newline]Assistant just asked: " & trim(arguments.assistantContext)
    //             : "" )
    //       & "[newline]User text: " & arguments.userText;
    var extractionPrompt = "" /* TODO-S2-10 */;

    // TODO-S2-11: Call the model and harvest its JSON response.
    //   CF's ChatModel.chat() returns {message, toolExecutionRequests, metadata}
    //   for non-streaming calls — text is in .message.
    //   Hint:
    //     var response = arguments.model.chat( extractionPrompt );
    //     var raw      = response.message ?: "";
    var raw = "" /* TODO-S2-11 */;

    // ===== END ATTENDEE TODO ZONE =============================================

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
    var validator = new api.agent.s2.lab.PreferenceValidator( arguments.userId );
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
