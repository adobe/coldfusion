component rest="true" restpath="/s4/ref/chat" {

  // Three-tier identity:
  //   1. getAuthUser()       — populated only if a cflogin block fires.
  //   2. X-Shopper-Id header — set by assets/js/api.js on every authenticated fetch.
  //   3. "demo-shopper-001"  — unauthenticated dev fallback (matches the row
  //                            seeded in 11_seed_workshop_demo_users.sql).
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

    var memory = new api.agent.s4.ref.Memory();
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
    var memory = new api.agent.s4.ref.Memory();
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

  private string function buildPrompt(
    required string userText,
    required string userId,
    required any    model,
    required string sessionId,
    required any    emitter
  ) {
    var memory        = new api.agent.s4.ref.Memory();
    var lastAssistant = getLastAssistantText( arguments.sessionId );
    var extracted     = memory.extractPrefs( arguments.userText, arguments.model, arguments.userId, lastAssistant );

    if ( !structIsEmpty( extracted ) ) {
      try { memory.savePrefs( arguments.userId, extracted ); } catch (any e) {}
      arguments.emitter.emit( "preference.persist", {
        "fields": structKeyArray( extracted ),
        "values": extracted,
        "userId": arguments.userId
      } );
    }

    var prefs = memory.loadPrefs( arguments.userId );
    if ( structKeyExists(prefs, "_corrupt") ) {
      arguments.emitter.emit( "error", {
        "type":   "preferences.store-unreachable",
        "title":  "Preferences temporarily unavailable",
        "detail": "Couldn't load your preferences — let's recapture your trip details.",
        "rule":   "store-unreachable"
      } );
      arguments.emitter.emit( "preferences.invalid", { "rule": "schema-mismatch" } );
      prefs = {};
    }

    var validator    = new api.agent.s4.ref.PreferenceValidator( arguments.userId );
    var schemaFields = validator.describeFields();
    var cleanPrefs   = {};
    for ( var field in listToArray( schemaFields, "," ) ) {
      var key = trim( listFirst( field, " " ) );
      if ( structKeyExists( prefs, key ) ) cleanPrefs[ key ] = prefs[ key ];
    }

    return "Known preferences: " & serializeJSON( cleanPrefs )
         & "

User: " & arguments.userText;
  }

  remote void function sendMessage(
    required string sessionId restargsource="path"
  ) httpmethod="POST" restpath="sessions/{sessionId}/messages" produces="text/event-stream" {
    var helper   = new api.agent.common.RequestHelper();
    var userText = helper.initRequest( arguments.sessionId, resolveUserId() );
    var stream   = helper.initStream( userText );
    var emitter  = stream.emitter;
    var bridge   = stream.bridge;

    var bundle = new AgentService().getOrCreateAgent( request.sessionId, request.userId );

    emitter.emit( "model.start", { "model": bundle.cfg.modelName } );

    try {
      var fullPrompt = buildPrompt( userText, request.userId, bundle.model, request.sessionId, emitter );

      emitter.emit( "memory.read", { "messages": "managed-by-agent" } );
      bridge.activate( request.messageId );
      bundle.agent.chat( fullPrompt, request.userId );

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

  // Most-recent assistant turn, ordered by id DESC so the latest wins regardless
  // of seq (which resets per turn). Returns "" when there is no prior turn.
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
