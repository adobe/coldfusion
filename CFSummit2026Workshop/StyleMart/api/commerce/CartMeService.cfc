component rest="true" restpath="/me/cart" produces="application/json" {

    remote struct function getMyCart(
        string shopperId restargsource="header" restargname="X-Shopper-Id" default="usr_demo_001"
    ) httpmethod="GET" {
        var dsn = "stylemart";

        var qCart = queryExecute("
            SELECT cart_id FROM carts WHERE user_id = :uid AND status = 'active' LIMIT 1
        ", {uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var cartId = "";
        if (qCart.recordCount == 0) {
            cartId = "crt_" & lCase(replace(createUUID(), "-", "", "all"));
            queryExecute("INSERT INTO carts (cart_id, user_id, status) VALUES (:cid, :uid, 'active')", {
                cid: {value: cartId, cfsqltype: "cf_sql_varchar"},
                uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
        } else {
            cartId = qCart.cart_id;
        }

        return loadCartFull(cartId, dsn);
    }

    remote struct function getCartSummary(
        string shopperId restargsource="header" restargname="X-Shopper-Id" default="usr_demo_001"
    ) httpmethod="GET" restpath="summary" {
        var dsn = "stylemart";

        var qCart = queryExecute("
            SELECT cart_id FROM carts WHERE user_id = :uid AND status = 'active' LIMIT 1
        ", {uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qCart.recordCount == 0) {
            return {"cartId": "", "itemCount": 0, "total": 0, "currency": "USD"};
        }

        var qItems = queryExecute("
            SELECT ci.quantity, p.base_price_cents
            FROM cart_items ci
            JOIN product_variants pv ON pv.variant_id = ci.variant_id
            JOIN products p ON p.product_id = pv.product_id
            WHERE ci.cart_id = :cid
        ", {cid: {value: qCart.cart_id, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var itemCount = 0;
        var total = 0;
        for (var row in qItems) {
            itemCount += row.quantity;
            total += (row.base_price_cents / 100) * row.quantity;
        }

        return {"cartId": qCart.cart_id, "itemCount": itemCount, "total": total, "currency": "USD"};
    }

    private struct function loadCartFull(required string cartId, required string dsn) {
        var qCart = queryExecute("
            SELECT cart_id, user_id, status, created_at, updated_at FROM carts WHERE cart_id = :cid
        ", {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: arguments.dsn});

        var qItems = queryExecute("
            SELECT ci.cart_item_id, ci.variant_id, ci.quantity, ci.added_at,
                   pv.product_id, pv.size, pv.color, pv.sku,
                   p.name, p.image_url, p.base_price_cents,
                   COALESCE(inv.quantity, 0) as stock_qty
            FROM cart_items ci
            JOIN product_variants pv ON pv.variant_id = ci.variant_id
            JOIN products p ON p.product_id = pv.product_id
            LEFT JOIN inventory inv ON inv.variant_id = ci.variant_id
            WHERE ci.cart_id = :cid ORDER BY ci.added_at
        ", {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: arguments.dsn});

        var items = [];
        var subtotal = 0;
        for (var row in qItems) {
            var unitPrice = row.base_price_cents / 100;
            var lineTotal = unitPrice * row.quantity;
            subtotal += lineTotal;
            items.append({
                "cartItemId": row.cart_item_id, "variantId": row.variant_id,
                "productId": row.product_id, "name": row.name, "imageUrl": row.image_url,
                "size": row.size, "color": row.color, "quantity": row.quantity,
                "unitPrice": unitPrice, "lineTotal": lineTotal, "discountAmount": 0,
                "currency": "USD", "inStock": row.stock_qty > 0, "maxQty": 10,
                "stale": false, "appliedPromotionIds": [],
                "addedAt": dateTimeFormat(row.added_at, "yyyy-MM-dd'T'HH:nn:ss'Z'")
            });
        }

        var qCpn = queryExecute("
            SELECT c.coupon_id, c.code, c.type, c.value, c.currency
            FROM applied_coupons ac JOIN coupons c ON c.coupon_id = ac.coupon_id
            WHERE ac.cart_id = :cid
        ", {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: arguments.dsn});

        var discountTotal = 0;
        var appliedCoupon = javacast("null", "");
        if (qCpn.recordCount > 0) {
            discountTotal = qCpn.type == "percent" ? subtotal * (qCpn.value / 100) : min(qCpn.value, subtotal);
            appliedCoupon = {"couponId": qCpn.coupon_id, "code": qCpn.code,
                "type": qCpn.type == "percent" ? "percentage" : "fixed",
                "value": qCpn.value, "currency": qCpn.currency};
        }

        return {
            "cartId": arguments.cartId, "userId": qCart.user_id, "status": qCart.status,
            "items": items, "subtotal": subtotal, "discountTotal": discountTotal,
            "total": subtotal - discountTotal, "currency": "USD",
            "appliedCoupon": isNull(appliedCoupon) ? javacast("null", "") : appliedCoupon,
            "createdAt": dateTimeFormat(qCart.created_at, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
            "updatedAt": dateTimeFormat(qCart.updated_at, "yyyy-MM-dd'T'HH:nn:ss'Z'")
        };
    }
}
