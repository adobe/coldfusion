component output=false {
    public struct function executeCommand(required string command, boolean debugMode = false) {
        var stateService = createObject("component", "cfc.GameStateService");
        var responseService = createObject("component", "cfc.ResponseService");

        if (!stateService.hasGame()) {
            return {"success": false, "message": "No active case.", "narration": "No case is loaded."};
        }

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var bundle = scenarioService.getCachedScenario(session.game.scenarioFile);
        var scenario = bundle.scenario;
        var guardrails = createObject("component", "cfc.GuardrailService");
        var inputCheck = guardrails.checkInput(arguments.command);

        if (!inputCheck.allowed) {
            var blockedState = stateService.getSafeState(scenario, bundle.assetFolder, arguments.debugMode);
            return responseService.actionResponse(false, "blocked", inputCheck.message, blockedState);
        }

        var parser = createObject("component", "cfc.CommandParserService");
        var context = stateService.getSafeParserContext(scenario);
        var parsed = parser.parse(arguments.command, context, true);
        var result = {};

        if (parsed.needsClarification) {
            result = simpleResult(false, "clarify", parsed.clarificationQuestion);
        }
        else {
            switch (parsed.action) {
                case "look":
                    result = look(scenario);
                    break;
                case "inventory":
                    result = simpleResult(true, "inventory", inventoryText(scenario));
                    break;
                case "clues":
                    result = simpleResult(true, "clues", cluesText(scenario));
                    break;
                case "help":
                    result = simpleResult(true, "help", responseService.helpText());
                    break;
                case "move":
                    result = move(scenario, parsed.destinationRoom);
                    break;
                case "search":
                    result = search(scenario, parsed.target);
                    break;
                case "examine":
                    result = examine(scenario, parsed.target);
                    break;
                case "read":
                    result = readObject(scenario, parsed.target);
                    break;
                case "take":
                    result = takeObject(scenario, parsed.target);
                    break;
                case "open":
                    result = openObject(scenario, parsed.target);
                    break;
                case "unlock":
                    result = unlockObject(scenario, parsed.target);
                    break;
                case "use":
                    result = useObject(scenario, parsed.target);
                    break;
                case "ask_iris":
                    result = askIris(scenario, parsed.question);
                    break;
                case "hint":
                    result = giveHint(scenario);
                    break;
                case "compare":
                    result = compareEvidence(scenario, parsed.question);
                    break;
                case "accuse":
                    result = accuse(scenario, parsed.accusedSuspect, parsed.theory);
                    break;
                default:
                    result = simpleResult(false, "unknown", responseService.unknownText());
            }
        }

        stateService.addHistory(arguments.command, parsed, result.narration);

        var safeState = stateService.getSafeState(scenario, bundle.assetFolder, arguments.debugMode);
        var debug = arguments.debugMode ? stateService.getDebugState() : {};

        return responseService.actionResponse(
            result.success,
            result.action,
            result.narration,
            safeState,
            result.stateChanges,
            parsed,
            debug
        );
    }

    private struct function look(required struct scenario) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var room = scenarioService.getRoomById(arguments.scenario, session.game.currentRoomId);
        return simpleResult(true, "look", room.description);
    }

    private struct function move(required struct scenario, required string roomId) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var currentRoom = scenarioService.getRoomById(arguments.scenario, session.game.currentRoomId);

        if (!arrayFindNoCase(scenarioService.safeArray(currentRoom, "exits"), arguments.roomId)) {
            return simpleResult(false, "move", "That way is sealed behind old stone and bad architectural decisions. You will need another route.");
        }

        stateService.moveToRoom(arguments.roomId);

        var vector = createObject("component", "cfc.VectorMemoryService");
        vector.indexCurrentRoom(session.game, arguments.scenario);

        var nextRoom = scenarioService.getRoomById(arguments.scenario, arguments.roomId);
        var roomLabel = reFindNoCase("'s", nextRoom.name) ? nextRoom.name : "the " & nextRoom.name;
        return {
            "success": true,
            "action": "move",
            "narration": "You move into " & roomLabel & ". " & nextRoom.description,
            "stateChanges": {"currentRoomId": arguments.roomId}
        };
    }

    private struct function search(required struct scenario, required string targetId) {
        if (!len(arguments.targetId)) {
            return searchCurrentRoom(arguments.scenario);
        }
        return runObjectInteraction(arguments.scenario, arguments.targetId, "search");
    }

    private struct function examine(required struct scenario, required string targetId) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var obj = scenarioService.getObjectById(arguments.scenario, arguments.targetId);

        if (!structCount(obj)) {
            if (len(arguments.targetId)) {
                if (stateService.isVisibleInCurrentRoom(arguments.targetId)) {
                    stateService.markExaminedObject(arguments.targetId);
                }
                return simpleResult(true, "examine", "You study the " & scenarioService.featureName(arguments.targetId) & ". It belongs to the room's atmosphere, but it offers no evidence yet.");
            }
            return simpleResult(false, "examine", "You need something specific to examine.");
        }

        if (!canAccessObject(arguments.targetId)) {
            return simpleResult(false, "examine", "You do not see that here.");
        }

        stateService.markExaminedObject(arguments.targetId);

        if (structKeyExists(obj, "interactions") && structKeyExists(obj.interactions, "examine")) {
            return runObjectInteraction(arguments.scenario, arguments.targetId, "examine");
        }

        return simpleResult(true, "examine", obj.description);
    }

    private struct function readObject(required struct scenario, required string targetId) {
        return runObjectInteraction(arguments.scenario, arguments.targetId, "read");
    }

    private struct function takeObject(required struct scenario, required string targetId) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var obj = scenarioService.getObjectById(arguments.scenario, arguments.targetId);

        if (!structCount(obj)) {
            if (len(arguments.targetId) && stateService.isVisibleInCurrentRoom(arguments.targetId)) {
                return simpleResult(false, "take", "The " & scenarioService.featureName(arguments.targetId) & " is logged in place rather than carried as inventory. Examine or search it instead.");
            }
            return simpleResult(false, "take", "You do not see that here.");
        }

        if (!canAccessObject(arguments.targetId)) {
            return simpleResult(false, "take", "You do not see that here.");
        }

        if (!structKeyExists(obj, "portable") || !obj.portable) {
            return simpleResult(false, "take", "The " & obj.name & " is not carryable. It can still matter as evidence, so examine or search it instead.");
        }

        if (!stateService.addInventory(arguments.targetId)) {
            return simpleResult(true, "take", "You already have the " & obj.name & ".");
        }

        createObject("component", "cfc.VectorMemoryService").indexObject(session.game, arguments.scenario, obj, "Taken into inventory.");

        return {
            "success": true,
            "action": "take",
            "narration": "You take the " & obj.name & ". It is now in your inventory for later reading, use, or unlocking.",
            "stateChanges": {"inventoryAdded": [arguments.targetId]}
        };
    }

    private struct function openObject(required struct scenario, required string targetId) {
        return runObjectInteraction(arguments.scenario, arguments.targetId, "open");
    }

    private struct function unlockObject(required struct scenario, required string targetId) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var obj = scenarioService.getObjectById(arguments.scenario, arguments.targetId);

        if (!structCount(obj) || !canAccessObject(arguments.targetId)) {
            return simpleResult(false, "unlock", "You do not see that here.");
        }

        if (!structKeyExists(obj, "unlockRequirements")) {
            return simpleResult(false, "unlock", "There is nothing obvious to unlock.");
        }

        if (!meetsUnlockRequirement(obj.unlockRequirements)) {
            return simpleResult(false, "unlock", "It is locked, and you do not have what it wants.");
        }

        stateService.unlockObject(arguments.targetId);
        return runObjectInteraction(arguments.scenario, arguments.targetId, "unlock");
    }

    private struct function useObject(required struct scenario, required string targetId) {
        return runObjectInteraction(arguments.scenario, arguments.targetId, "use");
    }

    private struct function askIris(required struct scenario, required string question) {
        var iris = createObject("component", "cfc.IrisService");
        var answer = iris.answerQuestion(session.game, arguments.scenario, len(trim(arguments.question)) ? arguments.question : "What should I look at?");
        return {
            "success": true,
            "action": "ask_iris",
            "narration": answer,
            "stateChanges": {}
        };
    }

    private struct function giveHint(required struct scenario) {
        var iris = createObject("component", "cfc.IrisService");
        var answer = iris.criticalPathHint(session.game, arguments.scenario);
        return {
            "success": true,
            "action": "hint",
            "narration": answer,
            "stateChanges": {}
        };
    }

    private struct function compareEvidence(required struct scenario, required string question) {
        var iris = createObject("component", "cfc.IrisService");
        var answer = iris.compareEvidence(session.game, arguments.scenario, arguments.question);
        return {
            "success": true,
            "action": "compare",
            "narration": answer,
            "stateChanges": {}
        };
    }

    private struct function accuse(required struct scenario, required string suspectId, required string theory) {
        var stateService = createObject("component", "cfc.GameStateService");
        var req = arguments.scenario.progression.accusationRequirements;

        if (!len(arguments.suspectId)) {
            return simpleResult(false, "accuse", "You need to name a suspect before the house will listen.");
        }

        var hasClues = true;
        for (var clueId in req.requiredClues) {
            if (!arrayFindNoCase(session.game.discoveredClues, clueId)) {
                hasClues = false;
            }
        }

        if (compareNoCase(arguments.suspectId, req.requiredSuspect) == 0 && hasClues) {
            stateService.markSolved();
            return {
                "success": true,
                "action": "accuse",
                "narration": arguments.scenario.endingText.success,
                "stateChanges": {"solved": true}
            };
        }

        return {
            "success": false,
            "action": "accuse",
            "narration": arguments.scenario.endingText.failure,
            "stateChanges": {"solved": false}
        };
    }

    private struct function searchCurrentRoom(required struct scenario) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var room = scenarioService.getRoomById(arguments.scenario, session.game.currentRoomId);

        for (var hiddenId in scenarioService.safeArray(room, "hiddenObjects")) {
            if (!stateService.isVisibleInCurrentRoom(hiddenId)) {
                var obj = scenarioService.getObjectById(arguments.scenario, hiddenId);
                stateService.addVisibleObject(room.id, hiddenId);
                createObject("component", "cfc.VectorMemoryService").indexObject(session.game, arguments.scenario, obj, "Discovered while searching the room.");
                return {
                    "success": true,
                    "action": "search",
                    "narration": "You search the " & room.name & " and uncover " & obj.name & ".",
                    "stateChanges": {"revealedObjects": [hiddenId], "revealedClues": []}
                };
            }
        }

        return simpleResult(true, "search", "You search carefully, but nothing else obvious gives itself up.");
    }

    private struct function runObjectInteraction(required struct scenario, required string targetId, required string interactionName) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var obj = scenarioService.getObjectById(arguments.scenario, arguments.targetId);

        if (!structCount(obj)) {
            if (len(arguments.targetId) && stateService.isVisibleInCurrentRoom(arguments.targetId)) {
                stateService.markExaminedObject(arguments.targetId);
                return simpleResult(true, arguments.interactionName, "You check the " & scenarioService.featureName(arguments.targetId) & ". It belongs to the room's atmosphere, but it offers no new evidence.");
            }
            return simpleResult(false, arguments.interactionName, "You do not see that here.");
        }

        if (!canAccessObject(arguments.targetId)) {
            return simpleResult(false, arguments.interactionName, "You do not see that here.");
        }

        stateService.markExaminedObject(arguments.targetId);

        if (
            arguments.interactionName == "search" &&
            structKeyExists(obj, "interactions") &&
            !structKeyExists(obj.interactions, "search")
        ) {
            if (structKeyExists(obj, "container") && obj.container && structKeyExists(obj.interactions, "open")) {
                return runObjectInteraction(arguments.scenario, arguments.targetId, "open");
            }

            if (structKeyExists(obj.interactions, "examine")) {
                return runObjectInteraction(arguments.scenario, arguments.targetId, "examine");
            }
        }

        if (!structKeyExists(obj, "interactions") || !structKeyExists(obj.interactions, arguments.interactionName)) {
            return simpleResult(true, arguments.interactionName, structKeyExists(obj, "description") ? obj.description : "Nothing new stands out.");
        }

        if (structKeyExists(obj, "locked") && obj.locked && arguments.interactionName == "open" && !stateService.isUnlocked(obj.id)) {
            return simpleResult(false, "open", obj.interactions.open.text);
        }

        if (structKeyExists(obj, "locked") && obj.locked && arguments.interactionName == "open" && stateService.isUnlocked(obj.id)) {
            return openUnlockedObject(arguments.scenario, obj);
        }

        var interaction = obj.interactions[arguments.interactionName];
        var key = session.game.currentRoomId & ":" & obj.id & ":" & arguments.interactionName;
        var revealedObjects = [];
        var revealedClues = [];
        var alreadyConsumed = stateService.isConsumed(key);

        if (alreadyConsumed && (structKeyExists(interaction, "revealsObject") || structKeyExists(interaction, "revealsClue"))) {
            return simpleResult(true, arguments.interactionName, "You check again, but you have already found what mattered here.");
        }

        stateService.consumeInteraction(key);

        if (structKeyExists(interaction, "revealsObject")) {
            var revealedObj = scenarioService.getObjectById(arguments.scenario, interaction.revealsObject);
            stateService.addVisibleObject(resolveObjectRoom(arguments.scenario, revealedObj), interaction.revealsObject);
            createObject("component", "cfc.VectorMemoryService").indexObject(session.game, arguments.scenario, revealedObj, interaction.text);
            arrayAppend(revealedObjects, interaction.revealsObject);
        }

        if (structKeyExists(interaction, "revealsClue")) {
            if (stateService.addDiscoveredClue(interaction.revealsClue)) {
                var clue = scenarioService.getClueById(arguments.scenario, interaction.revealsClue);
                createObject("component", "cfc.VectorMemoryService").indexClue(session.game, arguments.scenario, clue, obj);
                arrayAppend(revealedClues, interaction.revealsClue);
            }
        }

        return {
            "success": true,
            "action": arguments.interactionName,
            "narration": interaction.text,
            "stateChanges": {
                "revealedObjects": revealedObjects,
                "revealedClues": revealedClues
            }
        };
    }

    private struct function openUnlockedObject(required struct scenario, required struct obj) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var stateService = createObject("component", "cfc.GameStateService");
        var revealedObjects = [];
        var revealedClues = [];

        if (structKeyExists(arguments.obj, "interactions") && structKeyExists(arguments.obj.interactions, "unlock")) {
            var unlockInteraction = arguments.obj.interactions.unlock;

            if (structKeyExists(unlockInteraction, "revealsObject")) {
                var revealedObj = scenarioService.getObjectById(arguments.scenario, unlockInteraction.revealsObject);
                var revealRoom = resolveObjectRoom(arguments.scenario, revealedObj);
                if (!arrayFindNoCase(stateService.getVisibleObjectIds(revealRoom), unlockInteraction.revealsObject)) {
                    stateService.addVisibleObject(revealRoom, unlockInteraction.revealsObject);
                    createObject("component", "cfc.VectorMemoryService").indexObject(session.game, arguments.scenario, revealedObj, unlockInteraction.text);
                    arrayAppend(revealedObjects, unlockInteraction.revealsObject);
                }
            }

            if (structKeyExists(unlockInteraction, "revealsClue")) {
                if (stateService.addDiscoveredClue(unlockInteraction.revealsClue)) {
                    var clue = scenarioService.getClueById(arguments.scenario, unlockInteraction.revealsClue);
                    createObject("component", "cfc.VectorMemoryService").indexClue(session.game, arguments.scenario, clue, arguments.obj);
                    arrayAppend(revealedClues, unlockInteraction.revealsClue);
                }
            }
        }

        var displayName = reReplaceNoCase(arguments.obj.name, "^locked\s+", "", "one");

        return {
            "success": true,
            "action": "open",
            "narration": "The " & displayName & " is unlocked and open.",
            "stateChanges": {
                "revealedObjects": revealedObjects,
                "revealedClues": revealedClues
            }
        };
    }

    private boolean function canAccessObject(required string objectId) {
        var stateService = createObject("component", "cfc.GameStateService");
        return stateService.isVisibleInCurrentRoom(arguments.objectId) || stateService.isInInventory(arguments.objectId);
    }

    private string function resolveObjectRoom(required struct scenario, required struct obj) {
        if (!structKeyExists(obj, "location")) {
            return session.game.currentRoomId;
        }

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var room = scenarioService.getRoomById(arguments.scenario, obj.location);
        if (structCount(room)) {
            return room.id;
        }

        for (var parent in arguments.scenario.objects) {
            if (compareNoCase(parent.id, obj.location) == 0 && structKeyExists(parent, "location")) {
                return parent.location;
            }
        }

        return session.game.currentRoomId;
    }

    private boolean function meetsUnlockRequirement(required struct requirements) {
        if (structKeyExists(arguments.requirements, "requiresAnyItem")) {
            for (var itemId in arguments.requirements.requiresAnyItem) {
                if (arrayFindNoCase(session.game.inventory, itemId)) {
                    return true;
                }
            }
            return false;
        }

        return true;
    }

    private string function inventoryText(required struct scenario) {
        if (!arrayLen(session.game.inventory)) {
            return "You are carrying nothing but questions.";
        }

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var names = [];
        for (var id in session.game.inventory) {
            var obj = scenarioService.getObjectById(arguments.scenario, id);
            if (structCount(obj)) {
                arrayAppend(names, obj.name);
            }
        }
        return "Inventory: " & arrayToList(names, ", ") & ".";
    }

    private string function cluesText(required struct scenario) {
        if (!arrayLen(session.game.discoveredClues)) {
            return "No confirmed clues yet. The house is still keeping its mouth shut.";
        }

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var names = [];
        for (var id in session.game.discoveredClues) {
            var clue = scenarioService.getClueById(arguments.scenario, id);
            if (structCount(clue)) {
                arrayAppend(names, clue.title);
            }
        }
        return "Discovered clues: " & arrayToList(names, "; ") & ".";
    }

    private struct function simpleResult(required boolean success, required string action, required string narration) {
        return {
            "success": arguments.success,
            "action": arguments.action,
            "narration": arguments.narration,
            "stateChanges": {}
        };
    }
}
