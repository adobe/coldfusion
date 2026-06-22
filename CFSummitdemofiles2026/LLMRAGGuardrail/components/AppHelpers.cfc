component {
    public boolean function isOllamaReachable() {
        try {
            cfhttp(
                url = application.ollamaBaseUrl & "/api/tags",
                method = "get",
                timeout = 3,
                result = "ollamaProbe"
            );
            var statusCode = structKeyExists(ollamaProbe, "statusCode") ? ollamaProbe.statusCode : 0;
            return val(statusCode) == 200 || left(toString(statusCode), 1) == "2";
        } catch (any ignored) {
            return false;
        }
    }

    public any function makeVectorClient(required string collectionName) {
        var config = duplicate(application.embeddingConfig);
        config.collectionName = arguments.collectionName;

        try {
            return VectorStore(config);
        } catch (any firstError) {
            try {
                structDelete(config, "provider");
                structDelete(config, "baseUrl");
                return VectorStore(config);
            } catch (any secondError) {
                return VectorStore();
            }
        }
    }

    public void function clearVectorStore(any vectorStore) {
        if (!isObject(arguments.vectorStore)) {
            return;
        }

        try {
            arguments.vectorStore.deleteAll();
        } catch (any deleteError) {
            try {
                arguments.vectorStore.clear();
            } catch (any clearError) {
            }
        }
    }

    public string function makeCollectionName() {
        return "onboarding_kb_" & rereplace(createUUID(), "[^A-Za-z0-9]", "", "all");
    }

    public struct function runtimeStats() {
        var runtime = createObject("java", "java.lang.Runtime").getRuntime();
        var totalMb = round(runtime.totalMemory() / 1024 / 1024);
        var freeMb = round(runtime.freeMemory() / 1024 / 1024);
        var maxMb = round(runtime.maxMemory() / 1024 / 1024);
        var usedMb = max(totalMb - freeMb, 0);

        return {
            usedMb: usedMb,
            freeMb: freeMb,
            totalMb: totalMb,
            maxMb: maxMb,
            usedPct: maxMb > 0 ? round((usedMb / maxMb) * 100) : 0
        };
    }
}
