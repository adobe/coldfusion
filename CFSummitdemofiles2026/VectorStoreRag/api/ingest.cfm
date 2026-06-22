<cfsetting showdebugoutput="false">
<cfscript>
telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
trace = "";
ingestSpan = "";
ingestTokenEstimate = 0;
ingestByteEstimate = 0;

function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
}

function extractField(required string record, required string fieldName) {
    var prefix = fieldName & ":";
    var lines = listToArray(record, chr(10));

    for (var line in lines) {
        line = trim(line);
        if (findNoCase(prefix, line) == 1) {
            return trim(mid(line, len(prefix) + 1, len(line)));
        }
    }

    return "";
}

function getRequestJson() {
    var requestData = getHttpRequestData();
    if (!len(trim(requestData.content))) {
        return {};
    }
    return deserializeJSON(requestData.content);
}

function getAvailableDataFiles() {
    var dataQuery = directoryList(expandPath("../data"), false, "query", "*.txt*");
    var files = [];

    for (var row in dataQuery) {
        arrayAppend(files, row.name);
    }

    return files;
}

function makeCollectionName(required string sourceName) {
    return "donut_bot_" & rereplace(sourceName, "[^A-Za-z0-9]", "_", "all") & "_" & rereplace(createUUID(), "[^A-Za-z0-9]", "", "all");
}

function makeVectorClient(required string collectionName) {
    try {
        return VectorStore({
            embeddingModel: application.embeddingModelName,
            dimension: application.vectorDimension,
            metricType: "COSINE",
            apiKey: application.openAiApiKey,
            collectionName: collectionName
        });
    } catch (any firstError) {
        try {
            return VectorStore({
                embeddingModel: application.embeddingModelName,
                dimension: application.vectorDimension,
                metricType: "COSINE",
                collectionName: collectionName
            });
        } catch (any secondError) {
            return VectorStore();
        }
    }
}

function clearVectorStore(any vectorStore) {
    if (!isObject(arguments.vectorStore)) {
        return;
    }

    try {
        arguments.vectorStore.deleteAll();
    } catch (any deleteError) {
        try {
            arguments.vectorStore.clear();
        } catch (any clearError) {
            // A fresh collection name below is the primary isolation mechanism.
        }
    }
}

try {
    trace = telemetry.startTrace(
        workflowName = "donut_rag_ingest",
        userId = "donut-demo-admin",
        sessionId = structKeyExists(session, "sessionid") ? session.sessionid : "",
        metadata = {
            route: cgi.script_name,
            provider: "openai",
            embeddingModel: application.embeddingModelName
        }
    );
    request.cairoiTrace = trace;

    if (!len(trim(application.openAiApiKey))) {
        telemetry.finishTrace(trace, "error", { errorType: "MissingOpenAIKey" });
        sendJson({ ok: false, message: "Add the OpenAI API key to the keystore as openaiapi_donuts before ingesting.", cairoi: telemetry.traceLinks(trace) }, 400);
    }

    payload = getRequestJson();
    availableDataFiles = getAvailableDataFiles();
    selectedSource = structKeyExists(payload, "sourceName") ? payload.sourceName : application.ingestStatus.sourceName;

    if (!arrayFindNoCase(availableDataFiles, selectedSource)) {
        telemetry.finishTrace(trace, "error", { errorType: "InvalidSource" });
        sendJson({ ok: false, message: "Choose a valid data file from the data folder.", cairoi: telemetry.traceLinks(trace) }, 400);
    }

    selectedDataFile = expandPath("../data/" & selectedSource);

    if (!fileExists(selectedDataFile)) {
        telemetry.finishTrace(trace, "error", { errorType: "DataFileMissing" });
        sendJson({ ok: false, message: "Data file not found: " & selectedSource, cairoi: telemetry.traceLinks(trace) }, 404);
    }

    rawText = fileRead(selectedDataFile, "utf-8");
    normalizedText = replace(rawText, chr(13) & chr(10), chr(10), "all");
    normalizedText = replace(normalizedText, chr(13), chr(10), "all");
    records = normalizedText.split(chr(10) & "\s*" & chr(10));
    items = [];
    chunkIndex = 0;

    for (record in records) {
        recordText = trim(record);
        if (!len(recordText)) {
            continue;
        }

        chunkIndex++;
        donutName = extractField(recordText, "Name");
        category = extractField(recordText, "Category");
        available = extractField(recordText, "Available");

        arrayAppend(items, {
            id: rereplace(selectedSource, "[^A-Za-z0-9]", "-", "all") & "-" & chunkIndex,
            text: recordText,
            metadata: {
                source: selectedSource,
                chunkIndex: chunkIndex,
                name: donutName,
                category: category,
                available: available
            }
        });
    }

    if (!arrayLen(items)) {
        telemetry.finishTrace(trace, "error", { errorType: "NoRecords", sourceName: selectedSource });
        sendJson({ ok: false, message: "No donut records were found in the data file.", cairoi: telemetry.traceLinks(trace) }, 400);
    }

    for (item in items) {
        itemText = structKeyExists(item, "text") ? item.text : "";
        ingestTokenEstimate += telemetry.estimateTokens(itemText);
        ingestByteEstimate += telemetry.estimateBytes(itemText);
    }

    ingestSpan = telemetry.startSpan(
        trace = trace,
        operationType = "rag.ingest",
        operationName = "Donut RAG ingest catalog",
        metadata = {
            sourceName: selectedSource,
            chunkCount: arrayLen(items),
            provider: "openai"
        }
    );

    if (isObject(application.vectorClient)) {
        clearVectorStore(application.vectorClient);
    }

    collectionName = makeCollectionName(selectedSource);
    vectorStore = makeVectorClient(collectionName);
    clearVectorStore(vectorStore);
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

    lock name="VectorStoreRagIngestState" type="exclusive" timeout=60 {
        application.vectorClient = vectorStore;
        application.ingestStatus = {
            ready: true,
            sourceFile: selectedDataFile,
            sourceName: selectedSource,
            chunkCount: arrayLen(items),
            addedCount: arrayLen(addedIds) ? arrayLen(addedIds) : arrayLen(items),
            ingestedAt: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            collectionName: collectionName,
            message: "Ingested " & arrayLen(items) & " chunks from " & selectedSource & " into the in-memory vector store."
        };
    }

    telemetry.finishSpan(ingestSpan, {
        status: "success",
        provider: "openai",
        modelName: application.embeddingModelName,
        inputTokens: ingestTokenEstimate,
        totalTokens: ingestTokenEstimate,
        requestBytes: ingestByteEstimate,
        metadata: {
            sourceName: selectedSource,
            chunkCount: application.ingestStatus.chunkCount,
            addedCount: application.ingestStatus.addedCount,
            collectionName: application.ingestStatus.collectionName
        }
    });
    telemetry.finishTrace(trace, "success", {
        sourceName: application.ingestStatus.sourceName,
        chunkCount: application.ingestStatus.chunkCount,
        addedCount: application.ingestStatus.addedCount
    });
    sendJson({
        ok: true,
        ready: true,
        sourceName: application.ingestStatus.sourceName,
        chunkCount: application.ingestStatus.chunkCount,
        addedCount: application.ingestStatus.addedCount,
        ingestedAt: application.ingestStatus.ingestedAt,
        collectionName: application.ingestStatus.collectionName,
        message: application.ingestStatus.message,
        cairoi: telemetry.traceLinks(trace)
    });
} catch (any error) {
    telemetry.finishSpan(ingestSpan, {
        status: "error",
        provider: "openai",
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
    sendJson({
        ok: false,
        message: "Ingestion failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : "",
        cairoi: telemetry.traceLinks(trace)
    }, 500);
}
</cfscript>
