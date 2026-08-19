<cfsetting requesttimeout="120">
<cfscript>
var LF = chr(10);
writeOutput("<pre>");

if (structKeyExists(url, "reload")) {
    applicationStop();
    writeOutput("Application stopped. Next request will re-init." & LF);
}

stores = application.ragVectorStores ?: {};
writeOutput("application.ragVectorStores keys: " & structKeyList(stores) & LF);

for (key in stores) {
    writeOutput("  " & key & ": " & (isObject(stores[key]) ? "YES (object)" : "NO") & LF);
}

writeOutput("</pre>");
</cfscript>
