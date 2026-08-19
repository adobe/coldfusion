component rest="true" restpath="/s1/ref/chat" {

  MODEL_NAME = "gpt-4o-mini";

  remote void function sendMessage(
    required string sessionId restargsource="path"
  ) httpmethod="POST" restpath="sessions/{sessionId}/messages" produces="text/event-stream" {
    
    var helper   = new api.agent.common.RequestHelper();
    var userText = helper.initRequest( arguments.sessionId );
    var stream   = helper.initStream( userText, false );
    var emitter  = stream.emitter;
    var bridge   = stream.bridge;

    // Streaming flag — true drives the SSE bridge.poll path; flip to false to run
    // a fully synchronous chat call that emits one consolidated model.end + done.
    // Toggle this and re-send a message to compare the two transport modes.
    var streaming = true;

    var sessionAgent = new AgentService().getOrCreateAgent( request.sessionId, streaming );

    emitter.emit( "model.start", { "model": MODEL_NAME } );

    try {
      var cfg = new AgentService().loadConfig();
      sessionAgent.systemMessage( cfg.systemPrompt );

      if ( streaming ) {
        bridge.activate( request.messageId );
        sessionAgent.chat( userText );
        bridge.poll( request.messageId, emitter );
      } else {
        var resp = sessionAgent.chat( userText );
        emitter.emit( "model.delta", { "text": resp.message });
        emitter.emit( "done", { "status": "ok" } );
      }
    }
    catch ( any e ) {
      emitter.emit( "error", {
        "type":   "chat.unexpected",
        "title":  "Assistant unavailable",
        "detail": e.message
      } );
      emitter.emit( "done", { "status": "error" } );
    }
    finally {
      bridge.close( request.messageId );
    }
  }

  remote struct function openSession() httpmethod="POST" restpath="sessions" produces="application/json" {
    var sessionId = "ses_" & lCase( replace( createUUID(), "-", "", "all" ) );
    new AgentService().getOrCreateAgent( sessionId );
    return {
      "sessionId": sessionId,
      "createdAt": dateTimeFormat( now(), "yyyy-mm-dd'T'HH:nn:ss'Z'" )
    };
  }

  remote struct function resetSession(
    required string sessionId restargsource="path"
  ) httpmethod="POST" restpath="sessions/{sessionId}/reset" {
    new AgentService().evict( arguments.sessionId );
    return { "status": "reset" };
  }

  remote array function getHistory(
    required string sessionId restargsource="path"
  ) httpmethod="GET" restpath="sessions/{sessionId}/messages" {
    return [];
  }

}
