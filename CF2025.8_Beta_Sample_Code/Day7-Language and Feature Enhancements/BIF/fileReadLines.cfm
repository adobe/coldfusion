
<cfscript>
    logFile = expandPath("./logfiles/sample_log.txt");

    // Read lines around the database error (line 130)
    startLine = 125;
    lineCount = 30;

    // Use FileReadLines to read specific lines
    contextLines = FileReadLines(logFile, startLine, -lineCount);

    writeDump(var=contextLines, format="text");

</cfscript>
