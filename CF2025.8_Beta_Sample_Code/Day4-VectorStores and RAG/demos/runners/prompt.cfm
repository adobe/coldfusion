<cfscript>
id = url.id ?: "";
if (len(id) && structKeyExists(session, "prompts") && structKeyExists(session.prompts, id)) {
    writeOutput(session.prompts[id]);
} else {
    writeOutput("NOT_FOUND");
}
</cfscript>
