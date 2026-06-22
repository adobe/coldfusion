component output=false {
    public TokenExtractor function init() {
        return this;
    }

    public struct function extractFromResponse(any response = "", string promptText = "", string responseText = "") {
        var outputText = len(arguments.responseText) ? arguments.responseText : extractText(arguments.response);
        var result = {
            inputTokens: 0,
            outputTokens: 0,
            totalTokens: 0,
            inputTokenSource: "missing",
            outputTokenSource: "missing",
            totalTokenSource: "missing"
        };

        var inputCandidates = [
            "metadata.tokenUsage.inputTokenCount",
            "metadata.tokenUsage.promptTokenCount",
            "metadata.usage.prompt_tokens",
            "metadata.usage.input_tokens",
            "usage.prompt_tokens",
            "usage.input_tokens",
            "prompt_tokens",
            "input_tokens"
        ];
        var outputCandidates = [
            "metadata.tokenUsage.outputTokenCount",
            "metadata.tokenUsage.completionTokenCount",
            "metadata.usage.completion_tokens",
            "metadata.usage.output_tokens",
            "usage.completion_tokens",
            "usage.output_tokens",
            "completion_tokens",
            "output_tokens"
        ];
        var totalCandidates = [
            "metadata.tokenUsage.totalTokenCount",
            "metadata.usage.total_tokens",
            "usage.total_tokens",
            "total_tokens",
            "totalTokenCount"
        ];

        var inputValue = firstNumericPath(arguments.response, inputCandidates);
        var outputValue = firstNumericPath(arguments.response, outputCandidates);
        var totalValue = firstNumericPath(arguments.response, totalCandidates);

        if (inputValue >= 0) {
            result.inputTokens = inputValue;
            result.inputTokenSource = "provider";
        }
        if (outputValue >= 0) {
            result.outputTokens = outputValue;
            result.outputTokenSource = "provider";
        }
        if (totalValue >= 0) {
            result.totalTokens = totalValue;
            result.totalTokenSource = "provider";
        }

        if (result.inputTokenSource == "missing" && len(arguments.promptText)) {
            result.inputTokens = estimateTokens(arguments.promptText);
            result.inputTokenSource = "estimated";
        }

        if (result.outputTokenSource == "missing" && len(outputText)) {
            result.outputTokens = estimateTokens(outputText);
            result.outputTokenSource = "estimated";
        }

        if (result.totalTokenSource == "missing") {
            if (result.inputTokenSource != "missing" || result.outputTokenSource != "missing") {
                result.totalTokens = result.inputTokens + result.outputTokens;
                result.totalTokenSource = (result.inputTokenSource == "provider" && result.outputTokenSource == "provider") ? "provider" : "estimated";
            }
        }

        return result;
    }

    public numeric function estimateTokens(string text = "") {
        if (!len(arguments.text)) {
            return 0;
        }
        return ceiling(len(arguments.text) / 4);
    }

    public string function extractText(any response = "") {
        var candidates = collectTextCandidates(arguments.response, 0);
        if (!arrayLen(candidates)) {
            if (isSimpleValue(arguments.response)) {
                return toString(arguments.response);
            }
            return "";
        }
        return selectBestText(candidates);
    }

    private numeric function firstNumericPath(any value = "", required array paths) {
        for (var path in arguments.paths) {
            var possible = readPath(arguments.value, path, "");
            if (isNumeric(possible)) {
                return int(possible);
            }
        }
        return -1;
    }

    private any function readPath(any value = "", required string path, any fallback = "") {
        if (!structKeyExists(arguments, "value") || isNull(arguments.value)) {
            return arguments.fallback;
        }

        var current = arguments.value;
        for (var part in listToArray(arguments.path, ".")) {
            if (isNull(current)) {
                return arguments.fallback;
            }
            current = readKey(current, part, "__CAIROI_MISSING__");
            if (isSimpleValue(current) && current == "__CAIROI_MISSING__") {
                return arguments.fallback;
            }
        }
        return current;
    }

    private any function readKey(any value = "", required string key, any fallback = "") {
        if (!isStruct(arguments.value)) {
            return arguments.fallback;
        }
        for (var candidate in structKeyArray(arguments.value)) {
            if (compareNoCase(candidate, arguments.key) == 0) {
                return arguments.value[candidate];
            }
        }
        return arguments.fallback;
    }

    private array function collectTextCandidates(any value = "", numeric depth = 0) {
        var results = [];
        if (arguments.depth > 8 || !structKeyExists(arguments, "value") || isNull(arguments.value)) {
            return results;
        }

        if (isSimpleValue(arguments.value)) {
            var simpleText = trim(toString(arguments.value));
            if (len(simpleText)) {
                arrayAppend(results, simpleText);
            }
            return results;
        }

        if (isArray(arguments.value)) {
            for (var item in arguments.value) {
                var nestedArray = collectTextCandidates(item, arguments.depth + 1);
                arrayAppend(results, nestedArray, true);
            }
            return results;
        }

        if (!isStruct(arguments.value)) {
            return results;
        }

        for (var preferredKey in ["message", "content", "text", "answer", "response", "output", "body", "result", "completion"]) {
            var preferred = readKey(arguments.value, preferredKey, "__CAIROI_MISSING__");
            if (!(isSimpleValue(preferred) && preferred == "__CAIROI_MISSING__")) {
                var preferredNested = collectTextCandidates(preferred, arguments.depth + 1);
                arrayAppend(results, preferredNested, true);
            }
        }

        return results;
    }

    private string function selectBestText(required array candidates) {
        var bestText = "";
        var bestScore = -999999;

        for (var candidate in arguments.candidates) {
            var text = trim(toString(candidate));
            if (!len(text)) {
                continue;
            }

            var score = len(text);
            if (findNoCase("{", text) && (findNoCase("message", text) || findNoCase("answer", text))) {
                score += 1000;
            }
            if (len(text) < 8) {
                score -= 50;
            }

            if (score > bestScore) {
                bestScore = score;
                bestText = text;
            }
        }

        return bestText;
    }
}
