<cfsetting requesttimeout="300">
<cfscript>
// S5 RAG Bootstrap — run from onApplicationStart (non-fatal)
// Exports live corpus from DB → PDF/CSV, then pre-warms per-corpus VectorStores

server.stylemart.ragReadyRef = false;
server.stylemart.ragFuturesRef = [];

configDir = getDirectoryFromPath(getCurrentTemplatePath()) & "../config/";
cfg = deserializeJSON(fileRead(configDir & "ai.ref.json"));
ragCfg = cfg.rag ?: {};

if (!structKeyExists(ragCfg, "enabled") || !ragCfg.enabled) {
    writeLog(text="[S6-RAG] RAG disabled in ai.json — skipping bootstrap", file="rag");
    return;
}

// Step 1: Export live data from DB → PDF/CSV
//exporter = new api.agent.s6.ref.rag.CorpusExporter();
//exportResult = exporter.exportAll();
//writeLog(text="[S6-RAG] Export complete — catalog: #exportResult.catalog.fileCount# files, reviews: #exportResult.reviews.rowCount# rows, orders: #exportResult.orders.rowCount# rows", file="rag");

// Step 2: Create per-corpus VectorStores for intelligent routing
embeddingConfig = {
    provider: ragCfg.embeddingProvider ?: "openai",
    modelName: ragCfg.embeddingModel ?: "text-embedding-3-small",
    apiKey: application.OPENAI_API_KEY
};

ragDataDir = createObject("java","java.io.File").init(
    getDirectoryFromPath(getCurrentTemplatePath()) & "../data/rag/"
).getCanonicalPath() & "/";
docService = documentService();
totalIngested = 0;

corporaDirs = ["policy", "catalog", "reviews"];
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

        vs = VectorStore({
            provider: ragCfg.vectorStoreProvider ?: "INMEMORY",
            embeddingModel: embeddingConfig
        });

        future = docService.ingestAsync(segments, vs);
        arrayAppend(server.stylemart.ragFuturesRef, future);
        vectorStores[corpusName] = vs;
        totalIngested += arrayLen(segments);
        writeLog(text="[S6-RAG] Ingesting #corpusName# async: #arrayLen(segments)# segments", file="rag");
    } catch (any e) {
        writeLog(text="[S6-RAG] Failed to ingest #corpusName#: #e.message#", file="rag");
    }
}

// Step 3: Store in application scope for ChatService to use
application.ragVectorStoresRef = vectorStores;
writeLog(text="[S6-RAG] Bootstrap complete — #totalIngested# total segments ingested across #structCount(vectorStores)# corpora", file="rag");

// Step 4: Async poller to flip ragReady when all ingestion futures complete
runAsync(function() {
    while (structKeyExists(server.stylemart, "ragFuturesRef")) {
        allDone = true;
        for (f in server.stylemart.ragFuturesRef) {
            if (!f.isDone()) { allDone = false; break; }
        }
        if (allDone) {
            server.stylemart.ragReadyRef = true;
            structDelete(server.stylemart, "ragFuturesRef");
            writeLog(text="[S6-RAG] All ingestion futures complete. RAG is ready.", file="rag");
            return true;
        }
        sleep(5000);
    }
    return false;
});
</cfscript>
