<cfsetting showdebugoutput="false">
<cfscript>
util = new keystore.ApiUtil();

try {
    payload = {};
    method = ucase(cgi.request_method ?: "POST");

    if (method == "POST" || method == "DELETE") {
        payload = util.getRequestJson();
    }

    keyId = util.requestValue(payload, "keyId", util.requestValue(payload, "id", ""));

    if (!len(trim(keyId))) {
        util.sendJson({ ok: false, message: "Key ID is required." }, 400);
    }

    service = new keystore.KeystoreService(application.keystoreConfig);
    deleted = service.deleteKey(keyId);

    util.sendJson({
        ok: deleted,
        deleted: deleted,
        message: deleted ? "Key deleted." : "Key not found."
    }, deleted ? 200 : 404);
} catch (any error) {
    util.sendJson({
        ok: false,
        message: "Delete failed: " & error.message,
        detail: error.detail ?: ""
    }, 500);
}
</cfscript>
