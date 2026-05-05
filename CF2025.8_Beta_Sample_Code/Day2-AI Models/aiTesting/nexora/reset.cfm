<cfcontent type="application/json" reset="true">
<cfscript>
    try {
        structDelete(session, "nexoraFullAI4");
        apiPayload = {}; apiPayload["success"] = true;
        writeOutput(serializeJSON(apiPayload));
    } catch (any e) {
        apiPayload = {}; apiPayload["success"] = false; apiPayload["error"] = e.message;
        writeOutput(serializeJSON(apiPayload));
    }
</cfscript>
