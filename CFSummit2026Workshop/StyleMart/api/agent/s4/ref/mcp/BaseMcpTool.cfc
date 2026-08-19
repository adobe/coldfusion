component {

    private struct function startMcpCall(required string serverName, required string toolName, required struct args, string transport = "http") {
        var qid = "";
        try { qid = server.stylemart._streamQueueId ?: ""; } catch (any e) {}
        var callId = "mcp_" & left(lCase(replace(createUUID(), "-", "", "all")), 12);

        if (len(qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, qid)) {
            arrayAppend(server.stylemart.streams[qid], {
                "type": "mcp.call",
                "payload": {
                    "server":    arguments.serverName,
                    "toolName":  arguments.toolName,
                    "args":      arguments.args,
                    "callId":    callId,
                    "transport": arguments.transport
                }
            });
        }

        return {callId: callId, startTick: getTickCount(), qid: qid};
    }

    private void function endMcpCall(required struct ctx, required string status, string summary = "") {
        if (len(ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            arrayAppend(server.stylemart.streams[ctx.qid], {
                "type": "mcp.result",
                "payload": {
                    "callId":     ctx.callId,
                    "status":     arguments.status,
                    "durationMs": getTickCount() - ctx.startTick,
                    "summary":    arguments.summary
                }
            });
        }
    }
}
