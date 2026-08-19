component extends="BaseMcpTool" {

    variables.SERVER_NAME = "stylemart-commerce";

    remote struct function getInventory(
        required string productId hint="Product ID to check inventory for",
        string size hint="Size filter (e.g. S, M, L, XL)" default="",
        string color hint="Color filter (e.g. navy, black)" default=""
    ) hint="Check real-time stock levels for a product variant" {
        var ctx = startMcpCall(variables.SERVER_NAME, "getInventory", {productId: arguments.productId, size: arguments.size, color: arguments.color});

        var baseUrl = "http://localhost/api/commerce/inventory/#arguments.productId#";

        cfhttp(method="GET", url=baseUrl, result="local.r", timeout=10) {
            cfhttpparam(type="header", name="Accept", value="application/json");
        }

        if (local.r.statusCode != "200 OK" && !find("200", local.r.statusCode)) {
            endMcpCall(ctx, "error", "inventory_lookup_failed");
            return {"error": true, "code": "inventory_lookup_failed", "message": "Could not retrieve inventory for product #arguments.productId#"};
        }

        var data = deserializeJSON(local.r.fileContent);
        var variants = data.variants ?: [];

        if (len(arguments.size) || len(arguments.color)) {
            var filtered = [];
            for (var v in variants) {
                var matchSize = !len(arguments.size) || findNoCase(arguments.size, v.variantId);
                var matchColor = !len(arguments.color) || findNoCase(arguments.color, v.variantId);
                if (matchSize && matchColor) arrayAppend(filtered, v);
            }
            variants = filtered;
        }

        var result = {"productId": arguments.productId, "variants": variants, "totalVariants": arrayLen(variants), "anyInStock": variants.reduce(function(acc, v) { return acc || v.inStock; }, false)};
        endMcpCall(ctx, "ok", "#result.totalVariants# variants, anyInStock=#result.anyInStock#");
        return result;
    }

    remote struct function getEligibleCoupons(
        required string userId hint="Shopper user id"
    ) hint="Return real eligible coupons for a shopper. Workshop fixture — production reads from coupon service." {
        var ctx = startMcpCall(variables.SERVER_NAME, "getEligibleCoupons", {userId: arguments.userId});
        // Workshop fixture: every shopper sees the same two real coupons.
        var result = {
            "userId": arguments.userId,
            "coupons": [
                { "code": "GOLD10",   "description": "Gold loyalty 10% off cart" },
                { "code": "LONDON10", "description": "London-trip 10% off cart" }
            ]
        };
        endMcpCall(ctx, "ok", "#arrayLen(result.coupons)# coupons");
        return result;
    }
}
