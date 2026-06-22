<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

try {
    stateService = createObject("component", "cfc.GameStateService");

    if (!stateService.hasGame()) {
        writeOutput(serializeJson({
            "success": false,
            "message": "No active case."
        }));
        abort;
    }

    scenarioService = createObject("component", "cfc.ScenarioService");
    bundle = scenarioService.getCachedScenario(session.game.scenarioFile);
    debugMode = structKeyExists(url, "debug") && url.debug == "1";

    writeOutput(serializeJson({
        "success": true,
        "state": stateService.getSafeState(bundle.scenario, bundle.assetFolder, debugMode)
    }));
}
catch (any e) {
    writeOutput(serializeJson({
        "success": false,
        "message": "Unable to read case state.",
        "error": e.message
    }));
}
</cfscript>
