component {

    public void function open(required string queueId) {
        if (!structKeyExists(server, "stylemart")) server.stylemart = {streams: {}};
        if (!structKeyExists(server.stylemart, "streams")) server.stylemart.streams = {};
        server.stylemart.streams[arguments.queueId] = [];
        server.stylemart._streamQueueId = arguments.queueId;
    }

    public void function activate(required string queueId) {
        server.stylemart._streamQueueId = arguments.queueId;
    }

    public void function poll(required string queueId, required any emitter) {
        var cursor = 0;
        var maxWait = 120000;
        var elapsed = 0;
        while (elapsed < maxWait) {
            if (structKeyExists(server.stylemart.streams, arguments.queueId) && arrayLen(server.stylemart.streams[arguments.queueId]) > cursor) {
                cursor++;
                var frame = server.stylemart.streams[arguments.queueId][cursor];
                emitter.emit(frame.type, frame.payload);
                if (frame.type == "done") return;
                elapsed = 0;
            } else {
                sleep(20);
                elapsed += 20;
            }
        }
        emitter.emit("error", {type: "chat.timeout", title: "Stream timed out", detail: "Stream timed out"});
        emitter.emit("done", {status: "error"});
    }

    // Used by S6 when a guardrail short-circuits a turn. The agent threw, so the
    // streamer never enqueues a "done" frame — instead, drain only guardrail.*
    // frames already on the queue and return immediately so the caller can emit
    // its own done(status:blocked) without waiting on the 120s poll timeout.
    public void function drainGuardrailOnly(required string queueId, required any emitter) {
        if (!structKeyExists(server.stylemart.streams, arguments.queueId)) return;
        var frames = server.stylemart.streams[arguments.queueId];
        for (var f in frames) {
            if (left(f.type, 10) == "guardrail.") emitter.emit(f.type, f.payload);
        }
    }

    public void function close(required string queueId) {
        if (structKeyExists(server, "stylemart") && structKeyExists(server.stylemart, "streams")) {
            structDelete(server.stylemart.streams, arguments.queueId);
        }
    }
}
