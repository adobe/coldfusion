/**
 * DO NOT MODIFY — Trace-emission infrastructure from Session 1.
 * Tool CFCs extend this to get startToolCall/endToolCall helpers.
 * You never need to edit or understand the internals here.
 */
component {

    private struct function startToolCall(required string toolName, required struct args) {
        var qid = server.stylemart._streamQueueId ?: "";
        var callId = "cal_" & lCase(left(replace(createUUID(), "-", "", "all"), 12));

        if (len(qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, qid)) {
            arrayAppend(server.stylemart.streams[qid], {
                "type": "tool.call",
                "payload": {
                    "toolName": arguments.toolName,
                    "kind": "cfc",
                    "args": arguments.args,
                    "callId": callId
                }
            });
        }

        return {"callId": callId, "startTick": getTickCount(), "qid": qid};
    }

    private void function endToolCall(required struct ctx, required string status, string summary="") {
        if (len(arguments.ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, arguments.ctx.qid)) {
            arrayAppend(server.stylemart.streams[arguments.ctx.qid], {
                "type": "tool.result",
                "payload": {
                    "callId": arguments.ctx.callId,
                    "status": arguments.status,
                    "durationMs": getTickCount() - arguments.ctx.startTick,
                    "summary": arguments.summary
                }
            });
        }
    }

    private void function emitActionRequired(required struct ctx, required struct payload) {
        if (len(arguments.ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, arguments.ctx.qid)) {
            arrayAppend(server.stylemart.streams[arguments.ctx.qid], {
                "type": "action.required",
                "payload": arguments.payload
            });
        }
    }
}
