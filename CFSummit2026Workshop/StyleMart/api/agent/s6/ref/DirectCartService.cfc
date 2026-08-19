component rest="true" restpath="/s6/ref/cart-actions" produces="application/json" consumes="application/json" {

    remote struct function directAdd(
        string shopperId restargsource="header" restargname="X-Shopper-Id" default=""
    ) httpmethod="POST" restpath="add" {
        var body = deserializeJSON(toString(getHttpRequestData().content));
        var productId = body.productId ?: "";
        var size = body.size ?: "";
        var dsn = "stylemart";

        if (!len(productId)) {
            throw(type="RestError", errorcode="422", message="productId required");
        }

        var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
        var userId = resolveCartUser(arguments.shopperId);
        var cart = svc.cartMe.getMyCart(shopperId = userId);
        var cartId = cart.cartId;

        // Size is optional. When provided, match it; otherwise pick any in-stock
        // variant (covers one-size accessories used by the upsell/landing add-ons).
        var hasSize = len(trim(size)) GT 0;
        var variantSql = "
            SELECT pv.variant_id, pv.size, pv.color FROM product_variants pv
            JOIN inventory i ON i.variant_id = pv.variant_id
            WHERE pv.product_id = :pid AND i.quantity > 0
        ";
        var variantParams = { pid: {value: productId, cfsqltype: "cf_sql_varchar"} };
        if (hasSize) {
            variantSql &= " AND UPPER(pv.size) = :sz";
            variantParams.sz = {value: uCase(size), cfsqltype: "cf_sql_varchar"};
        }
        variantSql &= " ORDER BY i.quantity DESC LIMIT 1";

        var qVariant = queryExecute(variantSql, variantParams, {datasource: dsn});

        if (qVariant.recordCount == 0) {
            throw(type="RestError", errorcode="422",
                  message=hasSize ? "No in-stock variant for this product/size" : "No in-stock variant for this product");
        }

        svc.cart.addItemDirect(cartId = cartId, variantId = qVariant.variant_id, quantity = 1);
        var updatedCart = svc.cart.getCart(cartId = cartId);

        return {
            "status": "added",
            "variantId": qVariant.variant_id,
            "size": qVariant.size,
            "color": qVariant.color,
            "cartItemCount": arrayLen(updatedCart.items ?: []),
            "cartSubtotal": updatedCart.subtotal ?: 0
        };
    }

    remote struct function directRemove(
        required string variantId restargsource="path",
        string shopperId restargsource="header" restargname="X-Shopper-Id" default=""
    ) httpmethod="DELETE" restpath="remove/{variantId}" {
        var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
        var userId = resolveCartUser(arguments.shopperId);
        var cart = svc.cartMe.getMyCart(shopperId = userId);
        var cartId = cart.cartId;

        svc.cart.removeItem(cartId = cartId, variantId = arguments.variantId);
        var updatedCart = svc.cart.getCart(cartId = cartId);

        return {
            "status": "removed",
            "variantId": arguments.variantId,
            "cartItemCount": arrayLen(updatedCart.items ?: []),
            "cartSubtotal": updatedCart.subtotal ?: 0
        };
    }

    /**
     * Resolve the shopper whose cart we read/write. This MUST agree with the
     * commerce read path (CartMeService), which keys the cart off the
     * X-Shopper-Id header. REST services don't always share the web app's
     * cflogin session, so getAuthUser() can come back empty here — in that case
     * we honor the X-Shopper-Id header (the real, logged-in user the frontend
     * always sends) before falling back to the demo user. Without this, adds
     * land in usr_demo_001's cart while the storefront shows the real user's
     * cart, so items appear to vanish.
     */
    private string function resolveCartUser(string headerShopperId = "") {
        var u = "";
        try { u = getAuthUser(); } catch (any e) {}
        if (!isNull(u) && len(trim(u))) return trim(u);
        if (len(trim(arguments.headerShopperId))) return trim(arguments.headerShopperId);
        return "usr_demo_001";
    }
}
