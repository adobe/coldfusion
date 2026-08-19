component {

    remote struct function getInventory(
        required string productId hint="Product ID to check inventory for",
        string size hint="Size filter (e.g. S, M, L, XL)" default="",
        string color hint="Color filter (e.g. navy, black)" default=""
    ) hint="Check real-time stock levels for a product variant" {
        var baseUrl = "http://localhost/api/commerce/inventory/#arguments.productId#";

        cfhttp(method="GET", url=baseUrl, result="local.r", timeout=10) {
            cfhttpparam(type="header", name="Accept", value="application/json");
        }

        if (local.r.statusCode != "200 OK" && !find("200", local.r.statusCode)) {
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

        return {"productId": arguments.productId, "variants": variants, "totalVariants": arrayLen(variants), "anyInStock": variants.reduce(function(acc, v) { return acc || v.inStock; }, false)};
    }
}
