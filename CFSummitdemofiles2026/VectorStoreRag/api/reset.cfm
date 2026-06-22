<cfsetting showdebugoutput="false">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
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
            // Resetting application state below is still useful for the demo flow.
        }
    }
}

try {
    if (structKeyExists(application, "vectorClient")) {
        clearVectorStore(application.vectorClient);
    }

    lock name="VectorStoreRagIngestState" type="exclusive" timeout=60 {
        application.vectorClient = "";
        application.ingestStatus = {
            ready: false,
            sourceFile: application.dataFile,
            sourceName: "No menu ingested",
            chunkCount: 0,
            addedCount: 0,
            ingestedAt: "",
            collectionName: "",
            message: "Vector store reset. Choose a menu and ingest again."
        };
    }

    sendJson({
        ok: true,
        ready: false,
        sourceName: application.ingestStatus.sourceName,
        addedCount: 0,
        message: application.ingestStatus.message
    });
} catch (any error) {
    sendJson({
        ok: false,
        message: "Reset failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, 500);
}
</cfscript>
