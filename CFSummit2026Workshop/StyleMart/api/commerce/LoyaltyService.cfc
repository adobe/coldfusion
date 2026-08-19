component rest="true" restpath="/loyalty" produces="application/json" {

    remote array function getTiers() httpmethod="GET" restpath="tiers" {
        var dsn = "stylemart";

        var qTiers = queryExecute("
            SELECT tier_id, display_name, discount_pct, spend_threshold_cents, benefits, sort_order
            FROM loyalty_tiers ORDER BY sort_order
        ", {}, {datasource: dsn});

        var tiers = [];
        for (var t in qTiers) {
            tiers.append({
                "tierId": t.tier_id, "name": t.display_name,
                "discountPct": t.discount_pct,
                "minSpend": t.spend_threshold_cents / 100,
                "benefits": isJSON(t.benefits) ? deserializeJSON(t.benefits) : []
            });
        }
        return tiers;
    }
}
