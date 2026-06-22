component output=false {
    variables.chatConfig = {};
    variables.chatModel = "";

    public TrackedChatModel function init(required struct config) {
        variables.chatConfig = duplicate(config.chatConfig);
        variables.chatModel = ChatModel(variables.chatConfig);
        return this;
    }

    public any function chat(required string prompt, any trace = "", struct metadata = {}) {
        var span = "";
        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan("llm.chat", "ChatModel.chat", "", arguments.metadata);
        }

        try {
            var response = variables.chatModel.chat(arguments.prompt);
            finishSpan(span, "success");
            return response;
        } catch (any e) {
            finishSpan(span, "error", e);
            rethrow;
        }
    }

    public any function getNative() {
        return variables.chatModel;
    }

    private void function finishSpan(required any span, required string status, any error = "") {
        if (!isObject(arguments.span)) {
            return;
        }

        var payload = { status: arguments.status };
        if (isStruct(arguments.error)) {
            payload.errorType = arguments.error.type ?: "ColdFusion.AI.ChatModel";
            payload.errorMessage = arguments.error.message ?: "";
        }
        arguments.span.finish(payload);
    }
}
