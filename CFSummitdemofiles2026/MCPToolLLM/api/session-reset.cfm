<cfsetting showdebugoutput="false">
<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

structDelete(session, "selectedAiModelKey", false);

writeOutput(serializeJSON({
    "ok": true,
    "message": "Inventory AI session state cleared."
}));
</cfscript>
