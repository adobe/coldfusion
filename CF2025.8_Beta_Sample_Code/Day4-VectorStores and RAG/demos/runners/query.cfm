<cfscript>
// Routes chat/ask questions to whichever demo has been started in this session.
id     = url.id ?: "";
q      = url.q  ?: "";
method = url.method ?: "chat";

try {
    if (!len(id) || !structKeyExists(session.demos, id)) {
        writeOutput("Not initialized. Click Start first.");
    } else {
        service = session.demos[id];
        answer  = (method == "ask") ? service.ask(q) : service.chat(q);
        writeOutput(answer.message);
    }
} catch (any e) {
    if (findNoCase("guardrail", e.message)) {
        writeOutput("BLOCKED BY GUARDRAIL: " &
            reReplaceNoCase(e.message, ".*guardrail failed with this message:\s*", ""));
    } else {
        writeOutput("Error: " & e.message);
    }
}
</cfscript>
