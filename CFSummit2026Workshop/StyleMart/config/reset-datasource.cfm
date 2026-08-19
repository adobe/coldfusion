<cfsetting showdebugoutput="false">
<cfoutput>
<pre>
<cftry>
<cfscript>
    propsPath = getDirectoryFromPath(getCurrentTemplatePath()) & "db.properties";
    props     = getPropertyFile(propsPath);

    createObject("component", "CFIDE.adminapi.administrator").login(props["admin.password"]);
    ds = createObject("component", "CFIDE.adminapi.datasource");

    if (structKeyExists(ds.getDatasources(), "stylemart")) {
        ds.deleteDatasource("stylemart");
        writeOutput("[ok] removed existing 'stylemart' datasource&##10;");
    } else {
        writeOutput("[ok] no existing 'stylemart' datasource to remove&##10;");
    }

    new commonutils.db.DatasourceUtil().register("stylemart", propsPath);
    writeOutput("[ok] re-registered 'stylemart' from #propsPath#&##10;");

    // Sanity probe
    q = queryExecute("SELECT COUNT(*) AS n FROM users", {}, {datasource: "stylemart"});
    writeOutput("[ok] users.count = " & q.n[1] & "&##10;");
</cfscript>
<cfcatch type="any">
  <cfoutput>[fail] #cfcatch.message#&##10;#cfcatch.detail#&##10;</cfoutput>
  <cfdump var="#cfcatch#">
</cfcatch>
</cftry>
</pre>
</cfoutput>
