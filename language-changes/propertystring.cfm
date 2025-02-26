<cfscript>
    myFile=GetDirectoryFromPath(GetCurrentTemplatePath()) & "fileout.properties"
    setPropertyString(myFile,  "KEY11",  "value11", "UTF-8");
    someStruct=StructNew();
    someStruct.google = "search";
    someStruct.microsoft= "windows";
    someStruct.apple = "mac m1";
    someStruct.amazon = "shopping";
    setPropertyString(myFile, someStruct, "UTF-8");
    writeDump(myFile)
</cfscript>

<cfscript>
    path =GetDirectoryFromPath(GetCurrentTemplatePath()) & "fileout.properties"
    writeDump("Path: " & path);
    writeDump(getPropertyFile(path));
    writeDump("getPropertyString name : " & getPropertyString(path,"apple"));
</cfscript>