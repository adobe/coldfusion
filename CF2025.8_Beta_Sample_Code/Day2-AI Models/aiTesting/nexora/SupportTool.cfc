/**
 * SupportTool.cfc — Function tools the AI agent can call.
 * Each remote method is exposed as a tool to the LLM.
 * The hint, description, param, and returntype annotations are sent to the LLM
 * so it can decide which tool to call and how to pass arguments.
 */
component hint="Nexora customer support tools for order lookup and issue escalation" {

    variables.orders = {
        "12345": {
            status: "Shipped",
            carrier: "UPS",
            tracking: "1Z999AA10123456784",
            shipped: "April 8, 2026",
            eta: "April 13–14, 2026",
            item: "Nexora Pro Wireless Headphones (Midnight Black)",
            total: "$149.99",
            email: "alex.morgan@gmail.com"
        },
        "99821": {
            status: "Processing",
            carrier: "",
            tracking: "",
            shipped: "",
            eta: "April 16, 2026",
            item: "Nexora Smart Watch Ultra (Silver)",
            total: "$299.99",
            email: "sarah.chen@outlook.com"
        },
        "77654": {
            status: "Delivered",
            carrier: "FedEx",
            tracking: "748927489274892",
            shipped: "April 3, 2026",
            eta: "Delivered April 7, 2026",
            item: "Nexora Bluetooth Speaker (Ocean Blue)",
            total: "$89.99",
            email: "mike.johnson@yahoo.com"
        },
        "55432": {
            status: "Cancelled",
            carrier: "",
            tracking: "",
            shipped: "",
            eta: "",
            item: "Nexora Action Camera Kit",
            total: "$199.99",
            email: "lisa.park@hotmail.com"
        },
        "11111": {
            status: "Out for Delivery",
            carrier: "USPS",
            tracking: "92100903452345000017",
            shipped: "April 12, 2026",
            eta: "Today — expected by 8:00 PM",
            item: "Nexora Laptop Stand (Space Gray)",
            total: "$59.99",
            email: "james.wilson@gmail.com"
        }
    };

    /**
     * Get the current status and tracking information for a customer's order.
     * Call this tool whenever a customer asks about their order status, where their
     * order is, when it will arrive, tracking information, or delivery date.
     *
     * @hint Get order status, tracking info, and delivery date for a Nexora order
     * @orderId The order ID number provided by the customer (digits only, e.g. "12345")
     * @returntype string
     */
    remote string function getOrderStatus( required string orderId )
        hint="Get order status, tracking info, and delivery date for a Nexora order"
    {
        local.id = trim(reReplace(arguments.orderId, "[^0-9]", "", "all"));

        if (!len(local.id) || !structKeyExists(variables.orders, local.id)) {
            return "Order ##" & arguments.orderId & "## was not found in our system. " &
                   "Please double-check the order number and try again, or ask the customer to log in to verify it.";
        }

        local.o = variables.orders[local.id];
        local.result = "Order ##" & local.id & "## — " & local.o.item & chr(10) &
                       "Status: " & local.o.status & chr(10);

        if (len(local.o.tracking)) {
            local.result &= local.o.carrier & " tracking: " & local.o.tracking & chr(10);
        }
        if (len(local.o.shipped)) {
            local.result &= "Shipped: " & local.o.shipped & chr(10);
        }
        if (len(local.o.eta)) {
            local.result &= "Estimated delivery: " & local.o.eta & chr(10);
        }
        local.result &= "Order total: " & local.o.total & chr(10);
        local.result &= "Account email: " & local.o.email;

        return local.result;
    }

    /**
     * Escalate a customer's issue by creating a high-priority support ticket.
     * Call this tool when a customer explicitly asks to escalate, mentions this is a
     * recurring problem, expresses strong frustration, or asks to speak with a manager.
     * Do NOT call this for routine questions or first-time inquiries.
     *
     * @hint Escalate a customer issue by creating a high-priority support ticket
     * @summary A 1-2 sentence description of the issue being escalated
     * @orderId The related order ID if applicable (use empty string if none)
     * @returntype string
     */
    remote string function escalateIssue(
        required string summary,
        string orderId = ""
    )
        hint="Escalate a customer issue by creating a high-priority support ticket"
    {
        local.ticketId = "SUPPORT-" & randRange(4500, 4999);

        writeLog(
            text = "ESCALATION | ticket=" & local.ticketId &
                   " | order=" & arguments.orderId &
                   " | summary=" & arguments.summary,
            type = "information",
            file  = "nexora"
        );

        return "Escalation ticket ##" & local.ticketId & "## has been created and marked High Priority. " &
               "Our senior support team will contact the customer within 2 business hours. " &
               "Ticket reference: " & local.ticketId & ".";
    }

}
