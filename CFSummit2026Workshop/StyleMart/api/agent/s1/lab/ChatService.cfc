component rest="true" restpath="/s1/lab/chat" {

  MODEL_NAME = "gpt-4o-mini";

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
      /* ===== ATTENDEE TODO ZONE (Set system message) =========================== */

      /*
       TODO-S1-2: Apply the system prompt to the agent. S1 has no chat memory, so
       calling systemMessage() per turn is harmless — it just sets the persona for
       this call. (Session 2 introduces memory and you'll move this to one-time
       agent creation.) loadConfig() reads ai.properties fresh so persona/temp
       changes take effect on the very next message.
         Hint:
           var cfg = new AgentService().loadConfig();
           sessionAgent.systemMessage( cfg.systemPrompt );
      */
      /* TODO-S1-2 */

      /* ===== END ATTENDEE TODO ZONE ============================================= */

      if ( streaming ) {
        bridge.activate( request.messageId );
        /*
         TODO-S1-3: Invoke the cached agent in streaming mode. Returns IMMEDIATELY —
         tokens arrive via Streamer callbacks, which enqueue them onto
         server.stylemart.streams. bridge.poll() below drains that queue to SSE.
           Hint: sessionAgent.chat( userText );
        */
        bridge.poll( request.messageId, emitter );
      } else {
        /*
         TODO-S1-4: Invoke the cached agent in synchronous mode. Returns the FULL
         response struct — no callbacks, no queue. Then we hand the whole reply
         to the trace as a single model.delta and close out with done.
           Hint: var resp = sessionAgent.chat( userText );
        */
        emitter.emit( "model.delta", { "text": resp.message } );
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
}
