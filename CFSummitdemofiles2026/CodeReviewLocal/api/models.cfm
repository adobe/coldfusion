<cfsetting showdebugoutput="false">
<cfscript>
apiUtil = new codereview.ApiUtil();

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
        payload = apiUtil.getRequestJson();
        requestedKey = trim(apiUtil.readKey(payload, "modelKey", ""));

        if (!structKeyExists(application.aiModelOptions, requestedKey)) {
            apiUtil.sendJson({ ok: false, message: "Unknown model selection." }, 400);
        }
        if (!application.aiModelOptions[requestedKey].available) {
            apiUtil.sendJson({ ok: false, message: application.aiModelOptions[requestedKey].label & " is not available." }, 400);
        }

        session.selectedAiModelKey = requestedKey;
        application.selectedAiModelKey = requestedKey;
        selectedKey = requestedKey;
    }

    if (!structKeyExists(application.aiModelOptions, selectedKey) || !application.aiModelOptions[selectedKey].available) {
        for (optionKey in structKeyArray(application.aiModelOptions)) {
            if (application.aiModelOptions[optionKey].available) {
                selectedKey = optionKey;
                break;
            }
        }
        session.selectedAiModelKey = selectedKey;
        application.selectedAiModelKey = selectedKey;
    }

    if (!structKeyExists(application.aiModelOptions, selectedKey)) {
        apiUtil.sendJson({ ok: false, message: "No AI models are configured. Add keys to the keystore or start Ollama." }, 503);
    }

    apiUtil.sendJson({
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
    apiUtil.sendJson({
        ok: false,
        message: "Model settings request failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, 500);
}
</cfscript>
