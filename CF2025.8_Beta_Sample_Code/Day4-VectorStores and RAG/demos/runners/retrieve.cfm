<cfscript>
// Runs the same retrieval step that the RAG service is about to run, so the UI can
// display exactly which chunks (and scores) would be fed to the LLM.
// session.retrievers[id] = [{ vectorStore, topK, minScore, label }]
id = url.id ?: "";
q  = url.q  ?: "";

result = { "retrievers": [] };

try {
    if (!len(id) || !structKeyExists(session, "retrievers") || !structKeyExists(session.retrievers, id)) {
        result["error"] = "Not initialized. Click Start first.";
    } else {
        cfgs = session.retrievers[id];
        for (cfg in cfgs) {
            chunks = [];
            try {
                hits = cfg.vectorStore.search({
                    text     : q,
                    topK     : cfg.topK,
                    minScore : cfg.minScore
                });
                for (h in hits) {
                    fn = structKeyExists(h.metadata, "fileName") ? h.metadata.fileName
                       : (structKeyExists(h.metadata, "file_name") ? h.metadata.file_name : "");
                    arrayAppend(chunks, {
                        "score"    : h.score,
                        "text"     : h.text,
                        "fileName" : fn
                    });
                }
            } catch (any e) {
                // Fall through with empty chunks + error marker
                arrayAppend(chunks, { "score": 0, "text": "search error: " & e.message, "fileName": "" });
            }
            arrayAppend(result.retrievers, {
                "label"    : cfg.label,
                "topK"     : cfg.topK,
                "minScore" : cfg.minScore,
                "chunks"   : chunks
            });
        }
    }
} catch (any e) {
    result["error"] = e.message;
}

cfheader(name="Content-Type", value="application/json");
writeOutput(serializeJSON(result));
</cfscript>
