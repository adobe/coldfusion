component {

    variables.ragDataDir = getDirectoryFromPath(getCurrentTemplatePath()) & "../../data/rag/";

    public struct function exportAll() {
        return {
            catalog: exportCatalog(),
            reviews: exportReviews(),
            orders: exportOrders()
        };
    }

    public struct function exportCatalog() {
        var outputDir = variables.ragDataDir & "catalog/";
        if (!directoryExists(outputDir)) directoryCreate(outputDir);

        var products = queryExecute(
            "SELECT p.product_id, p.name, p.brand, p.category, p.subcategory,
                    p.description, p.care_instructions, p.base_price_cents,
                    p.average_rating, p.review_count
             FROM products p ORDER BY p.product_id",
            {}, {datasource: "stylemart"}
        );

        var exported = 0;
        var failed = 0;
        for (var row in products) {
            try {
                var variants = queryExecute(
                    "SELECT size, color, sku FROM product_variants
                     WHERE product_id = :pid ORDER BY size, color",
                    {pid: {value: row.product_id, cfsqltype: "cf_sql_varchar"}},
                    {datasource: "stylemart"}
                );

                var content = buildProductContent(row, variants);
                var fileName = reReplace(lCase(row.name), "[^a-z0-9]+", "-", "all") & ".pdf";
                generatePdf(content, row.name, outputDir & fileName);
                exported++;
            } catch (any e) {
                failed++;
                writeLog(text="[S5-RAG] exportCatalog failed for '#row.name#': #e.message#", file="rag");
            }
        }

        if (failed > 0) writeLog(text="[S5-RAG] exportCatalog: #exported# succeeded, #failed# failed", file="rag");
        return {directory: outputDir, fileCount: exported, failedCount: failed, docType: "catalog"};
    }

    public struct function exportReviews() {
        var outputDir = variables.ragDataDir & "reviews/";
        if (!directoryExists(outputDir)) directoryCreate(outputDir);

        var reviews = queryExecute(
            "SELECT r.review_id, r.product_id, r.rating, r.title, r.body,
                    r.verified, r.created_at, p.name AS product_name, p.category
             FROM product_reviews r
             JOIN products p ON p.product_id = r.product_id
             ORDER BY p.category, p.product_id, r.created_at DESC",
            {}, {datasource: "stylemart"}
        );

        var LF = chr(10);
        var csvContent = "review_id,product_id,product_name,category,rating,title,body,verified,created_at" & LF;
        for (var row in reviews) {
            csvContent &= '"#row.review_id#","#row.product_id#","#csvEscape(row.product_name)#","#row.category#",#row.rating#,"#csvEscape(row.title)#","#csvEscape(row.body)#",#row.verified#,"#dateTimeFormat(row.created_at, "yyyy-MM-dd")#"' & LF;
        }

        fileWrite(outputDir & "product-reviews.csv", csvContent, "utf-8");
        return {directory: outputDir, fileCount: 1, rowCount: reviews.recordCount, docType: "reviews"};
    }

    public struct function exportOrders() {
        var outputDir = variables.ragDataDir & "orders/";
        if (!directoryExists(outputDir)) directoryCreate(outputDir);

        var orders = queryExecute(
            "SELECT o.order_id, o.user_id, o.status, o.total_cents,
                    o.created_at, oi.product_id, oi.snapshot_name AS product_name,
                    oi.snapshot_size AS size, oi.snapshot_color AS color, oi.quantity, oi.unit_price_cents
             FROM orders o
             JOIN order_items oi ON oi.order_id = o.order_id
             ORDER BY o.created_at DESC",
            {}, {datasource: "stylemart"}
        );

        var LF = chr(10);
        var csvContent = "order_id,user_id,status,total_cents,order_date,product_id,product_name,size,color,quantity,unit_price_cents" & LF;
        for (var row in orders) {
            csvContent &= '"#row.order_id#","#row.user_id#","#row.status#",#row.total_cents#,"#dateTimeFormat(row.created_at, "yyyy-MM-dd")#","#row.product_id#","#csvEscape(row.product_name)#","#row.size#","#row.color#",#row.quantity#,#row.unit_price_cents#' & LF;
        }

        fileWrite(outputDir & "orders.csv", csvContent, "utf-8");
        return {directory: outputDir, fileCount: 1, rowCount: orders.recordCount, docType: "orders"};
    }

    private string function buildProductContent(required struct row, required query variants) {
        var LF = chr(10);
        var content = "PRODUCT: #arguments.row.name#" & LF;
        content &= "Brand: #arguments.row.brand#" & LF;
        content &= "Category: #arguments.row.category#";
        if (len(arguments.row.subcategory)) content &= " > #arguments.row.subcategory#";
        content &= LF;
        content &= "Price: $#numberFormat(arguments.row.base_price_cents / 100, '0.00')#" & LF;
        content &= "Rating: #arguments.row.average_rating#/5 (#arguments.row.review_count# reviews)" & LF & LF;

        if (len(arguments.row.description)) {
            content &= "DESCRIPTION" & LF;
            content &= arguments.row.description & LF & LF;
        }
        if (len(arguments.row.care_instructions)) {
            content &= "CARE INSTRUCTIONS" & LF;
            content &= arguments.row.care_instructions & LF & LF;
        }

        var sizes = [];
        var colors = [];
        for (var v in arguments.variants) {
            if (!arrayFind(sizes, v.size)) arrayAppend(sizes, v.size);
            if (!arrayFind(colors, v.color)) arrayAppend(colors, v.color);
        }
        content &= "AVAILABLE SIZES: #arrayToList(sizes, ', ')#" & LF;
        content &= "AVAILABLE COLORS: #arrayToList(colors, ', ')#" & LF;
        return content;
    }

    private void function generatePdf(required string content, required string title, required string filePath) {
        var htmlContent = "<html><body>";
        htmlContent &= "<h1>#encodeForHTML(arguments.title)#</h1>";
        htmlContent &= "<pre style='font-family: Arial, sans-serif; font-size: 11pt; white-space: pre-wrap;'>#encodeForHTML(arguments.content)#</pre>";
        htmlContent &= "</body></html>";

        cfDocument(format="pdf", filename="#arguments.filePath#", overwrite="true") {
            writeOutput(htmlContent);
        }
    }

    private string function csvEscape(required string val) {
        var LF = chr(10);
        return replace(replace(arguments.val, '"', '""', 'all'), LF, ' ', 'all');
    }
}
