component rest="true" restpath="/orders" produces="application/json" {

    remote struct function listOrders(
        string shopperId restargsource="header" restargname="X-Shopper-Id" default="usr_demo_001"
    ) httpmethod="GET" {
        var dsn = "stylemart";

        var qOrders = queryExecute("
            SELECT order_id, status, subtotal_cents, discount_cents, total_cents, currency, created_at
            FROM orders WHERE user_id = :uid ORDER BY created_at DESC
        ", {uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var items = [];
        for (var o in qOrders) {
            var qOI = queryExecute("
                SELECT snapshot_name, snapshot_image_url, quantity, unit_price_cents
                FROM order_items WHERE order_id = :oid
            ", {oid: {value: o.order_id, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

            var oiArr = [];
            for (var oi in qOI) {
                oiArr.append({
                    "name": oi.snapshot_name, "imageUrl": oi.snapshot_image_url ?: "",
                    "quantity": oi.quantity, "unitPrice": oi.unit_price_cents / 100
                });
            }
            items.append({
                "orderId": o.order_id, "status": o.status, "items": oiArr,
                "total": o.total_cents / 100, "currency": o.currency,
                "placedAt": dateTimeFormat(o.created_at, "yyyy-MM-dd'T'HH:nn:ss'Z'")
            });
        }

        return {"items": items, "page": 1, "pageSize": 20, "total": arrayLen(items)};
    }

    remote struct function getOrder(
        required string orderId restargsource="path"
    ) httpmethod="GET" restpath="{orderId}" {
        var dsn = "stylemart";

        var qOrder = queryExecute("
            SELECT order_id, user_id, cart_id, status, subtotal_cents, discount_cents, total_cents,
                   currency, applied_coupon_code, applied_coupon_type, applied_coupon_value, created_at
            FROM orders WHERE order_id = :oid
        ", {oid: {value: arguments.orderId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qOrder.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Order not found");
        }

        var qOItems = queryExecute("
            SELECT order_item_id, variant_id, product_id, quantity, unit_price_cents,
                   snapshot_name, snapshot_image_url, snapshot_size, snapshot_color
            FROM order_items WHERE order_id = :oid
        ", {oid: {value: arguments.orderId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var items = [];
        for (var row in qOItems) {
            items.append({
                "cartItemId": row.order_item_id, "variantId": row.variant_id,
                "productId": row.product_id, "name": row.snapshot_name,
                "imageUrl": row.snapshot_image_url ?: "",
                "size": row.snapshot_size, "color": row.snapshot_color,
                "quantity": row.quantity, "unitPrice": row.unit_price_cents / 100,
                "lineTotal": (row.unit_price_cents * row.quantity) / 100
            });
        }

        var appliedCoupon = javacast("null", "");
        if (len(qOrder.applied_coupon_code ?: "")) {
            appliedCoupon = {
                "code": qOrder.applied_coupon_code,
                "type": qOrder.applied_coupon_type == "percent" ? "percentage" : "fixed",
                "value": qOrder.applied_coupon_value
            };
        }

        return {
            "orderId": qOrder.order_id, "userId": qOrder.user_id, "status": qOrder.status,
            "items": items, "subtotal": qOrder.subtotal_cents / 100,
            "discountTotal": qOrder.discount_cents / 100, "total": qOrder.total_cents / 100,
            "currency": qOrder.currency,
            "appliedCoupon": isNull(appliedCoupon) ? javacast("null", "") : appliedCoupon,
            "placedAt": dateTimeFormat(qOrder.created_at, "yyyy-MM-dd'T'HH:nn:ss'Z'")
        };
    }
}
