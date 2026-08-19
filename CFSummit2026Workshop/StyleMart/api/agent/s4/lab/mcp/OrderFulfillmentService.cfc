component extends="BaseMcpTool" {

    variables.LOG_FILE = "stylemart-order-fulfillment-mcp";
    variables.SERVER_NAME = "stylemart-fulfillment";

    private any function getInventoryService() {
        if (!structKeyExists(variables, "inventoryService")) {
            variables.inventoryService = new api.commerce.InventoryService();
        }
        return variables.inventoryService;
    }

    remote struct function getInventory(
        required string productId hint="Product ID to check inventory for",
        string size hint="Size filter (e.g. S, M, L, XL)" default="",
        string color hint="Color filter (e.g. navy, black)" default=""
    ) hint="Check real-time stock levels for a product variant" {
        var ctx = startMcpCall(variables.SERVER_NAME, "getInventory", {productId: arguments.productId, size: arguments.size, color: arguments.color});
        cflog(text="#ctx.callId# - getInventory called - productId: #arguments.productId#, size: #arguments.size#, color: #arguments.color#", type="info", file=variables.LOG_FILE);

        try {
            var data = getInventoryService().findInventory(arguments.productId);

            if (structKeyExists(data, "error") && data.error) {
                cflog(text="#ctx.callId# - getInventory - product not found: #arguments.productId#", type="warning", file=variables.LOG_FILE);
                endMcpCall(ctx, "error", "product not found");
                return {
                    "error": true,
                    "code": "inventory_lookup_failed",
                    "message": "Could not retrieve inventory for product #arguments.productId#"
                };
            }

            var variants = data.variants ?: [];

            if (len(arguments.size) || len(arguments.color)) {
                var filtered = [];
                for (var v in variants) {
                    var matchSize  = !len(arguments.size) || findNoCase(arguments.size, v.variantId);
                    var matchColor = !len(arguments.color) || findNoCase(arguments.color, v.variantId);
                    if (matchSize && matchColor) arrayAppend(filtered, v);
                }
                variants = filtered;
            }

            var result = {
                "productId": arguments.productId,
                "variants": variants,
                "totalVariants": arrayLen(variants),
                "anyInStock": variants.reduce(function(acc, v) { return acc || (v.quantity ?: 0) > 0; }, false)
            };

            cflog(text="#ctx.callId# - getInventory complete - totalVariants: #result.totalVariants#, anyInStock: #result.anyInStock#", type="info", file=variables.LOG_FILE);
            endMcpCall(ctx, "ok", "#result.totalVariants# variants, inStock: #result.anyInStock#");
            return result;

        } catch (any e) {
            cflog(text="#ctx.callId# - getInventory ERROR - #e.message#", type="error", file=variables.LOG_FILE);
            endMcpCall(ctx, "error", e.message);
            return { "error": true, "code": "exception", "message": e.message };
        }
    }
}
