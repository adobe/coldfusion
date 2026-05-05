/**
 * StreamBuffer.cfc — Streaming handler for Problem 6.
 *
 * CF 2025 constraint: STREAMINGHANDLER callbacks run on Java ForkJoinPool
 * threads where all CF scopes (application, server, session, request) are null.
 * Only writeLog() with literal string arguments works reliably.
 *
 * Strategy: Write TOKEN/DONE/ERROR entries to nexora-stream log.
 * The calling code writes a START:{streamId} marker before chat().
 * The watcher thread reads entries after the START marker.
 *
 * @hint Handles streaming token callbacks from agent() STREAMINGHANDLER
 */
component {

    remote void function onPartialResponse( required string partialResponse ) {
        writeLog( text="TOKEN:" & arguments.partialResponse, type="information", file="nexora-stream" );
    }

    remote void function onCompleteResponse( required struct response ) {
        var msg = "";
        try { msg = arguments.response.message ?: ""; } catch (any e) {}
        writeLog( text="DONE:" & len(msg), type="information", file="nexora-stream" );
    }

    remote void function onError( required struct error ) {
        writeLog( text="STREAMERROR:" & (arguments.error.message ?: "unknown"), type="error", file="nexora-stream" );
    }

}
