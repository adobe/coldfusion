component extends="BaseTool"
          hint="Product reviews tool CFC" {

    remote struct function getProductReviews(
        required string productId hint="Product ID to get reviews for"
    ) hint="Get customer reviews for a specific product. Returns ratings, review text, and verified purchase status." {
        var ctx = startToolCall("getProductReviews", {"productId": arguments.productId});
        var status = "ok";

        try {
            var reviews = queryExecute(
                "SELECT r.review_id, r.rating, r.title, r.body, r.verified, r.created_at,
                        p.name AS product_name
                 FROM product_reviews r
                 JOIN products p ON p.product_id = r.product_id
                 WHERE r.product_id = :pid
                 ORDER BY r.created_at DESC
                 LIMIT 10",
                {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}},
                {datasource: "stylemart"}
            );

            var result = {
                "productId": arguments.productId,
                "productName": reviews.recordCount ? reviews.product_name[1] : "",
                "reviewCount": reviews.recordCount,
                "reviews": []
            };

            for (var row in reviews) {
                arrayAppend(result.reviews, {
                    "reviewId": row.review_id,
                    "rating": row.rating,
                    "title": row.title ?: "",
                    "body": row.body ?: "",
                    "verified": row.verified ? true : false,
                    "date": dateTimeFormat(row.created_at, "yyyy-MM-dd")
                });
            }

            if (reviews.recordCount) {
                var avgRating = queryExecute(
                    "SELECT AVG(rating) AS avg_rating FROM product_reviews WHERE product_id = :pid",
                    {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}},
                    {datasource: "stylemart"}
                );
                result.averageRating = numberFormat(avgRating.avg_rating, "0.0");
            }

            endToolCall(ctx, status, "Found #reviews.recordCount# reviews");
            return result;
        } catch (any e) {
            status = "error";
            endToolCall(ctx, status, e.message);
            return {"error": true, "message": e.message};
        }
    }
}
