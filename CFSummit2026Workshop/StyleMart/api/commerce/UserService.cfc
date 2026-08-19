component rest="true" restpath="/users" produces="application/json" consumes="application/json" {

    remote struct function getUser(
        required string userId restargsource="path"
    ) httpmethod="GET" restpath="{userId}" {
        var dsn = "stylemart";

        var qUser = queryExecute("
            SELECT u.user_id, u.display_name, u.email, u.loyalty_tier_id, u.created_at,
                   lt.display_name as tier_name
            FROM users u
            LEFT JOIN loyalty_tiers lt ON lt.tier_id = u.loyalty_tier_id
            WHERE u.user_id = :uid
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qUser.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="User not found");
        }

        var qCart = queryExecute("
            SELECT cart_id FROM carts WHERE user_id = :uid AND status = 'active' LIMIT 1
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        return {
            "userId": qUser.user_id, "displayName": qUser.display_name,
            "email": qUser.email ?: "", "loyaltyTierId": qUser.loyalty_tier_id ?: "",
            "loyaltyTierName": qUser.tier_name ?: "",
            "memberSince": dateTimeFormat(qUser.created_at, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
            "activeCartId": qCart.recordCount > 0 ? qCart.cart_id : ""
        };
    }

    remote any function getPreferences(
        required string userId restargsource="path"
    ) httpmethod="GET" restpath="{userId}/preferences" {
        var dsn = "stylemart";

        var qPrefs = queryExecute("
            SELECT user_id, preferences, schema_version, updated_at
            FROM user_preferences WHERE user_id = :uid
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qPrefs.recordCount == 0) {
            return {
                "userId": arguments.userId, "preferences": {},
                "updatedAt": dateTimeFormat(now(), "yyyy-MM-dd'T'HH:nn:ss'Z'"),
                "schemaVersion": 1
            };
        }

        var prefs = isJSON(qPrefs.preferences) ? deserializeJSON(qPrefs.preferences) : {};
        return {
            "userId": qPrefs.user_id, "preferences": prefs,
            "updatedAt": dateTimeFormat(qPrefs.updated_at, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
            "schemaVersion": qPrefs.schema_version
        };
    }

    remote struct function putPreferences(
        required string userId restargsource="path",
        required struct body
    ) httpmethod="PUT" restpath="{userId}/preferences" {
        var dsn = "stylemart";
        var prefsJSON = serializeJSON(body);

        var qExists = queryExecute("
            SELECT user_id FROM user_preferences WHERE user_id = :uid
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qExists.recordCount > 0) {
            queryExecute("
                UPDATE user_preferences SET preferences = :prefs, updated_at = CURRENT_TIMESTAMP WHERE user_id = :uid
            ", {
                prefs: {value: prefsJSON, cfsqltype: "cf_sql_varchar"},
                uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
        } else {
            queryExecute("
                INSERT INTO user_preferences (user_id, preferences, schema_version) VALUES (:uid, :prefs, 1)
            ", {
                uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"},
                prefs: {value: prefsJSON, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
        }

        return {
            "userId": arguments.userId, "preferences": body,
            "updatedAt": dateTimeFormat(now(), "yyyy-MM-dd'T'HH:nn:ss'Z'"),
            "schemaVersion": 1
        };
    }

    remote struct function deletePreferences(
        required string userId restargsource="path"
    ) httpmethod="DELETE" restpath="{userId}/preferences" {
        var dsn = "stylemart";
        queryExecute("
            DELETE FROM user_preferences WHERE user_id = :uid
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
        return {"userId": arguments.userId, "status": "deleted"};
    }

    remote struct function getUserLoyalty(
        required string userId restargsource="path"
    ) httpmethod="GET" restpath="{userId}/loyalty" {
        var dsn = "stylemart";

        var qUser = queryExecute("
            SELECT u.user_id, u.loyalty_tier_id, lt.display_name as tier_name,
                   lt.discount_pct, lt.sort_order
            FROM users u
            LEFT JOIN loyalty_tiers lt ON lt.tier_id = u.loyalty_tier_id
            WHERE u.user_id = :uid
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qUser.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="User not found");
        }

        var qSpend = queryExecute("
            SELECT COALESCE(SUM(total_cents), 0) as total_spend
            FROM orders WHERE user_id = :uid AND status = 'confirmed'
        ", {uid: {value: arguments.userId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var totalSpend = qSpend.total_spend / 100;

        var qNextTier = queryExecute("
            SELECT tier_id, display_name, spend_threshold_cents
            FROM loyalty_tiers WHERE sort_order > :so ORDER BY sort_order LIMIT 1
        ", {so: {value: qUser.sort_order ?: 0, cfsqltype: "cf_sql_integer"}}, {datasource: dsn});

        var result = {
            "userId": arguments.userId, "tierId": qUser.loyalty_tier_id ?: "",
            "tierName": qUser.tier_name ?: "Bronze", "totalSpend": totalSpend,
            "discount": qUser.discount_pct ?: 0
        };

        if (qNextTier.recordCount > 0) {
            result["nextTierId"] = qNextTier.tier_id;
            result["spendToNextTier"] = (qNextTier.spend_threshold_cents / 100) - totalSpend;
        }

        return result;
    }
}
