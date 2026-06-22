<cfsetting showdebugoutput="false">
<cfscript>
util = new keystore.ApiUtil();

try {
    payload = {};
    method = ucase(cgi.request_method ?: "GET");

    if (method == "POST") {
        payload = util.getRequestJson();
    }

    keyId = util.requestValue(payload, "keyId", util.requestValue(payload, "id", ""));

    if (!len(trim(keyId))) {
        util.sendJson({ ok: false, message: "Key ID is required." }, 400);
    }

    service = new keystore.KeystoreService(application.keystoreConfig);
    keyRecord = service.getKey(keyId, true);

    if (!keyRecord.ok) {
        util.sendJson(keyRecord, 404);
    }

    util.sendJson({
        ok: true,
        keyId: keyRecord.keyId,
        name: keyRecord.name,
        apiKey: keyRecord.value,
        value: keyRecord.value,
        fingerprint: keyRecord.fingerprint
    });
} catch (any error) {
    util.sendJson({
        ok: false,
        message: "Key lookup failed: " & error.message,
        detail: error.detail ?: ""
    }, 500);
}
</cfscript>
