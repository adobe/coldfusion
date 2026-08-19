component rest="true" restpath="/shipments" produces="application/json" {

    private string function normalizeDate(required any val) {
        if (isDate(arguments.val)) return dateFormat(arguments.val, "yyyy-mm-dd");
        if (isNumeric(arguments.val) && arguments.val > 1000000000000) {
            var dt = createObject("java", "java.util.Date").init(javaCast("long", arguments.val));
            return dateFormat(dt, "yyyy-mm-dd");
        }
        return "";
    }

    // ============================================================
    // Public methods (directly invocable — no HTTP overhead)
    // ============================================================

    public struct function findByOrder(required string orderId) {
        var rows = queryExecute(
            "SELECT shipment_id, order_id, tracking_number, carrier,
                    status, estimated_delivery, actual_delivery, created_at
               FROM shipments
              WHERE order_id = :oid
              ORDER BY created_at DESC",
            { oid: { value: arguments.orderId, cfsqltype: "cf_sql_varchar" } }
        );

        var shipments = [];
        for (var i = 1; i <= rows.recordCount; i++) {
            arrayAppend(shipments, {
                "shipmentId":        rows.shipment_id[i],
                "orderId":           rows.order_id[i],
                "trackingNumber":    rows.tracking_number[i],
                "carrier":           rows.carrier[i],
                "status":            rows.status[i],
                "estimatedDelivery": normalizeDate(rows.estimated_delivery[i]),
                "actualDelivery":    isDate(rows.actual_delivery[i]) ? dateFormat(rows.actual_delivery[i], "yyyy-mm-dd") : "",
                "createdAt":         dateTimeFormat(rows.created_at[i], "yyyy-mm-dd'T'HH:nn:ss'Z'")
            });
        }
        return { "orderId": arguments.orderId, "shipments": shipments };
    }

    public struct function findTracking(required string shipmentId) {
        var events = queryExecute(
            "SELECT status, location, notes, occurred_at
               FROM shipment_events
              WHERE shipment_id = :sid
              ORDER BY occurred_at ASC",
            { sid: { value: arguments.shipmentId, cfsqltype: "cf_sql_varchar" } }
        );

        var timeline = [];
        for (var i = 1; i <= events.recordCount; i++) {
            arrayAppend(timeline, {
                "status":     events.status[i],
                "location":   events.location[i],
                "notes":      events.notes[i],
                "occurredAt": dateTimeFormat(events.occurred_at[i], "yyyy-mm-dd'T'HH:nn:ss'Z'")
            });
        }

        var shipment = queryExecute(
            "SELECT tracking_number, carrier, status, estimated_delivery
               FROM shipments WHERE shipment_id = :sid",
            { sid: { value: arguments.shipmentId, cfsqltype: "cf_sql_varchar" } }
        );

        return {
            "shipmentId":        arguments.shipmentId,
            "trackingNumber":    shipment.tracking_number,
            "carrier":           shipment.carrier,
            "currentStatus":     shipment.status,
            "estimatedDelivery": normalizeDate(shipment.estimated_delivery),
            "events":            timeline
        };
    }

    public struct function findEta(required string shipmentId) {
        var row = queryExecute(
            "SELECT status, estimated_delivery, carrier FROM shipments WHERE shipment_id = :sid",
            { sid: { value: arguments.shipmentId, cfsqltype: "cf_sql_varchar" } }
        );

        if (!row.recordCount) {
            return { "error": true, "code": "not_found", "message": "Shipment not found" };
        }

        var estDateStr = normalizeDate(row.estimated_delivery);
        var daysRemaining = len(estDateStr) ? dateDiff("d", now(), estDateStr) : 0;
        return {
            "shipmentId":        arguments.shipmentId,
            "status":            row.status,
            "estimatedDelivery": estDateStr,
            "daysRemaining":     max(0, daysRemaining),
            "carrier":           row.carrier,
            "onTime":            row.status != "failed" && daysRemaining >= 0
        };
    }

    public struct function createShipment(required struct orderData) {
        var shipmentId = "shp_" & lCase(replace(createUUID(), "-", "", "all"));

        var existing = queryExecute(
            "SELECT customer_id FROM customers WHERE shopper_id = :sid",
            {sid: {value: orderData.shopperId, cfsqltype: "cf_sql_varchar"}}
        );
        if (!existing.recordCount) {
            var customerId = "cst_" & lCase(replace(createUUID(), "-", "", "all"));
            queryExecute(
                "INSERT INTO customers (customer_id, shopper_id, full_name, address_line1, city, state, postal_code, country, phone, email)
                 VALUES (:cid, :sid, :name, :addr1, :city, :state, :zip, :country, :phone, :email)",
                {
                    cid: customerId, sid: orderData.shopperId,
                    name: orderData.shipTo.fullName ?: "", addr1: orderData.shipTo.address1 ?: "",
                    city: orderData.shipTo.city ?: "", state: orderData.shipTo.state ?: "",
                    zip: orderData.shipTo.postalCode ?: "", country: orderData.shipTo.country ?: "US",
                    phone: orderData.shipTo.phone ?: "", email: orderData.shipTo.email ?: ""
                }
            );
        }

        var estDelivery = dateAdd("d", 5, now());
        var trackingNum = "PL-" & dateFormat(now(), "yyyy") & "-" & randRange(10000, 99999);
        queryExecute(
            "INSERT INTO shipments (shipment_id, order_id, tracking_number, carrier, status, estimated_delivery)
             VALUES (:sid, :oid, :trk, 'prologics', 'received', :eta)",
            {
                sid: shipmentId, oid: orderData.orderId,
                trk: trackingNum,
                eta: {value: dateFormat(estDelivery, "yyyy-mm-dd"), cfsqltype: "cf_sql_varchar"}
            }
        );

        var items = orderData.items ?: [];
        for (var item in items) {
            queryExecute(
                "INSERT INTO shipment_items (shipment_id, product_id, variant_id, quantity)
                 VALUES (:sid, :pid, :vid, :qty)",
                {sid: shipmentId, pid: item.productId, vid: item.variantId ?: "", qty: item.quantity ?: 1}
            );
        }

        queryExecute(
            "INSERT INTO shipment_events (event_id, shipment_id, status, location, notes)
             VALUES (:eid, :sid, 'received', 'ProLogics Hub', 'Order received from StyleMart')",
            {eid: "evt_" & lCase(replace(createUUID(), "-", "", "all")), sid: shipmentId}
        );

        return {
            "shipmentId": shipmentId,
            "orderId": orderData.orderId,
            "trackingNumber": trackingNum,
            "status": "received",
            "estimatedDelivery": dateFormat(estDelivery, "yyyy-mm-dd")
        };
    }

    // ============================================================
    // REST wrappers (thin layer over public methods)
    // ============================================================

    remote struct function getByOrder(
        required string orderId restargsource="path"
    ) httpmethod="GET" restpath="by-order/{orderId}" {
        return findByOrder(arguments.orderId);
    }

    remote struct function getTracking(
        required string shipmentId restargsource="path"
    ) httpmethod="GET" restpath="{shipmentId}/tracking" {
        return findTracking(arguments.shipmentId);
    }

    remote struct function getEta(
        required string shipmentId restargsource="path"
    ) httpmethod="GET" restpath="{shipmentId}/eta" {
        return findEta(arguments.shipmentId);
    }

    remote struct function ingest() httpmethod="POST" restpath="ingest" {
        var body = deserializeJSON(toString(getHttpRequestData().content));
        return createShipment(body);
    }
}
