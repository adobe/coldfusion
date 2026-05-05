<cfscript>
// documentTransformer enriches a Document BEFORE it's split.
// textSegmentTransformer enriches a Segment AFTER splitting.
// Both are UDFs you write — any metadata you add is stored with each segment.
try {
    docService = documentService();

    writeOutput("> PIPELINE: load() -> transform() -> split() -> transformSegments()" & chr(10));
    writeOutput("> ===================================================================" & chr(10) & chr(10));

    docs = docService.load({ path: expandPath("../Documents/product-docs.txt") });
    writeOutput("> Loaded " & arrayLen(docs) & " document(s)" & chr(10));

    // Capture baseline metadata keys before any enrichment
    baselineKeys = listToArray(structKeyList(docs[1].metadata));
    arraySort(baselineKeys, "textNoCase");

    writeOutput("> transform()          -> adds: source, ingestedAt, wordCount" & chr(10));
    docs = docService.transform(docs, function(document) {
        document.metadata.source     = "product-kb";
        document.metadata.ingestedAt = dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm:ss");
        document.metadata.wordCount  = listLen(document.text, " ");
        return document;
    });

    segments = docService.split(docs, { chunkSize: 300, chunkOverlap: 50 });
    writeOutput("> split()              -> " & arrayLen(segments) & " segments" & chr(10));

    writeOutput("> transformSegments()  -> adds: charCount, quality" & chr(10) & chr(10));
    segments = docService.transformSegments(segments, function(document, segment) {
        segment.metadata.charCount = len(segment.text);
        segment.metadata.quality   = len(segment.text) > 200 ? "high" : "low";
        return segment;
    });

    writeOutput("> METADATA ON SEGMENT ##1 (as stored in the vector DB)" & chr(10));
    writeOutput("> ----------------------------------------------------" & chr(10));
    meta = segments[1].metadata;
    keys = listToArray(structKeyList(meta));
    arraySort(keys, "textNoCase");

    addedFields = ["source","ingestedAt","wordCount","charCount","quality"];
    for (k in keys) {
        tag = arrayFindNoCase(addedFields, k) ? "  [ADDED]" : "         ";
        writeOutput(">  " & lJustify(k, 22) & " = " & lJustify(toString(meta[k]), 32) & tag & chr(10));
    }
    writeOutput(chr(10));
    writeOutput("> Fields marked [ADDED] came from your transformers." & chr(10));
    writeOutput("> You can now filter by quality, audit by ingestedAt and trace by source.");

    docService.close();
} catch (any e) {
    writeOutput("Error: " & e.message);
}
</cfscript>
