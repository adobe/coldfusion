component extends="BaseTool"
          hint="Catalog search tool CFC" {

    remote array function searchCatalog(
        string query hint="Free-text search (e.g. 'navy blazer for a wedding', 'casual sneakers')" default="",
        string category hint="Product category filter. Valid values: accessories, backpacks, dresses, formal-shoes, jackets, jeans, pants, raincoats, shirts, sneakers, sunglasses, sweaters, tshirts" default="",
        string colors hint="Comma-separated color filter (e.g. 'navy,charcoal')" default="",
        string size hint="Size filter (e.g. 'M', 'L', '32')" default="",
        numeric priceMin hint="Minimum price in USD" default="0",
        numeric priceMax hint="Maximum price in USD" default="999999"
    ) hint="Search the StyleMart catalog by free-text query and/or structured filters. Use for any product discovery — vague queries ('navy blazer for a wedding') AND specific criteria (category, color, size, price range). Always provide query for best results; filters narrow further." {
        var ctx = startToolCall("searchCatalog", {
            "query": arguments.query,
            "category": arguments.category,
            "colors": arguments.colors,
            "size": arguments.size,
            "priceMin": arguments.priceMin,
            "priceMax": arguments.priceMax
        });
        var status = "ok";
        var items = [];

        try {
            var svc = structKeyExists(application, "services") ? application.services : server.stylemart.services;
            var searchText = arguments.query;

            if (!len(trim(searchText))) {
                var parts = [];
                if (len(arguments.category)) arrayAppend(parts, singularize(arguments.category));
                if (len(arguments.colors)) arrayAppend(parts, arguments.colors);
                if (len(arguments.size)) arrayAppend(parts, arguments.size);
                searchText = arrayToList(parts, " ");
            }

            if (len(trim(searchText))) {
                var searchResult = svc.search.search(
                    q = searchText,
                    pageSize = 20
                );
                items = searchResult.items ?: [];

                if (!arrayLen(items)) {
                    var stopWords = "a,an,the,in,on,for,of,my,me,and,or,to,with,size,color,colour,please,find,show,get,search";
                    var words = listToArray(searchText, " ");
                    var cleanWords = [];
                    for (var w in words) {
                        if (!listFindNoCase(stopWords, w)) arrayAppend(cleanWords, singularize(w));
                    }
                    var cleanText = arrayToList(cleanWords, " ");
                    if (len(trim(cleanText)) && cleanText != searchText) {
                        searchResult = svc.search.search(q = cleanText, pageSize = 20);
                        items = searchResult.items ?: [];
                    }
                }

                if (arrayLen(items) && (len(arguments.colors) || arguments.priceMin > 0 || arguments.priceMax < 999999)) {
                    items = applyFilters(items, "", arguments.colors, arguments.priceMin, arguments.priceMax);
                }
            }

            if (!arrayLen(items) && (len(arguments.category) || len(arguments.colors) || len(arguments.size))) {
                var searchResult = svc.product.listProducts(
                    category = arguments.category,
                    colors = arguments.colors,
                    size = arguments.size,
                    priceMin = arguments.priceMin,
                    priceMax = arguments.priceMax,
                    pageSize = 8
                );
                items = searchResult.items ?: [];
            }
        } catch (any e) {
            status = "error";
        }

        endToolCall(ctx, status, "#arrayLen(items)# products found");

        var results = [];
        for (var item in items) {
            var sizes = [];
            try {
                var qSizes = queryExecute("
                    SELECT DISTINCT pv.size FROM product_variants pv
                    JOIN inventory i ON pv.variant_id = i.variant_id
                    WHERE pv.product_id = :pid AND i.quantity > 0
                    ORDER BY FIELD(pv.size,'XS','S','M','L','XL','XXL','2XL','3XL')
                ", {pid: {value: item.productId, cfsqltype: "cf_sql_varchar"}}, {datasource: "stylemart"});
                for (var row in qSizes) {
                    arrayAppend(sizes, row.size);
                }
            } catch (any e) {}

            arrayAppend(results, {
                "productId": item.productId,
                "name": item.name,
                "brand": item.brand ?: "",
                "price": item.price,
                "currency": item.currency ?: "USD",
                "colors": item.colors ?: [],
                "category": item.category ?: "",
                "description": left(item.description ?: "", 120),
                "imageUrl": item.imageUrl ?: "",
                "slug": item.slug ?: item.productId,
                "averageRating": item.averageRating ?: 0,
                "reviewCount": item.reviewCount ?: 0,
                "availableSizes": sizes
            });
        }

        if (arrayLen(results) && len(ctx.qid) && structKeyExists(server.stylemart, "streams") && structKeyExists(server.stylemart.streams, ctx.qid)) {
            var totalCount = 0;
            try { totalCount = searchResult.total ?: arrayLen(results); } catch (any e) { totalCount = arrayLen(results); }

            var matchedCategories = [];
            try {
                var qCats = queryExecute("
                    SELECT DISTINCT category FROM products
                    WHERE category LIKE :q
                    ORDER BY category
                    LIMIT 5
                ", {q: {value: "%" & lCase(trim(arguments.query)) & "%", cfsqltype: "cf_sql_varchar"}}, {datasource: "stylemart"});
                for (var row in qCats) {
                    arrayAppend(matchedCategories, {"slug": row.category, "name": replace(row.category, "-", " ", "all")});
                }
            } catch (any e) {}

            arrayAppend(server.stylemart.streams[ctx.qid], {
                "type": "tool.products",
                "payload": {
                    "callId": ctx.callId,
                    "products": results,
                    "totalCount": totalCount,
                    "query": trim(arguments.query),
                    "matchedCategories": matchedCategories
                }
            });
        }

        return results;
    }

    private string function singularize(required string word) {
        var w = trim(arguments.word);
        if (right(w, 3) == "ies") return left(w, len(w) - 3) & "y";
        if (right(w, 2) == "es" && !right(w, 3) == "ses") return left(w, len(w) - 2);
        if (right(w, 1) == "s" && right(w, 2) != "ss") return left(w, len(w) - 1);
        return w;
    }

    private array function applyFilters(
        required array items,
        string category,
        string colors,
        numeric priceMin,
        numeric priceMax
    ) {
        var filtered = [];
        for (var item in arguments.items) {
            if (len(arguments.category) && (item.category ?: "") != arguments.category) continue;
            if (len(arguments.colors)) {
                var wantColors = listToArray(lCase(arguments.colors));
                var hasMatch = false;
                for (var c in (item.colors ?: [])) {
                    for (var wc in wantColors) {
                        if (findNoCase(wc, c) > 0 || findNoCase(c, wc) > 0) {
                            hasMatch = true;
                            break;
                        }
                    }
                    if (hasMatch) break;
                }
                if (!hasMatch) continue;
            }
            if ((item.price ?: 0) < arguments.priceMin || (item.price ?: 0) > arguments.priceMax) continue;
            arrayAppend(filtered, item);
        }
        return filtered;
    }
}
