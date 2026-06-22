component output=false {
    variables.ollamaBaseUrl = "http://localhost:11434";
    variables.chatModelName = "llama3.2";
    variables.embeddingModelName = "nomic-embed-text";

    public any function getChatModel(numeric temperature = 0.3) {
        try {
            return ChatModel({
                "provider": "ollama",
                "baseUrl": variables.ollamaBaseUrl,
                "modelName": variables.chatModelName,
                "temperature": arguments.temperature,
                "timeout": 60
            });
        }
        catch (any e) {
            throw(
                type="CFCase.AIUnavailable",
                message="ColdFusion AI ChatModel for Ollama is not available.",
                detail=e.message
            );
        }
    }

    public string function chat(required array messages, numeric temperature = 0.3) {
        var prompt = messagesToPrompt(arguments.messages);
        var telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
        var span = telemetry.startSpan(
            trace = telemetry.currentTrace(),
            operationType = "llm.chat",
            operationName = "CFCase Ollama chat",
            metadata = {
                messageCount: arrayLen(arguments.messages),
                temperature: arguments.temperature,
                localModel: true
            }
        );

        try {
            var model = getChatModel(arguments.temperature);
            var result = model.chat(prompt);
            var answer = "";

            if (isSimpleValue(result)) {
                answer = toString(result);
            } else if (isStruct(result)) {
                if (structKeyExists(result, "content")) {
                    answer = toString(result.content);
                } else if (structKeyExists(result, "text")) {
                    answer = toString(result.text);
                } else if (structKeyExists(result, "message")) {
                    answer = isStruct(result.message) && structKeyExists(result.message, "content")
                        ? toString(result.message.content)
                        : toString(result.message);
                } else {
                    answer = serializeJson(result);
                }
            } else {
                answer = serializeJson(result);
            }

            var inputTokens = telemetry.estimateTokens(prompt);
            var outputTokens = telemetry.estimateTokens(answer);
            telemetry.finishSpan(span, {
                status: "success",
                provider: "ollama",
                modelName: variables.chatModelName,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                totalTokens: inputTokens + outputTokens,
                promptText: prompt,
                responseText: answer,
                requestBytes: telemetry.estimateBytes(prompt),
                responseBytes: telemetry.estimateBytes(answer),
                metadata: {
                    localModel: true
                }
            });

            return answer;
        }
        catch (any e) {
            var failedInputTokens = telemetry.estimateTokens(prompt);
            telemetry.finishSpan(span, {
                status: "error",
                provider: "ollama",
                modelName: variables.chatModelName,
                inputTokens: failedInputTokens,
                totalTokens: failedInputTokens,
                promptText: prompt,
                requestBytes: telemetry.estimateBytes(prompt),
                errorType: structKeyExists(e, "type") ? e.type : "",
                errorMessage: e.message,
                metadata: {
                    localModel: true
                }
            });
            throw(
                type="CFCase.AIChatFailed",
                message="The local Ollama chat model failed.",
                detail=e.message
            );
        }
    }

    public string function messagesToPrompt(required array messages) {
        var out = "";

        for (var msg in arguments.messages) {
            var role = structKeyExists(msg, "role") ? uCase(msg.role) : "USER";
            var content = structKeyExists(msg, "content") ? msg.content : "";
            out &= role & ":" & chr(10) & content & chr(10) & chr(10);
        }

        return out;
    }

    public struct function getConfig() {
        return {
            "provider": "ollama",
            "baseUrl": variables.ollamaBaseUrl,
            "chatModel": variables.chatModelName,
            "embeddingModel": variables.embeddingModelName,
            "strict": true
        };
    }
}
