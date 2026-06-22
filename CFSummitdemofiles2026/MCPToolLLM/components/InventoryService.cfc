component output="false" {
    property name="datasource";

    public any function init(string datasource = "") {
        variables.datasource = len(arguments.datasource) ? arguments.datasource : "cfsummit26_inventory";
        variables.lastSqlDebug = {
            datasource: variables.datasource,
            sql: "",
            params: {},
            postFilters: {}
        };
        return this;
    }

    public struct function bootstrap(boolean force = false) {
        return getStats();
    }

    public array function listItems(struct filters = {}) {
        var queryFilters = duplicate(arguments.filters);
        if (structKeyExists(queryFilters, "query")) {
            structDelete(queryFilters, "query");
        }
        if (structKeyExists(queryFilters, "stockStatus")) {
            queryFilters.stockStatus = normalizeStockStatusFilter(queryFilters.stockStatus);
        }

        var items = queryItems(queryFilters);
        var filtered = [];

        for (var item in items) {
            if (matchesFilters(item, arguments.filters)) {
                arrayAppend(filtered, normalizeItem(item));
            }
        }

        arraySort(filtered, function(a, b) {
            return compareNoCase(a.sku, b.sku);
        });

        return filtered;
    }

    public struct function getItemBySku(required string sku) {
        var sql = inventorySelectSql() & " WHERE sku = :sku";
        var params = { sku: { value: arguments.sku, cfsqltype: "cf_sql_varchar" } };
        setSqlDebug(sql, params);
        var rows = queryExecute(sql, params, { datasource: variables.datasource });
        var items = queryToItemArray(rows);

        for (var item in items) {
            if (compareNoCase(item.sku, arguments.sku) == 0) {
                return normalizeItem(item);
            }
        }

        return {};
    }

    public struct function findItems(string query = "", string warehouse = "", string category = "", string stockStatus = "") {
        var filters = {
            warehouse: arguments.warehouse,
            category: arguments.category,
            stockStatus: normalizeStockStatusFilter(arguments.stockStatus)
        };
        var candidates = queryItems(filters);
        var normalizedQuery = normalizeSearchText(arguments.query);
        var meaningfulTokens = meaningfulSearchTokens(normalizedQuery);
        var rankedItems = [];
        var topItems = [];
        var matchStrategy = "none";

        if (!len(normalizedQuery) && !arrayLen(meaningfulTokens)) {
            topItems = [];
            for (var item in candidates) {
                arrayAppend(topItems, formatSearchItem(item, {
                    score: 50,
                    type: "filtered_inventory",
                    terms: [],
                    explanation: "Returned by the supplied inventory filters."
                }));
            }

            return {
                count: arrayLen(topItems),
                query: arguments.query,
                normalizedQuery: normalizedQuery,
                meaningfulTokens: meaningfulTokens,
                matchStrategy: arrayLen(topItems) ? "filtered_inventory" : "none",
                items: topItems,
                message: arrayLen(topItems) ? "" : "No matching inventory items found."
            };
        }

        for (var item in candidates) {
            var match = scoreSearchItem(item, arguments.query, normalizedQuery, meaningfulTokens);
            if (match.score >= 50) {
                var rankedItem = formatSearchItem(item, match);
                arrayAppend(rankedItems, rankedItem);
            }
        }

        var nonFuzzyItems = [];
        for (var rankedItem in rankedItems) {
            if (rankedItem.matchType != "fuzzy_token_match") {
                arrayAppend(nonFuzzyItems, rankedItem);
            }
        }

        if (arrayLen(nonFuzzyItems)) {
            rankedItems = nonFuzzyItems;
        }

        arraySort(rankedItems, function(a, b) {
            if (b.matchScore != a.matchScore) {
                return b.matchScore - a.matchScore;
            }
            return compareNoCase(a.sku, b.sku);
        });

        for (var index = 1; index <= min(arrayLen(rankedItems), 5); index++) {
            arrayAppend(topItems, rankedItems[index]);
        }

        if (arrayLen(topItems)) {
            matchStrategy = topItems[1].matchType;
        }

        return {
            count: arrayLen(topItems),
            query: arguments.query,
            normalizedQuery: normalizedQuery,
            meaningfulTokens: meaningfulTokens,
            matchStrategy: matchStrategy,
            items: topItems,
            message: arrayLen(topItems) ? "" : "No matching inventory items found."
        };
    }

    public array function getLowStockItems(string warehouse = "", numeric threshold = -1) {
        var sql = inventorySelectSql() & " WHERE quantity_on_hand <= ";
        var params = {};

        if (arguments.threshold >= 0) {
            sql &= ":threshold";
            params.threshold = { value: arguments.threshold, cfsqltype: "cf_sql_integer" };
        } else {
            sql &= "reorder_threshold";
        }

        if (len(trim(arguments.warehouse)) && compareNoCase(arguments.warehouse, "all") != 0) {
            sql &= " AND warehouse = :warehouse";
            params.warehouse = { value: arguments.warehouse, cfsqltype: "cf_sql_varchar" };
        }

        sql &= " ORDER BY warehouse, quantity_on_hand ASC, sku";
        setSqlDebug(sql, params);

        return queryToItemArray(queryExecute(sql, params, { datasource: variables.datasource }));
    }

    public struct function getLastSqlDebug() {
        return duplicate(variables.lastSqlDebug);
    }

    public array function recommendReorders(string warehouse = "") {
        var lows = getLowStockItems(arguments.warehouse);
        var recommendations = [];

        for (var item in lows) {
            var shortage = max(item.reorderPoint - item.quantityOnHand, 0);
            arrayAppend(recommendations, {
                sku: item.sku,
                name: item.name,
                warehouse: item.warehouse,
                category: item.category,
                quantityOnHand: item.quantityOnHand,
                reorderPoint: item.reorderPoint,
                recommendedQuantity: max(item.reorderQuantity, shortage + item.reorderQuantity),
                supplier: item.supplier,
                leadTimeDays: item.leadTimeDays,
                estimatedCost: dollarFormat(max(item.reorderQuantity, shortage + item.reorderQuantity) * item.unitCost),
                status: item.status
            });
        }

        arraySort(recommendations, function(a, b) {
            return b.leadTimeDays - a.leadTimeDays;
        });

        return recommendations;
    }

    public struct function createReorderRequest(required string sku, numeric quantity = 0) {
        var item = getItemBySku(arguments.sku);

        if (structIsEmpty(item)) {
            return { ok: false, message: "SKU not found: " & arguments.sku };
        }

        var orderQuantity = arguments.quantity > 0 ? arguments.quantity : item.reorderQuantity;

        return {
            ok: true,
            reorderId: "RO-" & dateFormat(now(), "yyyymmdd") & "-" & right(replace(createUUID(), "-", "", "all"), 6),
            sku: item.sku,
            name: item.name,
            warehouse: item.warehouse,
            quantity: orderQuantity,
            supplier: item.supplier,
            leadTimeDays: item.leadTimeDays,
            estimatedCost: dollarFormat(orderQuantity * item.unitCost),
            message: "Created reorder request for " & orderQuantity & " units of " & item.sku & "."
        };
    }

    public struct function getStats() {
        var items = queryItems({});
        var stats = {
            totalItems: arrayLen(items),
            lowStock: 0,
            critical: 0,
            outOfStock: 0,
            totalValue: 0,
            warehouses: {},
            categories: {}
        };

        for (var rawItem in items) {
            var item = normalizeItem(rawItem);
            stats.totalValue += item.quantityOnHand * item.unitCost;

            if (item.quantityOnHand == 0) stats.outOfStock++;
            if (item.quantityOnHand <= item.reorderPoint) stats.lowStock++;
            if (item.status == "critical" || item.status == "out") stats.critical++;

            stats.warehouses[item.warehouse] = (structKeyExists(stats.warehouses, item.warehouse) ? stats.warehouses[item.warehouse] : 0) + 1;
            stats.categories[item.category] = (structKeyExists(stats.categories, item.category) ? stats.categories[item.category] : 0) + 1;
        }

        stats.totalValueFormatted = dollarFormat(stats.totalValue);
        return stats;
    }

    private boolean function matchesFilters(required struct item, required struct filters) {
        var normalized = normalizeItem(arguments.item);
        var queryText = "";

        if (structKeyExists(arguments.filters, "warehouse") && len(arguments.filters.warehouse) && compareNoCase(arguments.filters.warehouse, "all") != 0 && compareNoCase(normalized.warehouse, arguments.filters.warehouse) != 0) {
            return false;
        }

        if (structKeyExists(arguments.filters, "category") && len(arguments.filters.category) && compareNoCase(arguments.filters.category, "all") != 0 && compareNoCase(normalized.category, arguments.filters.category) != 0) {
            return false;
        }

        if (structKeyExists(arguments.filters, "stockStatus") && !itemMatchesStockStatusFilter(normalized, arguments.filters.stockStatus)) {
            return false;
        }

        if (structKeyExists(arguments.filters, "query") && len(trim(arguments.filters.query))) {
            var normalizedQuery = normalizeSearchText(arguments.filters.query);
            var meaningfulTokens = meaningfulSearchTokens(normalizedQuery);
            var match = scoreSearchItem(normalized, arguments.filters.query, normalizedQuery, meaningfulTokens);
            if (match.score < 50) {
                return false;
            }
        }

        return true;
    }

    private struct function normalizeItem(required struct item) {
        var normalized = duplicate(arguments.item);
        normalized.quantityOnHand = val(normalized.quantityOnHand);
        normalized.reorderPoint = val(normalized.reorderPoint);
        normalized.reorderQuantity = val(normalized.reorderQuantity);
        normalized.leadTimeDays = val(normalized.leadTimeDays);
        normalized.unitCost = val(normalized.unitCost);
        normalized.status = len(normalized.status) ? normalizeStatus(normalized.status, normalized.quantityOnHand, normalized.reorderPoint) : computeStatus(normalized.quantityOnHand, normalized.reorderPoint);
        normalized.inventoryValue = dollarFormat(normalized.quantityOnHand * normalized.unitCost);
        return normalized;
    }

    private string function normalizeSearchText(required string value) {
        var normalized = lcase(trim(arguments.value));
        normalized = reReplace(normalized, "^[\+\-\s]+", "", "all");
        normalized = reReplaceNoCase(normalized, "\busb[\s\-_\/]*c\b|\busbc\b", " usb c ", "all");
        normalized = reReplace(normalized, "[^a-z0-9\s]+", " ", "all");
        normalized = reReplace(normalized, "\s+", " ", "all");

        var tokens = listToArray(trim(normalized), " ");
        var normalizedTokens = [];

        for (var token in tokens) {
            token = normalizeSearchToken(token);
            if (len(token)) {
                arrayAppend(normalizedTokens, token);
            }
        }

        return arrayToList(normalizedTokens, " ");
    }

    private string function normalizeSearchToken(required string token) {
        var normalized = lcase(trim(arguments.token));

        if (!len(normalized)) return "";

        var variants = {
            cancelling: "cancel",
            canceling: "cancel",
            cancelled: "cancel",
            canceled: "cancel",
            cancels: "cancel",
            cancel: "cancel",
            headphones: "headphone",
            headphone: "headphone",
            headset: "headphone",
            headsets: "headphone",
            notebook: "laptop",
            notebooks: "laptop",
            laptop: "laptop",
            laptops: "laptop",
            display: "monitor",
            displays: "monitor",
            screen: "monitor",
            screens: "monitor",
            monitor: "monitor",
            monitors: "monitor",
            docking: "dock",
            dock: "dock",
            docks: "dock",
            hub: "dock",
            hubs: "dock",
            keyboard: "keyboard",
            keyboards: "keyboard",
            kb: "keyboard",
            mouse: "mouse",
            mice: "mouse",
            chair: "chair",
            chairs: "chair",
            seating: "chair",
            desk: "desk",
            desks: "desk",
            workstation: "desk",
            workstations: "desk"
        };

        if (structKeyExists(variants, normalized)) {
            return variants[normalized];
        }

        if (len(normalized) > 4 && right(normalized, 3) == "ies") {
            normalized = left(normalized, len(normalized) - 3) & "y";
        } else if (len(normalized) > 4 && right(normalized, 2) == "es") {
            normalized = left(normalized, len(normalized) - 2);
        } else if (len(normalized) > 3 && right(normalized, 1) == "s") {
            normalized = left(normalized, len(normalized) - 1);
        }

        return normalized;
    }

    private array function meaningfulSearchTokens(required string normalizedQuery) {
        var stopWords = "a,an,the,our,what,is,are,on,in,for,show,me,stock,status,current,available,inventory,of,to,about,that,item,items,need,needs,attention";
        var tokens = listToArray(arguments.normalizedQuery, " ");
        var meaningful = [];

        for (var token in tokens) {
            if (len(token) > 1 && !listFindNoCase(stopWords, token) && !arrayContainsNoCase(meaningful, token)) {
                arrayAppend(meaningful, token);
            }
        }

        return meaningful;
    }

    private struct function scoreSearchItem(required struct rawItem, required string originalQuery, required string normalizedQuery, required array meaningfulTokens) {
        var item = normalizeItem(arguments.rawItem);
        var normalizedSku = normalizeSearchText(item.sku);
        var normalizedName = normalizeSearchText(item.name);
        var searchableText = normalizeSearchText(item.name & " " & item.sku & " " & item.category & " " & item.warehouse & " " & item.supplier & " " & item.status & " " & item.notes);
        var nameTokenHits = matchedTokens(arguments.meaningfulTokens, normalizedName);
        var allTokenHits = matchedTokens(arguments.meaningfulTokens, searchableText);
        var nameHitCount = arrayLen(nameTokenHits);
        var allHitCount = arrayLen(allTokenHits);
        var tokenCount = max(arrayLen(arguments.meaningfulTokens), 1);
        var bestScore = 0;
        var matchType = "none";
        var explanation = "";

        if (len(trim(arguments.originalQuery)) && compareNoCase(trim(arguments.originalQuery), item.sku) == 0) {
            bestScore = 100;
            matchType = "sku_exact";
            explanation = "Exact SKU match.";
        } else if (len(arguments.normalizedQuery) && arguments.normalizedQuery == normalizedSku) {
            bestScore = 100;
            matchType = "sku_exact";
            explanation = "Exact normalized SKU match.";
        } else if (len(arguments.normalizedQuery) && arguments.normalizedQuery == normalizedName) {
            bestScore = 95;
            matchType = "normalized_name_exact";
            explanation = "Exact normalized product name match.";
        } else if (len(arguments.normalizedQuery) && find(arguments.normalizedQuery, normalizedName)) {
            bestScore = 90;
            matchType = "normalized_name_contains";
            explanation = "Normalized product name contains the normalized query.";
        } else if (arrayLen(arguments.meaningfulTokens) && nameHitCount == arrayLen(arguments.meaningfulTokens)) {
            bestScore = 85;
            matchType = "normalized_token_match";
            explanation = "Matched normalized product terms against item name.";
        } else if (arrayLen(arguments.meaningfulTokens) && nameHitCount >= ceiling(arrayLen(arguments.meaningfulTokens) * 0.66)) {
            bestScore = 75;
            matchType = "mostly_name_token_match";
            explanation = "Most meaningful query terms matched the item name.";
        } else if (arrayLen(arguments.meaningfulTokens) && allHitCount == arrayLen(arguments.meaningfulTokens)) {
            bestScore = 70;
            matchType = "cross_field_token_match";
            explanation = "Matched all meaningful terms across product and inventory fields.";
        } else if (arrayLen(arguments.meaningfulTokens) && allHitCount >= ceiling(arrayLen(arguments.meaningfulTokens) * 0.66)) {
            bestScore = 60;
            matchType = "partial_cross_field_token_match";
            explanation = "Matched most meaningful terms across product and inventory fields.";
        } else {
            var fuzzyScore = fuzzySearchScore(arguments.meaningfulTokens, normalizedName, searchableText);
            if (fuzzyScore >= 50) {
                bestScore = fuzzyScore;
                matchType = "fuzzy_token_match";
                explanation = "Matched by fuzzy normalized token similarity.";
                allTokenHits = fuzzyMatchedTokens(arguments.meaningfulTokens, searchableText);
            }
        }

        var reportedTerms = (matchType == "normalized_token_match" || matchType == "mostly_name_token_match" || matchType == "normalized_name_exact" || matchType == "normalized_name_contains")
            ? nameTokenHits
            : allTokenHits;

        return {
            score: bestScore,
            type: matchType,
            terms: reportedTerms,
            explanation: explanation
        };
    }

    private struct function formatSearchItem(required struct rawItem, required struct match) {
        var item = normalizeItem(arguments.rawItem);
        return {
            sku: item.sku,
            itemName: item.name,
            name: item.name,
            category: item.category,
            warehouse: item.warehouse,
            quantityOnHand: item.quantityOnHand,
            reorderThreshold: item.reorderPoint,
            reorderPoint: item.reorderPoint,
            reorderQuantity: item.reorderQuantity,
            stockStatus: statusLabel(item.status),
            status: item.status,
            leadTimeDays: item.leadTimeDays,
            supplier: item.supplier,
            unitCost: item.unitCost,
            inventoryValue: item.inventoryValue,
            matchScore: arguments.match.score,
            matchType: arguments.match.type,
            matchedTerms: arguments.match.terms,
            explanation: arguments.match.explanation
        };
    }

    private array function matchedTokens(required array tokens, required string normalizedText) {
        var matches = [];
        var paddedText = " " & arguments.normalizedText & " ";

        for (var token in arguments.tokens) {
            if (find(" " & token & " ", paddedText) && !arrayContainsNoCase(matches, token)) {
                arrayAppend(matches, token);
            }
        }

        return matches;
    }

    private numeric function fuzzySearchScore(required array tokens, required string normalizedName, required string searchableText) {
        if (!arrayLen(arguments.tokens)) return 0;

        var fuzzyHits = arrayLen(fuzzyMatchedTokens(arguments.tokens, arguments.searchableText));
        var ratio = fuzzyHits / arrayLen(arguments.tokens);

        if (ratio >= 1) return 70;
        if (ratio >= 0.66) return 60;
        if (ratio >= 0.5) return 50;

        return 0;
    }

    private array function fuzzyMatchedTokens(required array tokens, required string normalizedText) {
        var textTokens = listToArray(arguments.normalizedText, " ");
        var matches = [];

        for (var token in arguments.tokens) {
            for (var textToken in textTokens) {
                if (
                    len(token) > 2 &&
                    (
                        find(token, textToken) ||
                        find(textToken, token) ||
                        levenshteinDistance(token, textToken) <= (len(token) >= 7 ? 2 : 1)
                    )
                ) {
                    if (!arrayContainsNoCase(matches, token)) {
                        arrayAppend(matches, token);
                    }
                    break;
                }
            }
        }

        return matches;
    }

    private boolean function arrayContainsNoCase(required array values, required string value) {
        for (var candidate in arguments.values) {
            if (compareNoCase(candidate, arguments.value) == 0) {
                return true;
            }
        }

        return false;
    }

    private numeric function levenshteinDistance(required string leftValue, required string rightValue) {
        var leftLength = len(arguments.leftValue);
        var rightLength = len(arguments.rightValue);
        var previous = [];
        var current = [];

        for (var j = 0; j <= rightLength; j++) {
            previous[j + 1] = j;
        }

        for (var i = 1; i <= leftLength; i++) {
            current = [i];
            for (var j = 1; j <= rightLength; j++) {
                var cost = mid(arguments.leftValue, i, 1) == mid(arguments.rightValue, j, 1) ? 0 : 1;
                current[j + 1] = min(min(previous[j + 1] + 1, current[j] + 1), previous[j] + cost);
            }
            previous = duplicate(current);
        }

        return previous[rightLength + 1];
    }

    private array function queryItems(struct filters = {}) {
        var sql = inventorySelectSql();
        var whereClauses = [];
        var params = {};
        var requestedStockStatus = structKeyExists(arguments.filters, "stockStatus") ? arguments.filters.stockStatus : "";
        var normalizedStockStatus = normalizeStockStatusFilter(requestedStockStatus);

        if (structKeyExists(arguments.filters, "warehouse") && len(arguments.filters.warehouse) && compareNoCase(arguments.filters.warehouse, "all") != 0) {
            arrayAppend(whereClauses, "warehouse = :warehouse");
            params.warehouse = { value: arguments.filters.warehouse, cfsqltype: "cf_sql_varchar" };
        }

        if (structKeyExists(arguments.filters, "category") && len(arguments.filters.category) && compareNoCase(arguments.filters.category, "all") != 0) {
            arrayAppend(whereClauses, "category = :category");
            params.category = { value: arguments.filters.category, cfsqltype: "cf_sql_varchar" };
        }

        if (structKeyExists(arguments.filters, "query") && len(trim(arguments.filters.query))) {
            arrayAppend(whereClauses, "(sku LIKE :query OR item_name LIKE :query OR category LIKE :query OR warehouse LIKE :query OR supplier LIKE :query OR notes LIKE :query)");
            params.query = { value: "%" & trim(arguments.filters.query) & "%", cfsqltype: "cf_sql_varchar" };
        }

        if (arrayLen(whereClauses)) {
            sql &= " WHERE " & arrayToList(whereClauses, " AND ");
        }

        sql &= " ORDER BY sku";
        setSqlDebug(sql, params, {
            requestedStockStatus: requestedStockStatus,
            stockStatus: normalizedStockStatus
        });

        var items = queryToItemArray(queryExecute(sql, params, { datasource: variables.datasource }));
        if (len(normalizedStockStatus)) {
            var filtered = [];
            for (var item in items) {
                if (itemMatchesStockStatusFilter(item, normalizedStockStatus)) {
                    arrayAppend(filtered, item);
                }
            }
            return filtered;
        }

        return items;
    }

    private string function inventorySelectSql() {
        return "
            SELECT
                item_id,
                item_name,
                sku,
                category,
                warehouse,
                quantity_on_hand,
                reorder_threshold,
                reorder_quantity,
                stock_status,
                lead_time_days,
                supplier,
                unit_cost,
                last_ordered_date,
                notes,
                created_at,
                updated_at
            FROM [inventory].[dbo].[inventory_items]";
    }

    private void function setSqlDebug(required string sql, struct params = {}, struct postFilters = {}) {
        variables.lastSqlDebug = {
            datasource: variables.datasource,
            sql: trim(arguments.sql),
            params: publicSqlParams(arguments.params),
            postFilters: duplicate(arguments.postFilters)
        };
    }

    private struct function publicSqlParams(required struct params) {
        var cleanParams = {};

        for (var key in arguments.params) {
            var param = arguments.params[key];
            cleanParams[key] = {
                value: structKeyExists(param, "value") ? param.value : "",
                cfsqltype: structKeyExists(param, "cfsqltype") ? param.cfsqltype : ""
            };
        }

        return cleanParams;
    }

    private array function queryToItemArray(required query rows) {
        var items = [];

        for (var rowIndex = 1; rowIndex <= arguments.rows.recordCount; rowIndex++) {
            arrayAppend(items, normalizeItem({
                itemId: getColumnValue(arguments.rows, "item_id", rowIndex),
                name: getColumnValue(arguments.rows, "item_name", rowIndex),
                sku: getColumnValue(arguments.rows, "sku", rowIndex),
                category: getColumnValue(arguments.rows, "category", rowIndex),
                warehouse: getColumnValue(arguments.rows, "warehouse", rowIndex),
                quantityOnHand: getColumnValue(arguments.rows, "quantity_on_hand", rowIndex),
                reorderPoint: getColumnValue(arguments.rows, "reorder_threshold", rowIndex),
                reorderQuantity: getColumnValue(arguments.rows, "reorder_quantity", rowIndex),
                status: getColumnValue(arguments.rows, "stock_status", rowIndex),
                leadTimeDays: getColumnValue(arguments.rows, "lead_time_days", rowIndex),
                supplier: getColumnValue(arguments.rows, "supplier", rowIndex),
                unitCost: getColumnValue(arguments.rows, "unit_cost", rowIndex),
                lastOrderedDate: getColumnValue(arguments.rows, "last_ordered_date", rowIndex),
                notes: getColumnValue(arguments.rows, "notes", rowIndex),
                createdAt: getColumnValue(arguments.rows, "created_at", rowIndex),
                updatedAt: getColumnValue(arguments.rows, "updated_at", rowIndex)
            }));
        }

        return items;
    }

    private any function getColumnValue(required query rows, required string columnName, required numeric rowIndex) {
        if (!listFindNoCase(arguments.rows.columnList, arguments.columnName)) {
            return "";
        }

        return arguments.rows[arguments.columnName][arguments.rowIndex];
    }

    private string function computeStatus(required numeric quantityOnHand, required numeric reorderPoint) {
        if (arguments.quantityOnHand <= 0) return "out";
        if (arguments.quantityOnHand <= max(2, ceiling(arguments.reorderPoint / 2))) return "critical";
        if (arguments.quantityOnHand <= arguments.reorderPoint) return "low";
        return "ok";
    }

    private string function statusLabel(required string status) {
        if (arguments.status == "out") return "Out of Stock";
        if (arguments.status == "critical") return "Critical";
        if (arguments.status == "low") return "Low Stock";
        return "In Stock";
    }

    private boolean function itemMatchesStockStatusFilter(required struct item, string stockStatus = "") {
        var normalized = normalizeItem(arguments.item);
        var filter = normalizeStockStatusFilter(arguments.stockStatus);

        if (!len(filter)) return true;
        if (filter == "available") return normalized.quantityOnHand > 0;

        return compareNoCase(normalized.status, filter) == 0;
    }

    private string function normalizeStockStatusFilter(any stockStatus = "") {
        var lowerStatus = lcase(trim("" & arguments.stockStatus));
        var normalized = reReplace(lowerStatus, "[^a-z0-9]+", " ", "all");
        normalized = trim(reReplace(normalized, "\s+", " ", "all"));
        var compact = replace(normalized, " ", "", "all");

        if (!len(normalized) || normalized == "all" || normalized == "any") return "";

        if (normalized == "ok" || normalized == "healthy" || normalized == "normal") return "ok";
        if (find("critical", normalized)) return "critical";
        if (find("low", normalized)) return "low";

        if (
            listFindNoCase("available,instock,onhand,stocked,positive,nonzero", compact) ||
            normalized == "in stock" ||
            find("not out", normalized) ||
            find("has stock", normalized)
        ) {
            return "available";
        }

        if (
            normalized == "out" ||
            normalized == "out of stock" ||
            compact == "unavailable" ||
            find("no stock", normalized) ||
            find("zero stock", normalized)
        ) {
            return "out";
        }

        return "";
    }

    private string function normalizeStatus(required string stockStatus, required numeric quantityOnHand, required numeric reorderPoint) {
        var lowerStatus = lcase(trim(arguments.stockStatus));

        if (find("out", lowerStatus)) return "out";
        if (find("critical", lowerStatus)) return "critical";
        if (find("low", lowerStatus)) return "low";
        if (find("in stock", lowerStatus) || find("ok", lowerStatus)) return "ok";
        return computeStatus(arguments.quantityOnHand, arguments.reorderPoint);
    }
}
