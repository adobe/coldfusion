<cfsetting showdebugoutput="false" requesttimeout="15">
<cfinclude template="_request.cfm">
<cfscript>
cairoiHandleOptions("GET,OPTIONS");

function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = arguments.statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(arguments.payload));
    abort;
}

try {
    dbOk = false;
    dbMessage = "";
    try {
        application.cairoiDb.bootstrap();
        application.cairoiDb.execute("SELECT COUNT(*) AS ok FROM cairoi_applications");
        dbOk = true;
    } catch (any dbError) {
        dbMessage = dbError.message;
    }

    sendJson({
        ok: dbOk,
        service: "cairoi",
        publicBaseUrl: cairoiPublicBaseUrl(),
        telemetryUrl: structKeyExists(application, "cairoiTelemetryUrl") ? application.cairoiTelemetryUrl : "",
        dashboardUrl: cairoiDashboardUrl(),
        databaseType: "embedded-derby",
        databasePath: structKeyExists(application, "cairoiDatabasePath") ? application.cairoiDatabasePath : "",
        database: {
            ok: dbOk,
            message: dbMessage
        },
        cors: {
            enabled: structKeyExists(application, "cairoiCorsEnabled") && application.cairoiCorsEnabled,
            allowedOrigins: cairoiAllowedOrigins()
        }
    }, dbOk ? 200 : 503);
} catch (any e) {
    sendJson({ ok: false, service: "cairoi", error: e.message, detail: e.detail ?: "" }, 500);
}
</cfscript>
