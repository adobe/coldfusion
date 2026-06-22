<cfsetting showdebugoutput="false">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

function requestJson() {
    var body = getHttpRequestData().content;
    return len(trim(body)) ? deserializeJSON(body) : {};
}

function trackingService() {
    return new demotracking.DemoTrackingService(application.demoTrackingConfig);
}

function setTrackingCookie(required string sessionId) {
    cfheader(
        name = "Set-Cookie",
        value = application.demoTrackingConfig.cookieName & "=" & arguments.sessionId &
            "; Path=" & application.demoTrackingConfig.cookiePath &
            "; HttpOnly; SameSite=Lax"
    );
}

try {
    if (cgi.request_method != "POST") {
        sendJson({ ok: false, message: "POST required." }, 405);
    }

    payload = requestJson();
    service = trackingService();
    result = service.login(
        fullName = structKeyExists(payload, "name") ? payload.name : "",
        email = structKeyExists(payload, "email") ? payload.email : "",
        company = structKeyExists(payload, "company") ? payload.company : "",
        userAgent = structKeyExists(cgi, "http_user_agent") ? cgi.http_user_agent : "",
        remoteAddr = structKeyExists(cgi, "remote_addr") ? cgi.remote_addr : ""
    );

    setTrackingCookie(result.sessionId);

    sendJson(result);
} catch (DemoTracking.Validation e) {
    sendJson({ ok: false, message: e.message }, 400);
} catch (any error) {
    sendJson({
        ok: false,
        message: "Login tracking failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, 500);
}
</cfscript>
