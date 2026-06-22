<cfsetting showdebugoutput="false">
<cfscript>
cfcontent(type="application/json; charset=utf-8", reset=true);

structDelete(session, "onboardSessionId", false);
structDelete(session, "selectedStepId", false);
structDelete(session, "chatHistory", false);
structDelete(session, "metrics", false);

writeOutput(serializeJSON({
    "ok": true,
    "message": "OnboardIQ session state cleared."
}));
</cfscript>
