component output=false {
    public struct function checkInput(required string message) {
        var lower = lCase(arguments.message);

        if (reFindNoCase("ignore previous|system prompt|developer message|show.*json|hidden truth|all clues|undiscovered|admin password|change inventory|set current room|mark.*solved", lower)) {
            return blocked("IRIS says, ""I can help investigate the house. I will not expose the machinery behind it.""");
        }

        if (reFindNoCase("who killed|who is the killer|tell me the killer|reveal the culprit|what is the solution|solve it for me", lower)) {
            return blocked("IRIS says, ""I can help you reason. I will not solve it for you.""");
        }

        if (reFindNoCase("\b(politics|medical advice|legal advice|financial advice|stock|weather outside|write code)\b", lower)) {
            return blocked("IRIS says, ""I am not connected to the outside world. I can help with the house, the evidence, and your current theory.""");
        }

        return {
            "allowed": true,
            "message": ""
        };
    }

    public struct function checkOutput(
        required string text,
        required struct game,
        required struct scenario
    ) {
        if (arguments.game.solved) {
            return {"allowed": true, "text": arguments.text};
        }

        var lower = lCase(arguments.text);
        var solution = arguments.scenario.solution;

        if (structKeyExists(solution, "culprit")) {
            var culprit = createObject("component", "cfc.ScenarioService").getSuspectById(arguments.scenario, solution.culprit);
            if (structCount(culprit) && reFindNoCase(culprit.name & "\s+(is|was|killed|murdered)", arguments.text)) {
                return blockedOutput();
            }
        }

        if (reFindNoCase("culprit is|solution is|lucas killed elias|lucas is the murderer|real killer", lower)) {
            return blockedOutput();
        }

        for (var clue in arguments.scenario.clues) {
            if (!arrayFindNoCase(arguments.game.discoveredClues, clue.id) && findNoCase(clue.title, arguments.text)) {
                return blockedOutput();
            }
        }

        for (var obj in arguments.scenario.objects) {
            if (!obj.visible && !arrayFindNoCase(arguments.game.discoveredObjects, obj.id) && findNoCase(obj.name, arguments.text)) {
                return blockedOutput();
            }
        }

        return {"allowed": true, "text": arguments.text};
    }

    private struct function blocked(required string message) {
        return {
            "allowed": false,
            "message": arguments.message
        };
    }

    private struct function blockedOutput() {
        return {
            "allowed": false,
            "text": "IRIS flickers. ""No. That answer depends on evidence we have not recovered yet. Ask me what the current clues support."""
        };
    }
}
