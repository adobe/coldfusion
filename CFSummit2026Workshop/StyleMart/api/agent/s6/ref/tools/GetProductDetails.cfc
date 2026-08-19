component extends="BaseTool"
          hint="Product details tool CFC" {

    remote struct function getProductDetails(
        required string productId hint="The product ID (e.g. 'prd_01HZX01T001')"
    ) hint="Get full details for a specific product by ID. Use when the user asks about a specific product, needs sizing/color info, or before adding to cart." {
        var ctx = startToolCall("getProductDetails", {"productId": arguments.productId});
        var status = "ok";
        var product = {};

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            product = svc.product.getProduct(
                productId = arguments.productId
            );
            if (structIsEmpty(product) || !structKeyExists(product, "productId")) {
                status = "not_found";
                product = {"error": "Product not found", "productId": arguments.productId};
            }
        } catch (any e) {
            if (e.message contains "not found" || (structKeyExists(e, "errorcode") && e.errorcode == "404")) {
                status = "not_found";
                product = {"error": "Product not found", "productId": arguments.productId};
            } else {
                status = "error";
                product = {"error": "Failed to fetch product details"};
            }
        }

        endToolCall(ctx, status, status == "ok" ? product.name ?: "product" : status);

        if (status == "ok" && len(ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            var streamProduct = deserializeJSON(serializeJSON(product));
            arrayAppend(server.stylemart.streams[ctx.qid], {
                "type": "tool.product",
                "payload": {"callId": ctx.callId, "product": streamProduct}
            });
        }

        structDelete(product, "imageUrl");
        structDelete(product, "image_url");
        structDelete(product, "images");
        structDelete(product, "siblings");
        return product;
    }
}
