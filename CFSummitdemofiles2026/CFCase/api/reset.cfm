<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

structDelete(session, "game", false);

writeOutput(serializeJson({
    "success": true,
    "message": "Case state cleared."
}));
</cfscript>
