<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
trace = "";

try {
    body = getHttpRequestData().content;
    payload = len(trim(body)) ? deserializeJson(body) : {};

    if (!structKeyExists(payload, "file") || !len(trim(payload.file))) {
        throw(message="Missing scenario file.");
    }

    scenarioService = createObject("component", "cfc.ScenarioService");
    bundle = scenarioService.getCachedScenario(payload.file);
    trace = telemetry.startTrace(
        workflowName = "cfcase_start",
        userId = "cfcase-player",
        sessionId = structKeyExists(session, "sessionid") ? session.sessionid : "",
        metadata = {
            route: cgi.script_name,
            scenarioFile: payload.file,
            scenarioId: structKeyExists(bundle.scenario, "scenarioId") ? bundle.scenario.scenarioId : ""
        }
    );
    request.cairoiTrace = trace;

    if (arrayLen(bundle.validation.errors)) {
        telemetry.finishTrace(trace, "error", {
            validationErrors: arrayLen(bundle.validation.errors),
            validationWarnings: arrayLen(bundle.validation.warnings)
        });
        writeOutput(serializeJson({
            "success": false,
            "message": "Case file corrupted.",
            "validation": bundle.validation,
            "cairoi": telemetry.traceLinks(trace)
        }));
        abort;
    }

    stateService = createObject("component", "cfc.GameStateService");
    stateService.initializeGame(bundle);

    vectorService = createObject("component", "cfc.VectorMemoryService");
    vectorService.initializeGameMemory(session.game, bundle.scenario);
    vectorService.indexCurrentRoom(session.game, bundle.scenario);

    try {
        tracking = createObject("component", "demotracking.DemoTrackingService").init(application.demoTrackingConfig);
        tracking.trackEvent(
            eventType = "cfcase_mystery_start",
            demoKey = "CFCase",
            demoName = "CF Cases",
            scenarioId = structKeyExists(bundle.scenario, "scenarioId") ? bundle.scenario.scenarioId : "",
            scenarioTitle = structKeyExists(bundle.scenario, "title") ? bundle.scenario.title : "",
            scenarioFile = payload.file,
            payload = serializeJson({
                "scenarioId": structKeyExists(bundle.scenario, "scenarioId") ? bundle.scenario.scenarioId : "",
                "title": structKeyExists(bundle.scenario, "title") ? bundle.scenario.title : "",
                "file": payload.file
            })
        );
    } catch (any trackingError) {
    }

    writeOutput(serializeJson({
        "success": true,
        "message": "Case loaded.",
        "state": stateService.getSafeState(bundle.scenario, bundle.assetFolder, structKeyExists(url, "debug") && url.debug == "1"),
        "intro": stateService.getIntroText(bundle.scenario),
        "cairoi": telemetry.traceLinks(trace)
    }));
    telemetry.finishTrace(trace, "success", {
        scenarioId: structKeyExists(bundle.scenario, "scenarioId") ? bundle.scenario.scenarioId : "",
        roomId: structKeyExists(session.game, "currentRoomId") ? session.game.currentRoomId : ""
    });
}
catch (any e) {
    telemetry.finishTrace(trace, "error", {
        errorType: structKeyExists(e, "type") ? e.type : "",
        messageChars: len(e.message)
    });
    writeOutput(serializeJson({
        "success": false,
        "message": "The case could not be loaded.",
        "error": e.message,
        "cairoi": telemetry.traceLinks(trace)
    }));
}
</cfscript>
