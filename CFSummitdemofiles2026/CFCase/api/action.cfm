<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
trace = "";

try {
    body = getHttpRequestData().content;
    payload = len(trim(body)) ? deserializeJson(body) : {};
    command = structKeyExists(payload, "command") ? payload.command : "";
    debugMode = structKeyExists(url, "debug") && url.debug == "1";
    trace = telemetry.startTrace(
        workflowName = "cfcase_action",
        userId = "cfcase-player",
        sessionId = structKeyExists(session, "sessionid") ? session.sessionid : "",
        metadata = {
            route: cgi.script_name,
            commandChars: len(command),
            debugMode: debugMode,
            scenarioId: structKeyExists(session, "game") && structKeyExists(session.game, "scenarioId") ? session.game.scenarioId : ""
        }
    );
    request.cairoiTrace = trace;

    engine = createObject("component", "cfc.GameEngineService");
    result = engine.executeCommand(command, debugMode);
    cairoiLinks = telemetry.traceLinks(trace);
    if (!structIsEmpty(cairoiLinks)) {
        result.cairoi = cairoiLinks;
    }
    solvedNow = false;

    try {
        tracking = createObject("component", "demotracking.DemoTrackingService").init(application.demoTrackingConfig);
        tracking.getCurrentSession(true);

        solvedNow = (
            structKeyExists(result, "stateChanges") &&
            isStruct(result.stateChanges) &&
            structKeyExists(result.stateChanges, "solved") &&
            result.stateChanges.solved
        );

        if (
            solvedNow &&
            structKeyExists(session, "game") &&
            !structKeyExists(session.game, "trackingSolvedRecorded")
        ) {
            trackingResult = tracking.trackEvent(
                eventType = "cfcase_mystery_solved",
                demoKey = "CFCase",
                demoName = "CF Cases",
                scenarioId = structKeyExists(session.game, "scenarioId") ? session.game.scenarioId : "",
                scenarioTitle = structKeyExists(session.game, "title") ? session.game.title : "",
                scenarioFile = structKeyExists(session.game, "scenarioFile") ? session.game.scenarioFile : "",
                solved = true,
                payload = serializeJson({
                    "scenarioId": structKeyExists(session.game, "scenarioId") ? session.game.scenarioId : "",
                    "title": structKeyExists(session.game, "title") ? session.game.title : "",
                    "scenarioFile": structKeyExists(session.game, "scenarioFile") ? session.game.scenarioFile : "",
                    "command": command
                })
            );

            if (structKeyExists(trackingResult, "tracked") && trackingResult.tracked) {
                session.game.trackingSolvedRecorded = true;
            }
        }
    } catch (any trackingError) {
    }

    telemetry.finishTrace(
        trace,
        structKeyExists(result, "success") && !result.success ? "error" : "success",
        {
            solved: solvedNow,
            resultAction: structKeyExists(result, "action") ? result.action : "",
            messageChars: structKeyExists(result, "message") ? len(result.message) : 0
        }
    );
    writeOutput(serializeJson(result));
}
catch (any e) {
    telemetry.finishTrace(
        trace,
        "error",
        {
            errorType: structKeyExists(e, "type") ? e.type : "",
            messageChars: len(e.message)
        }
    );
    writeOutput(serializeJson({
        "success": false,
        "message": "The house system faulted while processing that command.",
        "error": e.message,
        "cairoi": telemetry.traceLinks(trace)
    }));
}
</cfscript>
