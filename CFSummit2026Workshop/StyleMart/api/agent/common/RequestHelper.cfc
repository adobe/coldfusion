component {

    public string function initRequest(required string sessionId, string userId = "") {
        var body = deserializeJSON(toString(getHttpRequestData().content));
        request.sessionId = arguments.sessionId;
        request.messageId = body.messageId ?: "msg_#lCase(replace(createUUID(), '-', '', 'all'))#";
        request.seq       = 0;
        if (len(arguments.userId)) request.userId = arguments.userId;
        return body.userText ?: "";
    }

    public struct function initStream(required string userText, boolean logMessage = true) {
        var emitter = new api.agent.common.TraceEmitter();
        emitter.initSSE();
        if (arguments.logMessage) emitter.logUserMessage(arguments.userText);
        var bridge = new api.agent.common.StreamBridge();
        bridge.open(request.messageId);
        return { "emitter": emitter, "bridge": bridge };
    }
}
