<cfsetting showdebugoutput="false">
<cfscript>
function fixDbPath(required string propsPath, required string key, required string correctPath) {
    var content = fileRead(arguments.propsPath);
    var pattern = arguments.key & "=.*";
    var replacement = arguments.key & "=" & arguments.correctPath;
    var updated = reReplace(content, pattern, replacement);
    if (updated != content) {
        fileWrite(arguments.propsPath, updated);
        writeOutput("[ok] updated " & arguments.key & " in " & arguments.propsPath & "<br>");
    }
}
</cfscript>
<cfoutput>
<pre>
<cftry>
<cfscript>
    base = createObject("java", "java.io.File").init(
        getDirectoryFromPath(getCurrentTemplatePath()) & "../../"
    ).getCanonicalPath() & "/";

    stylemartProps = base & "StyleMart/config/db.properties";
    prologicsProps = base & "externalservices/prologics/config/db.properties";

    agentRoot     = base & "StyleMart/api/agent";
    commerceRoot  = base & "StyleMart/api/commerce";
    prologicsRoot = base & "externalservices/prologics";

    // Fix hardcoded DB paths in properties files to match this machine
    stylemartDbPath = base & "StyleMart/db/sqlite/stylemart.db";
    prologicsDbPath = base & "externalservices/prologics/db/sqlite/prologics.db";

    fixDbPath(stylemartProps, "stylemart.file", stylemartDbPath);
    fixDbPath(prologicsProps, "prologics.file", prologicsDbPath);

    dsUtil = new commonutils.db.DatasourceUtil();

    // 1. Datasources
    writeOutput("=== Datasources ===&##10;");

    dsUtil.register("stylemart", stylemartProps);
    writeOutput("[ok] datasource 'stylemart' registered (#stylemartProps#)&##10;");

    dsUtil.register("prologics", prologicsProps);
    writeOutput("[ok] datasource 'prologics' registered (#prologicsProps#)&##10;");

    // 2. REST applications
    writeOutput("&##10;=== REST services ===&##10;");

    restInitApplication(agentRoot, "agent");
    writeOutput("[ok] REST 'agent' registered at #agentRoot#&##10;");

    restInitApplication(commerceRoot, "commerce");
    writeOutput("[ok] REST 'commerce' registered at #commerceRoot#&##10;");

    restInitApplication(prologicsRoot, "logistics");
    writeOutput("[ok] REST 'logistics' (prologics) registered at #prologicsRoot#&##10;");

    writeOutput("&##10;Setup complete.&##10;");
</cfscript>
<cfcatch type="any">
  [fail] #cfcatch.message#&##10;#cfcatch.detail#&##10;
  <cfdump var="#cfcatch#">
</cfcatch>
</cftry>
</pre>
</cfoutput>
