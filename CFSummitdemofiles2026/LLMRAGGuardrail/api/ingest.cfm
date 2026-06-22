<cfsetting showdebugoutput="false" requesttimeout="300">
<cfscript>
apiUtil = new onboardrag.ApiUtil();
service = new onboardrag.OnboardingService();
telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
trace = "";

try {
    if (cgi.request_method != "POST") {
        apiUtil.sendJson({ ok: false, message: "POST required." }, 405);
    }

    payload = apiUtil.getRequestJson();
    force = true;
    if (structKeyExists(payload, "force")) {
        force = payload.force;
    }

    trace = telemetry.startTrace(
        workflowName = "onboardiq_ingest",
        userId = "onboardiq-admin",
        sessionId = structKeyExists(session, "onboardSessionId") ? session.onboardSessionId : "",
        metadata = {
            route: cgi.script_name,
            force: force,
            localModel: true
        }
    );
    request.cairoiTrace = trace;

    ingestStatus = service.ensureIngested(force);
    telemetry.finishTrace(trace, ingestStatus.ready ? "success" : "error", {
        ready: ingestStatus.ready,
        chunkCount: ingestStatus.chunkCount,
        addedCount: ingestStatus.addedCount,
        collectionName: ingestStatus.collectionName
    });
    apiUtil.sendJson({
        ok: ingestStatus.ready,
        ingestStatus: ingestStatus,
        message: ingestStatus.message,
        cairoi: telemetry.traceLinks(trace)
    }, ingestStatus.ready ? 200 : 409);
} catch (any error) {
    telemetry.finishTrace(trace, "error", {
        errorType: structKeyExists(error, "type") ? error.type : "",
        messageChars: len(error.message)
    });
    statusCode = structKeyExists(error, "errorCode") ? val(error.errorCode) : 500;
    if (statusCode < 400) {
        statusCode = 500;
    }
    apiUtil.sendJson({
        ok: false,
        message: "Ingestion failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : "",
        cairoi: telemetry.traceLinks(trace)
    }, statusCode);
}
</cfscript>
