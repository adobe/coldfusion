<cfscript>
// lazyLoad() returns an iterator. Only one document is held in memory at a time,
// regardless of how many files the directory contains.
try {
    writeOutput("> LAZY LOAD — streaming iterator" & chr(10));
    writeOutput("> =================================" & chr(10) & chr(10));

    docService = documentService();

    writeOutput("> Opening iterator on Corpus/ (50 Wikipedia articles)..." & chr(10));
    iterator = docService.lazyLoad({
        path    : expandPath("../Corpus/"),
        pattern : "*.txt"
    });

    writeOutput("> Streaming one document at a time — memory stays flat" & chr(10) & chr(10));

    count      = 0;
    totalBytes = 0;
    startTick  = getTickCount();

    while (iterator.hasNext() && count < 10) {
        doc          = iterator.next();
        count       += 1;
        bytes        = len(doc.text);
        totalBytes  += bytes;
        fileName     = structKeyExists(doc.metadata, "file_name") ? doc.metadata.file_name : "doc-" & count;
        writeOutput(">   [" & count & "] " & fileName & "  —  " & bytes & " chars" & chr(10));
    }

    elapsed = getTickCount() - startTick;

    writeOutput(chr(10));
    writeOutput("> Streamed " & count & " docs | " & totalBytes & " chars | " & elapsed & "ms" & chr(10));
    writeOutput("> Peak memory footprint: ~1 document" & chr(10) & chr(10));

    writeOutput("> IDEAL WHEN:" & chr(10));
    writeOutput(">   +  The corpus is too large to fit in memory" & chr(10));
    writeOutput(">   +  You pipe docs straight into split + ingest as you go" & chr(10));
    writeOutput(">   +  You want processing to start before the whole set loads");

    docService.close();
} catch (any e) {
    writeOutput("Error: " & e.message);
}
</cfscript>
