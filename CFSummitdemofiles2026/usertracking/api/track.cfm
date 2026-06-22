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

try {
    if (cgi.request_method != "POST") {
        sendJson({ ok: false, message: "POST required." }, 405);
    }

    payload = requestJson();
    service = new demotracking.DemoTrackingService(application.demoTrackingConfig);
    result = service.trackEvent(
        eventType = structKeyExists(payload, "eventType") ? payload.eventType : "demo_event",
        demoKey = structKeyExists(payload, "demoKey") ? payload.demoKey : "",
        demoName = structKeyExists(payload, "demoName") ? payload.demoName : "",
        scenarioId = structKeyExists(payload, "scenarioId") ? payload.scenarioId : "",
        scenarioTitle = structKeyExists(payload, "scenarioTitle") ? payload.scenarioTitle : "",
        scenarioFile = structKeyExists(payload, "scenarioFile") ? payload.scenarioFile : "",
        solved = structKeyExists(payload, "solved") && isBoolean(payload.solved) ? payload.solved : false,
        payload = serializeJSON(payload)
    );

    sendJson(result);
} catch (any error) {
    sendJson({
        ok: false,
        tracked: false,
        message: "Tracking failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, 500);
}
</cfscript>
