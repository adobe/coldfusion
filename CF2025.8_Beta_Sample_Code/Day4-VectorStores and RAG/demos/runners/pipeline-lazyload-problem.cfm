<cfscript>
// load() reads every file into memory before returning the array.
// Simple and fast — but the whole corpus is held in heap.
try {
    writeOutput("> EAGER LOAD — everything in memory" & chr(10));
    writeOutput("> ===================================" & chr(10) & chr(10));

    docService = documentService();

    writeOutput("> Loading ALL files from Corpus/ in one shot..." & chr(10));
    startTick = getTickCount();

    docs = docService.load({
        path      : expandPath("../Corpus/"),
        pattern   : "*.txt",
        recursive : false
    });

    elapsed    = getTickCount() - startTick;
    totalBytes = 0;
    for (d in docs) { totalBytes += len(d.text); }

    writeOutput("> Loaded " & arrayLen(docs) & " docs | " & totalBytes & " chars | " & elapsed & "ms" & chr(10));
    writeOutput("> Peak memory: ALL " & arrayLen(docs) & " documents held at once" & chr(10) & chr(10));

    writeOutput("> FINE FOR small, bounded document sets." & chr(10));
    writeOutput("> SWITCH to lazyLoad() when the total size exceeds comfortable memory.");

    docService.close();
} catch (any e) {
    writeOutput("Error: " & e.message);
}
</cfscript>
