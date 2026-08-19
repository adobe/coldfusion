component rest="true" restpath="/products" produces="application/json" consumes="application/json" {

    remote struct function listProducts(
        string category restargsource="query" default="",
        string occasion restargsource="query" default="",
        numeric priceMin restargsource="query" default="0",
        numeric priceMax restargsource="query" default="999999",
        string colors restargsource="query" default="",
        string size restargsource="query" default="",
        string fit restargsource="query" default="",
        string q restargsource="query" default="",
        numeric page restargsource="query" default="1",
        numeric pageSize restargsource="query" default="24"
    ) httpmethod="GET" {
        var dsn = "stylemart";
        if (arguments.page < 1) arguments.page = 1;
        if (arguments.pageSize < 1 || arguments.pageSize > 100) arguments.pageSize = 24;

        var sql = "SELECT p.product_id, p.slug, p.name, p.brand, p.category, p.subcategory,
                   p.description, p.care_instructions, p.base_price_cents, p.currency,
                   p.image_url, p.attributes, p.occasion_tags, p.average_rating, p.review_count
                   FROM products p WHERE 1=1";
        var params = {};

        if (len(arguments.category)) {
            var catList = listToArray(arguments.category);
            if (arrayLen(catList) == 1) {
                sql &= " AND p.category = :category";
                params.category = {value: catList[1], cfsqltype: "cf_sql_varchar"};
            } else {
                var catPlaceholders = [];
                for (var i = 1; i <= arrayLen(catList); i++) {
                    catPlaceholders.append(":cat#i#");
                    params["cat#i#"] = {value: catList[i], cfsqltype: "cf_sql_varchar"};
                }
                sql &= " AND p.category IN (" & arrayToList(catPlaceholders) & ")";
            }
        }
        if (arguments.priceMin > 0) {
            sql &= " AND p.base_price_cents >= :priceMin";
            params.priceMin = {value: arguments.priceMin * 100, cfsqltype: "cf_sql_integer"};
        }
        if (arguments.priceMax < 999999) {
            sql &= " AND p.base_price_cents < :priceMax";
            params.priceMax = {value: arguments.priceMax * 100, cfsqltype: "cf_sql_integer"};
        }
        if (len(arguments.q)) {
            sql &= " AND (p.name LIKE :qname OR p.description LIKE :qdesc)";
            params.qname = {value: "%#arguments.q#%", cfsqltype: "cf_sql_varchar"};
            params.qdesc = {value: "%#arguments.q#%", cfsqltype: "cf_sql_varchar"};
        }
        if (len(arguments.size)) {
            sql &= " AND EXISTS (SELECT 1 FROM product_variants pv WHERE pv.product_id = p.product_id AND pv.size = :sz)";
            params.sz = {value: arguments.size, cfsqltype: "cf_sql_varchar"};
        }
        if (len(arguments.colors)) {
            var colorList = listToArray(arguments.colors);
            var colorPlaceholders = [];
            for (var i = 1; i <= arrayLen(colorList); i++) {
                colorPlaceholders.append(":clr#i#");
                params["clr#i#"] = {value: colorList[i], cfsqltype: "cf_sql_varchar"};
            }
            sql &= " AND EXISTS (SELECT 1 FROM product_variants pv WHERE pv.product_id = p.product_id AND pv.color IN (" & arrayToList(colorPlaceholders) & "))";
        }
        if (len(arguments.fit)) {
            var fitList = listToArray(arguments.fit);
            var fitPlaceholders = [];
            for (var i = 1; i <= arrayLen(fitList); i++) {
                fitPlaceholders.append(":fit#i#");
                params["fit#i#"] = {value: fitList[i], cfsqltype: "cf_sql_varchar"};
            }
            sql &= " AND json_extract(p.attributes, '$.fit') IN (" & arrayToList(fitPlaceholders) & ")";
        }

        sql &= " ORDER BY p.created_at DESC";

        var qProducts = queryExecute(sql, params, {datasource: dsn});
        var total = qProducts.recordCount;
        var startRow = ((arguments.page - 1) * arguments.pageSize) + 1;
        var endRow = min(startRow + arguments.pageSize - 1, total);

        var items = [];
        for (var row in qProducts) {
            if (qProducts.currentRow < startRow || qProducts.currentRow > endRow) continue;
            items.append(buildProductSummary(row, dsn));
        }

        var facets = buildFacets(dsn);

        return {
            "items": items,
            "page": arguments.page,
            "pageSize": arguments.pageSize,
            "total": total,
            "facets": facets
        };
    }

    remote struct function getProduct(
        required string productId restargsource="path"
    ) httpmethod="GET" restpath="{productId}" {
        var dsn = "stylemart";

        var qProduct = queryExecute("
            SELECT p.product_id, p.slug, p.name, p.brand, p.category, p.subcategory,
                   p.description, p.care_instructions, p.base_price_cents, p.currency,
                   p.image_url, p.attributes, p.occasion_tags, p.average_rating, p.review_count
            FROM products p WHERE p.product_id = :pid
        ", {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qProduct.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Product not found");
        }

        return buildProductSummary(queryGetRow(qProduct, 1), dsn);
    }

    remote struct function getProductBySlug(
        required string slug restargsource="path"
    ) httpmethod="GET" restpath="by-slug/{slug}" {
        var dsn = "stylemart";

        var qProduct = queryExecute("
            SELECT p.product_id, p.slug, p.name, p.brand, p.category, p.subcategory,
                   p.description, p.care_instructions, p.base_price_cents, p.currency,
                   p.image_url, p.attributes, p.occasion_tags, p.average_rating, p.review_count
            FROM products p WHERE p.slug = :slug
        ", {slug: {value: arguments.slug, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qProduct.recordCount == 0) {
            throw(type="RestError", errorcode="404", message="Product not found");
        }

        return buildProductSummary(queryGetRow(qProduct, 1), dsn);
    }

    remote struct function getReviews(
        required string productId restargsource="path",
        numeric page restargsource="query" default="1",
        numeric pageSize restargsource="query" default="10"
    ) httpmethod="GET" restpath="{productId}/reviews" {
        var dsn = "stylemart";

        var qSummary = queryExecute("
            SELECT COUNT(*) as total_reviews, COALESCE(AVG(rating), 0) as avg_rating
            FROM product_reviews WHERE product_id = :pid
        ", {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var qHist = queryExecute("
            SELECT rating, COUNT(*) as cnt FROM product_reviews WHERE product_id = :pid GROUP BY rating
        ", {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var histogram = {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0};
        for (var h in qHist) histogram[h.rating] = h.cnt;

        var offset = (arguments.page - 1) * arguments.pageSize;
        var qReviews = queryExecute("
            SELECT pr.review_id, pr.user_id, pr.rating, pr.title, pr.body, pr.verified, pr.created_at,
                   u.display_name
            FROM product_reviews pr
            JOIN users u ON u.user_id = pr.user_id
            WHERE pr.product_id = :pid
            ORDER BY pr.created_at DESC LIMIT :lim OFFSET :off
        ", {
            pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"},
            lim: {value: arguments.pageSize, cfsqltype: "cf_sql_integer"},
            off: {value: offset, cfsqltype: "cf_sql_integer"}
        }, {datasource: dsn});

        var items = [];
        for (var r in qReviews) {
            items.append({
                "reviewId": r.review_id, "userId": r.user_id,
                "displayName": r.display_name, "rating": r.rating,
                "title": r.title ?: "", "body": r.body ?: "",
                "createdAt": dateTimeFormat(r.created_at, "yyyy-MM-dd'T'HH:nn:ss'Z'"),
                "verified": r.verified == 1
            });
        }

        return {
            "productId": arguments.productId,
            "summary": {
                "averageRating": precisionEvaluate(qSummary.avg_rating),
                "totalReviews": qSummary.total_reviews,
                "histogram": histogram
            },
            "items": items,
            "page": arguments.page,
            "pageSize": arguments.pageSize,
            "total": qSummary.total_reviews
        };
    }

    remote struct function submitReview(
        required string productId restargsource="path"
    ) httpmethod="POST" restpath="{productId}/reviews" {
        var dsn = "stylemart";
        var shopperId = "";
        try { shopperId = getHttpRequestData().headers["X-Shopper-Id"]; } catch (any e) {}

        cflog(text="submitReview called — productId=#arguments.productId# shopperId=#shopperId#", file="stylemart-reviews");

        if (!len(shopperId)) {
            cflog(text="submitReview REJECTED — no shopperId header", file="stylemart-reviews");
            sendError(401, "Authentication required");
        }

        var body = {};
        try { body = deserializeJSON(toString(getHttpRequestData().content)); }
        catch (any e) { sendError(400, "Invalid request body"); }

        cflog(text="submitReview body — rating=#body.rating ?: 'null'# title=#structKeyExists(body,'title') ? body.title : '(none)'# bodyLen=#structKeyExists(body,'body') ? len(body.body) : 0#", file="stylemart-reviews");

        if (!structKeyExists(body, "rating") || !isNumeric(body.rating) || body.rating < 1 || body.rating > 5)
            sendError(422, "Rating must be between 1 and 5");
        if (!structKeyExists(body, "body") || len(trim(body.body)) < 10)
            sendError(422, "Review must be at least 10 characters");
        if (len(body.body) > 4000)
            sendError(422, "Review must not exceed 4000 characters");
        if (structKeyExists(body, "title") && len(body.title) > 120)
            sendError(422, "Title must not exceed 120 characters");

        var qProd = queryExecute("SELECT product_id FROM products WHERE product_id = :pid",
            {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
        if (qProd.recordCount == 0) sendError(404, "Product not found");

        var qUser = queryExecute("SELECT user_id, display_name FROM users WHERE user_id = :uid",
            {uid: {value: shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
        if (qUser.recordCount == 0) {
            cflog(text="submitReview REJECTED — user not found: #shopperId#", file="stylemart-reviews");
            sendError(401, "User not found");
        }

        var qExisting = queryExecute("SELECT review_id FROM product_reviews WHERE product_id = :pid AND user_id = :uid",
            {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"},
             uid: {value: shopperId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
        if (qExisting.recordCount > 0) {
            cflog(text="submitReview REJECTED — duplicate: user=#shopperId# product=#arguments.productId#", file="stylemart-reviews");
            sendError(409, "You have already reviewed this product");
        }

        var reviewId = "rev_" & lCase(replace(createUUID(), "-", "", "all"));
        var title = structKeyExists(body, "title") ? left(trim(body.title), 120) : "";

        var isVerified = false;
        if (structKeyExists(body, "fromOrder") && body.fromOrder == true) {
            var qOrder = queryExecute("
                SELECT 1 FROM orders o
                JOIN order_items oi ON oi.order_id = o.order_id
                WHERE o.user_id = :uid AND oi.product_id = :pid
                LIMIT 1
            ", {
                uid: {value: shopperId, cfsqltype: "cf_sql_varchar"},
                pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}
            }, {datasource: dsn});
            isVerified = qOrder.recordCount > 0;
        }

        queryExecute("
            INSERT INTO product_reviews (review_id, product_id, user_id, rating, title, body, verified)
            VALUES (:rid, :pid, :uid, :rating, :title, :body, :verified)
        ", {
            rid: {value: reviewId, cfsqltype: "cf_sql_varchar"},
            pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"},
            uid: {value: shopperId, cfsqltype: "cf_sql_varchar"},
            rating: {value: int(body.rating), cfsqltype: "cf_sql_integer"},
            title: {value: title, cfsqltype: "cf_sql_varchar", null: !len(title)},
            body: {value: left(trim(body.body), 4000), cfsqltype: "cf_sql_varchar"},
            verified: {value: isVerified, cfsqltype: "cf_sql_bit"}
        }, {datasource: dsn});

        cflog(text="submitReview SUCCESS — reviewId=#reviewId# user=#shopperId# product=#arguments.productId# rating=#body.rating#", file="stylemart-reviews");

        // Update product aggregate rating
        var qAgg = queryExecute("
            SELECT COUNT(*) as cnt, AVG(rating) as avg_r FROM product_reviews WHERE product_id = :pid
        ", {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
        queryExecute("UPDATE products SET average_rating = :avg, review_count = :cnt WHERE product_id = :pid", {
            avg: {value: qAgg.avg_r, cfsqltype: "cf_sql_decimal"},
            cnt: {value: qAgg.cnt, cfsqltype: "cf_sql_integer"},
            pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}
        }, {datasource: dsn});

        getPageContext().getResponse().setStatus(201);
        return {
            "reviewId": reviewId, "productId": arguments.productId,
            "userId": shopperId, "displayName": qUser.display_name,
            "rating": int(body.rating), "title": title,
            "body": trim(body.body), "verified": isVerified,
            "createdAt": dateTimeFormat(now(), "yyyy-MM-dd'T'HH:nn:ss'Z'")
        };
    }

    remote struct function getRelated(
        required string productId restargsource="path",
        string intent restargsource="query" default="complete-the-look"
    ) httpmethod="GET" restpath="{productId}/related" {
        var dsn = "stylemart";

        var qBase = queryExecute("
            SELECT category FROM products WHERE product_id = :pid
        ", {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qBase.recordCount == 0) {
            return {"items": [], "intent": arguments.intent};
        }

        var qRelated = queryExecute("
            SELECT product_id, slug, name, base_price_cents, currency, image_url, average_rating
            FROM products WHERE category != :cat ORDER BY average_rating DESC LIMIT 3
        ", {cat: {value: qBase.category, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var items = [];
        for (var r in qRelated) {
            items.append({
                "productId": r.product_id, "slug": r.slug, "name": r.name,
                "price": r.base_price_cents / 100, "currency": r.currency,
                "imageUrl": r.image_url, "averageRating": r.average_rating ?: 0
            });
        }

        return {"items": items, "intent": arguments.intent};
    }

    remote struct function compare(
        required struct body
    ) httpmethod="POST" restpath="compare" {
        var dsn = "stylemart";
        var productIds = body.productIds ?: [];
        var dimensions = body.dimensions ?: ["price", "fabric", "care", "sizes", "colors", "fit"];

        var products = [];
        var rows = [];

        for (var pid in productIds) {
            var qP = queryExecute("
                SELECT product_id, name, image_url, base_price_cents, attributes, care_instructions
                FROM products WHERE product_id = :pid
            ", {pid: {value: pid, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

            if (qP.recordCount > 0) {
                var p = queryGetRow(qP, 1);
                var attrs = isJSON(p.attributes) ? deserializeJSON(p.attributes) : {};

                products.append({"productId": p.product_id, "name": p.name, "imageUrl": p.image_url});

                var qVars = queryExecute("
                    SELECT size, color FROM product_variants WHERE product_id = :pid
                ", {pid: {value: pid, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
                var sizes = [];
                var colors = [];
                for (var v in qVars) {
                    if (!sizes.find(v.size)) sizes.append(v.size);
                    if (!colors.find(v.color)) colors.append(v.color);
                }

                for (var dim in dimensions) {
                    var existing = rows.filter(function(r) { return r.key == dim; });
                    var rowEntry = existing.len() ? existing[1] : {"key": dim, "values": {}};
                    switch (dim) {
                        case "price": rowEntry.values[pid] = "$#numberFormat(p.base_price_cents / 100, '0.00')#"; break;
                        case "fabric": rowEntry.values[pid] = attrs.fabric ?: "—"; break;
                        case "care": rowEntry.values[pid] = p.care_instructions ?: (attrs.care ?: "—"); break;
                        case "sizes": rowEntry.values[pid] = sizes.toList(", "); break;
                        case "colors": rowEntry.values[pid] = colors.toList(", "); break;
                        case "fit": rowEntry.values[pid] = attrs.fit ?: "—"; break;
                        default: rowEntry.values[pid] = attrs[dim] ?: "—";
                    }
                    if (!existing.len()) rows.append(rowEntry);
                }
            }
        }

        return {"dimensions": dimensions, "rows": rows, "products": products};
    }

    // --- Private helpers ---

    private struct function buildProductSummary(required struct row, required string dsn) {
        var qVariants = queryExecute("
            SELECT pv.variant_id, pv.size, pv.color, pv.sku,
                   COALESCE(i.quantity, 0) as stock_qty
            FROM product_variants pv
            LEFT JOIN inventory i ON i.variant_id = pv.variant_id
            WHERE pv.product_id = :pid
        ", {pid: {value: row.product_id, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var qImages = queryExecute("
            SELECT image_id, url, alt_text, position, color_ref
            FROM product_images WHERE product_id = :pid ORDER BY position
        ", {pid: {value: row.product_id, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        var attrs = isJSON(row.attributes) ? deserializeJSON(row.attributes) : {};
        var occasionTags = isJSON(row.occasion_tags) ? deserializeJSON(row.occasion_tags) : [];

        var variantArr = [];
        var availSizes = [];
        var colorSet = [];
        for (var v in qVariants) {
            variantArr.append({
                "variantId": v.variant_id, "sku": v.sku, "size": v.size, "color": v.color,
                "inStock": v.stock_qty > 0, "stockQty": v.stock_qty, "priceCents": row.base_price_cents
            });
            if (!availSizes.find(v.size)) availSizes.append(v.size);
            if (!colorSet.find(v.color)) colorSet.append(v.color);
        }

        var imageArr = [];
        for (var img in qImages) {
            imageArr.append({
                "imageId": img.image_id, "url": img.url, "altText": img.alt_text ?: "",
                "position": img.position, "colorRef": img.color_ref ?: ""
            });
        }

        // Sibling products in the same (category, subcategory) family. Each
        // product is single-color per the §12 invariant; the PDP color-picker
        // cross-navigates to the sibling whose color matches the user's pick.
        // Color is read from product_variants (single distinct value per product).
        var qSiblings = queryExecute("
            SELECT p.product_id, p.slug, p.image_url,
                   (SELECT pv2.color FROM product_variants pv2
                      WHERE pv2.product_id = p.product_id LIMIT 1) AS color
            FROM products p
            WHERE p.category = :cat
              AND COALESCE(p.subcategory, '') = COALESCE(:sub, '')
              AND p.product_id != :pid
            ORDER BY p.name
        ", {
            cat: {value: row.category, cfsqltype: "cf_sql_varchar"},
            sub: {value: row.subcategory ?: "", cfsqltype: "cf_sql_varchar"},
            pid: {value: row.product_id, cfsqltype: "cf_sql_varchar"}
        }, {datasource: dsn});

        var siblings = [];
        for (var s in qSiblings) {
            siblings.append({
                "productId": s.product_id,
                "slug": s.slug,
                "color": s.color ?: "",
                "imageUrl": s.image_url
            });
        }

        return {
            "productId": row.product_id, "slug": row.slug, "name": row.name,
            "brand": row.brand, "category": row.category, "subcategory": row.subcategory ?: "",
            "price": row.base_price_cents / 100, "basePrice": row.base_price_cents / 100,
            "appliedPromotionIds": [], "currency": row.currency, "imageUrl": row.image_url,
            "colors": colorSet, "availableSizes": availSizes,
            "attributes": attrs, "occasionTags": occasionTags,
            "averageRating": row.average_rating ?: 0, "reviewCount": row.review_count,
            "description": row.description ?: "", "careInstructions": row.care_instructions ?: "",
            "images": imageArr, "variants": variantArr,
            "siblings": siblings
        };
    }

    private struct function buildFacets(required string dsn) {
        // Category facet
        var qCats = queryExecute("
            SELECT category, COUNT(*) as cnt FROM products GROUP BY category ORDER BY category
        ", {}, {datasource: dsn});

        var facetCategory = [];
        for (var fc in qCats) {
            facetCategory.append({
                "value": fc.category,
                "label": uCase(left(fc.category, 1)) & replace(mid(fc.category, 2, len(fc.category)), "-", " ", "all"),
                "count": fc.cnt
            });
        }

        // Color facet
        var qColors = queryExecute("
            SELECT pv.color, COUNT(DISTINCT pv.product_id) as cnt
            FROM product_variants pv GROUP BY pv.color ORDER BY pv.color
        ", {}, {datasource: dsn});

        var colorConfig = new ColorConfig();
        var facetColor = [];
        for (var fc in qColors) {
            facetColor.append({
                "value": fc.color,
                "swatch": colorConfig.getSwatch(fc.color),
                "count": fc.cnt
            });
        }

        // Size facet (grouped)
        var qSizes = queryExecute("
            SELECT pv.size, COUNT(DISTINCT pv.product_id) as cnt
            FROM product_variants pv GROUP BY pv.size ORDER BY pv.size
        ", {}, {datasource: dsn});

        var APPAREL = ["XS", "S", "M", "L", "XL", "XXL"];
        var WAIST = ["28", "30", "32", "34", "36", "38"];
        var SHOE = ["7", "8", "9", "10", "11", "12"];
        var apparelSizes = [];
        var waistSizes = [];
        var shoeSizes = [];
        var otherSizes = [];
        for (var fs in qSizes) {
            var entry = {"value": fs.size, "count": fs.cnt};
            if (arrayFind(APPAREL, fs.size)) apparelSizes.append(entry);
            else if (arrayFind(WAIST, fs.size)) waistSizes.append(entry);
            else if (arrayFind(SHOE, fs.size)) shoeSizes.append(entry);
            else otherSizes.append(entry);
        }
        var sizeGroups = [];
        if (apparelSizes.len()) sizeGroups.append({"label": "Apparel", "sizes": apparelSizes});
        if (waistSizes.len()) sizeGroups.append({"label": "Waist", "sizes": waistSizes});
        if (shoeSizes.len()) sizeGroups.append({"label": "Shoe US", "sizes": shoeSizes});
        if (otherSizes.len()) sizeGroups.append({"label": "One-size", "sizes": otherSizes});

        // Price buckets
        var qPrices = queryExecute("
            SELECT
                SUM(CASE WHEN base_price_cents < 10000 THEN 1 ELSE 0 END) as b1,
                SUM(CASE WHEN base_price_cents >= 10000 AND base_price_cents < 20000 THEN 1 ELSE 0 END) as b2,
                SUM(CASE WHEN base_price_cents >= 20000 AND base_price_cents < 50000 THEN 1 ELSE 0 END) as b3,
                SUM(CASE WHEN base_price_cents >= 50000 THEN 1 ELSE 0 END) as b4
            FROM products
        ", {}, {datasource: dsn});
        var priceBuckets = [
            {"min": 0, "max": 100, "count": qPrices.b1},
            {"min": 100, "max": 200, "count": qPrices.b2},
            {"min": 200, "max": 500, "count": qPrices.b3}
        ];

        // Fit facet
        var qFits = queryExecute("
            SELECT json_extract(attributes, '$.fit') as fit_val, COUNT(*) as cnt
            FROM products
            WHERE json_extract(attributes, '$.fit') IS NOT NULL
            GROUP BY fit_val ORDER BY fit_val
        ", {}, {datasource: dsn});

        var facetFit = [];
        for (var ff in qFits) {
            if (len(ff.fit_val) && ff.fit_val != "null") {
                facetFit.append({
                    "value": ff.fit_val,
                    "label": uCase(left(ff.fit_val, 1)) & mid(ff.fit_val, 2, len(ff.fit_val)),
                    "count": ff.cnt
                });
            }
        }

        return {
            "category": facetCategory,
            "color": facetColor,
            "size": sizeGroups,
            "priceBuckets": priceBuckets,
            "fit": facetFit
        };
    }

    private void function sendError(required numeric status, required string message) {
        var resp = getPageContext().getResponse();
        resp.setStatus(javaCast("int", arguments.status));
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(serializeJSON({"error": true, "status": arguments.status, "message": arguments.message}));
        resp.getWriter().flush();
        abort;
    }
}
