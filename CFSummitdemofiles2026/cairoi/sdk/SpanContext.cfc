component output=false {
    variables.trace = "";
    variables.hashUtil = "";
    variables.spanId = "";
    variables.traceId = "";
    variables.parentSpanId = "";
    variables.appId = "";
    variables.environment = "dev";
    variables.workflowName = "";
    variables.operationType = "custom";
    variables.operationName = "";
    variables.provider = "";
    variables.modelName = "";
    variables.startedAt = now();
    variables.startedTick = getTickCount();
    variables.endedAt = "";
    variables.durationMs = 0;
    variables.status = "running";
    variables.inputTokens = 0;
    variables.outputTokens = 0;
    variables.totalTokens = 0;
    variables.inputTokenSource = "missing";
    variables.outputTokenSource = "missing";
    variables.totalTokenSource = "missing";
    variables.estimatedCost = 0;
    variables.costSource = "";
    variables.promptHash = "";
    variables.responseHash = "";
    variables.promptChars = 0;
    variables.responseChars = 0;
    variables.requestBytes = 0;
    variables.responseBytes = 0;
    variables.errorType = "";
    variables.errorMessage = "";
    variables.metadata = {};
    variables.addedToTrace = false;

    public SpanContext function init(required struct config) {
        variables.trace = readKey(arguments.config, "trace", "");
        variables.hashUtil = readKey(arguments.config, "hashUtil", "");
        variables.spanId = readKey(arguments.config, "spanId", "spn_" & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")));
        variables.traceId = readKey(arguments.config, "traceId", isObject(variables.trace) ? variables.trace.getTraceId() : "");
        variables.parentSpanId = readKey(arguments.config, "parentSpanId", "");
        variables.appId = readKey(arguments.config, "appId", "");
        variables.environment = readKey(arguments.config, "environment", "dev");
        variables.workflowName = readKey(arguments.config, "workflowName", "");
        variables.operationType = normalizeOperationType(readKey(arguments.config, "operationType", "custom"));
        variables.operationName = readKey(arguments.config, "operationName", "");
        variables.provider = readKey(arguments.config, "provider", "");
        variables.modelName = readKey(arguments.config, "modelName", "");
        variables.metadata = sanitizeMetadata(readKey(arguments.config, "metadata", {}));
        return this;
    }

    public SpanContext function finish(struct data = {}) {
        if (len(variables.endedAt)) {
            return this;
        }

        variables.endedAt = now();
        variables.durationMs = getTickCount() - variables.startedTick;
        variables.status = readKey(arguments.data, "status", "success");
        variables.provider = readKey(arguments.data, "provider", variables.provider);
        variables.modelName = readKey(arguments.data, "modelName", variables.modelName);
        variables.operationName = readKey(arguments.data, "operationName", variables.operationName);

        variables.inputTokens = val(readKey(arguments.data, "inputTokens", variables.inputTokens));
        variables.outputTokens = val(readKey(arguments.data, "outputTokens", variables.outputTokens));
        variables.totalTokens = val(readKey(arguments.data, "totalTokens", variables.totalTokens));
        if (!variables.totalTokens && (variables.inputTokens || variables.outputTokens)) {
            variables.totalTokens = variables.inputTokens + variables.outputTokens;
        }

        variables.inputTokenSource = readKey(arguments.data, "inputTokenSource", variables.inputTokenSource);
        variables.outputTokenSource = readKey(arguments.data, "outputTokenSource", variables.outputTokenSource);
        variables.totalTokenSource = readKey(arguments.data, "totalTokenSource", variables.totalTokenSource);
        variables.estimatedCost = numericValue(readKey(arguments.data, "estimatedCost", variables.estimatedCost));
        variables.costSource = readKey(arguments.data, "costSource", variables.costSource);
        variables.requestBytes = val(readKey(arguments.data, "requestBytes", variables.requestBytes));
        variables.responseBytes = val(readKey(arguments.data, "responseBytes", variables.responseBytes));

        var promptText = readKey(arguments.data, "promptText", "");
        var responseText = readKey(arguments.data, "responseText", "");
        variables.promptHash = readKey(arguments.data, "promptHash", variables.promptHash);
        variables.responseHash = readKey(arguments.data, "responseHash", variables.responseHash);
        variables.promptChars = val(readKey(arguments.data, "promptChars", variables.promptChars));
        variables.responseChars = val(readKey(arguments.data, "responseChars", variables.responseChars));

        if (len(promptText)) {
            variables.promptChars = len(promptText);
            variables.promptHash = hashValue(promptText);
        }
        if (len(responseText)) {
            variables.responseChars = len(responseText);
            variables.responseHash = hashValue(responseText);
        }

        variables.errorType = sanitizeString(readKey(arguments.data, "errorType", variables.errorType), 200);
        variables.errorMessage = sanitizeString(readKey(arguments.data, "errorMessage", variables.errorMessage), 2000);
        variables.metadata = mergeStructs(variables.metadata, sanitizeMetadata(readKey(arguments.data, "metadata", {})));

        if (!variables.addedToTrace && isObject(variables.trace)) {
            variables.trace.addSpan(this);
            variables.addedToTrace = true;
        }

        return this;
    }

    public struct function toStruct() {
        return {
            spanId: variables.spanId,
            traceId: variables.traceId,
            parentSpanId: variables.parentSpanId,
            appId: variables.appId,
            environment: variables.environment,
            workflowName: variables.workflowName,
            operationType: variables.operationType,
            operationName: variables.operationName,
            provider: variables.provider,
            modelName: variables.modelName,
            startedAt: formatDate(variables.startedAt),
            endedAt: len(variables.endedAt) ? formatDate(variables.endedAt) : "",
            durationMs: variables.durationMs,
            status: variables.status,
            inputTokens: variables.inputTokens,
            outputTokens: variables.outputTokens,
            totalTokens: variables.totalTokens,
            inputTokenSource: variables.inputTokenSource,
            outputTokenSource: variables.outputTokenSource,
            totalTokenSource: variables.totalTokenSource,
            estimatedCost: variables.estimatedCost,
            costSource: variables.costSource,
            promptHash: variables.promptHash,
            responseHash: variables.responseHash,
            promptChars: variables.promptChars,
            responseChars: variables.responseChars,
            requestBytes: variables.requestBytes,
            responseBytes: variables.responseBytes,
            errorType: variables.errorType,
            errorMessage: variables.errorMessage,
            metadata: duplicate(variables.metadata)
        };
    }

    public string function getSpanId() {
        return variables.spanId;
    }

    private string function hashValue(required string value) {
        if (isObject(variables.hashUtil)) {
            return variables.hashUtil.hashNullable(arguments.value);
        }
        return lcase(hash(arguments.value, "SHA-256", "UTF-8"));
    }

    private struct function mergeStructs(required struct leftStruct, required struct rightStruct) {
        var merged = duplicate(arguments.leftStruct);
        for (var key in structKeyArray(arguments.rightStruct)) {
            merged[key] = arguments.rightStruct[key];
        }
        return merged;
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

    private string function normalizeOperationType(required string operationType) {
        var allowed = "llm.chat,agent.chat,agent.tool_request,agent.tool_result,rag.ingest,rag.retrieve,rag.context_assembly,rag.generate,embedding.embed,embedding.embed_batch,vector.add,vector.add_batch,vector.search,vector.delete,mcp.list_tools,mcp.call_tool,mcp.read_resource,mcp.get_prompt,guardrail.input,guardrail.output,custom";
        return listFindNoCase(allowed, arguments.operationType) ? lcase(arguments.operationType) : "custom";
    }

    private struct function sanitizeMetadata(any metadata = {}) {
        var clean = {};
        if (!isStruct(arguments.metadata)) {
            return clean;
        }

        for (var key in structKeyArray(arguments.metadata)) {
            if (isSensitiveKey(key)) {
                continue;
            }
            var value = arguments.metadata[key];
            if (isNull(value)) {
                clean[key] = "";
            } else if (isSimpleValue(value)) {
                clean[key] = sanitizeString(toString(value), 1000);
            } else if (isArray(value)) {
                clean[key] = "array(" & arrayLen(value) & ")";
            } else if (isStruct(value)) {
                clean[key] = sanitizeMetadata(value);
            } else {
                clean[key] = "complex";
            }
        }

        return clean;
    }

    private boolean function isSensitiveKey(required string key) {
        var lowered = lcase(arguments.key);
        for (var pattern in ["password", "secret", "token", "apikey", "api_key", "authorization", "bearer", "prompt", "response", "content", "document", "chunk", "sourceText"]) {
            if (find(pattern, lowered)) {
                return true;
            }
        }
        return false;
    }

    private string function sanitizeString(any value = "", numeric maxLength = 1000) {
        var text = isSimpleValue(arguments.value) ? toString(arguments.value) : serializeJSON(arguments.value);
        text = reReplace(text, "(?i)(bearer\s+)[A-Za-z0-9._\-]+", "\1[redacted]", "all");
        text = reReplace(text, "(?i)(api[_-]?key\s*[:=]\s*)[A-Za-z0-9._\-]+", "\1[redacted]", "all");
        text = reReplace(text, "(?i)(password\s*[:=]\s*)\S+", "\1[redacted]", "all");
        return left(text, arguments.maxLength);
    }

    private numeric function numericValue(any value = 0) {
        if (isNull(arguments.value)) {
            return 0;
        }
        try {
            return createObject("java", "java.lang.Double").parseDouble(trim(toString(arguments.value)));
        } catch (any ignored) {
            return val(arguments.value);
        }
    }

    private string function formatDate(required date value) {
        return dateTimeFormat(arguments.value, "yyyy-mm-dd HH:nn:ss");
    }
}
