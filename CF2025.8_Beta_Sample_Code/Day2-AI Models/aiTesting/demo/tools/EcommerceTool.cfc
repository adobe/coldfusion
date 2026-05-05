/**
 * EcommerceTool - Realistic e-commerce assistant tool for AI function-calling demo.
 * Provides product search, order tracking, promo codes and recommendations.
 */
component {

    /**
     * Search the product catalog for items matching a keyword
     * @mcpTool true
     * @mcpDescription Search the product catalog for items matching a keyword. Returns an array of matching products with price, availability and description.
     * @keyword Search term to find products (e.g. "ColdFusion", "training", "support")
     * @maxResults Maximum number of results to return
     * @return Array of matching product structs
     */
     remote array function searchProducts(required string keyword, numeric maxResults = 5) {
        var catalog = [
            { id:"CF2025-PRO",    name:"ColdFusion 2025 Professional", price:1299, category:"Software",    inStock:true,  rating:4.8, description:"Full enterprise server with AI/LLM, PDF, REST and more" },
            { id:"CF2025-STD",    name:"ColdFusion 2025 Standard",      price:799,  category:"Software",    inStock:true,  rating:4.5, description:"Standard server for small-to-medium applications" },
            { id:"ADOBE-CC",      name:"Adobe Creative Cloud All Apps", price:599,  category:"Subscription",inStock:true,  rating:4.9, description:"Full suite: Photoshop, Illustrator, Premiere and 20+ more" },
            { id:"SUPPORT-GOLD",  name:"Gold Support Plan",             price:599,  category:"Support",     inStock:true,  rating:4.7, description:"Priority 24/7 support with 2-hour response SLA" },
            { id:"SUPPORT-SILVER",name:"Silver Support Plan",           price:299,  category:"Support",     inStock:false, rating:4.3, description:"Business-hours support with 8-hour response SLA" },
            { id:"TRAINING-ADV",  name:"Advanced ColdFusion Training",  price:349,  category:"Training",    inStock:true,  rating:4.6, description:"Deep-dive training: AI integration, security, performance" },
            { id:"TRAINING-BASIC",name:"ColdFusion Fundamentals",       price:149,  category:"Training",    inStock:true,  rating:4.4, description:"Beginner-friendly intro to ColdFusion development" },
            { id:"CF-HOSTING",    name:"CF Cloud Hosting (1 year)",     price:480,  category:"Hosting",     inStock:true,  rating:4.2, description:"Managed cloud hosting, auto-scaling, 99.9% uptime SLA" }
        ];

        var results = [];
        for (var p in catalog) {
            if (findNoCase(arguments.keyword, p.name) || findNoCase(arguments.keyword, p.category) || findNoCase(arguments.keyword, p.description)) {
                arrayAppend(results, p);
                if (arrayLen(results) >= arguments.maxResults) break;
            }
        }
        return results;
    }

    /**
     * Apply a promotional discount code to a cart total
     * @mcpTool true
     * @mcpDescription Apply a promotional discount code to a cart total. Returns discount details including savings amount and final price.
     * @promoCode The promo code to validate and apply (e.g. "SAVE20", "CF2025", "FLAT100")
     * @cartTotal The cart subtotal in USD before discount
     * @return Struct with discount details: valid, originalTotal, discount, finalTotal
     */
     remote struct function applyPromoCode(required string promoCode, required numeric cartTotal) {
        var codes = {
            "SAVE10":  { pct:10,  fixed:0,   minOrder:0,    label:"10% off any order" },
            "SAVE20":  { pct:20,  fixed:0,   minOrder:0,    label:"20% off any order" },
            "CF2025":  { pct:15,  fixed:0,   minOrder:500,  label:"15% off orders $500+" },
            "FLAT50":  { pct:0,   fixed:50,  minOrder:200,  label:"$50 off orders $200+" },
            "FLAT100": { pct:0,   fixed:100, minOrder:1000, label:"$100 off orders $1000+" },
            "WELCOME": { pct:5,   fixed:0,   minOrder:0,    label:"5% first-purchase welcome discount" }
        };

        var code = uCase(trim(arguments.promoCode));
        if (!structKeyExists(codes, code)) {
            return { valid:false, promoCode:code, reason:"Code not recognised", originalTotal:arguments.cartTotal, discount:0, finalTotal:arguments.cartTotal };
        }

        var promo = codes[code];
        if (arguments.cartTotal < promo.minOrder) {
            return { valid:false, promoCode:code, reason:"Minimum order $#promo.minOrder# required (cart is $#arguments.cartTotal#)", originalTotal:arguments.cartTotal, discount:0, finalTotal:arguments.cartTotal };
        }

        var discount = (promo.pct > 0) ? arguments.cartTotal * (promo.pct / 100) : promo.fixed;
        discount = int(discount * 100) / 100;

        return {
            valid:        true,
            promoCode:    code,
            description:  promo.label,
            originalTotal:arguments.cartTotal,
            discount:     discount,
            finalTotal:   int((arguments.cartTotal - discount) * 100) / 100,
            savings:      "#numberFormat(discount / arguments.cartTotal * 100, '0.0')#% saved"
        };
    }

    /**
     * Track the shipment status of an order
     * @mcpTool true
     * @mcpDescription Track the shipment status of an order by order ID. Returns carrier, tracking number, current location and estimated delivery date.
     * @orderId The order ID to track (e.g. ORD-5001, ORD-5002)
     * @return Struct with carrier, tracking number, status, location and estimated delivery
     */
     remote struct function trackOrder(required string orderId) {
        var orders = {
            "ORD-5001":{ status:"Delivered",   carrier:"FedEx",  tracking:"FX123456789US", estimatedDelivery:"2025-03-10", deliveredDate:"2025-03-10", location:"Recipient – San Jose, CA",   items:["CF2025-PRO"],     total:1299 },
            "ORD-5002":{ status:"In Transit",  carrier:"UPS",    tracking:"1Z9999W99999999999", estimatedDelivery:"2025-03-18", deliveredDate:"",           location:"Distribution Centre – Chicago, IL", items:["ADOBE-CC","SUPPORT-GOLD"], total:1198 },
            "ORD-5003":{ status:"Processing",  carrier:"",       tracking:"",                   estimatedDelivery:"2025-03-20", deliveredDate:"",           location:"Fulfilment Warehouse",      items:["TRAINING-ADV"],  total:349  },
            "ORD-5004":{ status:"Shipped",     carrier:"DHL",    tracking:"DHL555666777888",    estimatedDelivery:"2025-03-17", deliveredDate:"",           location:"Sorting Hub – Los Angeles, CA", items:["CF2025-STD"], total:799  },
            "ORD-5005":{ status:"Cancelled",   carrier:"",       tracking:"",                   estimatedDelivery:"",          deliveredDate:"",           location:"",                          items:["SUPPORT-SILVER"],total:299  }
        };

        var id = uCase(trim(arguments.orderId));
        if (!structKeyExists(orders, id)) {
            return { error:"Order #id# not found. Valid IDs: ORD-5001 to ORD-5005", orderId:id };
        }
        var o = orders[id];
        o["orderId"] = id;
        return o;
    }

    /**
     * Get personalised product recommendations by category and budget
     * @mcpTool true
     * @mcpDescription Get personalised product recommendations filtered by category and maximum budget. Returns up to 5 products sorted by rating.
     * @category Product category filter: Software, Support, Training, Hosting, or "all"
     * @maxBudget Maximum budget in USD
     * @return Array of up to 5 recommended products sorted by rating
     */
    remote array function getRecommendations(required string category, required numeric maxBudget) {
        var all = [
            { id:"CF2025-STD",    name:"ColdFusion 2025 Standard",     price:799,  category:"Software", rating:4.5, reason:"Best-value entry point for most teams" },
            { id:"CF2025-PRO",    name:"ColdFusion 2025 Professional",  price:1299, category:"Software", rating:4.8, reason:"Most popular — full AI & enterprise features" },
            { id:"TRAINING-BASIC",name:"ColdFusion Fundamentals",       price:149,  category:"Training", rating:4.4, reason:"Perfect starting point for new developers" },
            { id:"TRAINING-ADV",  name:"Advanced ColdFusion Training",  price:349,  category:"Training", rating:4.6, reason:"Covers AI integration and advanced patterns" },
            { id:"SUPPORT-SILVER",name:"Silver Support Plan",           price:299,  category:"Support",  rating:4.3, reason:"Solid business-hours coverage" },
            { id:"SUPPORT-GOLD",  name:"Gold Support Plan",             price:599,  category:"Support",  rating:4.7, reason:"24/7 priority with dedicated engineer" },
            { id:"CF-HOSTING",    name:"CF Cloud Hosting (1 year)",     price:480,  category:"Hosting",  rating:4.2, reason:"Zero-config managed hosting" },
            { id:"ADOBE-CC",      name:"Adobe Creative Cloud All Apps", price:599,  category:"Software", rating:4.9, reason:"##1 rated creative suite worldwide" }
        ];

        var recs = [];
        for (var p in all) {
            if ((lCase(arguments.category) == "all" || findNoCase(arguments.category, p.category)) && p.price <= arguments.maxBudget) {
                arrayAppend(recs, p);
            }
        }
        arraySort(recs, function(a, b) { return b.rating > a.rating ? 1 : -1; });
        return arrayLen(recs) > 5 ? arraySlice(recs, 1, 5) : recs;
    }
}
