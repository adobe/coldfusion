/**
 * DELIBERATELY SLOW Baby Supplies Service CFC for MCP server.
 * Simulates unoptimized lookups with 2000-4000ms response times and NO caching.
 */
component {

    /**
     * @mcpTool true
     * @mcpDescription Search for baby products in the catalog. Returns matching items with pricing and stock info. SLOW uncached response.
     */
    remote array function searchProducts(
        required string query hint="Search term to find baby products, e.g. 'diapers', 'formula', 'onesie'"
    ) {
        sleep(3000);

        var catalog = [
            { id: "DIAP-001",  name: "Pampers Swaddlers Newborn",        category: "Diapers",  price: 29.99, stock: 150 },
            { id: "DIAP-002",  name: "Huggies Little Snugglers Size 1",  category: "Diapers",  price: 34.99, stock: 200 },
            { id: "FORM-001",  name: "Similac Pro-Advance Formula",      category: "Feeding",  price: 39.99, stock: 80 },
            { id: "BOTT-001",  name: "Dr. Brown's Anti-Colic Bottles",   category: "Feeding",  price: 24.99, stock: 95 },
            { id: "ONES-001",  name: "Carter's Cotton Onesies Pack",     category: "Clothing", price: 19.99, stock: 120 },
            { id: "SWAD-001",  name: "Halo SleepSack Swaddle",           category: "Sleep",    price: 29.99, stock: 60 },
            { id: "WIPE-001",  name: "WaterWipes Sensitive Baby Wipes",  category: "Hygiene",  price: 14.99, stock: 250 },
            { id: "CREAM-001", name: "Desitin Maximum Strength Cream",   category: "Hygiene",  price: 8.99,  stock: 110 },
            { id: "THER-001",  name: "Braun Digital Ear Thermometer",    category: "Health",   price: 44.99, stock: 35 },
            { id: "PUMP-001",  name: "Medela Breast Pump Starter Set",   category: "Feeding",  price: 149.99, stock: 25 }
        ];

        var results = [];
        var q = lCase(trim(arguments.query));
        var words = listToArray(q, " ");
        for (var product in catalog) {
            var matched = false;
            for (var word in words) {
                if (len(word) >= 3 && (findNoCase(word, product.name) || findNoCase(word, product.category) || findNoCase(word, product.id))) {
                    matched = true;
                    break;
                }
            }
            if (matched) {
                arrayAppend(results, product);
            }
        }
        if (arrayLen(results) == 0) {
            results = catalog;
        }
        return results;
    }

    /**
     * @mcpTool true
     * @mcpDescription Check stock level for a specific baby product. SLOW uncached response.
     */
    remote struct function checkInventory(
        required string productId hint="The product ID, e.g. DIAP-001"
    ) {
        sleep(2000);

        var inventory = {
            "DIAP-001":  { productId: "DIAP-001",  inStock: true, quantity: 150, store: "Baby Mart" },
            "FORM-001":  { productId: "FORM-001",  inStock: true, quantity: 80,  store: "Baby Mart" },
            "BOTT-001":  { productId: "BOTT-001",  inStock: true, quantity: 95,  store: "Baby Central" },
            "SWAD-001":  { productId: "SWAD-001",  inStock: true, quantity: 60,  store: "Baby Mart" },
            "WIPE-001":  { productId: "WIPE-001",  inStock: true, quantity: 250, store: "Baby Central" },
            "THER-001":  { productId: "THER-001",  inStock: true, quantity: 35,  store: "Baby Central" }
        };

        return structKeyExists(inventory, uCase(arguments.productId))
            ? inventory[uCase(arguments.productId)]
            : { productId: arguments.productId, inStock: false, quantity: 0, message: "Product not found" };
    }

    /**
     * @mcpTool true
     * @mcpDescription Get the current status of a baby supplies order. SLOW uncached response.
     */
    remote struct function getOrderStatus(
        required string orderId hint="The order ID, e.g. ORD-BABY-1234"
    ) {
        sleep(4000);

        var orders = {
            "ORD-BABY-1234": { orderId: "ORD-BABY-1234", status: "Shipped",    item: "Pampers Swaddlers NB x3", shipped: "2026-04-12", eta: "2026-04-15", carrier: "Amazon" },
            "ORD-BABY-1235": { orderId: "ORD-BABY-1235", status: "Processing", item: "Bottles + Wipes bundle",   shipped: "N/A",        eta: "2026-04-17", carrier: "Target" },
            "ORD-BABY-1236": { orderId: "ORD-BABY-1236", status: "Delivered",  item: "Onesies + Swaddle",        shipped: "2026-04-10", eta: "Delivered",   carrier: "Amazon" }
        };

        return structKeyExists(orders, uCase(arguments.orderId))
            ? orders[uCase(arguments.orderId)]
            : { orderId: arguments.orderId, status: "Not Found", message: "Order not found." };
    }
}
