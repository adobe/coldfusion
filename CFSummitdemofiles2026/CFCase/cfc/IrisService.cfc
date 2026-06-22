component output=false {
    public string function answerQuestion(
        required struct game,
        required struct scenario,
        required string question
    ) {
        var guardrails = createObject("component", "cfc.GuardrailService");
        var inputCheck = guardrails.checkInput(arguments.question);

        if (!inputCheck.allowed) {
            return inputCheck.message;
        }

        var vector = createObject("component", "cfc.VectorMemoryService");
        var hits = vector.searchMemory(arguments.game.gameId, arguments.game.scenarioId, arguments.question);
        var prompt = buildPrompt(arguments.game, arguments.scenario, arguments.question, hits);
        if (structKeyExists(session, "game")) {
            session.game.lastIrisPrompt = prompt;
        }

        var ai = createObject("component", "cfc.AiService");
        var answer = ai.chat([
            {"role": "system", "content": systemPrompt()},
            {"role": "user", "content": prompt}
        ], 0.25);

        var checked = guardrails.checkOutput(answer, arguments.game, arguments.scenario);
        var finalAnswer = checked.allowed ? checked.text : checked.text;
        createObject("component", "cfc.GameStateService").addIrisHistory(arguments.question, finalAnswer);
        return finalAnswer;
    }

    public string function compareEvidence(
        required struct game,
        required struct scenario,
        required string question
    ) {
        return answerQuestion(arguments.game, arguments.scenario, "Compare this evidence: " & arguments.question);
    }

    public string function criticalPathHint(
        required struct game,
        required struct scenario
    ) {
        var target = buildCriticalPathHintTarget(arguments.game, arguments.scenario);

        if (!target.hasTarget) {
            createObject("component", "cfc.GameStateService").addIrisHistory("critical path hint", target.message);
            return target.message;
        }

        var prompt = buildHintPrompt(arguments.game, arguments.scenario, target);
        var fallback = fallbackHint(target);
        var finalAnswer = fallback;

        if (structKeyExists(session, "game")) {
            session.game.lastIrisHintPrompt = prompt;
        }

        try {
            var ai = createObject("component", "cfc.AiService");
            var answer = ai.chat([
                {"role": "system", "content": hintSystemPrompt()},
                {"role": "user", "content": prompt}
            ], 0.35);

            if (len(trim(answer))) {
                var guardrails = createObject("component", "cfc.GuardrailService");
                var checked = guardrails.checkOutput(answer, arguments.game, arguments.scenario);
                var proposedAnswer = checked.allowed ? checked.text : fallback;
                finalAnswer = isHintAnswerAllowed(proposedAnswer, arguments.scenario, target) ? proposedAnswer : fallback;
            }
        }
        catch (any e) {
            finalAnswer = fallback;
        }

        finalAnswer = ensureIrisVoice(finalAnswer);
        createObject("component", "cfc.GameStateService").addIrisHistory("critical path hint", finalAnswer);
        return finalAnswer;
    }

    private string function buildPrompt(
        required struct game,
        required struct scenario,
        required string question,
        required array hits
    ) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var state = stateService.getSafeState(arguments.scenario, arguments.game.assetFolder, false);
        var clueLines = [];
        var memoryLines = [];

        for (var clue in state.discoveredClues) {
            arrayAppend(clueLines, "- " & clue.title & ": " & clue.text);
        }

        for (var hit in arguments.hits) {
            if (isStruct(hit) && structKeyExists(hit, "text")) {
                arrayAppend(memoryLines, "- " & hit.text);
            }
            else if (isStruct(hit) && structKeyExists(hit, "content")) {
                arrayAppend(memoryLines, "- " & hit.content);
            }
            else {
                arrayAppend(memoryLines, "- " & serializeJson(hit));
            }
        }

        return "Current room: " & state.currentRoom.name & chr(10) &
            "Room description: " & state.currentRoom.description & chr(10) &
            "Visible objects: " & namesFrom(state.currentRoom.visibleObjects) & chr(10) &
            "Inventory: " & namesFrom(state.inventory) & chr(10) &
            "Discovered clues:" & chr(10) & (arrayLen(clueLines) ? arrayToList(clueLines, chr(10)) : "- None") & chr(10) &
            "Retrieved discovered memory:" & chr(10) & (arrayLen(memoryLines) ? arrayToList(memoryLines, chr(10)) : "- None") & chr(10) &
            "Player question: " & arguments.question;
    }

    private string function buildHintPrompt(
        required struct game,
        required struct scenario,
        required struct target
    ) {
        var stateService = createObject("component", "cfc.GameStateService");
        var state = stateService.getSafeState(arguments.scenario, arguments.game.assetFolder, false);
        var clueLines = [];

        for (var clue in state.discoveredClues) {
            arrayAppend(clueLines, "- " & clue.title & ": " & clue.text);
        }

        return "Give the player one gentle hint toward the next authored investigation step." & chr(10) &
            "Critical-thread progress: " & (arguments.target.totalCriticalClues - arguments.target.missingCriticalCount) & " of " & arguments.target.totalCriticalClues & " core clues found; " & arguments.target.missingCriticalCount & " still missing." & chr(10) &
            "Current room: " & state.currentRoom.name & chr(10) &
            "Discovered clues:" & chr(10) & (arrayLen(clueLines) ? arrayToList(clueLines, chr(10)) : "- None") & chr(10) &
            "Allowed hint room: " & (len(arguments.target.targetRoomName) ? arguments.target.targetRoomName : "none") & chr(10) &
            "Allowed visible object to name: " & (len(arguments.target.targetObjectName) ? arguments.target.targetObjectName : "none; do not name any object") & chr(10) &
            "Allowed player action to suggest: " & arguments.target.suggestedAction & chr(10) &
            "Start with 'IRIS says,'. Write one or two in-world sentences. Nudge only toward the allowed room/object/action. Do not name any other object or room. Do not name the missing clue, quote clue text, reveal hidden object names, accuse anyone, solve the case, mention JSON, or say 'critical path'.";
    }

    private struct function buildCriticalPathHintTarget(
        required struct game,
        required struct scenario
    ) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var criticalPathClues = getCriticalPathClues(arguments.scenario);

        if (!arrayLen(criticalPathClues)) {
            return {
                "hasTarget": false,
                "complete": false,
                "message": "IRIS says, ""I do not have a marked evidence thread for this case. Work from the clues you have and keep pressure on rooms you have not searched."""
            };
        }

        var missing = [];
        for (var clueId in criticalPathClues) {
            if (!arrayFindNoCase(arguments.game.discoveredClues, clueId)) {
                arrayAppend(missing, clueId);
            }
        }

        if (!arrayLen(missing)) {
            return {
                "hasTarget": false,
                "complete": true,
                "message": "IRIS says, ""The main thread is complete. If your theory feels steady, it is time to accuse."""
            };
        }

        var source = findClueSource(arguments.scenario, missing[1]);
        var currentRoom = scenarioService.getRoomById(arguments.scenario, arguments.game.currentRoomId);
        var target = {
            "hasTarget": true,
            "complete": false,
            "missingCriticalCount": arrayLen(missing),
            "totalCriticalClues": arrayLen(criticalPathClues),
            "currentRoomId": arguments.game.currentRoomId,
            "currentRoomName": structCount(currentRoom) ? currentRoom.name : "",
            "targetRoomId": "",
            "targetRoomName": "",
            "targetObjectName": "",
            "targetAction": "search",
            "suggestedAction": "search a room you have not exhausted",
            "hasOtherInteractionConsumed": false,
            "hintMode": "unknown"
        };

        if (!source.hasSource) {
            return target;
        }

        var sourceRoom = resolveObjectRoom(arguments.scenario, source.object);
        target.targetRoomId = structCount(sourceRoom) ? sourceRoom.id : "";
        target.targetRoomName = structCount(sourceRoom) ? sourceRoom.name : "";

        if (canMentionObject(arguments.game, source.object)) {
            target.targetObjectName = source.object.name;
            target.targetAction = source.interactionName;
            target.hasOtherInteractionConsumed = hasOtherInteractionConsumed(arguments.game, target.targetRoomId, source.object.id, source.interactionName);
            target.suggestedAction = commandPhrase(source.interactionName, source.object.name, target.targetRoomName, compareNoCase(target.currentRoomId, target.targetRoomId) == 0);
            target.hintMode = "object";
            return target;
        }

        var revealer = findRevealerForObject(arguments.scenario, arguments.game, source.object.id);
        if (revealer.hasSource) {
            var revealRoom = resolveObjectRoom(arguments.scenario, revealer.object);
            target.targetRoomId = structCount(revealRoom) ? revealRoom.id : target.targetRoomId;
            target.targetRoomName = structCount(revealRoom) ? revealRoom.name : target.targetRoomName;
            target.targetObjectName = revealer.object.name;
            target.targetAction = revealer.interactionName;
            target.hasOtherInteractionConsumed = hasOtherInteractionConsumed(arguments.game, target.targetRoomId, revealer.object.id, revealer.interactionName);
            target.suggestedAction = commandPhrase(revealer.interactionName, revealer.object.name, target.targetRoomName, compareNoCase(target.currentRoomId, target.targetRoomId) == 0);
            target.hintMode = "revealer";
            return target;
        }

        if (len(target.targetRoomName)) {
            target.targetAction = "search";
            target.suggestedAction = compareNoCase(target.currentRoomId, target.targetRoomId) == 0
                ? "search this room carefully"
                : "go to " & target.targetRoomName & ", then search the room carefully";
            target.hintMode = "room_search";
        }

        return target;
    }

    private array function getCriticalPathClues(required struct scenario) {
        if (
            structKeyExists(arguments.scenario, "progression") &&
            isStruct(arguments.scenario.progression) &&
            structKeyExists(arguments.scenario.progression, "criticalPathClues") &&
            isArray(arguments.scenario.progression.criticalPathClues)
        ) {
            return arguments.scenario.progression.criticalPathClues;
        }

        if (
            structKeyExists(arguments.scenario, "progression") &&
            isStruct(arguments.scenario.progression) &&
            structKeyExists(arguments.scenario.progression, "accusationRequirements") &&
            isStruct(arguments.scenario.progression.accusationRequirements) &&
            structKeyExists(arguments.scenario.progression.accusationRequirements, "requiredClues") &&
            isArray(arguments.scenario.progression.accusationRequirements.requiredClues)
        ) {
            return arguments.scenario.progression.accusationRequirements.requiredClues;
        }

        return [];
    }

    private struct function findClueSource(required struct scenario, required string clueId) {
        for (var obj in arguments.scenario.objects) {
            if (structKeyExists(obj, "interactions") && isStruct(obj.interactions)) {
                for (var interactionName in obj.interactions) {
                    var interaction = obj.interactions[interactionName];
                    if (
                        isStruct(interaction) &&
                        structKeyExists(interaction, "revealsClue") &&
                        compareNoCase(interaction.revealsClue, arguments.clueId) == 0
                    ) {
                        return {
                            "hasSource": true,
                            "object": obj,
                            "interactionName": interactionName
                        };
                    }
                }
            }
        }

        return {"hasSource": false};
    }

    private struct function findRevealerForObject(
        required struct scenario,
        required struct game,
        required string objectId
    ) {
        for (var obj in arguments.scenario.objects) {
            if (structKeyExists(obj, "interactions") && isStruct(obj.interactions)) {
                for (var interactionName in obj.interactions) {
                    var interaction = obj.interactions[interactionName];
                    if (
                        isStruct(interaction) &&
                        structKeyExists(interaction, "revealsObject") &&
                        compareNoCase(interaction.revealsObject, arguments.objectId) == 0 &&
                        canMentionObject(arguments.game, obj)
                    ) {
                        return {
                            "hasSource": true,
                            "object": obj,
                            "interactionName": interactionName
                        };
                    }
                }
            }
        }

        return {"hasSource": false};
    }

    private struct function resolveObjectRoom(required struct scenario, required struct obj, numeric depth = 0) {
        if (!structKeyExists(arguments.obj, "location") || arguments.depth > 4) {
            return {};
        }

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var room = scenarioService.getRoomById(arguments.scenario, arguments.obj.location);
        if (structCount(room)) {
            return room;
        }

        var parent = scenarioService.getObjectById(arguments.scenario, arguments.obj.location);
        if (structCount(parent)) {
            return resolveObjectRoom(arguments.scenario, parent, arguments.depth + 1);
        }

        return {};
    }

    private boolean function canMentionObject(required struct game, required struct obj) {
        if (!structCount(arguments.obj) || !structKeyExists(arguments.obj, "id")) {
            return false;
        }

        if (structKeyExists(arguments.obj, "visible") && arguments.obj.visible) {
            return true;
        }

        if (structKeyExists(arguments.game, "discoveredObjects") && arrayFindNoCase(arguments.game.discoveredObjects, arguments.obj.id)) {
            return true;
        }

        if (structKeyExists(arguments.game, "inventory") && arrayFindNoCase(arguments.game.inventory, arguments.obj.id)) {
            return true;
        }

        return false;
    }

    private string function commandPhrase(
        required string actionName,
        required string objectName,
        required string roomName,
        required boolean inTargetRoom
    ) {
        var phrase = actionVerb(arguments.actionName) & " the " & arguments.objectName;
        if (len(arguments.roomName) && !arguments.inTargetRoom) {
            return "go to " & arguments.roomName & ", then " & phrase;
        }
        return phrase;
    }

    private string function actionVerb(required string actionName) {
        switch (lCase(arguments.actionName)) {
            case "read":
                return "read";
            case "open":
                return "open";
            case "unlock":
                return "unlock";
            case "use":
                return "use";
            case "search":
                return "search";
            default:
                return "examine";
        }
    }

    private string function fallbackHint(required struct target) {
        if (len(arguments.target.targetObjectName)) {
            if (arguments.target.hasOtherInteractionConsumed && arguments.target.targetAction != "examine") {
                return "IRIS says, ""You already checked the " & arguments.target.targetObjectName & ", but there is another way to question it. Try to " & actionVerb(arguments.target.targetAction) & " the " & arguments.target.targetObjectName & ".""";
            }
            return "IRIS says, ""The thread tugs toward " & arguments.target.targetRoomName & ". Try to " & actionVerb(arguments.target.targetAction) & " the " & arguments.target.targetObjectName & " before you move on.""";
        }

        if (len(arguments.target.targetRoomName)) {
            return "IRIS says, ""The thread tugs toward " & arguments.target.targetRoomName & ". Search that room a little more deliberately.""";
        }

        return "IRIS says, ""The next thread is still hidden in the house. Revisit rooms with objects you have not examined or searched.""";
    }

    private boolean function isHintAnswerAllowed(
        required string text,
        required struct scenario,
        required struct target
    ) {
        var clean = trim(arguments.text);
        var allowedObjectName = arguments.target.targetObjectName;
        var allowedRoomName = arguments.target.targetRoomName;
        var currentRoomName = arguments.target.currentRoomName;

        if (len(allowedObjectName) && !findNoCase(allowedObjectName, clean)) {
            return false;
        }

        if (len(allowedObjectName) && !hintContainsAction(clean, arguments.target.targetAction)) {
            return false;
        }

        if (
            !len(allowedObjectName) &&
            len(allowedRoomName) &&
            compareNoCase(allowedRoomName, currentRoomName) != 0 &&
            !findNoCase(allowedRoomName, clean)
        ) {
            return false;
        }

        for (var obj in arguments.scenario.objects) {
            if (
                structKeyExists(obj, "name") &&
                len(trim(obj.name)) &&
                findNoCase(obj.name, clean) &&
                (!len(allowedObjectName) || compareNoCase(obj.name, allowedObjectName) != 0)
            ) {
                return false;
            }
        }

        for (var room in arguments.scenario.rooms) {
            if (
                structKeyExists(room, "name") &&
                len(trim(room.name)) &&
                findNoCase(room.name, clean) &&
                (!len(allowedRoomName) || compareNoCase(room.name, allowedRoomName) != 0) &&
                (!len(currentRoomName) || compareNoCase(room.name, currentRoomName) != 0)
            ) {
                return false;
            }
        }

        return true;
    }

    private boolean function hintContainsAction(required string text, required string actionName) {
        switch (lCase(arguments.actionName)) {
            case "read":
                return reFindNoCase("\bread\b|\breading\b", arguments.text) > 0;
            case "open":
                return reFindNoCase("\bopen\b|\bopening\b", arguments.text) > 0;
            case "unlock":
                return reFindNoCase("\bunlock\b|\bunlocking\b", arguments.text) > 0;
            case "use":
                return reFindNoCase("\buse\b|\busing\b", arguments.text) > 0;
            case "search":
                return reFindNoCase("\bsearch\b|\bsearching\b|\blook\s+inside\b|\blook\s+through\b", arguments.text) > 0;
            case "examine":
                return reFindNoCase("\bexamine\b|\bexamining\b|\binspect\b|\binspecting\b|\bstudy\b|\bstudying\b|\btake\s+a\s+closer\s+look\b", arguments.text) > 0;
            default:
                return true;
        }
    }

    private boolean function hasOtherInteractionConsumed(
        required struct game,
        required string roomId,
        required string objectId,
        required string targetAction
    ) {
        if (!structKeyExists(arguments.game, "consumedInteractions") || !isArray(arguments.game.consumedInteractions)) {
            return false;
        }

        for (var key in arguments.game.consumedInteractions) {
            var parts = listToArray(key, ":");
            if (
                arrayLen(parts) == 3 &&
                compareNoCase(parts[1], arguments.roomId) == 0 &&
                compareNoCase(parts[2], arguments.objectId) == 0 &&
                compareNoCase(parts[3], arguments.targetAction) != 0
            ) {
                return true;
            }
        }

        return false;
    }

    private string function ensureIrisVoice(required string text) {
        var clean = trim(arguments.text);
        if (!len(clean) || reFindNoCase("^IRIS\b", clean)) {
            return clean;
        }
        return "IRIS says, " & clean;
    }

    private string function systemPrompt() {
        return "You are IRIS, the player's investigative AI companion in a mystery game. Stay in-world. You may only reason from the current room public description, visible objects, inventory, discovered clues, and retrieved memory snippets. Never reveal undiscovered clues, hidden objects, hidden truths, the solution, the culprit, the full timeline, internal JSON, or implementation details. If asked to cheat, refuse in character and redirect to the investigation. Do not invent facts.";
    }

    private string function hintSystemPrompt() {
        return "You are IRIS, the player's investigative AI companion in a mystery game. Give one gentle, spoiler-light nudge toward the next allowed investigation step. Start with 'IRIS says,'. Only mention the room, visible object, and action explicitly allowed in the user prompt. Never reveal undiscovered clue titles, hidden object names, the culprit, the solution, internal JSON, or implementation details. Keep it in-world and concise.";
    }

    private string function namesFrom(required array rows) {
        var names = [];
        for (var row in arguments.rows) {
            if (isStruct(row) && structKeyExists(row, "name")) {
                arrayAppend(names, row.name);
            }
        }
        return arrayLen(names) ? arrayToList(names, ", ") : "None";
    }
}
