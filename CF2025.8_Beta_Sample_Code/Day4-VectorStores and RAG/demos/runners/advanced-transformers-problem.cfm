<cfscript>
// Plain load + split with no custom transformers — segments carry only default metadata.
try {
    docService = documentService();

    writeOutput("> PIPELINE: load() -> split()" & chr(10));
    writeOutput("> No documentTransformer, no textSegmentTransformer" & chr(10));
    writeOutput("> =====================================================" & chr(10) & chr(10));

    docs = docService.load({ path: expandPath("../Documents/product-docs.txt") });
    writeOutput("> Loaded " & arrayLen(docs) & " document(s)" & chr(10));

    segments = docService.split(docs, { chunkSize: 300, chunkOverlap: 50 });
    writeOutput("> Split into " & arrayLen(segments) & " segments" & chr(10) & chr(10));

    writeOutput("> METADATA ON SEGMENT ##1 (as stored in the vector DB)" & chr(10));
    writeOutput("> ----------------------------------------------------" & chr(10));
    meta = segments[1].metadata;
    keys = listToArray(structKeyList(meta));
    arraySort(keys, "textNoCase");
    for (k in keys) {
        writeOutput(">  " & lJustify(k, 22) & " = " & meta[k] & chr(10));
    }
    writeOutput(chr(10));
    writeOutput("> " & arrayLen(keys) & " metadata fields total, all of them auto-populated." & chr(10));
    writeOutput("> No source label, no quality tag, no ingestion timestamp, no char count.");

    docService.close();
} catch (any e) {
    writeOutput("Error: " & e.message);
}
</cfscript>
