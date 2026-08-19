component {

    variables.LOG_FILE = "prologics-mcp";
    variables.SERVER_NAME = "prologics-logistics";
    variables.shipmentService = new CFSummit2026Workshop.externalservices.prologics.ShipmentService();

    private struct function startMcpCall(required string toolName, required struct args) {
        var qid = "";
        try { qid = server.stylemart._streamQueueId ?: ""; } catch (any e) {}
        var callId = "mcp_" & left(lCase(replace(createUUID(), "-", "", "all")), 12);

        if (len(qid) && structKeyExists(server, "stylemart") && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, qid)) {
            arrayAppend(server.stylemart.streams[qid], {
                "type": "mcp.call",
                "payload": {
                    "server":    variables.SERVER_NAME,
                    "toolName":  arguments.toolName,
                    "args":      arguments.args,
                    "callId":    callId,
                    "transport": "http"
                }
            });
        }

        return {callId: callId, startTick: getTickCount(), qid: qid};
    }

    private void function endMcpCall(required struct ctx, required string status, string summary = "") {
        if (len(ctx.qid) && structKeyExists(server, "stylemart") && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            arrayAppend(server.stylemart.streams[ctx.qid], {
                "type": "mcp.result",
                "payload": {
                    "callId":     ctx.callId,
                    "status":     arguments.status,
                    "durationMs": getTickCount() - ctx.startTick,
                    "summary":    arguments.summary
                }
            });
        }
    }

    remote struct function trackShipment(
        required string orderId hint="StyleMart order ID to track"
    ) hint="Get shipment status and tracking timeline for an order" {
        var ctx = startMcpCall("trackShipment", {orderId: arguments.orderId});
        cflog(text="#ctx.callId# - trackShipment called - orderId: #arguments.orderId#", type="info", file=variables.LOG_FILE);

        try {
            var data = variables.shipmentService.findByOrder(arguments.orderId);
            var shipments = data.shipments ?: [];

            if (!arrayLen(shipments)) {
                cflog(text="#ctx.callId# - trackShipment - no shipments found", type="warning", file=variables.LOG_FILE);
                endMcpCall(ctx, "ok", "no shipments");
                return { "orderId": arguments.orderId, "status": "no_shipments", "message": "No shipments found." };
            }

            var primary = shipments[1];
            var tracking = variables.shipmentService.findTracking(primary.shipmentId);

            var result = {
                "orderId":           arguments.orderId,
                "shipmentId":        primary.shipmentId,
                "trackingNumber":    primary.trackingNumber,
                "carrier":           primary.carrier,
                "status":            primary.status,
                "estimatedDelivery": primary.estimatedDelivery,
                "events":            tracking.events ?: []
            };

            cflog(text="#ctx.callId# - trackShipment complete - status: #primary.status#", type="info", file=variables.LOG_FILE);
            endMcpCall(ctx, "ok", "status: #primary.status#");
            return result;

        } catch (any e) {
            cflog(text="#ctx.callId# - trackShipment ERROR - #e.message#", type="error", file=variables.LOG_FILE);
            endMcpCall(ctx, "error", e.message);
            return { "error": true, "message": "Failed to track shipment: " & e.message };
        }
    }

    remote struct function getDeliveryEta(
        required string orderId hint="StyleMart order ID"
    ) hint="Get estimated delivery date and whether the shipment is on time" {
        var ctx = startMcpCall("getDeliveryEta", {orderId: arguments.orderId});
        cflog(text="#ctx.callId# - getDeliveryEta called - orderId: #arguments.orderId#", type="info", file=variables.LOG_FILE);

        try {
            var data = variables.shipmentService.findByOrder(arguments.orderId);

            if (!arrayLen(data.shipments ?: [])) {
                cflog(text="#ctx.callId# - getDeliveryEta - not shipped yet", type="warning", file=variables.LOG_FILE);
                endMcpCall(ctx, "ok", "not shipped");
                return { "orderId": arguments.orderId, "status": "not_shipped", "message": "Order has not been shipped yet." };
            }

            var shipmentId = data.shipments[1].shipmentId;
            var eta = variables.shipmentService.findEta(shipmentId);
            eta["orderId"] = arguments.orderId;

            cflog(text="#ctx.callId# - getDeliveryEta complete - ETA: #eta.estimatedDelivery#, onTime: #eta.onTime#", type="info", file=variables.LOG_FILE);
            endMcpCall(ctx, "ok", "ETA: #eta.estimatedDelivery#");
            return eta;

        } catch (any e) {
            cflog(text="#ctx.callId# - getDeliveryEta ERROR - #e.message#", type="error", file=variables.LOG_FILE);
            endMcpCall(ctx, "error", e.message);
            return { "error": true, "message": "Failed to get delivery ETA: " & e.message };
        }
    }
}
