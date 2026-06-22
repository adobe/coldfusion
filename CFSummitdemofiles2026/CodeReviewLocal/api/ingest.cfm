<cfsetting showdebugoutput="false" requesttimeout="300">
<cfscript>
apiUtil = new codereview.ApiUtil();
chunker = new codereview.StandardsChunker();
helpers = new codereview.AppHelpers();
telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
trace = "";
ingestSpan = "";
ingestTokenEstimate = 0;
ingestByteEstimate = 0;

try {
    payload = apiUtil.getRequestJson();
    embeddingProfile = lcase(trim(apiUtil.readKey(payload, "embeddingProfile", application.embeddingProfile)));
    trace = telemetry.startTrace(
        workflowName = "code_review_ingest",
        userId = "code-review-admin",
        sessionId = structKeyExists(session, "sessionid") ? session.sessionid : "",
        metadata = {
            route: cgi.script_name,
            requestedEmbeddingProfile: embeddingProfile
        }
    );
    request.cairoiTrace = trace;

    if (!listFindNoCase("cloud,local", embeddingProfile)) {
        embeddingProfile = "cloud";
    }

    helpers.applyEmbeddingProfile(embeddingProfile);

    if (!helpers.canIngestWithProfile(embeddingProfile)) {
        msg = embeddingProfile == "local"
            ? "Ollama is not reachable at " & application.ollamaBaseUrl & ". Start Ollama and pull " & application.ollamaEmbeddingModel & "."
            : "Add your OpenAI API key to the keystore as openaiapi_codereview before ingesting with cloud embeddings.";
        telemetry.finishTrace(trace, "error", { errorType: "EmbeddingProfileUnavailable", embeddingProfile: embeddingProfile });
        apiUtil.sendJson({ ok: false, message: msg, cairoi: telemetry.traceLinks(trace) }, 400);
    }

    items = chunker.chunkDirectory(application.standardsDir);
    if (!arrayLen(items)) {
        telemetry.finishTrace(trace, "error", { errorType: "NoStandardsDocuments" });
        apiUtil.sendJson({ ok: false, message: "No standards documents found in data/standards/.", cairoi: telemetry.traceLinks(trace) }, 400);
    }

    for (item in items) {
        itemText = structKeyExists(item, "text") ? item.text : "";
        ingestTokenEstimate += telemetry.estimateTokens(itemText);
        ingestByteEstimate += telemetry.estimateBytes(itemText);
    }

    ingestSpan = telemetry.startSpan(
        trace = trace,
        operationType = "rag.ingest",
        operationName = "CodeReview manual standards ingest",
        metadata = {
            embeddingProfile: application.embeddingProfile,
            chunkCount: arrayLen(items),
            localModel: application.embeddingProvider == "ollama"
        }
    );

    if (isObject(application.vectorClient)) {
        helpers.clearVectorStore(application.vectorClient);
    }

    collectionName = helpers.makeCollectionName();
    vectorStore = helpers.makeVectorClient(collectionName);
    helpers.clearVectorStore(vectorStore);

    addedIds = [];
    batchSize = 100;
    for (i = 1; i <= arrayLen(items); i += batchSize) {
        count = min(batchSize, arrayLen(items) - i + 1);
        batch = arraySlice(items, i, count);
        batchIds = vectorStore.addAll(batch);
        if (isArray(batchIds)) {
            arrayAppend(addedIds, batchIds, true);
        }
    }

    lock name="CodeReviewLocalIngestState" type="exclusive" timeout=60 {
        application.vectorClient = vectorStore;
        application.ingestStatus = {
            ready: true,
            sourceName: "Coding standards corpus",
            chunkCount: arrayLen(items),
            addedCount: arrayLen(addedIds) ? arrayLen(addedIds) : arrayLen(items),
            ingestedAt: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            collectionName: collectionName,
            embeddingProfile: application.embeddingProfile,
            message: "Ingested " & arrayLen(items) & " standards chunks using " & application.embeddingProfile & " embeddings."
        };
    }

    telemetry.finishSpan(ingestSpan, {
        status: "success",
        provider: application.embeddingProvider,
        modelName: application.embeddingModelName,
        inputTokens: ingestTokenEstimate,
        totalTokens: ingestTokenEstimate,
        requestBytes: ingestByteEstimate,
        metadata: {
            embeddingProfile: application.embeddingProfile,
            chunkCount: application.ingestStatus.chunkCount,
            addedCount: application.ingestStatus.addedCount,
            collectionName: application.ingestStatus.collectionName,
            localModel: application.embeddingProvider == "ollama"
        }
    });
    telemetry.finishTrace(trace, "success", {
        embeddingProfile: application.ingestStatus.embeddingProfile,
        chunkCount: application.ingestStatus.chunkCount,
        addedCount: application.ingestStatus.addedCount
    });
    apiUtil.sendJson({
        ok: true,
        ready: true,
        chunkCount: application.ingestStatus.chunkCount,
        addedCount: application.ingestStatus.addedCount,
        ingestedAt: application.ingestStatus.ingestedAt,
        collectionName: application.ingestStatus.collectionName,
        embeddingProfile: application.ingestStatus.embeddingProfile,
        message: application.ingestStatus.message,
        cairoi: telemetry.traceLinks(trace)
    });
} catch (any error) {
    telemetry.finishSpan(ingestSpan, {
        status: "error",
        provider: structKeyExists(application, "embeddingProvider") ? application.embeddingProvider : "",
        modelName: structKeyExists(application, "embeddingModelName") ? application.embeddingModelName : "",
        inputTokens: ingestTokenEstimate,
        totalTokens: ingestTokenEstimate,
        requestBytes: ingestByteEstimate,
        errorType: structKeyExists(error, "type") ? error.type : "",
        errorMessage: error.message
    });
    telemetry.finishTrace(trace, "error", {
        errorType: structKeyExists(error, "type") ? error.type : "",
        messageChars: len(error.message)
    });
    apiUtil.sendJson({
        ok: false,
        message: "Ingestion failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : "",
        cairoi: telemetry.traceLinks(trace)
    }, 500);
}
</cfscript>
