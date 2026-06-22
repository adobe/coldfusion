<cfsetting showdebugoutput="false">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function clearTrackingCookie() {
    cfheader(
        name = "Set-Cookie",
        value = application.demoTrackingConfig.cookieName & "=; Path=" &
            application.demoTrackingConfig.cookiePath &
            "; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT; HttpOnly; SameSite=Lax"
    );
}

try {
    if (cgi.request_method != "POST") {
        sendJson({ ok: false, message: "POST required." }, 405);
    }

    service = new demotracking.DemoTrackingService(application.demoTrackingConfig);
    result = service.resetCurrentSession();
    clearTrackingCookie();

    try {
        structClear(session);
    } catch (any ignored) {
    }

    sendJson(result);
} catch (any error) {
    sendJson({
        ok: false,
        message: "Reset failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, 500);
}
</cfscript>
