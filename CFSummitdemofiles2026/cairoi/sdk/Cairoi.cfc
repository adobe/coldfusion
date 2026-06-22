component output=false {
    variables.config = {};
    variables.hashUtil = "";
    variables.tokenExtractor = "";
    variables.costCalculator = "";
    variables.telemetryClient = "";

    public Cairoi function init(struct config = {}) {
        variables.config = {
            appId: readKey(arguments.config, "appId", "demo-app"),
            environment: readKey(arguments.config, "environment", "dev"),
            collectorUrl: readKey(arguments.config, "collectorUrl", ""),
            apiKey: readKey(arguments.config, "apiKey", ""),
            failSilently: toBoolean(readKey(arguments.config, "failSilently", true), true),
            debug: toBoolean(readKey(arguments.config, "debug", false), false),
            asyncTelemetry: toBoolean(readKey(arguments.config, "asyncTelemetry", readKey(arguments.config, "async", true)), true),
            durableTelemetry: toBoolean(readKey(arguments.config, "durableTelemetry", readKey(arguments.config, "durable", true)), true),
            telemetryQueueDir: readKey(arguments.config, "telemetryQueueDir", readKey(arguments.config, "queueDir", "")),
            telemetryTimeout: val(readKey(arguments.config, "telemetryTimeout", readKey(arguments.config, "timeout", 2))),
            telemetryBatchSize: val(readKey(arguments.config, "telemetryBatchSize", 25)),
            telemetryMaxAttempts: val(readKey(arguments.config, "telemetryMaxAttempts", 20)),
            telemetryRetryBaseSeconds: val(readKey(arguments.config, "telemetryRetryBaseSeconds", 5)),
            telemetryRetryMaxSeconds: val(readKey(arguments.config, "telemetryRetryMaxSeconds", 300)),
            telemetryMaxQueueFiles: val(readKey(arguments.config, "telemetryMaxQueueFiles", 2000)),
            hashSalt: readKey(arguments.config, "hashSalt", ""),
            defaultProvider: readKey(arguments.config, "defaultProvider", ""),
            defaultModelName: readKey(arguments.config, "defaultModelName", ""),
            datasource: readKey(arguments.config, "datasource", "cairoi")
        };

        variables.hashUtil = sdkComponent("sdk.HashUtil").init(variables.config.hashSalt);
        variables.tokenExtractor = sdkComponent("sdk.TokenExtractor").init();
        variables.costCalculator = sdkComponent("sdk.CostCalculator").init(variables.config.datasource);
        variables.telemetryClient = sdkComponent("sdk.TelemetryClient").init(
            collectorUrl = variables.config.collectorUrl,
            apiKey = variables.config.apiKey,
            failSilently = variables.config.failSilently,
            timeout = variables.config.telemetryTimeout,
            debug = variables.config.debug,
            asyncMode = variables.config.asyncTelemetry,
            durable = variables.config.durableTelemetry,
            queueDir = variables.config.telemetryQueueDir,
            batchSize = variables.config.telemetryBatchSize,
            maxAttempts = variables.config.telemetryMaxAttempts,
            retryBaseSeconds = variables.config.telemetryRetryBaseSeconds,
            retryMaxSeconds = variables.config.telemetryRetryMaxSeconds,
            maxQueueFiles = variables.config.telemetryMaxQueueFiles
        );
        return this;
    }

    public any function startTrace(
        required string workflowName,
        string userId = "",
        string sessionId = "",
        string requestId = "",
        struct metadata = {}
    ) {
        return sdkComponent("sdk.TraceContext").init({
            appId: variables.config.appId,
            environment: variables.config.environment,
            workflowName: arguments.workflowName,
            userId: arguments.userId,
            sessionId: arguments.sessionId,
            requestId: arguments.requestId,
            metadata: arguments.metadata,
            telemetryClient: variables.telemetryClient,
            hashUtil: variables.hashUtil
        });
    }

    public any function createChatModel(required struct chatConfig) {
        return sdkComponent("sdk.wrappers.TrackedChatModel").init({
            cairoi: this,
            chatConfig: arguments.chatConfig
        });
    }

    public any function createAgent(required struct agentConfig) {
        return sdkComponent("sdk.wrappers.TrackedAgent").init({
            cairoi: this,
            agentConfig: arguments.agentConfig
        });
    }

    public any function createMCPClient(required struct mcpConfig) {
        return sdkComponent("sdk.wrappers.TrackedMCPClient").init({
            cairoi: this,
            mcpConfig: arguments.mcpConfig
        });
    }

    public any function createVectorStore(struct vectorConfig = {}) {
        return sdkComponent("sdk.wrappers.TrackedVectorStore").init({
            cairoi: this,
            vectorConfig: arguments.vectorConfig
        });
    }

    public any function createRAG(struct ragConfig = {}) {
        return sdkComponent("sdk.wrappers.TrackedRAG").init({
            cairoi: this,
            ragConfig: arguments.ragConfig
        });
    }

    public struct function recordSpan(required struct spanData) {
        if (!structKeyExists(arguments.spanData, "appId")) {
            arguments.spanData.appId = variables.config.appId;
        }
        if (!structKeyExists(arguments.spanData, "environment")) {
            arguments.spanData.environment = variables.config.environment;
        }
        return variables.telemetryClient.sendSpan(arguments.spanData);
    }

    public struct function flush() {
        return isObject(variables.telemetryClient)
            ? variables.telemetryClient.flushQueue()
            : { ok: false, message: "No telemetry client configured." };
    }

    public struct function getTelemetryQueueStatus() {
        return isObject(variables.telemetryClient)
            ? variables.telemetryClient.getQueueStatus()
            : { ok: false, message: "No telemetry client configured." };
    }

    public any function getHashUtil() {
        return variables.hashUtil;
    }

    public any function getTokenExtractor() {
        return variables.tokenExtractor;
    }

    public any function getCostCalculator() {
        return variables.costCalculator;
    }

    public struct function getConfig() {
        return duplicate(variables.config);
    }

    public string function extractResponseText(any response = "") {
        return variables.tokenExtractor.extractText(arguments.response);
    }

    private any function sdkComponent(required string suffix) {
        try {
            return createObject("component", "cairoiLive." & arguments.suffix);
        } catch (any ignored) {
            return createObject("component", "cairoi." & arguments.suffix);
        }
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

    private boolean function toBoolean(any value = "", boolean fallback = false) {
        if (isBoolean(arguments.value)) {
            return arguments.value;
        }
        if (!isSimpleValue(arguments.value)) {
            return arguments.fallback;
        }
        var text = lcase(trim(toString(arguments.value)));
        if (listFindNoCase("true,1,yes,on", text)) {
            return true;
        }
        if (listFindNoCase("false,0,no,off", text)) {
            return false;
        }
        return arguments.fallback;
    }
}
