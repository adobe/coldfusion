/* Tool CFC: each public remote method becomes an MCP tool.
   - component hint = tool group description
   - function hint = tool description (shown to the LLM)
   - argument hints = parameter descriptions for the LLM's tool schema */
component hint="Simple shipment tracking tool" {

    remote struct function getShipmentStatus(
        required string orderId hint="Order ID to track (e.g. ord_001)"
    ) hint="Returns the current shipment status for an order." {
        var shipments = {
            "ord_001": { status: "shipped",    carrier: "FedEx",  tracking: "FX123456789", eta: "2026-06-15" },
            "ord_002": { status: "processing", carrier: "",       tracking: "",            eta: "" },
            "ord_003": { status: "delivered",  carrier: "UPS",    tracking: "UP987654321", eta: "2026-06-10" }
        };

        if (structKeyExists(shipments, arguments.orderId)) {
            return shipments[arguments.orderId];
        }
        return { status: "not_found", carrier: "", tracking: "", eta: "" };
    }
}
