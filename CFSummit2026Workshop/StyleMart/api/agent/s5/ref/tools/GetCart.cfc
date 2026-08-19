component extends="BaseTool"
          hint="Cart retrieval tool CFC" {

    remote struct function getCart(
    ) hint="Get the current shopping cart contents. Use when the user asks 'what is in my cart' or before suggesting additions." {
        var ctx = startToolCall("getCart", {});
        var status = "ok";
        var cart = {};

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            cart = svc.cartMe.getMyCart();
            // Enrich cart items with productId and slug for frontend links
            if (arrayLen(cart.items ?: [])) {
                for (var i = 1; i <= arrayLen(cart.items); i++) {
                    var item = cart.items[i];
                    if (!structKeyExists(item, "productId") || !structKeyExists(item, "slug")) {
                        try {
                            var qProd = queryExecute("
                                SELECT p.product_id, p.slug FROM products p
                                JOIN product_variants pv ON pv.product_id = p.product_id
                                WHERE pv.variant_id = :vid LIMIT 1
                            ", {vid: {value: item.variantId, cfsqltype: "cf_sql_varchar"}}, {datasource: "stylemart"});
                            if (qProd.recordCount > 0) {
                                cart.items[i]["productId"] = qProd.product_id;
                                cart.items[i]["slug"] = qProd.slug;
                            }
                        } catch (any e) {}
                    }
                }
            }
        } catch (any e) {
            status = "error";
            cart = {"error": "Failed to fetch cart", "items": []};
        }

        endToolCall(ctx, status, "#arrayLen(cart.items ?: [])# items in cart");

        if (arrayLen(cart.items ?: []) && len(ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            arrayAppend(server.stylemart.streams[ctx.qid], {
                "type": "tool.cart",
                "payload": {
                    "callId": ctx.callId,
                    "items": cart.items,
                    "cartId": cart.cartId ?: "",
                    "subtotal": cart.subtotal ?: 0,
                    "itemCount": arrayLen(cart.items ?: [])
                }
            });
        }

        return cart;
    }
}
