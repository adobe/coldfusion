component rest="true" restpath="/s5/ref/chat" {

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

    new AgentService().getOrCreateAgent( sessionId, userId );

    var prefs = {};
    try { prefs = application.services.user.getPreferences(userId=userId); } catch (any e) {}

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
    application.services.user.deletePreferences(userId=userId);
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

    if ( !structKeyExists(server, "stylemart") || !(server.stylemart.ragReadyRef ?: false) ) {
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
      var prefs = {};
      try { prefs = application.services.user.getPreferences(userId=request.userId); } catch (any e) {}

      var fullPrompt = "Known preferences: " & serializeJSON( prefs )
                     & "

User: " & userText;

      if ( structKeyExists(application, "ragVectorStoresRef") && !structIsEmpty(application.ragVectorStoresRef) ) {
        emitter.emit( "retrieval.start", {
          "query":      userText,
          "loaders":    [ "pdf", "csv" ],
          "maxResults": bundle.cfg.rag.maxResults ?: 4,
          "minScore":   bundle.cfg.rag.minScore   ?: 0.5
        } );
      }

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
}
