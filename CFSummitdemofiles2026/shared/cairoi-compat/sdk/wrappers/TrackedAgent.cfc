component output=false {
    variables.agentConfig = {};
    variables.chatConfig = {};
    variables.agent = "";

    public TrackedAgent function init(required struct config) {
        variables.agentConfig = duplicate(config.agentConfig);
        variables.chatConfig = readKey(variables.agentConfig, "chatConfig", {});

        if (isStruct(variables.chatConfig) && !structIsEmpty(variables.chatConfig)) {
            var chatModel = ChatModel(variables.chatConfig);
            variables.agent = Agent({ chatModel: chatModel });
        } else {
            variables.agent = Agent(variables.agentConfig);
        }

        return this;
    }

    public any function chat(required any message, any userId = "", any trace = "", struct metadata = {}) {
        var span = "";
        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan("agent.chat", "Agent.chat", "", arguments.metadata);
        }

        try {
            var response = "";
            if (len(trim(toString(arguments.userId)))) {
                response = variables.agent.chat(arguments.message, arguments.userId);
            } else {
                response = variables.agent.chat(arguments.message);
            }
            finishSpan(span, "success");
            return response;
        } catch (any e) {
            finishSpan(span, "error", e);
            rethrow;
        }
    }

    public any function systemMessage(required string message) {
        return variables.agent.systemMessage(arguments.message);
    }

    public any function getNative() {
        return variables.agent;
    }

    private void function finishSpan(required any span, required string status, any error = "") {
        if (!isObject(arguments.span)) {
            return;
        }

        var payload = { status: arguments.status };
        if (isStruct(arguments.error)) {
            payload.errorType = arguments.error.type ?: "ColdFusion.AI.Agent";
            payload.errorMessage = arguments.error.message ?: "";
        }
        arguments.span.finish(payload);
    }

    private any function readKey(any value = "", required string key, any fallback = "") {
        if (!isStruct(arguments.value)) {
            return arguments.fallback;
        }
        for (var candidate in structKeyArray(arguments.value)) {
            if (compareNoCase(candidate, arguments.key) == 0) {
                return arguments.value[candidate];
            }
        }
        return arguments.fallback;
    }
}
