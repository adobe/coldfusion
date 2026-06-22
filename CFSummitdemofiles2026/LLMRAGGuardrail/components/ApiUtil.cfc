component {
    public void function sendJson(required struct payload, numeric statusCode = 200) {
        cfheader(statuscode = arguments.statusCode);
        cfcontent(type = "application/json; charset=utf-8", reset = true);
        try {
            writeOutput(jsonSerialize(arguments.payload, { structKeyCase: "lower" }));
        } catch (any jsonEncodeError) {
            writeOutput(serializeJSON(arguments.payload, false));
        }
        abort;
    }

    public struct function getRequestJson() {
        var requestData = getHttpRequestData();
        if (!len(trim(structKeyExists(requestData, "content") ? requestData.content : ""))) {
            return {};
        }
        return deserializeJSON(requestData.content);
    }

    public any function readKey(required any value, required string key, any fallback = "") {
        if (isStruct(arguments.value)) {
            for (var candidate in structKeyArray(arguments.value)) {
                if (compareNoCase(candidate, arguments.key) == 0) {
                    return arguments.value[candidate];
                }
            }
        }
        return arguments.fallback;
    }
}
