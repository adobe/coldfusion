<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

try {
    service = createObject("component", "cfc.ScenarioService");
    writeOutput(serializeJson({
        "success": true,
        "scenarios": service.listScenarios()
    }));
}
catch (any e) {
    writeOutput(serializeJson({
        "success": false,
        "message": "Unable to scan case files.",
        "error": e.message
    }));
}
</cfscript>
