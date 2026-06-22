component output=false {
    public void function initializeGameMemory(required struct game, required struct scenario) {
        getStore();
        session.game.lastVectorHits = [];
    }

    public any function getStore() {
        if (!structKeyExists(application, "caseVectorStore")) {
            try {
                application.caseVectorStore = VectorStore({
                    "provider": "inmemory",
                    "embeddingModel": {
                        "provider": "ollama",
                        "modelName": "nomic-embed-text",
                        "baseUrl": "http://localhost:11434"
                    }
                });
            }
            catch (any e) {
                throw(
                    type="CFCase.VectorStoreUnavailable",
                    message="ColdFusion VectorStore with Ollama embeddings is not available.",
                    detail=e.message
                );
            }
        }

        return application.caseVectorStore;
    }

    public void function indexCurrentRoom(required struct game, required struct scenario) {
        var scenarioService = createObject("component", "cfc.ScenarioService");
        var room = scenarioService.getRoomById(arguments.scenario, arguments.game.currentRoomId);
        var visibleNames = [];

        for (var id in arguments.game.visibleObjects[room.id]) {
            var obj = scenarioService.getObjectById(arguments.scenario, id);
            arrayAppend(visibleNames, structCount(obj) ? obj.name : scenarioService.featureName(id));
        }

        addMemory(
            arguments.game.gameId,
            arguments.game.scenarioId,
            "Room: " & room.name & ". " & room.description & " Visible: " & arrayToList(visibleNames, ", "),
            {
                "sourceType": "room",
                "sourceId": room.id,
                "roomId": room.id
            }
        );
    }

    public void function indexObject(
        required struct game,
        required struct scenario,
        required struct obj,
        string note = ""
    ) {
        if (!structCount(arguments.obj)) {
            return;
        }

        addMemory(
            arguments.game.gameId,
            arguments.game.scenarioId,
            "Object: " & arguments.obj.name & ". " & arguments.obj.description & " " & arguments.note,
            {
                "sourceType": "object",
                "sourceId": arguments.obj.id,
                "objectId": arguments.obj.id,
                "roomId": structKeyExists(arguments.obj, "location") ? arguments.obj.location : arguments.game.currentRoomId
            }
        );
    }

    public void function indexClue(
        required struct game,
        required struct scenario,
        required struct clue,
        required struct sourceObject
    ) {
        if (!structCount(arguments.clue)) {
            return;
        }

        addMemory(
            arguments.game.gameId,
            arguments.game.scenarioId,
            "Clue: " & arguments.clue.title & ". " & arguments.clue.text,
            {
                "sourceType": "clue",
                "sourceId": arguments.clue.id,
                "objectId": structKeyExists(arguments.sourceObject, "id") ? arguments.sourceObject.id : "",
                "roomId": structKeyExists(arguments.sourceObject, "location") ? arguments.sourceObject.location : arguments.game.currentRoomId,
                "tags": structKeyExists(arguments.clue, "tags") ? arrayToList(arguments.clue.tags, ",") : ""
            }
        );
    }

    public void function addMemory(
        required string gameId,
        required string scenarioId,
        required string text,
        required struct metadata
    ) {
        var telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
        var span = telemetry.startSpan(
            trace = telemetry.currentTrace(),
            operationType = "vector.add",
            operationName = "CFCase vector memory add",
            metadata = {
                sourceType: structKeyExists(arguments.metadata, "sourceType") ? arguments.metadata.sourceType : "",
                sourceId: structKeyExists(arguments.metadata, "sourceId") ? arguments.metadata.sourceId : "",
                scenarioId: arguments.scenarioId,
                localModel: true
            }
        );
        var store = "";
        var meta = duplicate(arguments.metadata);
        meta.gameId = arguments.gameId;
        meta.scenarioId = arguments.scenarioId;
        meta.visibility = "discovered";
        meta.createdAt = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss");

        try {
            store = getStore();
            store.add({
                "text": arguments.text,
                "metadata": meta
            });
            var inputTokens = telemetry.estimateTokens(arguments.text);
            telemetry.finishSpan(span, {
                status: "success",
                provider: "ollama",
                modelName: "nomic-embed-text",
                inputTokens: inputTokens,
                totalTokens: inputTokens,
                promptText: arguments.text,
                requestBytes: telemetry.estimateBytes(arguments.text),
                metadata: {
                    sourceType: structKeyExists(arguments.metadata, "sourceType") ? arguments.metadata.sourceType : "",
                    scenarioId: arguments.scenarioId,
                    localModel: true
                }
            });
        }
        catch (any e) {
            var failedInputTokens = telemetry.estimateTokens(arguments.text);
            telemetry.finishSpan(span, {
                status: "error",
                provider: "ollama",
                modelName: "nomic-embed-text",
                inputTokens: failedInputTokens,
                totalTokens: failedInputTokens,
                promptText: arguments.text,
                requestBytes: telemetry.estimateBytes(arguments.text),
                errorType: structKeyExists(e, "type") ? e.type : "",
                errorMessage: e.message,
                metadata: {
                    sourceType: structKeyExists(arguments.metadata, "sourceType") ? arguments.metadata.sourceType : "",
                    scenarioId: arguments.scenarioId,
                    localModel: true
                }
            });
            throw(
                type="CFCase.VectorAddFailed",
                message="Unable to index discovered memory.",
                detail=e.message
            );
        }
    }

    public array function searchMemory(
        required string gameId,
        required string scenarioId,
        required string query
    ) {
        var telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
        var span = telemetry.startSpan(
            trace = telemetry.currentTrace(),
            operationType = "vector.search",
            operationName = "CFCase vector memory search",
            metadata = {
                scenarioId: arguments.scenarioId,
                topK: 6,
                minScore: 0.35,
                localModel: true
            }
        );
        var store = "";

        try {
            store = getStore();
            var hits = store.search({
                "text": arguments.query,
                "topK": 6,
                "minScore": 0.35,
                "filter": {
                    "gameId": arguments.gameId,
                    "scenarioId": arguments.scenarioId,
                    "visibility": "discovered"
                }
            });

            session.game.lastVectorHits = isArray(hits) ? hits : [hits];
            var inputTokens = telemetry.estimateTokens(arguments.query);
            telemetry.finishSpan(span, {
                status: "success",
                provider: "ollama",
                modelName: "nomic-embed-text",
                inputTokens: inputTokens,
                totalTokens: inputTokens,
                promptText: arguments.query,
                requestBytes: telemetry.estimateBytes(arguments.query),
                metadata: {
                    resultCount: arrayLen(session.game.lastVectorHits),
                    scenarioId: arguments.scenarioId,
                    localModel: true
                }
            });
            return session.game.lastVectorHits;
        }
        catch (any e) {
            var failedInputTokens = telemetry.estimateTokens(arguments.query);
            telemetry.finishSpan(span, {
                status: "error",
                provider: "ollama",
                modelName: "nomic-embed-text",
                inputTokens: failedInputTokens,
                totalTokens: failedInputTokens,
                promptText: arguments.query,
                requestBytes: telemetry.estimateBytes(arguments.query),
                errorType: structKeyExists(e, "type") ? e.type : "",
                errorMessage: e.message,
                metadata: {
                    scenarioId: arguments.scenarioId,
                    localModel: true
                }
            });
            throw(
                type="CFCase.VectorSearchFailed",
                message="Unable to search discovered memory.",
                detail=e.message
            );
        }
    }
}
