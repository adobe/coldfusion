<cfsetting showdebugoutput="false">
<cfscript>
util = new keystore.ApiUtil();

try {
    service = new keystore.KeystoreService(application.keystoreConfig);
    util.sendJson({
        ok: true,
        status: service.bootstrap(),
        keys: service.listKeys()
    });
} catch (any error) {
    util.sendJson({
        ok: false,
        message: "Status failed: " & error.message,
        detail: error.detail ?: ""
    }, 500);
}
</cfscript>
