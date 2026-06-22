component output=false {
    public boolean function hasGame() {
        return structKeyExists(session, "game") && isStruct(session.game);
    }

    public void function initializeGame(required struct bundle) {
        var scenario = arguments.bundle.scenario;
        var nowText = isoNow();
        var visibleByRoom = {};

        for (var room in scenario.rooms) {
            visibleByRoom[room.id] = duplicate(createObject("component", "cfc.ScenarioService").safeArray(room, "visibleObjects"));
        }

        session.game = {
            "gameId": createUUID(),
            "scenarioFile": arguments.bundle.file,
            "assetFolder": arguments.bundle.assetFolder,
            "scenarioId": scenario.scenarioId,
            "title": scenario.title,
            "currentRoomId": scenario.startingRoom,
            "visitedRooms": [scenario.startingRoom],
            "visibleObjects": visibleByRoom,
            "discoveredObjects": [],
            "examinedObjects": [],
            "discoveredClues": [],
            "inventory": duplicate(structKeyExists(scenario, "inventoryDefaults") ? scenario.inventoryDefaults : []),
            "unlockedObjects": [],
            "consumedInteractions": [],
            "actionHistory": [],
            "irisHistory": [],
            "memoryIds": [],
            "lastParsedAction": {},
            "lastVectorHits": [],
            "lastParserPrompt": "",
            "lastIrisPrompt": "",
            "lastIrisHintPrompt": "",
            "solved": false,
            "createdAt": nowText,
            "updatedAt": nowText
        };
    }

    public struct function getSafeState(
        required struct scenario,
        required string assetFolder,
        boolean debugMode = false
    ) {
        if (!hasGame()) {
            return {};
        }

        ensureCollections();

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var room = scenarioService.getRoomById(arguments.scenario, session.game.currentRoomId);
        var exits = [];
        var visible = [];
        var inventory = [];
        var clues = [];
        var suspects = [];

        for (var exitId in scenarioService.safeArray(room, "exits")) {
            var exitRoom = scenarioService.getRoomById(arguments.scenario, exitId);
            if (structCount(exitRoom)) {
                arrayAppend(exits, {"id": exitRoom.id, "name": exitRoom.name});
            }
        }

        for (var itemId in getVisibleObjectIds(session.game.currentRoomId)) {
            arrayAppend(visible, safeVisibleItem(arguments.scenario, itemId));
        }

        for (var itemId in session.game.inventory) {
            var obj = scenarioService.getObjectById(arguments.scenario, itemId);
            if (structCount(obj)) {
                arrayAppend(inventory, safeObject(obj));
            }
        }

        for (var clueId in session.game.discoveredClues) {
            var clue = scenarioService.getClueById(arguments.scenario, clueId);
            if (structCount(clue)) {
                arrayAppend(clues, safeClue(clue));
            }
        }

        for (var suspect in arguments.scenario.suspects) {
            arrayAppend(suspects, {
                "id": suspect.id,
                "name": suspect.name,
                "role": structKeyExists(suspect, "role") ? suspect.role : "",
                "publicDescription": structKeyExists(suspect, "publicDescription") ? suspect.publicDescription : "",
                "publicAlibi": structKeyExists(suspect, "publicAlibi") ? suspect.publicAlibi : ""
            });
        }

        var criticalPathProgress = getCriticalPathProgress(arguments.scenario);

        var state = {
            "gameId": session.game.gameId,
            "scenarioId": session.game.scenarioId,
            "title": session.game.title,
            "currentRoom": {
                "id": room.id,
                "name": room.name,
                "description": room.description,
                "image": scenarioService.buildImageUrl(arguments.assetFolder, structKeyExists(room, "imageFile") ? room.imageFile : ""),
                "exits": exits,
                "visibleObjects": visible
            },
            "inventory": inventory,
            "discoveredClues": clues,
            "clueProgress": {
                "found": arrayLen(session.game.discoveredClues),
                "total": arrayLen(arguments.scenario.clues),
                "remaining": max(0, arrayLen(arguments.scenario.clues) - arrayLen(session.game.discoveredClues))
            },
            "criticalPathProgress": criticalPathProgress,
            "suspects": suspects,
            "visitedRooms": session.game.visitedRooms,
            "solved": session.game.solved
        };

        if (arguments.debugMode) {
            state["debug"] = getDebugState();
        }

        return state;
    }

    public struct function getSafeParserContext(required struct scenario) {
        var state = getSafeState(arguments.scenario, session.game.assetFolder, false);
        return {
            "currentRoom": {
                "id": state.currentRoom.id,
                "name": state.currentRoom.name,
                "description": state.currentRoom.description
            },
            "exits": state.currentRoom.exits,
            "visibleObjects": state.currentRoom.visibleObjects,
            "inventory": state.inventory,
            "discoveredClues": state.discoveredClues,
            "suspects": state.suspects,
            "availableActions": ["look", "move", "search", "examine", "take", "open", "unlock", "use", "read", "ask_iris", "hint", "compare", "accuse"]
        };
    }

    public array function getVisibleObjectIds(required string roomId) {
        ensureCollections();
        if (structKeyExists(session.game.visibleObjects, arguments.roomId)) {
            return session.game.visibleObjects[arguments.roomId];
        }
        return [];
    }

    public boolean function isVisibleInCurrentRoom(required string objectId) {
        return arrayFindNoCase(getVisibleObjectIds(session.game.currentRoomId), arguments.objectId) > 0;
    }

    public boolean function isInInventory(required string objectId) {
        ensureCollections();
        return arrayFindNoCase(session.game.inventory, arguments.objectId) > 0;
    }

    public void function moveToRoom(required string roomId) {
        session.game.currentRoomId = arguments.roomId;
        if (!arrayFindNoCase(session.game.visitedRooms, arguments.roomId)) {
            arrayAppend(session.game.visitedRooms, arguments.roomId);
        }
        touch();
    }

    public boolean function markExaminedObject(required string objectId) {
        ensureCollections();
        if (!arrayFindNoCase(session.game.examinedObjects, arguments.objectId)) {
            arrayAppend(session.game.examinedObjects, arguments.objectId);
            touch();
            return true;
        }
        return false;
    }

    public boolean function isExaminedObject(required string objectId) {
        ensureCollections();
        return arrayFindNoCase(session.game.examinedObjects, arguments.objectId) > 0;
    }

    public void function addVisibleObject(required string roomId, required string objectId) {
        ensureCollections();
        if (!structKeyExists(session.game.visibleObjects, arguments.roomId)) {
            session.game.visibleObjects[arguments.roomId] = [];
        }
        if (!arrayFindNoCase(session.game.visibleObjects[arguments.roomId], arguments.objectId)) {
            arrayAppend(session.game.visibleObjects[arguments.roomId], arguments.objectId);
        }
        addDiscoveredObject(arguments.objectId);
        touch();
    }

    public void function addDiscoveredObject(required string objectId) {
        if (!arrayFindNoCase(session.game.discoveredObjects, arguments.objectId)) {
            arrayAppend(session.game.discoveredObjects, arguments.objectId);
        }
        touch();
    }

    public boolean function addDiscoveredClue(required string clueId) {
        if (!arrayFindNoCase(session.game.discoveredClues, arguments.clueId)) {
            arrayAppend(session.game.discoveredClues, arguments.clueId);
            touch();
            return true;
        }
        return false;
    }

    public boolean function addInventory(required string objectId) {
        if (!arrayFindNoCase(session.game.inventory, arguments.objectId)) {
            arrayAppend(session.game.inventory, arguments.objectId);
            removeVisibleObject(session.game.currentRoomId, arguments.objectId);
            touch();
            return true;
        }
        return false;
    }

    public void function removeVisibleObject(required string roomId, required string objectId) {
        if (!structKeyExists(session.game.visibleObjects, arguments.roomId)) {
            return;
        }
        var idx = arrayFindNoCase(session.game.visibleObjects[arguments.roomId], arguments.objectId);
        if (idx) {
            arrayDeleteAt(session.game.visibleObjects[arguments.roomId], idx);
        }
    }

    public boolean function unlockObject(required string objectId) {
        if (!arrayFindNoCase(session.game.unlockedObjects, arguments.objectId)) {
            arrayAppend(session.game.unlockedObjects, arguments.objectId);
            touch();
            return true;
        }
        return false;
    }

    public boolean function isUnlocked(required string objectId) {
        return arrayFindNoCase(session.game.unlockedObjects, arguments.objectId) > 0;
    }

    public boolean function consumeInteraction(required string key) {
        if (!arrayFindNoCase(session.game.consumedInteractions, arguments.key)) {
            arrayAppend(session.game.consumedInteractions, arguments.key);
            touch();
            return true;
        }
        return false;
    }

    public boolean function isConsumed(required string key) {
        return arrayFindNoCase(session.game.consumedInteractions, arguments.key) > 0;
    }

    public void function addHistory(required string command, required struct parsed, required string narration) {
        arrayAppend(session.game.actionHistory, {
            "command": arguments.command,
            "parsed": arguments.parsed,
            "narration": arguments.narration,
            "createdAt": isoNow()
        });
        session.game.lastParsedAction = arguments.parsed;
        touch();
    }

    public void function addIrisHistory(required string question, required string answer) {
        arrayAppend(session.game.irisHistory, {
            "question": arguments.question,
            "answer": arguments.answer,
            "createdAt": isoNow()
        });
        touch();
    }

    public void function markSolved() {
        session.game.solved = true;
        touch();
    }

    public string function getIntroText(required struct scenario) {
        for (var key in ["introText", "publicIntro", "openingText", "scenarioIntro"]) {
            if (structKeyExists(arguments.scenario, key) && len(trim(arguments.scenario[key]))) {
                return arguments.scenario[key];
            }
        }

        if (
            structKeyExists(arguments.scenario, "initialCaseFile") &&
            isStruct(arguments.scenario.initialCaseFile) &&
            structKeyExists(arguments.scenario.initialCaseFile, "publicFacts") &&
            isArray(arguments.scenario.initialCaseFile.publicFacts) &&
            arrayLen(arguments.scenario.initialCaseFile.publicFacts)
        ) {
            return arrayToList(arguments.scenario.initialCaseFile.publicFacts, chr(10) & chr(10));
        }

        var scenarioService = createObject("component", "cfc.ScenarioService");
        var title = structKeyExists(arguments.scenario, "title") ? arguments.scenario.title : "the case";
        var roomName = "the starting room";

        if (structKeyExists(arguments.scenario, "startingRoom")) {
            var room = scenarioService.getRoomById(arguments.scenario, arguments.scenario.startingRoom);
            roomName = structCount(room) && structKeyExists(room, "name") ? room.name : scenarioService.featureName(arguments.scenario.startingRoom);
        }

        return "The case file opens: " & title & "." & chr(10) & chr(10) &
            "You stand in " & roomName & ".";
    }

    public struct function getDebugState() {
        ensureCollections();
        return {
            "currentRoomId": session.game.currentRoomId,
            "visibleObjectIds": getVisibleObjectIds(session.game.currentRoomId),
            "discoveredObjectIds": session.game.discoveredObjects,
            "examinedObjectIds": session.game.examinedObjects,
            "discoveredClueIds": session.game.discoveredClues,
            "inventoryIds": session.game.inventory,
            "unlockedObjectIds": session.game.unlockedObjects,
            "consumedInteractions": session.game.consumedInteractions,
            "lastParsedAction": session.game.lastParsedAction,
            "lastVectorHits": session.game.lastVectorHits,
            "lastParserPrompt": session.game.lastParserPrompt,
            "lastIrisPrompt": session.game.lastIrisPrompt,
            "lastIrisHintPrompt": structKeyExists(session.game, "lastIrisHintPrompt") ? session.game.lastIrisHintPrompt : ""
        };
    }

    private struct function safeVisibleItem(required struct scenario, required string itemId) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var obj = scenarioService.getObjectById(arguments.scenario, arguments.itemId);

        if (structCount(obj)) {
            return safeObject(obj);
        }

        return {
            "id": arguments.itemId,
            "name": scenarioService.featureName(arguments.itemId),
            "description": "A visible room feature. It may be worth noting, but it is not evidence by itself.",
            "type": "feature",
            "portable": false,
            "aliases": [],
            "examined": isExaminedObject(arguments.itemId)
        };
    }

    private struct function safeObject(required struct obj) {
        return {
            "id": arguments.obj.id,
            "name": arguments.obj.name,
            "description": structKeyExists(arguments.obj, "description") ? arguments.obj.description : "",
            "type": "object",
            "portable": structKeyExists(arguments.obj, "portable") ? arguments.obj.portable : false,
            "aliases": structKeyExists(arguments.obj, "aliases") ? arguments.obj.aliases : [],
            "examined": isExaminedObject(arguments.obj.id)
        };
    }

    private struct function safeClue(required struct clue) {
        return {
            "id": arguments.clue.id,
            "title": arguments.clue.title,
            "text": structKeyExists(arguments.clue, "text") ? arguments.clue.text : "",
            "category": structKeyExists(arguments.clue, "category") ? arguments.clue.category : "",
            "tags": structKeyExists(arguments.clue, "tags") ? arguments.clue.tags : []
        };
    }

    private struct function getCriticalPathProgress(required struct scenario) {
        var criticalPathClues = [];

        if (
            structKeyExists(arguments.scenario, "progression") &&
            isStruct(arguments.scenario.progression) &&
            structKeyExists(arguments.scenario.progression, "criticalPathClues") &&
            isArray(arguments.scenario.progression.criticalPathClues)
        ) {
            criticalPathClues = arguments.scenario.progression.criticalPathClues;
        }

        var found = 0;
        for (var clueId in criticalPathClues) {
            if (arrayFindNoCase(session.game.discoveredClues, clueId)) {
                found++;
            }
        }

        return {
            "found": found,
            "total": arrayLen(criticalPathClues),
            "remaining": max(0, arrayLen(criticalPathClues) - found)
        };
    }

    private void function touch() {
        session.game.updatedAt = isoNow();
    }

    private void function ensureCollections() {
        if (!hasGame()) {
            return;
        }

        if (!structKeyExists(session.game, "examinedObjects") || !isArray(session.game.examinedObjects)) {
            session.game.examinedObjects = [];
        }
    }

    private string function isoNow() {
        return dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss");
    }
}
