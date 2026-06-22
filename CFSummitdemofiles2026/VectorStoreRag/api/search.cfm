<cfsetting showdebugoutput="false">
<cfscript>
telemetry = createObject("component", "cairoiLive.sdk.DemoTelemetry").init();
trace = "";
retrieveSpan = "";
generateSpan = "";
question = "";
prompt = "";
answer = "";

function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
}

function getRequestJson() {
    var requestData = getHttpRequestData();
    if (!len(trim(requestData.content))) {
        return {};
    }
    return deserializeJSON(requestData.content);
}

function valueFrom(required any value, required string key, any fallback = "") {
    if (isStruct(value) && structKeyExists(value, key)) {
        return value[key];
    }

    try {
        return invoke(value, "get" & key);
    } catch (any ignored) {
        return fallback;
    }
}

function resultText(required any result) {
    for (var key in ["text", "content", "document", "pageContent"]) {
        var possible = valueFrom(result, key, "");
        if (isSimpleValue(possible) && len(trim(possible))) {
            return possible;
        }
    }
    return serializeJSON(result);
}

function resultMetadata(required any result) {
    var metadata = valueFrom(result, "metadata", {});
    return isStruct(metadata) ? metadata : {};
}

function resultScore(required any result) {
    for (var key in ["score", "similarity", "distance"]) {
        var possible = valueFrom(result, key, "");
        if (isNumeric(possible)) {
            return numberFormat(possible, "0.000");
        }
    }
    return "n/a";
}

function responseText(required any response) {
    if (isSimpleValue(response)) {
        return response;
    }

    for (var key in ["message", "content", "text", "answer", "response"]) {
        var possible = valueFrom(response, key, "");
        if (isSimpleValue(possible) && len(trim(possible))) {
            return possible;
        }
    }

    return serializeJSON(response);
}

function makeAgent(required any chatModel) {
    try {
        return {
            service: Agent({ chatModel: chatModel }),
            factory: "Agent()"
        };
    } catch (any agentError) {
        try {
            return {
                service: getAIService({ chatModel: chatModel }),
                factory: "getAIService() fallback"
            };
        } catch (any serviceError) {
            rethrow;
        }
    }
}

try {
    payload = getRequestJson();
    question = trim(structKeyExists(payload, "question") ? payload.question : "");
    trace = telemetry.startTrace(
        workflowName = "donut_rag_search",
        userId = "donut-demo-user",
        sessionId = structKeyExists(session, "sessionid") ? session.sessionid : "",
        metadata = {
            route: cgi.script_name,
            questionChars: len(question),
            provider: "openai",
            chatModel: application.chatConfig.modelName,
            embeddingModel: application.embeddingModelName
        }
    );
    request.cairoiTrace = trace;

    if (!len(question)) {
        telemetry.finishTrace(trace, "error", { errorType: "ValidationError" });
        sendJson({ ok: false, message: "Question is required.", cairoi: telemetry.traceLinks(trace) }, 400);
    }

    if (!len(trim(application.openAiApiKey))) {
        telemetry.finishTrace(trace, "error", { errorType: "MissingOpenAIKey" });
        sendJson({ ok: false, message: "Add the OpenAI API key to the keystore as openaiapi_donuts before searching.", cairoi: telemetry.traceLinks(trace) }, 400);
    }

    if (!application.ingestStatus.ready || !isObject(application.vectorClient)) {
        telemetry.finishTrace(trace, "error", { errorType: "RagNotReady" });
        sendJson({ ok: false, message: "Stock The Case first so the donut menu is in memory.", cairoi: telemetry.traceLinks(trace) }, 409);
    }

    currentSource = application.ingestStatus.sourceName;
    retrieveSpan = telemetry.startSpan(
        trace = trace,
        operationType = "rag.retrieve",
        operationName = "Donut RAG retrieve menu",
        metadata = {
            sourceName: currentSource,
            topK: 50,
            provider: "openai"
        }
    );

    try {
        matches = application.vectorClient.search({ text: question, topK: 50, minScore: 0.15 });
    } catch (any searchOptionError) {
        matches = application.vectorClient.search({ text: question, topK: 50 });
    }

    sources = [];
    contextBlocks = [];
    sourceIndex = 0;

    for (match in matches) {
        text = resultText(match);
        metadata = resultMetadata(match);

        if (!structKeyExists(metadata, "source") || compareNoCase(metadata.source, currentSource) != 0) {
            continue;
        }

        sourceIndex++;
        name = structKeyExists(metadata, "name") ? metadata.name : "Donut catalog chunk " & sourceIndex;
        category = structKeyExists(metadata, "category") ? metadata.category : "";
        available = structKeyExists(metadata, "available") ? metadata.available : "";
        score = resultScore(match);

        arrayAppend(sources, {
            name: name,
            category: category,
            available: available,
            source: metadata.source,
            score: score,
            text: text
        });

        arrayAppend(contextBlocks, "Source " & sourceIndex & " (" & name & ", score " & score & "):" & chr(10) & text);
    }

    if (!arrayLen(contextBlocks)) {
        retrieveTokens = telemetry.estimateTokens(question);
        telemetry.finishSpan(retrieveSpan, {
            status: "success",
            provider: "openai",
            modelName: application.embeddingModelName,
            inputTokens: retrieveTokens,
            totalTokens: retrieveTokens,
            promptText: question,
            requestBytes: telemetry.estimateBytes(question),
            metadata: {
                sourceName: currentSource,
                sourceCount: 0
            }
        });
        telemetry.finishTrace(trace, "error", { errorType: "NoRelevantChunks", sourceName: currentSource });
        sendJson({ ok: false, message: "No relevant chunks were found in the currently ingested menu.", cairoi: telemetry.traceLinks(trace) }, 404);
    }

    retrieveTokens = telemetry.estimateTokens(question);
    telemetry.finishSpan(retrieveSpan, {
        status: "success",
        provider: "openai",
        modelName: application.embeddingModelName,
        inputTokens: retrieveTokens,
        totalTokens: retrieveTokens,
        promptText: question,
        requestBytes: telemetry.estimateBytes(question),
        metadata: {
            sourceName: currentSource,
            sourceCount: arrayLen(sources),
            contextBlockCount: arrayLen(contextBlocks)
        }
    });

    chatConfig = duplicate(application.chatConfig);
    chatConfig.apiKey = application.openAiApiKey;
    try {
        chatModel = ChatModel(chatConfig);
    } catch (any chatModelError) {
        chatModel = getChatModel(chatConfig);
    }
    agentWrapper = makeAgent(chatModel);
    aiAgent = agentWrapper.service;

    systemPrompt = "You are the Glaze Against The Machine chat bot, a friendly donut shop menu assistant. Answer only from the provided donut menu context. If the context does not contain the answer, say that the current menu does not include that information. Keep answers concise, mention specific donut names when useful, and lean into the circuit-safe AI donut joke when the retrieved menu supports it.";

    try {
        aiAgent.systemMessage(systemPrompt);
        prompt = "Catalog context:" & chr(10) & arrayToList(contextBlocks, chr(10) & chr(10)) & chr(10) & chr(10) & "Customer question: " & question;
    } catch (any systemMessageError) {
        prompt = systemPrompt & chr(10) & chr(10) & "Catalog context:" & chr(10) & arrayToList(contextBlocks, chr(10) & chr(10)) & chr(10) & chr(10) & "Customer question: " & question;
    }

    generateSpan = telemetry.startSpan(
        trace = trace,
        operationType = "rag.generate",
        operationName = "Donut RAG generate answer",
        metadata = {
            sourceName: currentSource,
            sourceCount: arrayLen(sources),
            provider: "openai",
            agentFactory: agentWrapper.factory
        }
    );
    answerResponse = aiAgent.chat(prompt, "donut-demo-user");
    answer = responseText(answerResponse);
    promptTokens = telemetry.estimateTokens(systemPrompt & chr(10) & prompt);
    completionTokens = telemetry.estimateTokens(answer);
    telemetry.finishSpan(generateSpan, {
        status: "success",
        provider: "openai",
        modelName: application.chatConfig.modelName,
        inputTokens: promptTokens,
        outputTokens: completionTokens,
        totalTokens: promptTokens + completionTokens,
        promptText: systemPrompt & chr(10) & prompt,
        responseText: answer,
        requestBytes: telemetry.estimateBytes(systemPrompt & chr(10) & prompt),
        responseBytes: telemetry.estimateBytes(answer),
        metadata: {
            sourceName: currentSource,
            sourceCount: arrayLen(sources),
            agentFactory: agentWrapper.factory
        }
    });
    telemetry.finishTrace(trace, "success", {
        sourceName: application.ingestStatus.sourceName,
        sourceCount: arrayLen(sources),
        modelName: application.chatConfig.modelName
    });

    sendJson({
        ok: true,
        question: question,
        answer: answer,
        sources: sources,
        modelName: application.chatConfig.modelName,
        agentFactory: agentWrapper.factory,
        sourceName: application.ingestStatus.sourceName,
        cairoi: telemetry.traceLinks(trace)
    });
} catch (any error) {
    telemetry.finishSpan(generateSpan, {
        status: "error",
        provider: "openai",
        modelName: structKeyExists(application, "chatConfig") && structKeyExists(application.chatConfig, "modelName") ? application.chatConfig.modelName : "",
        inputTokens: telemetry.estimateTokens(prompt),
        totalTokens: telemetry.estimateTokens(prompt),
        promptText: prompt,
        requestBytes: telemetry.estimateBytes(prompt),
        errorType: structKeyExists(error, "type") ? error.type : "",
        errorMessage: error.message
    });
    telemetry.finishSpan(retrieveSpan, {
        status: "error",
        provider: "openai",
        modelName: structKeyExists(application, "embeddingModelName") ? application.embeddingModelName : "",
        inputTokens: telemetry.estimateTokens(question),
        totalTokens: telemetry.estimateTokens(question),
        promptText: question,
        requestBytes: telemetry.estimateBytes(question),
        errorType: structKeyExists(error, "type") ? error.type : "",
        errorMessage: error.message
    });
    telemetry.finishTrace(trace, "error", {
        errorType: structKeyExists(error, "type") ? error.type : "",
        messageChars: len(error.message)
    });
    sendJson({
        ok: false,
        message: "Search failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : "",
        cairoi: telemetry.traceLinks(trace)
    }, 500);
}
</cfscript>
