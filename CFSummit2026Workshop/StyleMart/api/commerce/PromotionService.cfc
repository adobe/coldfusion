component rest="true" restpath="/promotions" produces="application/json" {

    remote struct function listPromotions() httpmethod="GET" {
        var dsn = "stylemart";

        var qPromos = queryExecute("
            SELECT promotion_id, name, type, value, valid_from, valid_to, active
            FROM promotions
            WHERE active = TRUE AND valid_from <= CURRENT_TIMESTAMP AND valid_to > CURRENT_TIMESTAMP
            ORDER BY priority DESC
        ", {}, {datasource: dsn});

        var items = [];
        for (var p in qPromos) {
            items.append({
                "promotionId": p.promotion_id, "name": p.name,
                "type": p.type == "percent" ? "percentage" : p.type,
                "value": p.value, "active": p.active,
                "startsAt": dateTimeFormat(p.valid_from, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
                "endsAt": dateTimeFormat(p.valid_to, "yyyy-MM-dd'T'HH:nn:ss'Z'")
            });
        }

        return {"items": items};
    }

    remote struct function getPromotion(
        required string promotionId restargsource="path"
    ) httpmethod="GET" restpath="{promotionId}" {
        var dsn = "stylemart";

        var qPromo = queryExecute("
            SELECT promotion_id, name, type, value, scope_json, priority, valid_from, valid_to, active
            FROM promotions WHERE promotion_id = :pid
        ", {pid: {value: arguments.promotionId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qPromo.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Promotion not found");
        }

        return {
            "promotionId": qPromo.promotion_id, "name": qPromo.name,
            "type": qPromo.type == "percent" ? "percentage" : qPromo.type,
            "value": qPromo.value, "active": qPromo.active,
            "startsAt": dateTimeFormat(qPromo.valid_from, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
            "endsAt": dateTimeFormat(qPromo.valid_to, "yyyy-MM-dd'T'HH:nn:ss'Z'")
        };
    }
}
