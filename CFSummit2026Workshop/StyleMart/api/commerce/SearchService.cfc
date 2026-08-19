component rest="true" restpath="/search" produces="application/json" {

    remote struct function search(
        string q restargsource="query" default="",
        numeric page restargsource="query" default="1",
        numeric pageSize restargsource="query" default="24"
    ) httpmethod="GET" {
        var dsn = "stylemart";
        if (arguments.page < 1) arguments.page = 1;
        if (arguments.pageSize < 1 || arguments.pageSize > 100) arguments.pageSize = 24;

        if (!len(arguments.q)) {
            return {"items": [], "page": 1, "pageSize": arguments.pageSize, "total": 0, "query": ""};
        }

        var words = listToArray(trim(arguments.q), " ");
        var sql = "SELECT p.product_id, p.slug, p.name, p.brand, p.category, p.subcategory,
                   p.description, p.base_price_cents, p.currency, p.image_url,
                   p.attributes, p.occasion_tags, p.average_rating, p.review_count,
                   p.care_instructions
            FROM products p WHERE 1=1";
        var params = {};

        for (var i = 1; i <= arrayLen(words); i++) {
            sql &= " AND (p.name LIKE :w#i# OR p.description LIKE :w#i# OR p.category LIKE :w#i#)";
            params["w#i#"] = {value: "%#words[i]#%", cfsqltype: "cf_sql_varchar"};
        }

        sql &= " ORDER BY p.average_rating DESC";

        var qSearch = queryExecute(sql, params, {datasource: dsn});

        var total = qSearch.recordCount;
        var startRow = ((arguments.page - 1) * arguments.pageSize) + 1;
        var endRow = min(startRow + arguments.pageSize - 1, total);

        var items = [];
        for (var row in qSearch) {
            if (qSearch.currentRow < startRow || qSearch.currentRow > endRow) continue;

            var attrs = isJSON(row.attributes) ? deserializeJSON(row.attributes) : {};
            var occasionTags = isJSON(row.occasion_tags) ? deserializeJSON(row.occasion_tags) : [];

            var qColors = queryExecute("
                SELECT DISTINCT color FROM product_variants WHERE product_id = :pid
            ", {pid: {value: row.product_id, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
            var colorArr = [];
            for (var c in qColors) colorArr.append(c.color);

            items.append({
                "productId": row.product_id, "slug": row.slug, "name": row.name,
                "brand": row.brand, "category": row.category,
                "price": row.base_price_cents / 100, "currency": row.currency,
                "imageUrl": row.image_url, "colors": colorArr,
                "attributes": attrs, "occasionTags": occasionTags,
                "averageRating": row.average_rating ?: 0,
                "reviewCount": row.review_count, "description": row.description ?: ""
            });
        }

        return {"items": items, "page": arguments.page, "pageSize": arguments.pageSize, "total": total, "query": arguments.q};
    }
}
