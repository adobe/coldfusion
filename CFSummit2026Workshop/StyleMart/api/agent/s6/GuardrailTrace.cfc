component {

  /**
   * Return only the shopper's actual typed turn from whatever string CF hands an
   * input guardrail. CF runs INPUT guardrails over the RAG-augmented message
   * (retrieved context + framing + the user's turn), so scanning the whole blob
   * causes false positives — e.g. a returns-policy chunk that reads "40% discount"
   * trips the discount guard regardless of what the shopper typed.
   *
   * Why the "User:" marker in fullMessage is authoritative (and request.userText is NOT):
   * With chatMemory.perUser=true, CF builds the per-user AI service once (on the first
   * turn) and CAPTURES that turn's CFML request scope. Every later turn's guardrails
   * execute inside that frozen context, so request.userText stays stuck at the FIRST
   * message — making input guards inspect stale text and silently pass turns 2+.
   * The fullMessage argument, by contrast, is passed fresh on every guardrail call and
   * always carries the current turn as "...\n\nUser: <typed text>" (ChatService builds
   * it that way). So we extract from fullMessage first and never let the frozen
   * request.userText override a real turn.
   *
   * Resolution order:
   *   1. text after the LAST "User:" marker in fullMessage — the live current turn.
   *   2. request.userText — only for marker-less calls running in a FRESH request scope
   *      (e.g. the verify-guardrail.cfm harness), never for the per-user chat path.
   *   3. "" — a marker-less, request-less call is the system-prompt seed CF issues from
   *      systemMessage(); returning empty makes guards no-op so they neither false-trip
   *      on retrieved/system text nor block agent construction.
   */
  public string function userTurn( required string fullMessage ) {
    var MARKER = "User:";
    var idx = arguments.fullMessage.lastIndexOf( MARKER );  // 0-based, -1 if absent
    if ( idx >= 0 ) {
      return trim( mid( arguments.fullMessage, idx + len( MARKER ) + 1, len( arguments.fullMessage ) ) );
    }
    if ( structKeyExists( request, "userText" ) && len( trim( request.userText ) ) ) {
      return request.userText;
    }
    return "";
  }

  /**
   * Emit a guardrail trace frame and append the outcome to request.guardrailResults.
   * Called from inside every guardrail CFC's validate() — never directly by attendees.
   *
   * out.result is the validate() return — one of "success" | "failure" | "fatal".
   *   success           -> emits guardrail.check    (passed:true)
   *   failure | fatal   -> emits guardrail.violation (with message + repromptMessage if set)
   *
   * The frame is queued into application.streams[queueId] (set up by ChatService at the
   * top of sendMessage()); the ChatService poll loop flushes it as SSE. RecoveryEmailService
   * also gets the guardrailResults via the request.guardrailResults collector, even though
   * it does not stream SSE.
   */
  public void function report(
    required string rule,
    required string phase,    // "input" | "output"
    required struct out
  ) {

    var passed = arguments.out.result == "success";

    var payload = {
      "rule":   arguments.rule,
      "phase":  arguments.phase,
      "passed": passed
    };
    if ( !passed ) {
      // Bracket notation preserves lowercase keys; dot notation would serialize as
      // RESULT/MESSAGE and the case-sensitive JS (trace.js/chat.js) would miss them.
      payload[ "result" ]  = arguments.out.result;
      payload[ "message" ] = arguments.out.message ?: "";
      if ( len( arguments.out.repromptMessage ?: "" ) ) {
        payload[ "repromptMessage" ] = arguments.out.repromptMessage;
      }
    }

    // 1. Append to request.guardrailResults so RecoveryEmailService can collect outcomes.
    if ( !structKeyExists( request, "guardrailResults" ) ) request.guardrailResults = [];
    arrayAppend( request.guardrailResults, {
      "rule":    arguments.rule,
      "phase":   arguments.phase,
      "result":  arguments.out.result,
      "passed":  passed,
      "message": arguments.out.message ?: "",
      "repromptMessage": arguments.out.repromptMessage ?: ""
    });

    // 2. Emit the SSE frame onto the same shared queue the Streamer + ChatService use
    //    (server.stylemart.streams keyed by server.stylemart._streamQueueId). The poll
    //    loop in ChatService.sendMessage drains it onto the SSE stream, so the trace
    //    panel's "guardrails" group renders guardrail.check / guardrail.violation.
    var queueId = "";
    try { queueId = server.stylemart._streamQueueId ?: ""; }
    catch ( any e ) { queueId = ""; }
    if ( len( queueId )
      && structKeyExists( server, "stylemart" )
      && structKeyExists( server.stylemart, "streams" )
      && structKeyExists( server.stylemart.streams, queueId ) ) {
      arrayAppend( server.stylemart.streams[ queueId ], {
        "type":    passed ? "guardrail.check" : "guardrail.violation",
        "payload": payload
      });
    }
  }
}
