component rest="true" restpath="/carts" produces="application/json" consumes="application/json" {

    remote struct function getCart(
        required string cartId restargsource="path"
    ) httpmethod="GET" restpath="{cartId}" {
        return loadCart(arguments.cartId);
    }

    remote struct function addItem(
        required string cartId restargsource="path"
    ) httpmethod="POST" restpath="{cartId}/items" {
        var body = deserializeJSON(toString(getHttpRequestData().content));
        var resp = getPageContext().getResponse();
        resp.setStatus(201);
        return addItemDirect(
            cartId = arguments.cartId,
            variantId = body.variantId,
            quantity = structKeyExists(body, "quantity") ? body.quantity : 1
        );
    }

    public struct function addItemDirect(
        required string cartId,
        required string variantId,
        numeric quantity = 1
    ) {
        var dsn = "stylemart";

        var qVar = queryExecute("
            SELECT pv.variant_id, pv.product_id, pv.size, pv.color, pv.sku,
                   p.name, p.image_url, p.base_price_cents
            FROM product_variants pv
            JOIN products p ON p.product_id = pv.product_id
            WHERE pv.variant_id = :vid
        ", {vid: {value: arguments.variantId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qVar.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Variant not found");
        }

        var qExisting = queryExecute("
            SELECT cart_item_id, quantity FROM cart_items
            WHERE cart_id = :cid AND variant_id = :vid
        ", {
            cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"},
            vid: {value: arguments.variantId, cfsqltype: "cf_sql_varchar"}
        }, {datasource: dsn});

        if (qExisting.recordCount > 0) {
            var newQty = min(qExisting.quantity + arguments.quantity, 10);
            queryExecute("UPDATE cart_items SET quantity = :qty WHERE cart_item_id = :ciid", {
                qty: {value: newQty, cfsqltype: "cf_sql_integer"},
                ciid: {value: qExisting.cart_item_id, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
        } else {
            var itemId = "cit_" & lCase(replace(createUUID(), "-", "", "all"));
            queryExecute("
                INSERT INTO cart_items (cart_item_id, cart_id, variant_id, quantity)
                VALUES (:ciid, :cid, :vid, :qty)
            ", {
                ciid: {value: itemId, cfsqltype: "cf_sql_varchar"},
                cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"},
                vid: {value: arguments.variantId, cfsqltype: "cf_sql_varchar"},
                qty: {value: arguments.quantity, cfsqltype: "cf_sql_integer"}
            }, {datasource: dsn});
        }

        queryExecute("UPDATE carts SET updated_at = CURRENT_TIMESTAMP WHERE cart_id = :cid",
            {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        return loadCart(arguments.cartId);
    }

    remote struct function removeItem(
        required string cartId restargsource="path",
        required string variantId restargsource="path"
    ) httpmethod="DELETE" restpath="{cartId}/items/{variantId}" {
        var dsn = "stylemart";

        queryExecute("DELETE FROM cart_items WHERE cart_id = :cid AND variant_id = :vid", {
            cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"},
            vid: {value: arguments.variantId, cfsqltype: "cf_sql_varchar"}
        }, {datasource: dsn});

        queryExecute("UPDATE carts SET updated_at = CURRENT_TIMESTAMP WHERE cart_id = :cid",
            {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        return loadCart(arguments.cartId);
    }

    remote struct function applyCoupon(
        required string cartId restargsource="path"
    ) httpmethod="POST" restpath="{cartId}/coupon" {
        var dsn = "stylemart";
        var body = deserializeJSON(toString(getHttpRequestData().content));
        var code = uCase(trim(body.code));

        var qCoupon = queryExecute("
            SELECT coupon_id, code, type, value, currency FROM coupons
            WHERE code = :code AND active = TRUE AND valid_from <= CURRENT_TIMESTAMP AND valid_to > CURRENT_TIMESTAMP
        ", {code: {value: code, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qCoupon.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Coupon not found");
        }

        queryExecute("DELETE FROM applied_coupons WHERE cart_id = :cid",
            {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        queryExecute("INSERT INTO applied_coupons (cart_id, coupon_id) VALUES (:cid, :cpid)", {
            cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"},
            cpid: {value: qCoupon.coupon_id, cfsqltype: "cf_sql_varchar"}
        }, {datasource: dsn});

        return loadCart(arguments.cartId);
    }

    remote struct function removeCoupon(
        required string cartId restargsource="path"
    ) httpmethod="DELETE" restpath="{cartId}/coupon" {
        var dsn = "stylemart";

        queryExecute("DELETE FROM applied_coupons WHERE cart_id = :cid",
            {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        return loadCart(arguments.cartId);
    }

    // --- Private helper ---

    private struct function loadCart(required string cartId) {
        var dsn = "stylemart";

        var qCart = queryExecute("
            SELECT cart_id, user_id, status, created_at, updated_at FROM carts WHERE cart_id = :cid
        ", {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qCart.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Cart not found");
        }

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
        ", {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

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
        ", {cid: {value: arguments.cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var discountTotal = 0;
        var appliedCoupon = javacast("null", "");
        if (qCpn.recordCount > 0) {
            if (qCpn.type == "percent") {
                discountTotal = subtotal * (qCpn.value / 100);
            } else {
                discountTotal = min(qCpn.value, subtotal);
            }
            appliedCoupon = {
                "couponId": qCpn.coupon_id, "code": qCpn.code,
                "type": qCpn.type == "percent" ? "percentage" : "fixed",
                "value": qCpn.value, "currency": qCpn.currency
            };
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
