<cfscript>
// Standalone ingestion job powered by documentService().
// Run load -> transform -> split -> transformSegments -> ingest as separate steps.
// The resulting vector store can then be used by any RAG service.
try {
    writeOutput("> documentService() staged ingestion" & chr(10));
    writeOutput("> ===================================" & chr(10) & chr(10));

    vs = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_doc_service",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    try { vs.deleteCollection(); } catch (any c) {}

    vs = vectorStore({
        provider       : "milvus",
        url            : application.vectorDB.milvus.url,
        databaseName   : "default",
        collectionName : "demo_doc_service",
        dimension      : 384,
        indexType      : "HNSW",
        metricType     : "COSINE",
        embeddingModel : {
            provider  : "ollama",
            modelName : "all-minilm",
            baseUrl   : application.ollamaBaseUrl
        }
    });

    docService = documentService();

    writeOutput("> 1. load(): reading ../Documents/*.txt" & chr(10));
    docs = docService.load({
        path      : expandPath("../Documents/"),
        pattern   : "*.txt",
        recursive : false
    });
    writeOutput(">    loaded " & arrayLen(docs) & " document(s)" & chr(10) & chr(10));

    writeOutput("> 2. transform(): tag every document with pipeline metadata" & chr(10));
    docs = docService.transform(docs, function(document) {
        document.metadata.pipeline = "nightly-ingest";
        document.metadata.loadedAt = dateFormat(now(), "yyyy-mm-dd");
        return document;
    });
    writeOutput(">    sample metadata: " & serializeJSON(docs[1].metadata) & chr(10) & chr(10));

    writeOutput("> 3. split(): chunk into 400-char segments" & chr(10));
    segments = docService.split(docs, {
        chunkSize    : 400,
        chunkOverlap : 60,
        splitterType : "recursive"
    });
    writeOutput(">    produced " & arrayLen(segments) & " segment(s)" & chr(10) & chr(10));

    writeOutput("> 4. transformSegments(): enrich each chunk with quality score" & chr(10));
    segments = docService.transformSegments(segments, function(document, segment) {
        segment.metadata.charCount = len(segment.text);
        segment.metadata.quality   = len(segment.text) > 150 ? "high" : "low";
        return segment;
    });
    highCount = 0;
    for (s in segments) { if (s.metadata.quality EQ "high") highCount++; }
    writeOutput(">    high-quality chunks: " & highCount & " / " & arrayLen(segments) & chr(10) & chr(10));

    writeOutput("> 5. ingest(): embed + push into vector store" & chr(10));
    startTick = getTickCount();
    docService.ingest(segments, vs, {
        batchSize       : 50,
        continueOnError : true
    });
    writeOutput(">    ingested in " & (getTickCount() - startTick) & "ms" & chr(10) & chr(10));

    docService.close();

    writeOutput("> Done." & chr(10));
    writeOutput("> Collection 'demo_doc_service' is ready." & chr(10));
    writeOutput("> Start the RAG service on the right to query this vector store.");
} catch (any e) {
    writeOutput("Error: " & e.message);
}
</cfscript>
