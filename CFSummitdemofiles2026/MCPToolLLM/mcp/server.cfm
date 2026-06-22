<cfsetting showdebugoutput="false">
<cfscript>
try {
    if (!structKeyExists(application, "mcpServer") || !isObject(application.mcpServer)) {
        throw(
            type = "MissingMCPServer",
            message = "ColdFusion MCPServer() is not initialized.",
            detail = structKeyExists(application, "mcpServerError") ? application.mcpServerError : ""
        );
    }

    application.mcpServer.handleRequest();
} catch (any error) {
    cfheader(statuscode = 500);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON({
        jsonrpc: "2.0",
        error: { code: -32000, message: error.message, data: error.detail ?: "" },
        ok: false
    }));
    abort;
}
</cfscript>
