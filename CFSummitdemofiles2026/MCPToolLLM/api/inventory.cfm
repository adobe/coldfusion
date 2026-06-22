<cfsetting showdebugoutput="false">
<cfscript>
function sendJson(required struct payload, numeric statusCode = 200) {
    cfheader(statuscode = statusCode);
    cfcontent(type = "application/json; charset=utf-8", reset = true);
    writeOutput(serializeJSON(payload));
    abort;
}

try {
    filters = {
        query: structKeyExists(url, "query") ? url.query : "",
        warehouse: structKeyExists(url, "warehouse") ? url.warehouse : "",
        category: structKeyExists(url, "category") ? url.category : "",
        stockStatus: structKeyExists(url, "stockStatus") ? url.stockStatus : ""
    };

    service = new mcpinventory.InventoryService(application.inventoryDatasource);
    items = service.listItems(filters);
    stats = service.getStats();

    sendJson({
        ok: true,
        items: items,
        stats: stats,
        filters: filters
    });
} catch (any error) {
    sendJson({ ok: false, message: "Inventory request failed: " & error.message, detail: error.detail ?: "" }, 500);
}
</cfscript>
