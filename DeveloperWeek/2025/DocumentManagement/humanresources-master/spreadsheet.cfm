<!---
Add 50k rows to spreadsheet and write to a file
For traditional spreadsheets
    50k rows : 700KB : ~5s
    100k rows : Heap space error
    1M rows : Heap space error
For streaming spreadsheets-
    50k rows : 700KB : ~700ms
    100k rows : 1.4MB : ~1.4s
    1M rows : 14MB : ~13s
--->
<cfset sheet = "Sheet1">
<cfset randomAccessSize = 4>
<cfscript>
    theFile = GetDirectoryFromPath(GetCurrentTemplatePath()) & "new-spreadsheet.xlsx";
    // Create a streaming spreadsheet
    // obj = StreamingSpreadsheetNew(#sheet#, #randomAccessSize#)
    // Create a traditional spreadsheet
    obj = SpreadsheetNew(#sheet#,true) 
   
    // Add 50,000 rows [If we make it 100,000 rows, it will fail for traditional spreadsheets, however it continues to work for streaming spreadsheets]
    for(i = 1; i <= 10000; i++)
    {
        SpreadsheetAddRow(obj, "150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1,150,ENGL,95,Poetry 1", i, 1);
    }
    SpreadSheetSetColumnWidth(obj, 2, 35);
    writedump(obj)
    
    // Write the spreadsheet to a file
    spreadsheetwrite(obj, theFile, "", true, false);
    if(SpreadsheetIsStreamingXMLFormat(obj))
        streamingSpreadsheetCleanup(obj) // cleanup the temporary files created by streaming spreadsheet after writing the file
    
    fileExist = FileExists(theFile);
    writeOutput("FileExist:" & #fileExist#)
</cfscript>