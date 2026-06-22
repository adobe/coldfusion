<cfsetting showdebugoutput="false">
<cfscript>
apiUtil = new codereview.ApiUtil();
helpers = new codereview.AppHelpers();

try {
    if (isObject(application.vectorClient)) {
        helpers.clearVectorStore(application.vectorClient);
    }

    lock name="CodeReviewLocalIngestState" type="exclusive" timeout=60 {
        application.vectorClient = "";
        application.ingestStatus = {
            ready: false,
            sourceName: "No standards ingested",
            chunkCount: 0,
            addedCount: 0,
            ingestedAt: "",
            collectionName: "",
            embeddingProfile: application.embeddingProfile,
            message: "Vector store reset. Standards will ingest automatically on the next review."
        };
    }

    apiUtil.sendJson({
        ok: true,
        ready: false,
        message: application.ingestStatus.message
    });
} catch (any error) {
    apiUtil.sendJson({
        ok: false,
        message: "Reset failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, 500);
}
</cfscript>
