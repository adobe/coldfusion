/**
 * StreamHandler2.cfc — Streaming response handler for the AI Features Demo.
 *
 * Writes tokens to "demo-stream2" log file via writeLog().
 * stream_poll.cfm reads this log to reconstruct the streaming buffer.
 *
 * NOTE (CF 2025 bug): STREAMINGHANDLER callbacks run on Java ForkJoinPool
 * threads where CF scopes (application, variables, session, request) are
 * all null (SymTab_implicitCFScopes is null). Only writeLog() with literal
 * string args works. Do NOT reference any CF scope in these methods.
 *
 * @hint Handles streaming token callbacks from agent() STREAMINGHANDLER
 */
component {

    remote void function onPartialResponse(required string partialResponse) {
        writeLog(text="CHUNK:" & arguments.partialResponse, type="information", file="demo-stream2");
    }

    remote void function onCompleteResponse(required struct response) {
        msg = arguments.response.message ?: "";
        writeLog(text="DONE:" & len(msg), type="information", file="demo-stream2");
    }

    remote void function onError(required struct error) {
        writeLog(text="STREAMERROR:" & (arguments.error.message ?: "unknown"), type="error", file="demo-stream2");
    }

}
