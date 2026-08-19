component rest="true" restpath="/pricing" produces="application/json" {

    remote struct function getPricing(
        required string productId restargsource="path"
    ) httpmethod="GET" restpath="{productId}" {
        return resolvePrice(arguments.productId);
    }

    remote struct function getBulk(
        string productIds restargsource="query" default=""
    ) httpmethod="GET" restpath="bulk" {
        var ids = listToArray(arguments.productIds);
        var items = [];
        for (var id in ids) {
            items.append(resolvePrice(id));
        }
        return {"items": items};
    }

    private struct function resolvePrice(required string pid) {
        var dsn = "stylemart";

        var qP = queryExecute("
            SELECT product_id, base_price_cents, currency FROM products WHERE product_id = :pid
        ", {pid: {value: arguments.pid, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qP.recordCount == 0) {
            return {"productId": arguments.pid, "basePrice": 0, "currentPrice": 0, "currency": "USD", "appliedRules": []};
        }

        var qPrice = queryExecute("
            SELECT price_cents FROM prices
            WHERE product_id = :pid AND segment = 'public'
              AND valid_from <= CURRENT_TIMESTAMP AND (valid_to IS NULL OR valid_to > CURRENT_TIMESTAMP)
            ORDER BY priority DESC, valid_from DESC LIMIT 1
        ", {pid: {value: arguments.pid, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var basePrice = qP.base_price_cents / 100;
        var currentPrice = qPrice.recordCount > 0 ? qPrice.price_cents / 100 : basePrice;

        var appliedRules = [];
        if (currentPrice != basePrice) {
            appliedRules.append({
                "type": "price-override", "name": "Sale Price",
                "discount": basePrice - currentPrice
            });
        }

        return {
            "productId": arguments.pid, "basePrice": basePrice,
            "currentPrice": currentPrice, "currency": qP.currency,
            "appliedRules": appliedRules
        };
    }
}
