component rest="true" restpath="/categories" produces="application/json" {

    remote any function listCategories(
        string slug restargsource="query" default=""
    ) httpmethod="GET" {
        var dsn = "stylemart";

        if (len(arguments.slug)) {
            var qCat = queryExecute("
                SELECT slug, display_name, description, hero_image, parent_slug, sort_order
                FROM categories WHERE slug = :slug
            ", {slug: {value: arguments.slug, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

            if (qCat.recordCount == 0) {
                throw(type="RestError", errorcode="404", message="Category not found");
            }

            var qCount = queryExecute("
                SELECT COUNT(*) as cnt FROM products WHERE category = :slug
            ", {slug: {value: arguments.slug, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

            var qFeatured = queryExecute("
                SELECT product_id, slug, name, base_price_cents, currency, image_url, average_rating, review_count
                FROM products WHERE category = :slug ORDER BY average_rating DESC LIMIT 4
            ", {slug: {value: arguments.slug, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

            var featured = [];
            for (var f in qFeatured) {
                featured.append({
                    "productId": f.product_id, "slug": f.slug, "name": f.name,
                    "price": f.base_price_cents / 100, "currency": f.currency,
                    "imageUrl": f.image_url, "averageRating": f.average_rating ?: 0,
                    "reviewCount": f.review_count ?: 0
                });
            }

            return {
                "slug": qCat.slug,
                "name": qCat.display_name,
                "description": qCat.description ?: "Browse our #qCat.display_name# collection",
                "heroImageUrl": qCat.hero_image ?: "",
                "productCount": qCount.cnt,
                "featured": featured
            };
        }

        var qCats = queryExecute("
            SELECT slug, display_name, description, hero_image, parent_slug, sort_order
            FROM categories ORDER BY sort_order, display_name
        ", {}, {datasource: dsn});

        var result = [];
        for (var c in qCats) {
            result.append({
                "slug": c.slug, "name": c.display_name,
                "description": c.description ?: "",
                "heroImageUrl": c.hero_image ?: "",
                "parentSlug": c.parent_slug ?: javacast("null", "")
            });
        }
        return result;
    }
}
