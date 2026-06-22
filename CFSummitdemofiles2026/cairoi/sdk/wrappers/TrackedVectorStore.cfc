component output=false {
    variables.cairoi = "";
    variables.vectorConfig = {};
    variables.vectorStore = "";

    public TrackedVectorStore function init(required struct config) {
        variables.cairoi = config.cairoi;
        variables.vectorConfig = duplicate(config.vectorConfig);
        variables.vectorStore = structIsEmpty(variables.vectorConfig) ? VectorStore() : VectorStore(variables.vectorConfig);
        return this;
    }

    public any function add(required any item, any trace = "", struct metadata = {}) {
        return trackedCall("vector.add", "VectorStore.add", arguments.item, arguments.trace, mergeStructs(vectorMetadata(), arguments.metadata), function() {
            return variables.vectorStore.add(item);
        });
    }

    public any function addAll(required array items, any trace = "", struct metadata = {}) {
        var safeMetadata = mergeStructs(vectorMetadata(), { itemCount: arrayLen(arguments.items) });
        safeMetadata = mergeStructs(safeMetadata, arguments.metadata);
        return trackedCall("vector.add_batch", "VectorStore.addAll", { itemCount: arrayLen(arguments.items) }, arguments.trace, safeMetadata, function() {
            return variables.vectorStore.addAll(items);
        });
    }

    public any function search(required any query, any trace = "", struct metadata = {}) {
        var safeMetadata = mergeStructs(vectorMetadata(), searchMetadata(arguments.query));
        safeMetadata = mergeStructs(safeMetadata, arguments.metadata);
        return trackedCall("vector.search", "VectorStore.search", safeMetadata, arguments.trace, safeMetadata, function() {
            return variables.vectorStore.search(query);
        });
    }

    public any function delete(required any request, any trace = "", struct metadata = {}) {
        var nativeRequest = arguments.request;
        return trackedCall("vector.delete", "VectorStore.delete", summarizeRequest(arguments.request), arguments.trace, mergeStructs(vectorMetadata(), arguments.metadata), function() {
            return variables.vectorStore.delete(nativeRequest);
        });
    }

    public any function deleteAll(any trace = "", struct metadata = {}) {
        return trackedCall("vector.delete", "VectorStore.deleteAll", {}, arguments.trace, mergeStructs(vectorMetadata(), arguments.metadata), function() {
            return variables.vectorStore.deleteAll();
        });
    }

    public any function getNative() {
        return variables.vectorStore;
    }

    private any function trackedCall(
        required string operationType,
        required string operationName,
        any requestPayload = "",
        any trace = "",
        struct metadata = {},
        required any callback
    ) {
        var span = "";
        var response = "";
        var requestBytes = isSimpleValue(arguments.requestPayload) ? len(toString(arguments.requestPayload)) : len(serializeJSON(arguments.requestPayload));

        if (isObject(arguments.trace)) {
            span = arguments.trace.startSpan(arguments.operationType, arguments.operationName, "", arguments.metadata);
        }

        try {
            response = arguments.callback();
            if (isObject(span)) {
                var finishData = {
                    status: "success",
                    requestBytes: requestBytes,
                    responseBytes: isSimpleValue(response) ? len(toString(response)) : len(serializeJSON(response)),
                    metadata: { resultCount: isArray(response) ? arrayLen(response) : 0 }
                };
                span.finish(finishData);
            }
            return response;
        } catch (any e) {
            if (isObject(span)) {
                span.finish({
                    status: "error",
                    requestBytes: requestBytes,
                    errorType: e.type ?: "ColdFusion.AI.VectorStore",
                    errorMessage: e.message
                });
            }
            rethrow;
        }
    }

    private struct function vectorMetadata() {
        return {
            provider: readKey(variables.vectorConfig, "provider", readKey(variables.vectorConfig, "storeType", "")),
            collectionName: readKey(variables.vectorConfig, "collectionName", readKey(variables.vectorConfig, "collection", ""))
        };
    }

    private struct function searchMetadata(any query = "") {
        var result = {};
        if (isStruct(arguments.query)) {
            var queryText = readKey(arguments.query, "text", readKey(arguments.query, "query", ""));
            if (len(queryText)) {
                result.queryHash = variables.cairoi.getHashUtil().hashNullable(queryText);
                result.queryChars = len(queryText);
            }
            result.topK = readKey(arguments.query, "topK", "");
            result.minScore = readKey(arguments.query, "minScore", "");
            result.hasMetadataFilter = isStruct(readKey(arguments.query, "metadata", {})) && !structIsEmpty(readKey(arguments.query, "metadata", {}));
        }
        return result;
    }

    private any function summarizeRequest(any request = "") {
        if (isSimpleValue(arguments.request)) {
            return left(toString(arguments.request), 200);
        }
        if (isStruct(arguments.request)) {
            return structKeyArray(arguments.request);
        }
        return "complex";
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
}
