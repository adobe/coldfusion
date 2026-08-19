component extends="BaseTool"
          hint="Submit product review tool CFC" {

    remote struct function submitReview(
        required string productId hint="Product ID to review (e.g. 'prd_01HZX01T001')",
        required numeric rating hint="Star rating from 1 to 5",
        required string reviewBody hint="Review text, minimum 10 characters",
        string title hint="Optional short title for the review" default=""
    ) hint="Submit a product review on behalf of the user. Use when the user wants to leave a review, rate a product, or share feedback about something they bought. Ask the user for their rating (1-5) and review text before calling." {
        var ctx = startToolCall("submitReview", {
            "productId": arguments.productId,
            "rating": arguments.rating,
            "title": arguments.title
        });
        var status = "ok";

        try {
            if (arguments.rating < 1 || arguments.rating > 5) {
                status = "validation_error";
                endToolCall(ctx, status, "Rating must be between 1 and 5");
                return {"error": true, "message": "Rating must be between 1 and 5"};
            }
            if (len(trim(arguments.reviewBody)) < 10) {
                status = "validation_error";
                endToolCall(ctx, status, "Review must be at least 10 characters");
                return {"error": true, "message": "Review must be at least 10 characters"};
            }

            var userId = "demo-shopper-001";
            try { userId = request.userId; } catch (any e) {}

            var qProd = queryExecute(
                "SELECT product_id, name FROM products WHERE product_id = :pid",
                {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}},
                {datasource: "stylemart"}
            );
            if (qProd.recordCount == 0) {
                status = "not_found";
                endToolCall(ctx, status, "Product not found");
                return {"error": true, "message": "Product not found"};
            }

            var qExisting = queryExecute(
                "SELECT review_id FROM product_reviews WHERE product_id = :pid AND user_id = :uid",
                {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"},
                 uid: {value: userId, cfsqltype: "cf_sql_varchar"}},
                {datasource: "stylemart"}
            );
            if (qExisting.recordCount > 0) {
                status = "duplicate";
                endToolCall(ctx, status, "Already reviewed");
                return {"error": true, "message": "You have already reviewed this product"};
            }

            var isVerified = false;
            var qOrder = queryExecute("
                SELECT 1 FROM orders o
                JOIN order_items oi ON oi.order_id = o.order_id
                WHERE o.user_id = :uid AND oi.product_id = :pid
                LIMIT 1
            ", {
                uid: {value: userId, cfsqltype: "cf_sql_varchar"},
                pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}
            }, {datasource: "stylemart"});
            isVerified = qOrder.recordCount > 0;

            var reviewId = "rev_" & lCase(replace(createUUID(), "-", "", "all"));
            var cleanTitle = len(trim(arguments.title)) ? left(trim(arguments.title), 120) : "";

            queryExecute("
                INSERT INTO product_reviews (review_id, product_id, user_id, rating, title, body, verified)
                VALUES (:rid, :pid, :uid, :rating, :title, :body, :verified)
            ", {
                rid: {value: reviewId, cfsqltype: "cf_sql_varchar"},
                pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"},
                uid: {value: userId, cfsqltype: "cf_sql_varchar"},
                rating: {value: int(arguments.rating), cfsqltype: "cf_sql_integer"},
                title: {value: cleanTitle, cfsqltype: "cf_sql_varchar", null: !len(cleanTitle)},
                body: {value: left(trim(arguments.reviewBody), 4000), cfsqltype: "cf_sql_varchar"},
                verified: {value: isVerified, cfsqltype: "cf_sql_bit"}
            }, {datasource: "stylemart"});

            var qAgg = queryExecute(
                "SELECT COUNT(*) as cnt, AVG(rating) as avg_r FROM product_reviews WHERE product_id = :pid",
                {pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}},
                {datasource: "stylemart"}
            );
            queryExecute("UPDATE products SET average_rating = :avg, review_count = :cnt WHERE product_id = :pid", {
                avg: {value: qAgg.avg_r, cfsqltype: "cf_sql_decimal"},
                cnt: {value: qAgg.cnt, cfsqltype: "cf_sql_integer"},
                pid: {value: arguments.productId, cfsqltype: "cf_sql_varchar"}
            }, {datasource: "stylemart"});

            endToolCall(ctx, status, "Review submitted for #qProd.name#");
            return {
                "success": true,
                "reviewId": reviewId,
                "productId": arguments.productId,
                "productName": qProd.name,
                "rating": int(arguments.rating),
                "verified": isVerified,
                "message": "Review submitted successfully" & (isVerified ? " (verified purchase)" : "")
            };

        } catch (any e) {
            status = "error";
            endToolCall(ctx, status, e.message);
            return {"error": true, "message": "Failed to submit review: " & e.message};
        }
    }
}
