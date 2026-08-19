component rest="true" restpath="/s5/lab/chat" {

  // Three-tier identity:
  //   1. getAuthUser()       — populated only if a cflogin block fires.
  //   2. X-Shopper-Id header — set by assets/js/api.js on every authenticated fetch.
  //   3. "demo-shopper-001"  — unauthenticated dev fallback.
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

    var memory = new api.agent.s5.lab.Memory();
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
    new AgentService().evict( arguments.sessionId );
    return {
      "status":    "reset",
      "sessionId": "ses_" & lCase( replace( createUUID(), "-", "", "all" ) ),
      "userId":    resolveUserId()
    };
  }

  remote struct function resetPreferences(
    required string sessionId restargsource="path"
  ) httpmethod="DELETE" restpath="sessions/{sessionId}/preferences" {
    var userId = resolveUserId();
    var memory = new api.agent.s5.lab.Memory();
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
    var body = deserializeJSON( toString( getHttpRequestData().content ) );

    request.sessionId = arguments.sessionId;
    request.messageId = body.messageId ?: "msg_#lCase(replace(createUUID(), '-', '', 'all'))#";
    request.seq       = 0;
    request.userId    = resolveUserId();
    var userText      = body.userText ?: "";

    var emitter = new api.agent.common.TraceEmitter();
    emitter.initSSE();

    // Only gate on ragReady when ingestion futures are actively in progress.
    // When TODOs are unfilled (no futures created), skip the gate so lab chat works without RAG.
    if ( structKeyExists(server, "stylemart")
         && isArray(server.stylemart.ragFuturesLab ?: "")
         && arrayLen(server.stylemart.ragFuturesLab) > 0
         && !(server.stylemart.ragReadyLab ?: false) ) {
      emitter.emit( "model.start", { "model": "warming-up" } );
      emitter.emit( "model.delta", { "text": "I'm still loading product knowledge. Please try again in a couple of minutes." } );
      emitter.emit( "done", { "status": "warming_up" } );
      return;
    }

    emitter.logUserMessage( userText );

    var bridge = new api.agent.common.StreamBridge();
    bridge.open( request.messageId );

    var bundle = new AgentService().getOrCreateAgent( request.sessionId, request.userId );

    emitter.emit( "model.start", { "model": bundle.cfg.modelName } );

    try {
      var memory        = new api.agent.s5.lab.Memory();
      var lastAssistant = getLastAssistantText( request.sessionId );
      var extracted     = memory.extractPrefs( userText, bundle.model, request.userId, lastAssistant );
      if ( !structIsEmpty( extracted ) ) {
        try { memory.savePrefs( request.userId, extracted ); } catch (any e) {}
        emitter.emit( "preference.persist", {
          "fields": structKeyArray( extracted ),
          "values": extracted,
          "userId": request.userId
        } );
      }
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

      var validator    = new api.agent.s5.lab.PreferenceValidator( request.userId );
      var schemaFields = validator.describeFields();
      var cleanPrefs   = {};
      for ( var field in listToArray( schemaFields, "," ) ) {
        var key = trim( listFirst( field, " " ) );
        if ( structKeyExists( prefs, key ) ) cleanPrefs[ key ] = prefs[ key ];
      }

      var fullPrompt = "Known preferences: " & serializeJSON( cleanPrefs )
                     & "

User: " & userText;

      // Surface "retrieval starting" only when RAG vector stores are actually populated
      if ( structKeyExists(application, "ragVectorStoresLab") && !structIsEmpty(application.ragVectorStoresLab) ) {
        emitter.emit( "retrieval.start", {
          "query":      userText,
          "loaders":    [ "pdf", "csv" ],
          "maxResults": bundle.cfg.rag.maxResults ?: 4,
          "minScore":   bundle.cfg.rag.minScore   ?: 0.5
        } );
      }

      emitter.emit( "memory.read", { "messages": "managed-by-agent" } );

      // Re-assert the active queue id immediately before .chat() — MCP/RAG
      // initialization (which can interleave with streaming setup) may have
      // overwritten server.stylemart._streamQueueId, so the streamer wouldn't
      // know which queue to enqueue tokens onto.
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
