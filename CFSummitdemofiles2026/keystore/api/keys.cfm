<cfsetting showdebugoutput="false">
<cfscript>
util = new keystore.ApiUtil();

try {
    service = new keystore.KeystoreService(application.keystoreConfig);
    method = ucase(cgi.request_method ?: "GET");

    if (method == "GET") {
        util.sendJson({
            ok: true,
            status: service.bootstrap(),
            keys: service.listKeys()
        });
    }

    if (method == "POST" || method == "PUT" || method == "PATCH") {
        payload = util.getRequestJson();
        keyId = util.requestValue(payload, "keyId", util.requestValue(payload, "id", ""));
        displayName = util.requestValue(payload, "name", util.requestValue(payload, "displayName", ""));
        secretValue = util.requestValue(payload, "apiKey", util.requestValue(payload, "value", ""));
        notes = util.requestValue(payload, "notes", "");

        result = service.saveKey(keyId, displayName, secretValue, notes);
        util.sendJson(result);
    }

    util.sendJson({ ok: false, message: "Method not allowed." }, 405);
} catch (any error) {
    statusCode = error.type == "Keystore.Validation" ? 400 : 500;
    util.sendJson({
        ok: false,
        message: error.message,
        detail: error.detail ?: ""
    }, statusCode);
}
</cfscript>
