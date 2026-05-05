<cfscript>

    // Create a nested directory structure in one call
    basePath = expandPath("./temp_demo");
    nestedPath = basePath & "/reports/2026/April";

    // createPath=true creates all parent directories
    // ignoreExists=true won't throw error if directory already exists
    DirectoryCreate(path=nestedPath, createPath=true, ignoreExists=true);

    // Verify by listing the structure
    writeOutput("Directory structure created:" & chr(10) & "<br>");
    dirs = DirectoryList(basePath, true, "path");
    for (dir in dirs) {
        writeOutput("  " & dir & chr(10) & "<br>");
    }
</cfscript>
