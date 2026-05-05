/**
 * OPTIMIZED Baby Supplies Service CFC for MCP server.
 * Fast, cached baby product lookups with 100-300ms response times.
 */
component {

    variables.cache = {};

    /**
     * @mcpTool true
     * @mcpDescription Search for baby products and supplies. Returns matching items with pricing and stock info.
     */
    remote array function searchProducts(
        required string query hint="Search term to find baby products, e.g. 'diapers', 'formula', 'onesie'"
    ) {
        var cacheKey = "search_" & lCase(trim(arguments.query));
        if (structKeyExists(variables.cache, cacheKey)) {
            return variables.cache[cacheKey];
        }

        sleep(150);

        var catalog = [
            { id: "DIAP-001",  name: "Pampers Swaddlers Newborn",        category: "Diapers",     price: 29.99, stock: 150, size: "Newborn (up to 10 lbs)" },
            { id: "DIAP-002",  name: "Huggies Little Snugglers Size 1",  category: "Diapers",     price: 34.99, stock: 200, size: "Size 1 (8-14 lbs)" },
            { id: "FORM-001",  name: "Similac Pro-Advance Formula",      category: "Feeding",     price: 39.99, stock: 80,  size: "23.2 oz powder" },
            { id: "BOTT-001",  name: "Dr. Brown's Anti-Colic Bottles",   category: "Feeding",     price: 24.99, stock: 95,  size: "4 oz, 3-pack" },
            { id: "ONES-001",  name: "Carter's Cotton Onesies Pack",     category: "Clothing",    price: 19.99, stock: 120, size: "0-3 months, 5-pack" },
            { id: "SWAD-001",  name: "Halo SleepSack Swaddle",           category: "Sleep",       price: 29.99, stock: 60,  size: "Newborn" },
            { id: "WIPE-001",  name: "WaterWipes Sensitive Baby Wipes",  category: "Hygiene",     price: 14.99, stock: 250, size: "60 count, 3-pack" },
            { id: "CREAM-001", name: "Desitin Maximum Strength Cream",   category: "Hygiene",     price: 8.99,  stock: 110, size: "4 oz tube" },
            { id: "THER-001",  name: "Braun Digital Ear Thermometer",    category: "Health",      price: 44.99, stock: 35,  size: "One Size" },
            { id: "PUMP-001",  name: "Medela Breast Pump Starter Set",   category: "Feeding",     price: 149.99, stock: 25, size: "Electric, double" }
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

        variables.cache[cacheKey] = results;
        return results;
    }

    /**
     * @mcpTool true
     * @mcpDescription Check the current stock level and availability of a specific baby product by its ID.
     */
    remote struct function checkInventory(
        required string productId hint="The product ID, e.g. DIAP-001"
    ) {
        var cacheKey = "inv_" & uCase(trim(arguments.productId));
        if (structKeyExists(variables.cache, cacheKey)) {
            return variables.cache[cacheKey];
        }

        sleep(100);

        var inventory = {
            "DIAP-001":  { productId: "DIAP-001",  name: "Pampers Swaddlers Newborn",       inStock: true,  quantity: 150, store: "Baby Mart",    reorderLevel: 30, nextRestock: "2026-04-20" },
            "DIAP-002":  { productId: "DIAP-002",  name: "Huggies Little Snugglers Size 1", inStock: true,  quantity: 200, store: "Baby Mart",    reorderLevel: 40, nextRestock: "N/A" },
            "FORM-001":  { productId: "FORM-001",  name: "Similac Pro-Advance Formula",     inStock: true,  quantity: 80,  store: "Baby Mart",    reorderLevel: 15, nextRestock: "2026-04-18" },
            "BOTT-001":  { productId: "BOTT-001",  name: "Dr. Brown's Anti-Colic Bottles",  inStock: true,  quantity: 95,  store: "Baby Central", reorderLevel: 20, nextRestock: "N/A" },
            "ONES-001":  { productId: "ONES-001",  name: "Carter's Cotton Onesies Pack",    inStock: true,  quantity: 120, store: "Baby Central", reorderLevel: 25, nextRestock: "N/A" },
            "SWAD-001":  { productId: "SWAD-001",  name: "Halo SleepSack Swaddle",          inStock: true,  quantity: 60,  store: "Baby Mart",    reorderLevel: 10, nextRestock: "2026-04-22" },
            "WIPE-001":  { productId: "WIPE-001",  name: "WaterWipes Sensitive Baby Wipes", inStock: true,  quantity: 250, store: "Baby Central", reorderLevel: 50, nextRestock: "N/A" },
            "CREAM-001": { productId: "CREAM-001", name: "Desitin Maximum Strength Cream",  inStock: true,  quantity: 110, store: "Baby Mart",    reorderLevel: 20, nextRestock: "N/A" },
            "THER-001":  { productId: "THER-001",  name: "Braun Digital Ear Thermometer",   inStock: true,  quantity: 35,  store: "Baby Central", reorderLevel: 5,  nextRestock: "2026-04-25" },
            "PUMP-001":  { productId: "PUMP-001",  name: "Medela Breast Pump Starter Set",  inStock: true,  quantity: 25,  store: "Baby Mart",    reorderLevel: 5,  nextRestock: "2026-04-30" }
        };

        var result = structKeyExists(inventory, uCase(arguments.productId))
            ? inventory[uCase(arguments.productId)]
            : { productId: arguments.productId, inStock: false, quantity: 0, message: "Product not found in catalog" };

        variables.cache[cacheKey] = result;
        return result;
    }

    /**
     * @mcpTool true
     * @mcpDescription Get the current status of a baby supplies order.
     */
    remote struct function getOrderStatus(
        required string orderId hint="The order ID, e.g. ORD-BABY-1234"
    ) {
        var cacheKey = "order_" & uCase(trim(arguments.orderId));
        if (structKeyExists(variables.cache, cacheKey)) {
            return variables.cache[cacheKey];
        }

        sleep(200);

        var orders = {
            "ORD-BABY-1234": { orderId: "ORD-BABY-1234", status: "Shipped",    item: "Pampers Swaddlers NB x3 boxes", shipped: "2026-04-12", eta: "2026-04-15", tracking: "1Z999BB20123456784", carrier: "Amazon" },
            "ORD-BABY-1235": { orderId: "ORD-BABY-1235", status: "Processing", item: "Dr. Brown's Bottles + Wipes bundle", shipped: "N/A",   eta: "2026-04-17", tracking: "Pending",              carrier: "Target" },
            "ORD-BABY-1236": { orderId: "ORD-BABY-1236", status: "Delivered",  item: "Carter's Onesies + Swaddle",    shipped: "2026-04-10", eta: "Delivered",   tracking: "1Z999BB20123456785", carrier: "Amazon" }
        };

        var result = structKeyExists(orders, uCase(arguments.orderId))
            ? orders[uCase(arguments.orderId)]
            : { orderId: arguments.orderId, status: "Not Found", message: "Order not found. Please verify the order ID." };

        variables.cache[cacheKey] = result;
        return result;
    }
}
