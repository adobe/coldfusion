component output="false" displayname="InventoryDatabaseToolV3" {

    public array function listTools() {
        return [
            {
                name: "findItems",
                description: "Find ranked inventory item candidates by natural language product text, SKU, warehouse, category, supplier, status, or notes. Returns normalized query metadata and match scores.",
                inputSchema: {
                    type: "object",
                    properties: {
                        query: { type: "string" },
                        warehouse: { type: "string", enum: ["Munich", "Berlin", "Vienna", "all"] },
                        category: { type: "string" },
                        stockStatus: {
                            type: "string",
                            enum: ["available", "ok", "low", "critical", "out", "all"],
                            description: "Use available for natural-language requests like in stock, on hand, or available; it means quantity_on_hand > 0. Use ok only for healthy stock."
                        }
                    }
                }
            },
            {
                name: "getLowStockItems",
                description: "Return items at or below reorder point, optionally scoped by warehouse.",
                inputSchema: {
                    type: "object",
                    properties: {
                        warehouse: { type: "string" },
                        threshold: { type: "number" }
                    }
                }
            },
            {
                name: "getItemBySku",
                description: "Return one inventory item by SKU.",
                inputSchema: {
                    type: "object",
                    properties: {
                        sku: { type: "string" }
                    },
                    required: ["sku"]
                }
            },
            {
                name: "recommendReorders",
                description: "Recommend reorder quantities for low, critical, or out-of-stock inventory. Use this for risky inventory questions like what needs attention or what might cause problems soon.",
                inputSchema: {
                    type: "object",
                    properties: {
                        warehouse: { type: "string" }
                    }
                }
            },
            {
                name: "createReorderRequest",
                description: "Create a demo reorder request for a SKU and quantity.",
                inputSchema: {
                    type: "object",
                    properties: {
                        sku: { type: "string" },
                        quantity: { type: "number" }
                    },
                    required: ["sku"]
                }
            }
        ];
    }

    remote struct function findItems(string query = "", string warehouse = "", string category = "", string stockStatus = "") {
        var service = getService();
        var result = service.findItems(arguments.query, arguments.warehouse, arguments.category, arguments.stockStatus);
        result.ok = true;
        result.sqlDebug = sqlDebugPayload(service, "findItems", arguments);
        return result;
    }

    remote struct function getLowStockItems(string warehouse = "", numeric threshold = -1) {
        var service = getService();
        var items = service.getLowStockItems(arguments.warehouse, arguments.threshold);
        return { ok: true, count: arrayLen(items), items: items, sqlDebug: sqlDebugPayload(service, "getLowStockItems", arguments) };
    }

    remote struct function getItemBySku(required string sku) {
        var service = getService();
        var item = service.getItemBySku(arguments.sku);
        return { ok: !structIsEmpty(item), item: item, message: structIsEmpty(item) ? "SKU not found." : "SKU found.", sqlDebug: sqlDebugPayload(service, "getItemBySku", arguments) };
    }

    remote struct function recommendReorders(string warehouse = "") {
        var service = getService();
        var recommendations = service.recommendReorders(arguments.warehouse);
        return { ok: true, count: arrayLen(recommendations), recommendations: recommendations, sqlDebug: sqlDebugPayload(service, "recommendReorders", arguments) };
    }

    remote struct function createReorderRequest(required string sku, numeric quantity = 0) {
        var service = getService();
        var result = service.createReorderRequest(arguments.sku, arguments.quantity);
        result.sqlDebug = sqlDebugPayload(service, "createReorderRequest", arguments);
        return result;
    }

    remote struct function stats() {
        return { ok: true, stats: getService().getStats() };
    }

    private any function getService() {
        var datasource = structKeyExists(application, "inventoryDatasource")
            ? application.inventoryDatasource
            : "cfsummit26_inventory";
        return new mcpinventory.InventoryService(datasource);
    }

    private struct function sqlDebugPayload(required any service, required string toolName, required struct toolArguments) {
        var sqlDebug = arguments.service.getLastSqlDebug();
        sqlDebug.toolName = arguments.toolName;
        sqlDebug.toolArguments = duplicate(arguments.toolArguments);
        return sqlDebug;
    }
}
