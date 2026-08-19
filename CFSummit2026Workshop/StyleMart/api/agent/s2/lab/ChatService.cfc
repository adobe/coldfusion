component rest="true" restpath="/s2/lab/chat" {

  private string function resolveUserId() {
    var u = getAuthUser();
    if ( !isNull(u) && len(trim(u)) ) return u;
    var headers = getHttpRequestData().headers ?: {};
    if ( structKeyExists(headers, "X-Shopper-Id") && len(trim(headers["X-Shopper-Id"])) ) {
      return trim(headers["X-Shopper-Id"]);
    }
    return "demo-shopper-001";
  }

  remote struct function openSession() httpmethod="POST" restpath="sessions" produces="application/json" {
    var sessionId = "ses_" & lCase( replace( createUUID(), "-", "", "all" ) );
    var userId    = resolveUserId();

    var memory = new api.agent.s2.lab.Memory();
    var prefs  = memory.loadPrefs( userId );
    if ( structKeyExists(prefs, "_corrupt") ) prefs = {};

    new AgentService().getOrCreateAgent( sessionId, userId );

    return {
      "sessionId":  sessionId,
      "createdAt":  dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ss'Z'" ),
      "userId":     userId,
      "savedPrefs": prefs
    };
  }

  remote struct function resetSession(
    required string sessionId restargsource="path"
  ) httpmethod="POST" restpath="sessions/{sessionId}/reset" {
    var userId = resolveUserId();
    new AgentService().evict( arguments.sessionId );
    return {
      "status":    "reset",
      "sessionId": "ses_" & lCase( replace( createUUID(), "-", "", "all" ) ),
      "userId":    userId
    };
  }

  remote struct function resetPreferences(
    required string sessionId restargsource="path"
  ) httpmethod="DELETE" restpath="sessions/{sessionId}/preferences" {
    var userId = resolveUserId();
    var memory = new api.agent.s2.lab.Memory();
    memory.deletePrefs( userId );
    return { "status": "deleted", "userId": userId };
  }

  remote array function getMessages(
    required string sessionId restargsource="path"
  ) httpmethod="GET" restpath="sessions/{sessionId}/messages" {
    var rows = queryExecute(
      "SELECT seq, type, payload_json, ts
         FROM agent_traces
        WHERE session_id = :sid
          AND type IN ('user.message', 'model.end')
        ORDER BY id ASC",
      { sid: { value: arguments.sessionId, cfsqltype: "cf_sql_varchar" } },
      { datasource: "stylemart" }
    );
    var transcript = [];
    for ( var i = 1; i <= rows.recordCount; i++ ) {
      var payload = deserializeJSON( rows.payload_json[i] );
      arrayAppend( transcript, {
        "role":    rows.type[i] == "user.message" ? "user" : "assistant",
        "content": payload.text ?: "",
        "ts":      dateTimeFormat( rows.ts[i], "yyyy-mm-dd'T'HH:nn:ss'Z'" )
      } );
    }
    return transcript;
  }

  remote void function sendMessage(
    required string sessionId restargsource="path"
  ) httpmethod="POST" restpath="sessions/{sessionId}/messages" produces="text/event-stream" {
    var helper   = new api.agent.common.RequestHelper();
    var userText = helper.initRequest( arguments.sessionId, resolveUserId() );
    var stream   = helper.initStream( userText );
    var emitter  = stream.emitter;
    var bridge   = stream.bridge;

    var bundle  = new AgentService().getOrCreateAgent( request.sessionId, request.userId );
    local.cfg   = bundle.cfg;
    local.model = bundle.model;

    emitter.emit( "model.start", { "model": local.cfg.modelName } );

    try {
      /* ===== ATTENDEE TODO ZONE (Memory-aware turn) ============================= */

      /*
       TODO-S2-4: Extract any new preferences from THIS turn.
         Memory.extractPrefs builds an LLM prompt with worked examples + schema
         field hints, runs the model, and returns a {field: value} struct.
         Pass `lastAssistant` so a bare reply ("455") binds to the just-asked field.
         Hint:
           var memory        = new api.agent.s2.lab.Memory();
           var lastAssistant = getLastAssistantText( request.sessionId );
           var extracted     = memory.extractPrefs( userText, local.model, request.userId, lastAssistant );
      */
      var extracted = {} /* TODO-S2-4 */;

      /*
       TODO-S2-5: Persist extracted prefs and emit preference.persist for the rail UI.
         Hint:
           if ( !structIsEmpty( extracted ) ) {
             memory.savePrefs( request.userId, extracted );
             emitter.emit( "preference.persist", {
               "fields": structKeyArray( extracted ),
               "values": extracted,
               "userId": request.userId
             } );
           }
      */
      /* TODO-S2-5 */

      /*
       TODO-S2-6: Load full prefs (handle _corrupt by emitting an error frame).
         Hint:
           var prefs = memory.loadPrefs( request.userId );
           if ( structKeyExists(prefs, "_corrupt") ) {
             emitter.emit( "error", { "type": "preferences.store-unreachable",
                                      "title": "Preferences temporarily unavailable",
                                      "detail": "Couldn't load your preferences — let's recapture your trip details.",
                                      "rule": "store-unreachable" } );
             emitter.emit( "preferences.invalid", { "rule": "schema-mismatch" } );
             prefs = {};
           }
      */
      var prefs = {} /* TODO-S2-6 */;

      /*
       TODO-S2-7: Whitelist envelope keys (userId/updatedAt/_corrupt) before splicing into the prompt.
         Use PreferenceValidator.describeFields() to enumerate schema fields, then keep only those.
         Hint:
           var validator    = new api.agent.s2.lab.PreferenceValidator( request.userId );
           var schemaFields = validator.describeFields();
           var cleanPrefs   = {};
           for ( var field in listToArray( schemaFields, "," ) ) {
             var key = trim( listFirst( field, " " ) );
             if ( structKeyExists( prefs, key ) ) cleanPrefs[ key ] = prefs[ key ];
           }
      */
      var cleanPrefs = {} /* TODO-S2-7 */;

      /*
       TODO-S2-8: Compose the per-turn prompt. System prompt is set on the agent
         once (in getOrCreateAgent), so this prompt only carries the dynamic
         per-turn context (known prefs + user text).
         Hint:
           var fullPrompt = "Known preferences: " & serializeJSON( cleanPrefs )
                          & "

User: " & userText;
      */
      var fullPrompt = "" /* TODO-S2-8 */;

      /*
       TODO-S2-9: Emit memory.read, then invoke the cached agent (PERUSER + per-call userId).
         Hint:
           emitter.emit( "memory.read", { "messages": "managed-by-agent" } );
           bridge.activate( request.messageId );
           bundle.agent.chat( fullPrompt, request.userId );
      */
      bridge.activate( request.messageId );
      /* TODO-S2-9 */

      /* ===== END ATTENDEE TODO ZONE ============================================= */

      bridge.poll( request.messageId, emitter );

      emitter.emit( "memory.write", { "messages": "appended-by-agent" } );
    }
    catch ( any e ) {
      emitter.emit( "error", {
        "type":   "chat.unexpected",
        "title":  "Assistant unavailable",
        "detail": e.message,
        "rule":   "internal"
      } );
      emitter.emit( "done", { "status": "error" } );
    }
    finally {
      bridge.close( request.messageId );
    }
  }

  /*
   Most-recent assistant turn, ordered by id DESC so the latest wins regardless
   of seq (which resets per turn). Returns "" when there is no prior turn.
  */
  private string function getLastAssistantText( required string sessionId ) {
    try {
      var q = queryExecute(
        "SELECT payload_json FROM agent_traces
          WHERE session_id = :sid AND type = 'model.end'
          ORDER BY id DESC",
        { sid: { value: arguments.sessionId, cfsqltype: "cf_sql_varchar" } },
        { datasource: "stylemart", maxrows: 1 }
      );
      if ( q.recordCount == 0 ) return "";
      var payload = deserializeJSON( q.payload_json[1] );
      return payload.text ?: "";
    } catch ( any e ) {
      return "";
    }
  }
}
