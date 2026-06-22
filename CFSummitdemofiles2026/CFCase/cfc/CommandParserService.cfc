component output=false {
    public struct function parse(
        required string command,
        required struct safeContext,
        boolean allowAiFallback = true
    ) {
        var raw = trim(arguments.command);
        var lower = lCase(raw);
        var parsed = deterministicParse(raw, lower, arguments.safeContext);

        if (parsed.action != "" || parsed.needsClarification) {
            return parsed;
        }

        if (arguments.allowAiFallback && shouldUseAiFallback(lower, arguments.safeContext)) {
            return parseWithAi(raw, arguments.safeContext);
        }

        return {
            "action": "unknown",
            "target": "",
            "targetType": "",
            "secondaryTarget": "",
            "destinationRoom": "",
            "question": "",
            "accusedSuspect": "",
            "theory": "",
            "confidence": 0.4,
            "needsClarification": false,
            "clarificationQuestion": ""
        };
    }

    private struct function deterministicParse(required string raw, required string lower, required struct safeContext) {
        var normalized = normalize(arguments.lower);

        if (!len(normalized)) {
            return blank(true, "What would you like to do?");
        }

        if (listFindNoCase("look,l,look around,where am i,room", normalized)) {
            return actionOnly("look", 1);
        }

        if (listFindNoCase("inventory,inv,i", normalized)) {
            return actionOnly("inventory", 1);
        }

        if (listFindNoCase("clues,evidence", normalized)) {
            return actionOnly("clues", 1);
        }

        if (listFindNoCase("help,commands", normalized)) {
            return actionOnly("help", 1);
        }

        if (
            listFindNoCase("hint,give me a hint,need a hint,i need a hint", normalized) ||
            reFindNoCase("\b(give|need|want|show)\s+(me\s+)?(a\s+)?hint\b", normalized) ||
            reFindNoCase("\b(ask\s+iris|iris)\b.*\bhint\b", normalized)
        ) {
            return actionOnly("hint", 0.98);
        }

        if (left(normalized, 5) == "iris " || left(normalized, 9) == "ask iris" || findNoCase("iris,", arguments.raw) == 1) {
            var q = reReplaceNoCase(arguments.raw, "^\s*(ask\s+iris|iris[:,]?)\s*", "", "one");
            return withQuestion("ask_iris", len(trim(q)) ? trim(q) : "What should I look at next?", 0.95);
        }

        if (left(normalized, 8) == "compare ") {
            return {
                "action": "compare",
                "target": "",
                "targetType": "",
                "secondaryTarget": "",
                "destinationRoom": "",
                "question": mid(arguments.raw, 9, len(arguments.raw)),
                "accusedSuspect": "",
                "theory": "",
                "confidence": 0.9,
                "needsClarification": false,
                "clarificationQuestion": ""
            };
        }

        if (left(normalized, 7) == "accuse " || normalized == "accuse") {
            var suspectId = resolveSuspect(arguments.raw, arguments.safeContext);
            return {
                "action": "accuse",
                "target": suspectId,
                "targetType": "suspect",
                "secondaryTarget": "",
                "destinationRoom": "",
                "question": "",
                "accusedSuspect": suspectId,
                "theory": arguments.raw,
                "confidence": len(suspectId) ? 0.92 : 0.55,
                "needsClarification": !len(suspectId),
                "clarificationQuestion": "Who do you want to accuse?"
            };
        }

        var roomId = resolveRoom(arguments.raw, arguments.safeContext);
        if (len(roomId) && reFindNoCase("\b(go|move|walk|head|enter|return|travel)\b", normalized)) {
            return {
                "action": "move",
                "target": roomId,
                "targetType": "room",
                "secondaryTarget": "",
                "destinationRoom": roomId,
                "question": "",
                "accusedSuspect": "",
                "theory": "",
                "confidence": 0.95,
                "needsClarification": false,
                "clarificationQuestion": ""
            };
        }

        var objectId = resolveObject(arguments.raw, arguments.safeContext);
        var idiom = parseIdiomaticCommand(arguments.raw, normalized, objectId, arguments.safeContext);

        if (idiom.action != "" || idiom.needsClarification) {
            return idiom;
        }

        if (reFindNoCase("\b(take|get|grab|carry|pick\s+up)\b", normalized)) {
            return targetAction("take", objectId, "object", 0.9);
        }

        if (reFindNoCase("\b(read)\b", normalized)) {
            return targetAction("read", objectId, "object", 0.9);
        }

        if (reFindNoCase("\b(open)\b", normalized)) {
            return targetAction("open", objectId, "object", 0.9);
        }

        if (reFindNoCase("\b(unlock)\b", normalized)) {
            var unlockTargetText = trim(reReplaceNoCase(arguments.raw, "\bwith\b.*$", "", "one"));
            var unlockTargetId = resolveObject(unlockTargetText, arguments.safeContext);
            return targetAction("unlock", len(unlockTargetId) ? unlockTargetId : objectId, "object", 0.9);
        }

        if (reFindNoCase("\b(use)\b", normalized)) {
            return targetAction("use", objectId, "object", 0.8);
        }

        if (reFindNoCase("\b(search|check|look inside|look in)\b", normalized)) {
            if (!len(objectId) && reFindNoCase("\b(room|around|area|here)\b", normalized)) {
                return actionOnly("search", 0.95);
            }
            return targetAction("search", objectId, "object", len(objectId) ? 0.92 : 0.55);
        }

        if (reFindNoCase("\b(examine|inspect|look at|study)\b", normalized)) {
            return targetAction("examine", objectId, len(objectId) ? "object" : "", len(objectId) ? 0.92 : 0.55);
        }

        if (reFindNoCase("\b(who do you suspect|what do you suspect|what seems suspicious|hint)\b", normalized)) {
            return withQuestion("ask_iris", arguments.raw, 0.88);
        }

        return blank(false, "");
    }

    private boolean function shouldUseAiFallback(required string lower, required struct safeContext) {
        if (!structKeyExists(application, "caseUseAiParserFallback") || !application.caseUseAiParserFallback) {
            return false;
        }

        if (reFindNoCase("\b(lick|dance|sing|jump|sleep|eat|punch)\b", arguments.lower)) {
            return false;
        }

        return len(trim(arguments.lower)) > 3;
    }

    private struct function parseWithAi(required string raw, required struct safeContext) {
        var ai = createObject("component", "cfc.AiService");
        var prompt = "Map the player command to exactly one JSON object. Return JSON only." & chr(10) &
            "Allowed actions: look, move, search, examine, take, open, unlock, use, read, ask_iris, hint, compare, accuse." & chr(10) &
            "Treat idioms by intent: 'take a look at X', 'have a look at X', 'check out X', and 'look over X' mean examine X, not take X. 'look inside X' or 'look through X' means search X. 'take a look around' means look." & chr(10) &
            "Use only visible context. If a target is not visible, in inventory, an exit, or a listed suspect, leave the target blank and ask for clarification." & chr(10) &
            "Visible context only:" & chr(10) & serializeJson(arguments.safeContext) & chr(10) &
            "Schema: {""action"":"""",""target"":"""",""targetType"":"""",""secondaryTarget"":"""",""destinationRoom"":"""",""question"":"""",""accusedSuspect"":"""",""theory"":"""",""confidence"":0.0,""needsClarification"":false,""clarificationQuestion"":""""}" & chr(10) &
            "Player command: " & arguments.raw;

        if (structKeyExists(session, "game")) {
            session.game.lastParserPrompt = prompt;
        }

        var text = ai.chat([
            {"role": "system", "content": "You parse mystery game commands using only visible context. Never infer hidden facts."},
            {"role": "user", "content": prompt}
        ], 0.1);

        try {
            var parsed = deserializeJson(trim(text));
            return normalizeParsed(parsed);
        }
        catch (any e) {
            throw(
                type="CFCase.ParserAIInvalid",
                message="The AI parser returned invalid JSON.",
                detail=text
            );
        }
    }

    private struct function normalizeParsed(required struct parsed) {
        var base = blank(false, "");
        for (var key in base) {
            if (structKeyExists(arguments.parsed, key)) {
                base[key] = arguments.parsed[key];
            }
        }
        return base;
    }

    private string function resolveRoom(required string raw, required struct safeContext) {
        var lower = normalize(lCase(arguments.raw));
        for (var room in arguments.safeContext.exits) {
            if (containsNormalizedTerm(lower, room.id) || containsNormalizedTerm(lower, room.name)) {
                return room.id;
            }
        }
        return "";
    }

    private string function resolveObject(required string raw, required struct safeContext) {
        var lower = normalize(lCase(arguments.raw));
        var candidates = [];

        if (structKeyExists(arguments.safeContext, "visibleObjects")) {
            for (var item in arguments.safeContext.visibleObjects) {
                arrayAppend(candidates, item);
            }
        }

        if (structKeyExists(arguments.safeContext, "inventory")) {
            for (var item in arguments.safeContext.inventory) {
                arrayAppend(candidates, item);
            }
        }

        var exactId = "";
        var exactTokenCount = 0;
        var exactTieCount = 0;

        for (var candidate in candidates) {
            var exactScore = scoreExactCandidateMatch(candidate, lower);
            if (exactScore > exactTokenCount) {
                exactId = candidate.id;
                exactTokenCount = exactScore;
                exactTieCount = 1;
            }
            else if (exactScore > 0 && exactScore == exactTokenCount) {
                exactTieCount++;
            }
        }

        if (exactTokenCount > 1 && exactTieCount == 1) {
            return exactId;
        }

        var commandTokens = significantTokens(lower);
        var bestId = "";
        var bestScore = 0;
        var tieCount = 0;

        for (var candidate in candidates) {
            var score = scoreCandidateMatch(candidate, commandTokens);
            if (score > bestScore) {
                bestId = candidate.id;
                bestScore = score;
                tieCount = 1;
            }
            else if (score > 0 && score == bestScore) {
                tieCount++;
            }
        }

        if (bestScore > 0 && tieCount == 1) {
            return bestId;
        }

        return "";
    }

    private struct function parseIdiomaticCommand(
        required string raw,
        required string normalized,
        required string objectId,
        required struct safeContext
    ) {
        if (
            reFindNoCase("\b(take|have|get)\s+(a\s+)?(closer\s+|good\s+|quick\s+)?look\s+(inside|in|through)\b", arguments.normalized) ||
            reFindNoCase("\b(look|peek)\s+(inside|in|through)\b", arguments.normalized)
        ) {
            if (!len(arguments.objectId) && reFindNoCase("\b(room|around|area|here)\b", arguments.normalized)) {
                return actionOnly("search", 0.95);
            }
            return targetAction("search", arguments.objectId, len(arguments.objectId) ? "object" : "", len(arguments.objectId) ? 0.92 : 0.55);
        }

        if (
            reFindNoCase("\b(take|have|get)\s+(a\s+)?(closer\s+|good\s+|quick\s+)?look\s+(at|over)\b", arguments.normalized) ||
            reFindNoCase("\b(check out|look over|look closer at|look closely at)\b", arguments.normalized)
        ) {
            return targetAction("examine", arguments.objectId, len(arguments.objectId) ? "object" : "", len(arguments.objectId) ? 0.92 : 0.55);
        }

        if (reFindNoCase("\b(take|have|get)\s+(a\s+)?(closer\s+|good\s+|quick\s+)?look\b", arguments.normalized)) {
            if (!len(arguments.objectId) || reFindNoCase("\b(around|room|area|here)\b", arguments.normalized)) {
                return actionOnly("look", 0.95);
            }
            return targetAction("examine", arguments.objectId, "object", 0.9);
        }

        if (
            reFindNoCase("\b(look for|search for|find)\b", arguments.normalized) &&
            reFindNoCase("\b(clue|clues|evidence|anything|something)\b", arguments.normalized)
        ) {
            return actionOnly("search", 0.9);
        }

        if (
            !len(arguments.objectId) &&
            reFindNoCase("\b(inspect|examine|study|search|check)\b", arguments.normalized) &&
            reFindNoCase("\b(room|area|here)\b", arguments.normalized)
        ) {
            return actionOnly("search", 0.9);
        }

        return blank(false, "");
    }

    private string function resolveSuspect(required string raw, required struct safeContext) {
        var lower = normalize(lCase(arguments.raw));

        if (reFindNoCase("\b(me|myself|yourself|the player|the investigator)\b", lower)) {
            for (var playerSuspect in arguments.safeContext.suspects) {
                if (compareNoCase(playerSuspect.id, "player") == 0) {
                    return playerSuspect.id;
                }
            }
        }

        for (var suspect in arguments.safeContext.suspects) {
            if (find(normalize(lCase(suspect.id)), lower) || find(normalize(lCase(suspect.name)), lower)) {
                return suspect.id;
            }
            var firstName = listFirst(suspect.name, " ");
            if (len(firstName) && reFindNoCase("\b" & normalize(lCase(firstName)) & "\b", lower)) {
                return suspect.id;
            }
        }
        return "";
    }

    private string function normalize(required string value) {
        var cleaned = replace(arguments.value, "_", " ", "all");
        cleaned = reReplace(cleaned, "'s\b", " ", "all");
        cleaned = reReplace(cleaned, "[^a-zA-Z0-9 ]", " ", "all");
        return trim(reReplace(cleaned, "\s+", " ", "all"));
    }

    private boolean function containsNormalizedTerm(required string haystack, required string needle) {
        var cleanNeedle = normalize(lCase(arguments.needle));
        if (!len(cleanNeedle)) {
            return false;
        }
        return find(" " & cleanNeedle & " ", " " & arguments.haystack & " ") > 0;
    }

    private numeric function scoreExactCandidateMatch(required struct candidate, required string lower) {
        var fields = [arguments.candidate.id, arguments.candidate.name];
        var score = 0;

        if (structKeyExists(arguments.candidate, "aliases")) {
            for (var alias in arguments.candidate.aliases) {
                arrayAppend(fields, alias);
            }
        }

        for (var field in fields) {
            if (containsNormalizedTerm(arguments.lower, field)) {
                score = max(score, arrayLen(listToArray(normalize(lCase(field)), " ")));
            }
        }

        return score;
    }

    private array function significantTokens(required string normalized) {
        var tokens = [];
        var stopWords = "a,an,the,to,from,with,on,at,in,inside,into,through,around,here,room,take,get,grab,carry,pick,up,read,open,unlock,use,search,check,look,examine,inspect,study";

        for (var token in listToArray(arguments.normalized, " ")) {
            if (len(token) && !listFindNoCase(stopWords, token)) {
                arrayAppend(tokens, token);
            }
        }

        return tokens;
    }

    private numeric function scoreCandidateMatch(required struct candidate, required array commandTokens) {
        var fields = [arguments.candidate.id, arguments.candidate.name];
        var score = 0;

        if (structKeyExists(arguments.candidate, "aliases")) {
            for (var alias in arguments.candidate.aliases) {
                arrayAppend(fields, alias);
            }
        }

        for (var fieldIndex = 1; fieldIndex <= arrayLen(fields); fieldIndex++) {
            var field = fields[fieldIndex];
            var fieldTokens = listToArray(normalize(lCase(field)), " ");
            for (var i = 1; i <= arrayLen(arguments.commandTokens); i++) {
                if (arrayFindNoCase(fieldTokens, arguments.commandTokens[i])) {
                    score = max(score, (fieldIndex <= 2 ? 100 : 0) + i);
                }
            }
        }

        return score;
    }

    private struct function blank(required boolean needsClarification, required string question) {
        return {
            "action": "",
            "target": "",
            "targetType": "",
            "secondaryTarget": "",
            "destinationRoom": "",
            "question": "",
            "accusedSuspect": "",
            "theory": "",
            "confidence": 0,
            "needsClarification": arguments.needsClarification,
            "clarificationQuestion": arguments.question
        };
    }

    private struct function actionOnly(required string action, required numeric confidence) {
        var parsed = blank(false, "");
        parsed.action = arguments.action;
        parsed.confidence = arguments.confidence;
        return parsed;
    }

    private struct function withQuestion(required string action, required string question, required numeric confidence) {
        var parsed = actionOnly(arguments.action, arguments.confidence);
        parsed.question = arguments.question;
        return parsed;
    }

    private struct function targetAction(required string action, required string target, required string targetType, required numeric confidence) {
        var parsed = actionOnly(arguments.action, arguments.confidence);
        parsed.target = arguments.target;
        parsed.targetType = arguments.targetType;
        if (!len(arguments.target)) {
            parsed.needsClarification = true;
            parsed.clarificationQuestion = "What do you want to " & arguments.action & "?";
        }
        return parsed;
    }
}
