<cfscript>
adminObj = createObject("component", "CFIDE.adminapi.administrator");
adminObj.login("admin");
runtimeObj = createObject("component", "CFIDE.adminapi.runtime");
runtimeObj.clearTrustedCache();
runtimeObj.clearComponentCache();
writeOutput("Cache cleared at " & now());
</cfscript>
