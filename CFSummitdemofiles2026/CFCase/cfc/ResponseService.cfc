component output=false {
    public struct function actionResponse(
        required boolean success,
        required string action,
        required string narration,
        required struct state,
        struct stateChanges = {},
        struct parsed = {},
        struct debug = {}
    ) {
        var out = {
            "success": arguments.success,
            "action": arguments.action,
            "narration": arguments.narration,
            "stateChanges": arguments.stateChanges,
            "state": arguments.state
        };

        if (structCount(arguments.parsed)) {
            out["parsed"] = arguments.parsed;
        }

        if (structCount(arguments.debug)) {
            out["debug"] = arguments.debug;
        }

        return out;
    }

    public string function helpText() {
        return "Try: look around, go to another room, examine a visible object, search a container, take a portable item, read a document, ask IRIS what seems suspicious, give me a hint, compare two pieces of evidence, or accuse a suspect by name.";
    }

    public string function unknownText() {
        return "The house offers no useful response to that. Try a verb like look, move, search, examine, read, take, open, unlock, use, ask IRIS, hint, compare, or accuse.";
    }
}
