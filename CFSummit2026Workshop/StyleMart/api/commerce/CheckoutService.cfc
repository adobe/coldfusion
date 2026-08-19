component rest="true" restpath="/checkout" produces="application/json" consumes="application/json" {

    remote struct function checkout(
        required struct body,
        string shopperId restargsource="header" restargname="X-Shopper-Id" default="usr_demo_001"
    ) httpmethod="POST" {
        var dsn = "stylemart";
        var cartId = body.cartId;

        var qCart = queryExecute("
            SELECT cart_id, user_id, status FROM carts
            WHERE cart_id = :cid AND status = 'active'
        ", {cid: {value: cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qCart.recordCount == 0) {
            throw(type="RestError", errorcode="409", message="Cart not active");
        }

        var qItems = queryExecute("
            SELECT ci.variant_id, ci.quantity, pv.product_id, pv.size, pv.color, pv.sku,
                   p.name, p.image_url, p.base_price_cents
            FROM cart_items ci
            JOIN product_variants pv ON pv.variant_id = ci.variant_id
            JOIN products p ON p.product_id = pv.product_id
            WHERE ci.cart_id = :cid
        ", {cid: {value: cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qItems.recordCount == 0) {
            throw(type="RestError", errorcode="422", message="Cart is empty");
        }

        var subtotalCents = 0;
        for (var row in qItems) subtotalCents += row.base_price_cents * row.quantity;

        var discountCents = 0;
        var couponId = "";
        var couponCode = "";
        var couponType = "";
        var couponValue = 0;
        var couponCurrency = "";

        var qCpn = queryExecute("
            SELECT c.coupon_id, c.code, c.type, c.value, c.currency
            FROM applied_coupons ac JOIN coupons c ON c.coupon_id = ac.coupon_id
            WHERE ac.cart_id = :cid
        ", {cid: {value: cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qCpn.recordCount > 0) {
            couponId = qCpn.coupon_id;
            couponCode = qCpn.code;
            couponType = qCpn.type;
            couponValue = qCpn.value;
            couponCurrency = qCpn.currency;
            discountCents = couponType == "percent"
                ? int(subtotalCents * (couponValue / 100))
                : min(int(couponValue * 100), subtotalCents);
        }

        var totalCents = subtotalCents - discountCents;
        var newOrderId = "ord_" & lCase(replace(createUUID(), "-", "", "all"));

        if (len(couponId)) {
            queryExecute("
                INSERT INTO orders (order_id, user_id, cart_id, status, subtotal_cents, discount_cents,
                    total_cents, currency, coupon_id, applied_coupon_code, applied_coupon_type,
                    applied_coupon_value, applied_coupon_currency)
                VALUES (:oid, :uid, :cid, 'confirmed', :sub, :disc, :tot, 'USD',
                    :cpid, :cpcode, :cptype, :cpval, :cpcur)
            ", {
                oid: {value: newOrderId, cfsqltype: "cf_sql_varchar"},
                uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"},
                cid: {value: cartId, cfsqltype: "cf_sql_varchar"},
                sub: {value: subtotalCents, cfsqltype: "cf_sql_integer"},
                disc: {value: discountCents, cfsqltype: "cf_sql_integer"},
                tot: {value: totalCents, cfsqltype: "cf_sql_integer"},
                cpid: {value: couponId, cfsqltype: "cf_sql_varchar"},
                cpcode: {value: couponCode, cfsqltype: "cf_sql_varchar"},
                cptype: {value: couponType, cfsqltype: "cf_sql_varchar"},
                cpval: {value: couponValue, cfsqltype: "cf_sql_numeric"},
                cpcur: {value: couponCurrency, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
        } else {
            queryExecute("
                INSERT INTO orders (order_id, user_id, cart_id, status, subtotal_cents,
                    discount_cents, total_cents, currency)
                VALUES (:oid, :uid, :cid, 'confirmed', :sub, :disc, :tot, 'USD')
            ", {
                oid: {value: newOrderId, cfsqltype: "cf_sql_varchar"},
                uid: {value: arguments.shopperId, cfsqltype: "cf_sql_varchar"},
                cid: {value: cartId, cfsqltype: "cf_sql_varchar"},
                sub: {value: subtotalCents, cfsqltype: "cf_sql_integer"},
                disc: {value: discountCents, cfsqltype: "cf_sql_integer"},
                tot: {value: totalCents, cfsqltype: "cf_sql_integer"}
            }, {datasource: dsn});
        }

        for (var row in qItems) {
            var oitId = "oit_" & lCase(replace(createUUID(), "-", "", "all"));
            queryExecute("
                INSERT INTO order_items (order_item_id, order_id, variant_id, product_id, quantity,
                    unit_price_cents, discount_cents, snapshot_name, snapshot_image_url,
                    snapshot_size, snapshot_color, snapshot_sku)
                VALUES (:oiid, :oid, :vid, :pid, :qty, :upc, 0, :sname, :simg, :ssize, :scolor, :ssku)
            ", {
                oiid: {value: oitId, cfsqltype: "cf_sql_varchar"},
                oid: {value: newOrderId, cfsqltype: "cf_sql_varchar"},
                vid: {value: row.variant_id, cfsqltype: "cf_sql_varchar"},
                pid: {value: row.product_id, cfsqltype: "cf_sql_varchar"},
                qty: {value: row.quantity, cfsqltype: "cf_sql_integer"},
                upc: {value: row.base_price_cents, cfsqltype: "cf_sql_integer"},
                sname: {value: row.name, cfsqltype: "cf_sql_varchar"},
                simg: {value: row.image_url, cfsqltype: "cf_sql_varchar"},
                ssize: {value: row.size, cfsqltype: "cf_sql_varchar"},
                scolor: {value: row.color, cfsqltype: "cf_sql_varchar"},
                ssku: {value: row.sku, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
        }

        queryExecute("UPDATE carts SET status = 'checked-out', updated_at = CURRENT_TIMESTAMP WHERE cart_id = :cid",
            {cid: {value: cartId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        // Webhook: notify ProLogics to create shipment (fire-and-forget)
        try {
            var shipItems = [];
            for (var row in qItems) {
                arrayAppend(shipItems, {productId: row.product_id, variantId: row.variant_id, quantity: row.quantity});
            }
            var webhookUrl = "http://localhost:#CGI.SERVER_PORT#/api/logistics/shipments/ingest";
            cfhttp(method="POST", url=webhookUrl, result="local.whRes", timeout=5) {
                cfhttpparam(type="header", name="Content-Type", value="application/json");
                var addr = body.shippingAddress ?: {};
                var shipTo = {
                    fullName:   addr.name ?: addr.fullName ?: arguments.shopperId,
                    address1:   addr.line1 ?: addr.address1 ?: "",
                    city:       addr.city ?: "",
                    state:      addr.state ?: "",
                    postalCode: addr.zip ?: addr.postalCode ?: "",
                    country:    addr.country ?: "US",
                    phone:      addr.phone ?: "",
                    email:      addr.email ?: ""
                };
                cfhttpparam(type="body", value=serializeJSON({
                    orderId:   newOrderId,
                    shopperId: arguments.shopperId,
                    items:     shipItems,
                    shipTo:    shipTo
                }));
            }
            cflog(text="Webhook to ProLogics for order #newOrderId# - URL: #webhookUrl# - Status: #local.whRes.statusCode# - Response: #left(local.whRes.fileContent ?: '', 200)#", type="info", file="stylemart-checkout");
        } catch (any e) {
            cflog(text="Webhook to ProLogics EXCEPTION for order #newOrderId# - URL: #webhookUrl ?: 'unknown'# - Error: #e.message#", type="error", file="stylemart-checkout");
        }

        var resp = getPageContext().getResponse();
        resp.setStatus(201);

        return {
            "orderId": newOrderId, "userId": arguments.shopperId, "status": "confirmed",
            "subtotal": subtotalCents / 100, "discountTotal": discountCents / 100,
            "total": totalCents / 100, "currency": "USD",
            "placedAt": dateTimeFormat(now(), "yyyy-MM-dd'T'HH:nn:ss'Z'")
        };
    }
}
