component output=false {
    public array function listScenarios() {
        var out = [];
        var jsonDir = getJsonDir();
        var stateService = createObject("component", "cfc.GameStateService");

        if (!directoryExists(jsonDir)) {
            return out;
        }

        var files = directoryList(jsonDir, false, "path", "*.json");

        for (var filePath in files) {
            try {
                var bundle = loadScenario(getFileFromPath(filePath));
                var scenario = bundle.scenario;

                arrayAppend(out, {
                    "file": bundle.file,
                    "assetFolder": bundle.assetFolder,
                    "scenarioId": getValue(scenario, "scenarioId", ""),
                    "title": getValue(scenario, "title", bundle.file),
                    "subtitle": getValue(scenario, "subtitle", ""),
                    "genre": getValue(scenario, "genre", ""),
                    "tone": getValue(scenario, "tone", ""),
                    "startingRoom": getValue(scenario, "startingRoom", ""),
                    "thumbnail": buildThumbnailPath(scenario, bundle.assetFolder),
                    "intro": stateService.getIntroText(scenario),
                    "warnings": bundle.validation.warnings
                });
            }
            catch (any e) {
                // Ignore unreadable scenario files so one bad case does not break the selector.
            }
        }

        return out;
    }

    public struct function getCachedScenario(required string fileName) {
        var cleanName = sanitizeFileName(arguments.fileName);
        var filePath = joinPath(getJsonDir(), cleanName);
        var sourceStamp = getSourceStamp(filePath);

        if (!structKeyExists(application, "scenarioCache")) {
            application.scenarioCache = {};
        }

        if (
            !structKeyExists(application.scenarioCache, cleanName) ||
            !structKeyExists(application.scenarioCache[cleanName], "sourceStamp") ||
            application.scenarioCache[cleanName].sourceStamp != sourceStamp
        ) {
            var bundle = loadScenario(cleanName);
            bundle["sourceStamp"] = sourceStamp;
            application.scenarioCache[cleanName] = bundle;
        }

        return application.scenarioCache[cleanName];
    }

    public struct function loadScenario(required string fileName) {
        var cleanName = sanitizeFileName(arguments.fileName);
        var filePath = joinPath(getJsonDir(), cleanName);

        if (!fileExists(filePath)) {
            throw(type="CFCase.ScenarioMissing", message="Scenario file not found: " & cleanName);
        }

        var scenario = deserializeJson(fileRead(filePath));
        var assetFolder = structKeyExists(scenario, "assetFolder") && len(trim(scenario.assetFolder))
            ? scenario.assetFolder
            : replace(cleanName, ".json", "", "all");
        var validation = validateScenario(scenario, cleanName, assetFolder);

        return {
            "file": cleanName,
            "path": filePath,
            "assetFolder": assetFolder,
            "scenario": scenario,
            "validation": validation
        };
    }

    public struct function validateScenario(
        required struct scenario,
        required string fileName,
        required string assetFolder
    ) {
        var errors = [];
        var warnings = [];

        for (var key in ["scenarioId", "title", "startingRoom", "rooms", "objects", "clues", "suspects", "abilities"]) {
            if (!structKeyExists(arguments.scenario, key)) {
                arrayAppend(errors, "Missing required key: " & key);
            }
        }

        if (arrayLen(errors)) {
            return {"errors": errors, "warnings": warnings};
        }

        var roomIds = idsFrom(arguments.scenario.rooms);
        var objectIds = idsFrom(arguments.scenario.objects);
        var clueIds = idsFrom(arguments.scenario.clues);
        var suspectIds = idsFrom(arguments.scenario.suspects);

        addDuplicateErrors(errors, roomIds, "room");
        addDuplicateErrors(errors, objectIds, "object");
        addDuplicateErrors(errors, clueIds, "clue");
        addDuplicateErrors(errors, suspectIds, "suspect");

        if (!arrayFindNoCase(roomIds, arguments.scenario.startingRoom)) {
            arrayAppend(errors, "startingRoom does not match a room id: " & arguments.scenario.startingRoom);
        }

        for (var room in arguments.scenario.rooms) {
            for (var exitId in safeArray(room, "exits")) {
                if (!arrayFindNoCase(roomIds, exitId)) {
                    arrayAppend(errors, "Room " & room.id & " exit points to missing room " & exitId);
                }
            }

            for (var visibleId in safeArray(room, "visibleObjects")) {
                if (!arrayFindNoCase(objectIds, visibleId)) {
                    arrayAppend(warnings, "Room " & room.id & " visible feature is not a top-level object: " & visibleId);
                }
            }

            for (var hiddenId in safeArray(room, "hiddenObjects")) {
                if (!arrayFindNoCase(objectIds, hiddenId)) {
                    arrayAppend(errors, "Room " & room.id & " hiddenObject points to missing object " & hiddenId);
                }
            }

            if (structKeyExists(room, "imageFile") && len(trim(room.imageFile))) {
                var imagePath = joinPath(joinPath(getImgDir(), arguments.assetFolder), room.imageFile);
                if (!fileExists(imagePath)) {
                    arrayAppend(warnings, "Room " & room.id & " image missing: " & room.imageFile);
                }
            }
        }

        for (var obj in arguments.scenario.objects) {
            if (structKeyExists(obj, "location") && len(trim(obj.location))) {
                if (!arrayFindNoCase(roomIds, obj.location) && !arrayFindNoCase(objectIds, obj.location)) {
                    arrayAppend(errors, "Object " & obj.id & " location points to missing id " & obj.location);
                }
            }

            if (structKeyExists(obj, "interactions")) {
                for (var interactionName in obj.interactions) {
                    var interaction = obj.interactions[interactionName];
                    if (structKeyExists(interaction, "revealsObject") && !arrayFindNoCase(objectIds, interaction.revealsObject)) {
                        arrayAppend(errors, "Object " & obj.id & "." & interactionName & " reveals missing object " & interaction.revealsObject);
                    }
                    if (structKeyExists(interaction, "revealsClue") && !arrayFindNoCase(clueIds, interaction.revealsClue)) {
                        arrayAppend(errors, "Object " & obj.id & "." & interactionName & " reveals missing clue " & interaction.revealsClue);
                    }
                }
            }
        }

        if (structKeyExists(arguments.scenario, "progression") && structKeyExists(arguments.scenario.progression, "accusationRequirements")) {
            var req = arguments.scenario.progression.accusationRequirements;
            if (structKeyExists(req, "requiredSuspect") && !arrayFindNoCase(suspectIds, req.requiredSuspect)) {
                arrayAppend(errors, "Accusation requiredSuspect missing: " & req.requiredSuspect);
            }
            for (var clueId in safeArray(req, "requiredClues")) {
                if (!arrayFindNoCase(clueIds, clueId)) {
                    arrayAppend(errors, "Accusation requiredClue missing: " & clueId);
                }
            }
        }

        return {"errors": errors, "warnings": warnings};
    }

    public struct function getRoomById(required struct scenario, required string id) {
        for (var room in arguments.scenario.rooms) {
            if (compareNoCase(room.id, arguments.id) == 0) {
                return room;
            }
        }
        return {};
    }

    public struct function getObjectById(required struct scenario, required string id) {
        for (var obj in arguments.scenario.objects) {
            if (compareNoCase(obj.id, arguments.id) == 0) {
                return obj;
            }
        }
        return {};
    }

    public struct function getClueById(required struct scenario, required string id) {
        for (var clue in arguments.scenario.clues) {
            if (compareNoCase(clue.id, arguments.id) == 0) {
                return clue;
            }
        }
        return {};
    }

    public struct function getSuspectById(required struct scenario, required string id) {
        for (var suspect in arguments.scenario.suspects) {
            if (compareNoCase(suspect.id, arguments.id) == 0) {
                return suspect;
            }
        }
        return {};
    }

    public string function buildImageUrl(required string assetFolder, required string imageFile) {
        if (!len(trim(arguments.imageFile))) {
            return "/CFSummit2026/demos/CFCase/img/placeholder_room.png";
        }
        return "/CFSummit2026/demos/CFCase/img/" & arguments.assetFolder & "/" & arguments.imageFile;
    }

    public string function featureName(required string id) {
        var words = listToArray(replace(arguments.id, "_", " ", "all"), " ");
        var out = [];
        for (var word in words) {
            if (len(word)) {
                arrayAppend(out, uCase(left(word, 1)) & mid(word, 2, len(word)));
            }
        }
        return arrayToList(out, " ");
    }

    public array function safeArray(required struct source, required string key) {
        if (structKeyExists(arguments.source, arguments.key) && isArray(arguments.source[arguments.key])) {
            return arguments.source[arguments.key];
        }
        return [];
    }

    private string function getRoot() {
        return structKeyExists(application, "caseRoot") ? application.caseRoot : expandPath("./");
    }

    private string function getJsonDir() {
        return joinPath(getRoot(), "json");
    }

    private string function getImgDir() {
        return joinPath(getRoot(), "img");
    }

    private string function sanitizeFileName(required string fileName) {
        var cleanName = getFileFromPath(arguments.fileName);
        cleanName = replace(cleanName, "\", "", "all");
        cleanName = replace(cleanName, "/", "", "all");
        if (!reFindNoCase("\.json$", cleanName)) {
            throw(type="CFCase.InvalidScenarioName", message="Scenario file must be a JSON file.");
        }
        return cleanName;
    }

    private string function joinPath(required string left, required string right) {
        var sep = createObject("java", "java.io.File").separator;
        var l = reReplace(arguments.left, "[\\/]+$", "", "all");
        var r = reReplace(arguments.right, "^[\\/]+", "", "all");
        return l & sep & r;
    }

    private string function buildThumbnailPath(required struct scenario, required string assetFolder) {
        var room = getRoomById(arguments.scenario, getValue(arguments.scenario, "startingRoom", ""));
        if (structCount(room) && structKeyExists(room, "imageFile")) {
            return buildImageUrl(arguments.assetFolder, room.imageFile);
        }
        return "/CFSummit2026/demos/CFCase/img/placeholder_room.png";
    }

    private string function getSourceStamp(required string filePath) {
        if (!fileExists(arguments.filePath)) {
            return "";
        }

        var fileInfo = getFileInfo(arguments.filePath);
        return dateTimeFormat(fileInfo.lastModified, "yyyy-mm-dd HH:nn:ss") & ":" & fileInfo.size;
    }

    private any function getValue(required struct source, required string key, required any fallback) {
        return structKeyExists(arguments.source, arguments.key) ? arguments.source[arguments.key] : arguments.fallback;
    }

    private array function idsFrom(required array rows) {
        var ids = [];
        for (var row in arguments.rows) {
            if (isStruct(row) && structKeyExists(row, "id")) {
                arrayAppend(ids, row.id);
            }
        }
        return ids;
    }

    private void function addDuplicateErrors(required array errors, required array ids, required string label) {
        var seen = {};
        for (var id in arguments.ids) {
            var key = lCase(id);
            if (structKeyExists(seen, key)) {
                arrayAppend(arguments.errors, "Duplicate " & arguments.label & " id: " & id);
            }
            seen[key] = true;
        }
    }
}
