component rest="true" restpath="/me" produces="application/json" {

    remote struct function getMe(
        string shopperId restargsource="header" restargname="X-Shopper-Id" default="usr_demo_001"
    ) httpmethod="GET" {
        var dsn = "stylemart";

        // Log the incoming shopperId
        cflog(file="stylemart", text="UserMeService.getMe - shopperId param: [#arguments.shopperId#]", type="information");

        var qUser = queryExecute("
            SELECT u.user_id, u.display_name, u.email, u.loyalty_tier_id, u.created_at,
                   lt.display_name as tier_name
            FROM users u
            LEFT JOIN loyalty_tiers lt ON lt.tier_id = u.loyalty_tier_id
            WHERE u.user_id = :uid
        ", {uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        // Log query results
        cflog(file="stylemart", text="UserMeService.getMe - Query recordCount: #qUser.recordCount#", type="information");

        if (qUser.recordCount > 0) {
            cflog(file="stylemart", text="UserMeService.getMe - Found user: user_id=#qUser.user_id#, display_name=#qUser.display_name#", type="information");
        } else {
            cflog(file="stylemart", text="UserMeService.getMe - NO USER FOUND for shopperId: [#arguments.shopperId#]", type="error");
        }

        if (qUser.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="User not found");
        }

        var qCart = queryExecute("
            SELECT cart_id FROM carts WHERE user_id = :uid AND status = 'active' LIMIT 1
        ", {uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        return {
            "userId": qUser.user_id, "displayName": qUser.display_name,
            "email": qUser.email ?: "", "loyaltyTierId": qUser.loyalty_tier_id ?: "",
            "loyaltyTierName": qUser.tier_name ?: "",
            "memberSince": dateTimeFormat(qUser.created_at, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
            "activeCartId": qCart.recordCount > 0 ? qCart.cart_id : ""
        };
    }
}
