component output="false" {
    public void function sendJson(required struct payload, numeric statusCode = 200) {
        cfheader(statuscode = arguments.statusCode);
        cfheader(name = "Cache-Control", value = "no-store, no-cache, must-revalidate, max-age=0");
        cfheader(name = "Pragma", value = "no-cache");
        cfcontent(type = "application/json; charset=utf-8", reset = true);
        writeOutput(serializeJSON(arguments.payload));
        abort;
    }

    public struct function getRequestJson() {
        var requestData = getHttpRequestData();
        if (!len(trim(requestData.content ?: ""))) {
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

    public string function requestValue(required struct payload, required string key, string fallback = "") {
        var value = readKey(arguments.payload, arguments.key, "");
        if (!len(trim(value)) && structKeyExists(form, arguments.key)) {
            value = form[arguments.key];
        }
        if (!len(trim(value)) && structKeyExists(url, arguments.key)) {
            value = url[arguments.key];
        }
        return len(trim(value)) ? trim(value) : arguments.fallback;
    }
}
