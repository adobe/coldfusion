component extends="BaseTool"
          hint="Cart add tool CFC (direct, no staging)" {

    remote struct function addToCart(
        required any productIds hint="Array of product IDs to add to cart (or a single product ID string)",
        string size hint="Preferred size (e.g. 'M', 'L')" default="",
        string reason hint="Brief reason for the suggestion" default=""
    ) hint="Add one or more products directly to the user's cart. Returns the added items and updated cart total." {
        if (isSimpleValue(arguments.productIds)) {
            try { arguments.productIds = deserializeJSON(arguments.productIds); } catch (any e) {}
            if (isSimpleValue(arguments.productIds)) arguments.productIds = [arguments.productIds];
        }
        var ctx = startToolCall("addToCart", {"productIds": arguments.productIds, "size": arguments.size, "reason": arguments.reason});

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            var u = "";
            try { u = getAuthUser(); } catch (any e) {}
            var userId = (isNull(u) || !len(trim(u))) ? "usr_demo_001" : u;
            var cart = svc.cartMe.getMyCart(shopperId = userId);
            var cartId = cart.cartId;

            var addedItems = [];
            for (var pid in arguments.productIds) {
                var variantId = resolveVariant(pid, arguments.size, userId, svc);
                svc.cart.addItemDirect(cartId = cartId, variantId = variantId, quantity = 1);
                arrayAppend(addedItems, {"productId": pid, "variantId": variantId});
            }

            var updatedCart = svc.cart.getCart(cartId = cartId);
            endToolCall(ctx, "ok", "#arrayLen(addedItems)# items added");

            return {
                "status": "added",
                "addedItems": addedItems,
                "cartItemCount": arrayLen(updatedCart.items ?: []),
                "cartSubtotal": updatedCart.subtotal ?: 0
            };
        } catch (any e) {
            logToolError(ctx, e);
            endToolCall(ctx, "error", e.message);
            return {"status": "error", "error": e.message};
        }
    }

    private string function resolveVariant(required string productId, string size="", string userId="", required any svc) {
        var dsn = "stylemart";
        var pid = arguments.productId;
        if (left(pid, 4) == "var_") return pid;

        if (len(trim(arguments.size))) {
            var qVariant = queryExecute("
                SELECT pv.variant_id FROM product_variants pv
                JOIN inventory i ON i.variant_id = pv.variant_id
                WHERE pv.product_id = :pid AND UPPER(pv.size) = :sz AND i.quantity > 0
                LIMIT 1
            ", {
                pid: {value: pid, cfsqltype: "cf_sql_varchar"},
                sz: {value: uCase(arguments.size), cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
            if (qVariant.recordCount > 0) return qVariant.variant_id;
        }

        var qFallback = queryExecute("
            SELECT pv.variant_id FROM product_variants pv
            JOIN inventory i ON i.variant_id = pv.variant_id
            WHERE pv.product_id = :pid AND i.quantity > 0
            LIMIT 1
        ", {pid: {value: pid, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qFallback.recordCount == 0) {
            throw(type="RestError", errorcode="422", message="No in-stock variant for product: #pid#");
        }
        return qFallback.variant_id;
    }
}
