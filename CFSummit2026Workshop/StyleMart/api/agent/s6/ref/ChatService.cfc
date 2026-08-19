component rest="true" restpath="/s6/ref/chat" {

    STREAMER_CFC = "api.agent.s6.ref.Streamer";
    MODE         = "ref";

    private string function resolveUserId() {
        var u = "";
        try { u = getAuthUser(); } catch (any e) {}
        if (!isNull(u) && len(trim(u))) return trim(u);
        // The REST "agent" app may not share the storefront's cflogin session, so
        // getAuthUser() comes back empty for an unauthenticated request. Honor the
        // X-Shopper-Id header the frontend always sends before falling back to the
        // demo user. Without this, preference reads/resets target "demo-shopper-001"
        // while the storefront reads/writes "usr_demo_001", so reset deletes nothing.
        var headers = getHttpRequestData(false).headers;
        if (structKeyExists(headers, "X-Shopper-Id") && len(trim(headers["X-Shopper-Id"]))) {
            return trim(headers["X-Shopper-Id"]);
        }
        return "demo-shopper-001";
    }

    remote struct function openSession() httpmethod="POST" restpath="sessions" produces="application/json" {
        var sessionId = "ses_" & lCase(replace(createUUID(), "-", "", "all"));
        var userId = resolveUserId();
        var prefs = {};
        try { prefs = application.services.user.getPreferences(userId=userId); } catch (any e) {}

        // Build ChatModel + agent (with MCP, RAG, and guardrails) once for this
        // session so the first user message doesn't pay the construction cost.
        new AgentService().getOrCreateAgent(sessionId, userId);

        return {"sessionId": sessionId, "createdAt": dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss'Z'"), "userId": userId, "savedPrefs": prefs};
    }

    remote struct function resetSession(required string sessionId restargsource="path") httpmethod="POST" restpath="sessions/{sessionId}/reset" {
        // The cached agent owns the conversation memory; evicting it is the only
        // way to truly wipe memory (mirrors S2). The new sessionId is returned so
        // the client switches to a fresh server-side agent.
        new AgentService().evict(arguments.sessionId);
        return {"status": "reset", "sessionId": "ses_" & lCase(replace(createUUID(), "-", "", "all")), "userId": resolveUserId()};
    }

    remote struct function resetPreferences(required string sessionId restargsource="path") httpmethod="DELETE" restpath="sessions/{sessionId}/preferences" {
        var userId = resolveUserId();
        application.services.user.deletePreferences(userId=userId);
        return {"status": "deleted", "userId": userId};
    }

    remote array function getMessages(required string sessionId restargsource="path") httpmethod="GET" restpath="sessions/{sessionId}/messages" {
        var rows = queryExecute(
            "SELECT seq, type, payload_json, ts FROM agent_traces
             WHERE session_id = :sid AND type IN ('user.message','model.end') ORDER BY id ASC",
            {sid: {value: arguments.sessionId, cfsqltype: "cf_sql_varchar"}},
            {datasource: "stylemart"}
        );
        var transcript = [];
        for (var i = 1; i <= rows.recordCount; i++) {
            var payload = deserializeJSON(rows.payload_json[i]);
            arrayAppend(transcript, {
                "role": rows.type[i] == "user.message" ? "user" : "assistant",
                "content": payload.text ?: "",
                "ts": dateTimeFormat(rows.ts[i], "yyyy-mm-dd'T'HH:nn:ss'Z'")
            });
        }
        return transcript;
    }

    remote void function sendMessage(required string sessionId restargsource="path") httpmethod="POST" restpath="sessions/{sessionId}/messages" produces="text/event-stream" {
        var body = deserializeJSON(toString(getHttpRequestData().content));
        request.sessionId = arguments.sessionId;
        request.messageId = body.messageId ?: "msg_#lCase(replace(createUUID(), '-', '', 'all'))#";
        request.seq = 0;
        request.userId = resolveUserId();
        request.guardrailResults = [];
        var userText = body.userText ?: "";
        // Authoritative source of the shopper's typed turn for input guardrails.
        // CF runs input guards over the RAG-augmented prompt; GuardrailTrace.userTurn()
        // reads this so guards inspect intent only, not retrieved context (e.g. a
        // returns-policy chunk that mentions "40% discount").
        request.userText = userText;

        var response = getPageContext().getResponse();
        response.setContentType("text/event-stream");
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Connection", "keep-alive");

        if (!structKeyExists(server, "stylemart") || !(server.stylemart.ragReadyRef ?: false)) {
            emitFrame("model.start", {"model": "warming-up"});
            emitFrame("model.delta", {"text": "I'm still loading product knowledge. Please try again in a couple of minutes."});
            emitFrame("done", {"status": "warming_up"});
            return;
        }

        queryExecute(
            "INSERT INTO agent_traces (session_id, message_id, seq, type, payload_json, ts)
             VALUES (:sid, :mid, :seq, :evtType, :payload, :ts)",
            {sid:{value:request.sessionId,cfsqltype:"cf_sql_varchar"}, mid:{value:request.messageId,cfsqltype:"cf_sql_varchar"}, seq:{value:0,cfsqltype:"cf_sql_integer"}, evtType:{value:"user.message",cfsqltype:"cf_sql_varchar"}, payload:{value:serializeJSON({text:userText}),cfsqltype:"cf_sql_longvarchar"}, ts:{value:now(),cfsqltype:"cf_sql_timestamp"}},
            {datasource: "stylemart"}
        );

        var queueId = request.messageId;
        if (!structKeyExists(server, "stylemart")) server.stylemart = {};
        if (!structKeyExists(server.stylemart, "streams")) server.stylemart.streams = {};
        server.stylemart.streams[queueId] = [];
        server.stylemart._streamQueueId = queueId;

        // ChatModel + agent + MCP + RAG + guardrails are built once per session by
        // AgentService.getOrCreateAgent and cached in application.s6Agents[sessionId].
        // Pull the cached bundle here so each turn reuses the same instances.
        local.bundle = new AgentService().getOrCreateAgent(request.sessionId, request.userId);
        local.cfg    = local.bundle.cfg;

        emitFrame("model.start", {"model": local.cfg.modelName});

        try {
            emitFrame("memory.read", {"messages": "managed-by-agent"});

            // Replay diagnostics captured while building the cached agent (MCP/RAG).
            for (var bf in local.bundle.buildFrames) {
                emitFrame(bf.type, bf.payload);
            }

            if (local.bundle.ragActive) {
                emitFrame("retrieval.start", {
                    "query": userText,
                    "loaders": ["pdf", "csv"],
                    "maxResults": local.bundle.ragCfg.maxResults ?: 4,
                    "minScore": local.bundle.ragCfg.minScore ?: 0.5
                });
            }

            // The system prompt lives on the cached agent (set once in
            // AgentService.getOrCreateAgent via .systemMessage()), so we ship only
            // the per-turn dynamic preferences + user text in the user channel
            // (mirrors S2).
            var prefs = {};
            try { prefs = application.services.user.getPreferences(userId=request.userId); } catch (any e) {}
            var fullPrompt = "Known preferences: " & serializeJSON(prefs) & "

User: " & userText;

            var guardrailBlocked = false;
            try {
                local.bundle.agent.chat(fullPrompt, request.userId);
            } catch (any chatErr) {
                // CF's agent() BIF throws when a guardrail returns failure/fatal. The guardrail
                // CFC has already queued guardrail.violation frame(s) via GuardrailTrace.report();
                // we drain those below and emit a clean done(status:blocked) instead of bubbling
                // to the generic chat.unexpected handler.
                if ( findNoCase("Guardrail validation failed", chatErr.message)
                  || findNoCase("CfcInputGuardrail",         chatErr.message)
                  || findNoCase("CfcOutputGuardrail",        chatErr.message)
                  || findNoCase("guardrail",                 chatErr.message) ) {
                    guardrailBlocked = true;
                } else {
                    rethrow;
                }
            }

            // Poll the stream queue for events from Streamer + tools (and any queued guardrail frames)
            var cursor = 0;
            var maxWait = guardrailBlocked ? 1000 : 120000;
            var elapsed = 0;
            while (elapsed < maxWait) {
                if (arrayLen(server.stylemart.streams[queueId]) > cursor) {
                    cursor++;
                    var frame = server.stylemart.streams[queueId][cursor];
                    if (guardrailBlocked) {
                        // The turn was blocked by a guardrail. Surface only the
                        // guardrail.* frame(s); suppress the framework's generic
                        // streaming error/done so the block ends as one clean event.
                        if (left(frame.type, 10) == "guardrail.") emitFrame(frame.type, frame.payload);
                    } else {
                        emitFrame(frame.type, frame.payload);
                        if (frame.type == "done") break;
                    }
                    elapsed = 0;
                } else {
                    if (guardrailBlocked) break;
                    sleep(20);
                    elapsed += 20;
                }
            }

            if (guardrailBlocked) {
                emitFrame("done", {"status": "blocked"});
            } else if (elapsed >= maxWait) {
                emitFrame("error", {"type": "chat.timeout", "title": "Stream timed out", "detail": "Stream timed out", "rule": "timeout"});
                emitFrame("done", {"status": "error"});
            }

            if (!guardrailBlocked) emitFrame("memory.write", {"messages": "appended-by-agent"});
        }
        catch (any e) {
            emitFrame("error", {"type": "chat.unexpected", "title": "Assistant unavailable", "detail": e.message, "rule": "internal"});
            emitFrame("done", {"status": "error"});
        }
        finally {
            structDelete(server.stylemart.streams, queueId);
        }
    }

    private void function emitFrame(required string evtType, required struct payload) {
        var LF = chr(10);
        request.seq = (request.seq ?: 0) + 1;
        writeOutput("data: " & serializeJSON({
            "sessionId": request.sessionId, "messageId": request.messageId,
            "seq": request.seq,
            "ts": dateTimeFormat(dateConvert("local2Utc", now()), "yyyy-mm-dd'T'HH:nn:ss.lll'Z'"),
            "type": arguments.evtType, "payload": arguments.payload
        }) & LF & LF);
        getPageContext().getOut().flush();

        try {
            queryExecute(
                "INSERT INTO agent_traces (session_id, message_id, seq, type, payload_json, ts) VALUES (:sid, :mid, :seq, :evtType, :payload, :ts)",
                {sid:{value:request.sessionId,cfsqltype:"cf_sql_varchar"}, mid:{value:request.messageId,cfsqltype:"cf_sql_varchar"}, seq:{value:request.seq,cfsqltype:"cf_sql_integer"}, evtType:{value:arguments.evtType,cfsqltype:"cf_sql_varchar"}, payload:{value:serializeJSON(arguments.payload),cfsqltype:"cf_sql_longvarchar"}, ts:{value:now(),cfsqltype:"cf_sql_timestamp"}},
                {datasource: "stylemart"}
            );
        } catch (any e) {}
    }

    private string function getLastAssistantText(required string sessionId) {
        try {
            var q = queryExecute(
                "SELECT payload_json FROM agent_traces
                  WHERE session_id = :sid AND type = 'model.end'
                  ORDER BY id DESC",
                {sid: {value: arguments.sessionId, cfsqltype: "cf_sql_varchar"}},
                {datasource: "stylemart", maxrows: 1}
            );
            if (q.recordCount == 0) return "";
            var payload = deserializeJSON(q.payload_json[1]);
            return payload.text ?: "";
        } catch (any e) {
            return "";
        }
    }
}
