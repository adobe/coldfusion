component extends="BaseTool"
          hint="Order history tool CFC" {

    remote struct function getOrderHistory(
        numeric limit hint="Maximum number of orders to return. Pass 1 for 'my last order' or 'where is my order' queries." default="0"
    ) hint="Get the user's past order history. Use when the user asks about previous purchases, wants to reorder, or asks about order status/tracking. Pass limit=1 when user asks for their 'last', 'most recent', or 'where is my' order." {
        var ctx = startToolCall("getOrderHistory", {"limit": arguments.limit});
        var status = "ok";
        var orders = {};

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            orders = svc.order.listOrders();
            // Enrich order items with productId and slug for frontend links
            // listOrders() doesn't return variantId/productId, so query order_items directly
            if (arrayLen(orders.items ?: [])) {
                for (var o = 1; o <= arrayLen(orders.items); o++) {
                    var orderId = orders.items[o].orderId ?: "";
                    var orderItems = orders.items[o].items ?: [];
                    if (len(orderId) && arrayLen(orderItems)) {
                        try {
                            var qOI = queryExecute("
                                SELECT oi.variant_id, oi.product_id, oi.snapshot_name,
                                       p.slug
                                FROM order_items oi
                                JOIN products p ON p.product_id = oi.product_id
                                WHERE oi.order_id = :oid
                                ORDER BY oi.order_item_id
                            ", {oid: {value: orderId, cfsqltype: "cf_sql_varchar"}}, {datasource: "stylemart"});
                            for (var i = 1; i <= arrayLen(orderItems); i++) {
                                if (i <= qOI.recordCount) {
                                    orders.items[o].items[i]["productId"] = qOI.product_id[i];
                                    orders.items[o].items[i]["slug"] = qOI.slug[i];
                                    orders.items[o].items[i]["variantId"] = qOI.variant_id[i];
                                }
                            }
                        } catch (any e) {}
                    }
                    // Enrich items with hasReview flag
                    try {
                        var userId = "usr_demo_001";
                        var productIds = [];
                        for (var item in orders.items[o].items) {
                            if (structKeyExists(item, "productId") && len(item.productId)) {
                                arrayAppend(productIds, item.productId);
                            }
                        }
                        if (arrayLen(productIds)) {
                            var pidList = "'" & arrayToList(productIds, "','") & "'";
                            var qReviewed = queryExecute("
                                SELECT product_id FROM product_reviews
                                WHERE user_id = :uid AND product_id IN (#pidList#)
                            ", {uid: {value: userId, cfsqltype: "cf_sql_varchar"}}, {datasource: "stylemart"});
                            var reviewedSet = {};
                            for (var rv in qReviewed) { reviewedSet[rv.product_id] = true; }
                            for (var i = 1; i <= arrayLen(orders.items[o].items); i++) {
                                var pid = orders.items[o].items[i]["productId"] ?: "";
                                orders.items[o].items[i]["hasReview"] = structKeyExists(reviewedSet, pid);
                            }
                        }
                    } catch (any e) {}
                }
            }
        } catch (any e) {
            status = "error";
            orders = {"error": "Failed to fetch orders", "items": []};
        }

        if (arguments.limit > 0 && arrayLen(orders.items ?: []) > arguments.limit) {
            orders.items = orders.items.slice(1, arguments.limit);
        }

        endToolCall(ctx, status, "#arrayLen(orders.items ?: [])# past orders");

        if (arrayLen(orders.items ?: []) && len(ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            for (var idx = 1; idx <= arrayLen(orders.items); idx++) {
                var streamOrder = deserializeJSON(serializeJSON(orders.items[idx]));
                arrayAppend(server.stylemart.streams[ctx.qid], {
                    "type": "tool.order",
                    "payload": {"callId": ctx.callId, "order": streamOrder, "index": idx, "total": arrayLen(orders.items)}
                });
            }
        }

        if (arrayLen(orders.items ?: [])) {
            for (var o in orders.items) {
                for (var item in (o.items ?: [])) {
                    structDelete(item, "imageUrl");
                    structDelete(item, "image_url");
                }
            }
        }

        return orders;
    }
}
