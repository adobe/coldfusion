component {

    public void function initSSE() {
        var response = getPageContext().getResponse();
        response.setContentType("text/event-stream; charset=UTF-8");
        response.setHeader("Cache-Control", "no-cache");
        response.setHeader("Connection", "keep-alive");
    }

    public void function logUserMessage(required string text) {
        persist("user.message", {text: arguments.text}, 0);
    }

    public void function emit(required string evtType, required struct payload) {
        var LF = chr(10);
        request.seq = (request.seq ?: 0) + 1;
        var frame = {
            "sessionId": request.sessionId,
            "messageId": request.messageId,
            "seq":       request.seq,
            "ts":        dateTimeFormat(dateConvert("local2Utc", now()), "yyyy-mm-dd'T'HH:nn:ss.lll'Z'"),
            "type":      arguments.evtType,
            "payload":   arguments.payload
        };
        writeOutput("data: " & serializeJSON(frame) & LF & LF);
        getPageContext().getOut().flush();
        persist(arguments.evtType, arguments.payload, request.seq);
    }

    private void function persist(required string evtType, required struct payload, required numeric seq) {
        try {
            queryExecute(
                "INSERT INTO agent_traces (session_id, message_id, seq, type, payload_json, ts)
                 VALUES (:sid, :mid, :seq, :evtType, :payload, :ts)",
                {
                    sid:     {value: request.sessionId,                cfsqltype: "cf_sql_varchar"},
                    mid:     {value: request.messageId,                cfsqltype: "cf_sql_varchar"},
                    seq:     {value: int(arguments.seq),               cfsqltype: "cf_sql_integer"},
                    evtType: {value: arguments.evtType,                cfsqltype: "cf_sql_varchar"},
                    payload: {value: serializeJSON(arguments.payload), cfsqltype: "cf_sql_longvarchar"},
                    ts:      {value: now(),                            cfsqltype: "cf_sql_timestamp"}
                },
                {datasource: "stylemart"}
            );
        } catch (any e) {}
    }
}
