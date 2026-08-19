component extends="BaseTool"
          hint="Product comparison tool CFC" {

    remote struct function compareProducts(
        required array productIds hint="Array of product IDs to compare (2-4 items)",
        array dimensions hint="Dimensions to compare (e.g. ['price','fabric','care','sizes','colors','fit'])" default="['price','fabric','care','sizes','colors','fit']"
    ) hint="Compare two or more products side-by-side across dimensions like price, fabric, care instructions, sizes, and colors. Use when the user asks 'which one should I get?' or wants to see differences." {
        var ctx = startToolCall("compareProducts", {"productIds": arguments.productIds, "dimensions": arguments.dimensions});
        var status = "ok";
        var comparison = {};

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            comparison = svc.product.compare(
                body = {"productIds": arguments.productIds, "dimensions": arguments.dimensions}
            );
        } catch (any e) {
            status = "error";
            comparison = {"error": "Comparison failed"};
        }

        endToolCall(ctx, status, "#arrayLen(arguments.productIds)# products compared");

        // Emit SSE event for rich table UI
        if (!structKeyExists(comparison, "error") && len(ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            arrayAppend(server.stylemart.streams[ctx.qid], {
                "type": "tool.compare",
                "payload": {"callId": ctx.callId, "comparison": comparison}
            });
        }

        return comparison;
    }
}
