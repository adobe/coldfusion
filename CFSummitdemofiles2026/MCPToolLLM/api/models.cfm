<cfsetting showdebugoutput="false">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
}

function getRequestJson() {
    var requestData = getHttpRequestData();
    if (!len(trim(requestData.content))) {
        return {};
    }
    return deserializeJSON(requestData.content);
}

function readKey(required any value, required string key, any fallback = "") {
    if (isStruct(arguments.value)) {
        for (var candidate in structKeyArray(arguments.value)) {
            if (compareNoCase(candidate, arguments.key) == 0) {
                return arguments.value[candidate];
            }
        }
    }
    return arguments.fallback;
}

function publicModelOptions() {
    var options = [];
    for (var key in structKeyArray(application.aiModelOptions)) {
        var option = application.aiModelOptions[key];
        arrayAppend(options, {
            key: option.key,
            label: option.label,
            providerLabel: option.providerLabel,
            modelName: option.chatConfig.modelName,
            modelLabel: option.modelLabel,
            available: option.available
        });
    }

    arraySort(options, function(a, b) {
        return compareNoCase(a.label, b.label);
    });

    return options;
}

try {
    if (!structKeyExists(application, "aiModelOptions")) {
        applicationStop();
        location(url = cgi.script_name, addToken = false);
    }

    selectedKey = structKeyExists(session, "selectedAiModelKey") ? session.selectedAiModelKey : application.selectedAiModelKey;

    if (cgi.request_method == "POST") {
        payload = getRequestJson();
        requestedKey = trim(readKey(payload, "modelKey", ""));

        if (!structKeyExists(application.aiModelOptions, requestedKey)) {
            sendJson({ ok: false, message: "Unknown model selection." }, 400);
        }

        if (!application.aiModelOptions[requestedKey].available) {
            sendJson({ ok: false, message: application.aiModelOptions[requestedKey].label & " is not configured with an API key yet." }, 400);
        }

        session.selectedAiModelKey = requestedKey;
        selectedKey = requestedKey;
    }

    if (!structKeyExists(application.aiModelOptions, selectedKey) || !application.aiModelOptions[selectedKey].available) {
        selectedKey = "openai-nano";
        session.selectedAiModelKey = selectedKey;
    }

    sendJson({
        ok: true,
        selectedModelKey: selectedKey,
        selectedModel: {
            key: selectedKey,
            label: application.aiModelOptions[selectedKey].label,
            providerLabel: application.aiModelOptions[selectedKey].providerLabel,
            modelName: application.aiModelOptions[selectedKey].chatConfig.modelName,
            modelLabel: application.aiModelOptions[selectedKey].modelLabel,
            available: application.aiModelOptions[selectedKey].available
        },
        options: publicModelOptions()
    });
} catch (any error) {
    sendJson({ ok: false, message: "Model settings request failed: " & error.message, detail: error.detail ?: "" }, 500);
}
</cfscript>
