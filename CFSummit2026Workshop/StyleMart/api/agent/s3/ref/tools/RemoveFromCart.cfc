component extends="BaseTool"
          hint="Cart removal tool CFC (direct, no staging)" {

    remote struct function removeFromCart(
        required string variantId hint="The variant ID to remove (from getCart results)"
    ) hint="Remove an item from the user's cart immediately. Returns the updated cart state." {
        var ctx = startToolCall("removeFromCart", {"variantId": arguments.variantId});

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            var u = "";
            try { u = getAuthUser(); } catch (any e) {}
            var userId = (isNull(u) || !len(trim(u))) ? "usr_demo_001" : u;
            var cart = svc.cartMe.getMyCart(shopperId = userId);
            var cartId = cart.cartId;

            var removedName = "";
            for (var item in (cart.items ?: [])) {
                if (item.variantId == arguments.variantId) {
                    removedName = (item.name ?: "Unknown");
                    break;
                }
            }

            svc.cart.removeItem(cartId = cartId, variantId = arguments.variantId);
            var updatedCart = svc.cart.getCart(cartId = cartId);

            endToolCall(ctx, "ok", "Removed #removedName#");

            return {
                "status": "removed",
                "removedItem": removedName,
                "variantId": arguments.variantId,
                "cartItemCount": arrayLen(updatedCart.items ?: []),
                "cartSubtotal": updatedCart.subtotal ?: 0
            };
        } catch (any e) {
            endToolCall(ctx, "error", e.message);
            return {"status": "error", "error": e.message};
        }
    }
}
