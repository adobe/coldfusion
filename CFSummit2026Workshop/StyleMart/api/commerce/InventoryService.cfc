component rest="true" restpath="/inventory" produces="application/json" {

    // ============================================================
    // Public methods (directly invocable — no HTTP overhead)
    // ============================================================

    public struct function findInventory(required string productId) {
        var dsn = "stylemart";

        var qVars = queryExecute("
            SELECT pv.variant_id, COALESCE(i.quantity, 0) as stock_qty
            FROM product_variants pv
            LEFT JOIN inventory i ON i.variant_id = pv.variant_id
            WHERE pv.product_id = :pid
        ", {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qVars.recordCount == 0) {
            return {"productId": arguments.productId, "variants": [], "error": true, "code": "not_found"};
        }

        var variants = [];
        for (var v in qVars) {
            variants.append({
                "variantId": v.variant_id, "inStock": v.stock_qty > 0,
                "quantity": v.stock_qty, "warehouseId": "wh_us_east_01"
            });
        }

        return {"productId": arguments.productId, "variants": variants};
    }

    public struct function findInventoryBulk(required array productIds) {
        var items = [];
        for (var id in arguments.productIds) {
            arrayAppend(items, findInventory(id));
        }
        return {"items": items};
    }

    // ============================================================
    // REST wrappers
    // ============================================================

    remote struct function getInventory(
        required string productId restargsource="path"
    ) httpmethod="GET" restpath="{productId}" {
        var result = findInventory(arguments.productId);
        if (structKeyExists(result, "error") && result.error) {
            throw(type="RestError", errorcode="404", message="Product not found");
        }
        return result;
    }

    remote struct function getBulk(
        string productIds restargsource="query" default=""
    ) httpmethod="GET" restpath="bulk" {
        return findInventoryBulk(listToArray(arguments.productIds));
    }
}
