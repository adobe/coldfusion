<cfsetting requesttimeout="300">
<cfscript>
// S5 RAG Bootstrap — run from onApplicationStart (non-fatal)
// Exports live corpus from DB → PDF/CSV, then pre-warms per-corpus VectorStores

server.stylemart.ragReadyLab = false;
server.stylemart.ragFuturesLab = [];

configDir = getDirectoryFromPath(getCurrentTemplatePath()) & "../config/";
cfg = deserializeJSON(fileRead(configDir & "ai.lab.json"));
ragCfg = cfg.rag ?: {};

if (!structKeyExists(ragCfg, "enabled") || !ragCfg.enabled) {
    writeLog(text="[S5-RAG] RAG disabled in ai.json — skipping bootstrap", file="rag");
    return;
}

// Step 1: Export live data from DB → PDF/CSV
//exporter = new api.agent.s5.lab.rag.CorpusExporter();
//exportResult = exporter.exportAll();
//writeLog(text="[S5-RAG] Export complete — catalog: #exportResult.catalog.fileCount# files, reviews: #exportResult.reviews.rowCount# rows, orders: #exportResult.orders.rowCount# rows", file="rag");

// Step 2: Create per-corpus VectorStores for intelligent routing
embeddingConfig = {
    provider: ragCfg.embeddingProvider ?: "openai",
    modelName: ragCfg.embeddingModel ?: "text-embedding-3-small",
    apiKey: application.OPENAI_API_KEY
};

ragDataDir = reReplace(getDirectoryFromPath(getCurrentTemplatePath()), "lab[/\\]$", "data/rag/");
docService = documentService();
totalIngested = 0;

corporaDirs = ["policy", "catalog", "reviews", "orders"];
vectorStores = {};

for (corpusName in corporaDirs) {
    corpusDir = ragDataDir & corpusName & "/";
    if (!directoryExists(corpusDir)) continue;

    try {
        documents = docService.load(corpusDir);
        if (arrayLen(documents) == 0) continue;

        // Policy docs use larger chunks so related sections stay together
        if (corpusName == "policy") {
            chunkSize = 2000;
            chunkOverlap = 200;
        } else {
            chunkSize = ragCfg.chunkSize ?: 500;
            chunkOverlap = ragCfg.chunkOverlap ?: 100;
        }

        segments = docService.split(documents, {
            chunkSize: chunkSize,
            chunkOverlap: chunkOverlap,
            splitterType: ragCfg.splitterType ?: "recursive"
        });

        if (arrayLen(segments) == 0) continue;

        // ===== ATTENDEE TODO ZONE (Per-corpus VectorStore + ingest) =====

        // TODO-S5-1: Create a VectorStore for this corpus. embeddingConfig
        //   was assembled above and the provider defaults to INMEMORY for
        //   the workshop (cfg.rag.vectorStoreProvider).
        //   Hint: vs = VectorStore({
        //           provider: ragCfg.vectorStoreProvider ?: "INMEMORY",
        //           embeddingModel: embeddingConfig
        //         });
        vs = VectorStore({
  provider:
    ragCfg.vectorStoreProvider ?: "INMEMORY",
  embeddingModel: embeddingConfig
});

        // TODO-S5-2: Kick off ingestion asynchronously and stash the future
        //   on server.stylemart.ragFuturesLab so the async poller below can
        //   flip ragReadyLab once everything's loaded.
        //   Hint: future = docService.ingestAsync(segments, vs);
        //         arrayAppend(server.stylemart.ragFuturesLab, future);
        /* TODO-S5-2 */
        future = docService.ingestAsync(segments, vs);
arrayAppend(
  server.stylemart.ragFuturesLab, future
);

        // ===== END ATTENDEE TODO ZONE =====================================

        if (isObject(vs)) {
            vectorStores[corpusName] = vs;
            totalIngested += arrayLen(segments);
            writeLog(text="[S5-RAG] Ingesting #corpusName# async: #arrayLen(segments)# segments", file="rag");
        }
    } catch (any e) {
        writeLog(text="[S5-RAG] Failed to ingest #corpusName#: #e.message#", file="rag");
    }
}

// Step 3: Store in application scope for ChatService to use
application.ragVectorStoresLab = vectorStores;
writeLog(text="[S5-RAG] Bootstrap complete — #totalIngested# total segments ingested across #structCount(vectorStores)# corpora", file="rag");

// Step 4: Async poller to flip ragReady when all ingestion futures complete
runAsync(function() {
    while (structKeyExists(server.stylemart, "ragFuturesLab")) {
        allDone = true;
        for (f in server.stylemart.ragFuturesLab) {
            if (!f.isDone()) { allDone = false; break; }
        }
        if (allDone) {
            server.stylemart.ragReadyLab = true;
            structDelete(server.stylemart, "ragFuturesLab");
            writeLog(text="[S5-RAG] All ingestion futures complete. RAG is ready.", file="rag");
            return true;
        }
        sleep(5000);
    }
    return false;
});
</cfscript>
