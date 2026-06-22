<cfsetting showdebugoutput="false">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
}

try {
    service = new mcpinventory.InventoryService(application.inventoryDatasource);
    stats = service.bootstrap(false);
    sendJson({ ok: true, message: "Inventory datasource queried.", stats: stats });
} catch (any error) {
    sendJson({ ok: false, message: "Datasource check failed: " & error.message, detail: error.detail ?: "" }, 500);
}
</cfscript>
