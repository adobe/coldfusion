component {

  // Resolve the active stream queue, or "" if none. Streaming callbacks fire on
  // ForkJoinPool worker threads outside the originating request, so the queue
  // may be missing entirely (warm-up call before sendMessage opened one) or
  // already closed (late callback after bridge.close()). Returning "" makes
  // each callback a no-op instead of throwing into the worker pool.
  private string function activeQueueId() {
    if ( !structKeyExists(server, "stylemart") ) return "";
    if ( !structKeyExists(server.stylemart, "_streamQueueId") ) return "";
    var qid = server.stylemart._streamQueueId;
    if ( !len(qid) ) return "";
    if ( !structKeyExists(server.stylemart, "streams") ) return "";
    if ( !structKeyExists(server.stylemart.streams, qid) ) return "";
    return qid;
  }

  remote void function onPartialResponse( required string partialResponse ) {
    var qid = activeQueueId();
    if ( !len(qid) ) return;
    arrayAppend( server.stylemart.streams[qid], {
      "type": "model.delta",
      "payload": { "text": arguments.partialResponse }
    } );
  }

  remote void function onCompleteResponse( required struct response ) {
    var qid = activeQueueId();
    if ( !len(qid) ) return;
    arrayAppend( server.stylemart.streams[qid], {
      "type": "model.end",
      "payload": {
        "text":   arguments.response.message  ?: "",
        "tokens": arguments.response.metadata ?: {}
      }
    } );
    arrayAppend( server.stylemart.streams[qid], {
      "type": "done",
      "payload": { "status": "ok" }
    } );
  }

  remote void function onError( required struct error ) {
    var qid = activeQueueId();
    if ( !len(qid) ) return;
    arrayAppend( server.stylemart.streams[qid], {
      "type": "error",
      "payload": { "detail": arguments.error.message ?: "Streaming error" }
    } );
    arrayAppend( server.stylemart.streams[qid], {
      "type": "done",
      "payload": { "status": "error" }
    } );
  }
}
