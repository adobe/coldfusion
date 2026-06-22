component output=false {
    variables.datasource = "embedded-derby";
    variables.store = "";

    public CostCalculator function init(string datasource = "embedded-derby", struct config = {}) {
        variables.datasource = arguments.datasource;
        variables.store = new cairoi.db.DerbyStore(deriveStoreConfig(arguments.config));
        return this;
    }

    public struct function calculate(string provider = "", string modelName = "", numeric inputTokens = 0, numeric outputTokens = 0) {
        if (isLocalProvider(arguments.provider, arguments.modelName)) {
            return {
                estimatedCost: 0,
                costSource: "local_model_zero_cost",
                price: {
                    found: true,
                    provider: normalizeProvider(arguments.provider),
                    modelName: arguments.modelName,
                    inputCostPer1M: 0,
                    outputCostPer1M: 0,
                    currency: "USD"
                }
            };
        }

        var price = getPrice(arguments.provider, arguments.modelName);
        if (!price.found) {
            return {
                estimatedCost: 0,
                costSource: "missing_price",
                price: price
            };
        }

        var estimatedCost = ((val(arguments.inputTokens) / 1000000.0) * numericValue(price.inputCostPer1M))
            + ((val(arguments.outputTokens) / 1000000.0) * numericValue(price.outputCostPer1M));

        return {
            estimatedCost: estimatedCost,
            costSource: "calculated",
            price: price
        };
    }

    public struct function getPrice(string provider = "", string modelName = "", any asOfDate = "") {
        try {
            var lookupDate = isDate(arguments.asOfDate) ? arguments.asOfDate : now();
            var priceQuery = variables.store.execute(
                "SELECT price_id, provider, model_name, input_cost_per_1m, output_cost_per_1m, currency
                FROM cairoi_model_prices
                WHERE LOWER(provider) = LOWER(:provider)
                    AND LOWER(model_name) = LOWER(:modelName)
                    AND is_active = 1
                    AND effective_start <= :asOfDate
                    AND (effective_end IS NULL OR effective_end >= :asOfDate)
                ORDER BY effective_start DESC, price_id DESC
                FETCH FIRST 1 ROWS ONLY",
                {
                    provider: { value: normalizeProvider(arguments.provider), cfsqltype: "cf_sql_varchar" },
                    modelName: { value: arguments.modelName, cfsqltype: "cf_sql_varchar" },
                    asOfDate: { value: lookupDate, cfsqltype: "cf_sql_timestamp" }
                }
            );

            if (!priceQuery.recordCount) {
                return missingPrice(arguments.provider, arguments.modelName);
            }

            return {
                found: true,
                priceId: priceQuery.price_id[1],
                provider: priceQuery.provider[1],
                modelName: priceQuery.model_name[1],
                inputCostPer1M: priceQuery.input_cost_per_1m[1],
                outputCostPer1M: priceQuery.output_cost_per_1m[1],
                currency: priceQuery.currency[1]
            };
        } catch (any e) {
            var missing = missingPrice(arguments.provider, arguments.modelName);
            missing.error = e.message;
            return missing;
        }
    }

    private struct function missingPrice(required string provider, required string modelName) {
        return {
            found: false,
            provider: arguments.provider,
            modelName: arguments.modelName,
            inputCostPer1M: 0,
            outputCostPer1M: 0,
            currency: "USD"
        };
    }

    private string function normalizeProvider(required string provider) {
        return compareNoCase(arguments.provider, "openAi") == 0 ? "openai" : lcase(trim(arguments.provider));
    }

    private boolean function isLocalProvider(string provider = "", string modelName = "") {
        var normalizedProvider = normalizeProvider(arguments.provider);
        if (listFindNoCase("ollama,local", normalizedProvider)) {
            return true;
        }

        var normalizedModel = lcase(trim(arguments.modelName));
        return find("llama", normalizedModel) || find("nomic-embed", normalizedModel);
    }

    private struct function deriveStoreConfig(required struct config) {
        if (!structIsEmpty(arguments.config)) {
            return arguments.config;
        }

        if (structKeyExists(application, "cairoiDbConfig") && isStruct(application.cairoiDbConfig)) {
            return application.cairoiDbConfig;
        }

        var sdkRoot = getDirectoryFromPath(getCurrentTemplatePath());
        var appRoot = getParentDirectory(sdkRoot);
        var pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
        return {
            appRoot: appRoot,
            dataRoot: appRoot & "data" & pathSep,
            dbParentPath: appRoot & "data" & pathSep & "derby" & pathSep,
            databasePath: appRoot & "data" & pathSep & "derby" & pathSep & "cairoi"
        };
    }

    private string function getParentDirectory(required string directoryPath) {
        var pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
        var dirFile = createObject("java", "java.io.File").init(arguments.directoryPath);
        var parentPath = dirFile.getParent();
        if (isNull(parentPath)) {
            return arguments.directoryPath;
        }
        parentPath = toString(parentPath);
        if (right(parentPath, 1) != pathSep) {
            parentPath &= pathSep;
        }
        return parentPath;
    }

    private numeric function numericValue(any value = 0) {
        if (isNull(arguments.value)) {
            return 0;
        }
        try {
            var text = replace(trim(toString(arguments.value)), ",", "", "all");
            return createObject("java", "java.lang.Double").parseDouble(text);
        } catch (any ignored) {
            return val(arguments.value);
        }
    }
}
