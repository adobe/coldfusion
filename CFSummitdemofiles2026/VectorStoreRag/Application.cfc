component {
    variables.appRoot = getDirectoryFromPath(getCurrentTemplatePath());
    variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
    variables.trackingComponentsPath = createObject("java", "java.io.File")
        .init(variables.appRoot & ".." & variables.pathSep & "usertracking" & variables.pathSep & "components")
        .getCanonicalPath();
    variables.keystoreComponentsPath = createObject("java", "java.io.File")
        .init(variables.appRoot & ".." & variables.pathSep & "keystore" & variables.pathSep & "components")
        .getCanonicalPath();
    variables.cairoiFallbackPath = createObject("java", "java.io.File")
        .init(variables.appRoot & ".." & variables.pathSep & "shared" & variables.pathSep & "cairoi-compat")
        .getCanonicalPath();
    variables.cairoiPath = variables.cairoiFallbackPath;
    variables.cairoiCandidatePaths = [];
    try {
        variables.cairoiConfiguredPath = createObject("java", "java.lang.System").getenv("CAIROI_ROOT");
        if (!isNull(variables.cairoiConfiguredPath) && len(trim(toString(variables.cairoiConfiguredPath)))) {
            arrayAppend(variables.cairoiCandidatePaths, toString(variables.cairoiConfiguredPath));
        }
        variables.cairoiConfiguredPath = createObject("java", "java.lang.System").getenv("CAIROI_SDK_ROOT");
        if (!isNull(variables.cairoiConfiguredPath) && len(trim(toString(variables.cairoiConfiguredPath)))) {
            arrayAppend(variables.cairoiCandidatePaths, toString(variables.cairoiConfiguredPath));
        }
        variables.cairoiConfiguredPath = createObject("java", "java.lang.System").getProperty("cairoi.root");
        if (!isNull(variables.cairoiConfiguredPath) && len(trim(toString(variables.cairoiConfiguredPath)))) {
            arrayAppend(variables.cairoiCandidatePaths, toString(variables.cairoiConfiguredPath));
        }
        variables.cairoiConfiguredPath = createObject("java", "java.lang.System").getProperty("cairoi.sdkRoot");
        if (!isNull(variables.cairoiConfiguredPath) && len(trim(toString(variables.cairoiConfiguredPath)))) {
            arrayAppend(variables.cairoiCandidatePaths, toString(variables.cairoiConfiguredPath));
        }
    } catch (any ignored) {
    }
    arrayAppend(variables.cairoiCandidatePaths, variables.appRoot & ".." & variables.pathSep & "CAIROI");
    arrayAppend(variables.cairoiCandidatePaths, variables.appRoot & ".." & variables.pathSep & "cairoi");
    arrayAppend(variables.cairoiCandidatePaths, variables.appRoot & ".." & variables.pathSep & ".." & variables.pathSep & "CAIROI");
    arrayAppend(variables.cairoiCandidatePaths, variables.appRoot & ".." & variables.pathSep & ".." & variables.pathSep & "cairoi");
    arrayAppend(variables.cairoiCandidatePaths, variables.appRoot & ".." & variables.pathSep & ".." & variables.pathSep & ".." & variables.pathSep & "CAIROI");
    arrayAppend(variables.cairoiCandidatePaths, variables.appRoot & ".." & variables.pathSep & ".." & variables.pathSep & ".." & variables.pathSep & "cairoi");
    try {
        arrayAppend(variables.cairoiCandidatePaths, expandPath("/CAIROI"));
        arrayAppend(variables.cairoiCandidatePaths, expandPath("/cairoi"));
    } catch (any ignored) {
    }
    arrayAppend(variables.cairoiCandidatePaths, variables.cairoiFallbackPath);
    for (variables.cairoiCandidatePath in variables.cairoiCandidatePaths) {
        try {
            if (len(trim(toString(variables.cairoiCandidatePath)))) {
                variables.cairoiCandidateRoot = createObject("java", "java.io.File")
                    .init(toString(variables.cairoiCandidatePath))
                    .getCanonicalPath();
                if (
                    fileExists(variables.cairoiCandidateRoot & variables.pathSep & "sdk" & variables.pathSep & "Cairoi.cfc") &&
                    fileExists(variables.cairoiCandidateRoot & variables.pathSep & "sdk" & variables.pathSep & "DemoTelemetry.cfc")
                ) {
                    variables.cairoiPath = variables.cairoiCandidateRoot;
                    break;
                }
            }
        } catch (any ignored) {
        }
    }
    if (right(variables.trackingComponentsPath, 1) != variables.pathSep) {
        variables.trackingComponentsPath &= variables.pathSep;
    }
    if (right(variables.keystoreComponentsPath, 1) != variables.pathSep) {
        variables.keystoreComponentsPath &= variables.pathSep;
    }
    if (right(variables.cairoiPath, 1) != variables.pathSep) {
        variables.cairoiPath &= variables.pathSep;
    }

    this.name = "CFSummit2026VectorStoreRag";
    this.applicationTimeout = createTimeSpan(0, 4, 0, 0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 10, 0);
    this.setClientCookies = true;
    this.mappings["/demotracking"] = variables.trackingComponentsPath;
    this.mappings["/keystore"] = variables.keystoreComponentsPath;
    this.mappings["/cairoi"] = variables.cairoiPath;
    this.mappings["/CAIROI"] = variables.cairoiPath;
    this.mappings["/cairoiLive"] = variables.cairoiPath;

    public boolean function onApplicationStart() {
        initializeDemoState();
        return true;
    }

    public void function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reloadApp") && url.reloadApp == "1") {
            applicationStop();
            location(url = cgi.script_name, addToken = false);
        }

        if (
            !structKeyExists(application, "demoInitialized") ||
            !structKeyExists(application, "demoTrackingConfig") ||
            !structKeyExists(application.demoTrackingConfig, "sessionMinutes") ||
            val(application.demoTrackingConfig.sessionMinutes) != 10
        ) {
            initializeDemoState();
        }

        refreshAiConfig();
        touchDemoTracking();
    }

    private void function initializeDemoState() {
        application.demoInitialized = true;
        application.appRoot = variables.appRoot;
        application.pathSep = variables.pathSep;
        application.demosRoot = getParentDirectory(application.appRoot);
        application.demoTrackingConfig = {
            appRoot: application.demosRoot,
            dataRoot: application.demosRoot & "usertracking" & application.pathSep & "data" & application.pathSep,
            dbParentPath: application.demosRoot & "usertracking" & application.pathSep & "data" & application.pathSep & "derby" & application.pathSep,
            databasePath: application.demosRoot & "usertracking" & application.pathSep & "data" & application.pathSep & "derby" & application.pathSep & "trackingdb",
            sessionMinutes: 10,
            cookieName: "cfsummit_demo_session",
            cookiePath: "/CFSummit2026/demos/"
        };
        application.keystoreRoot = application.demosRoot & "keystore" & application.pathSep;
        application.keystoreKeyIds = {
            openAi: "openaiapi_donuts"
        };
        application.keystoreApiKeyCache = {};
        application.keystoreConfig = {
            appRoot: application.keystoreRoot,
            dataRoot: application.keystoreRoot & "data" & application.pathSep,
            dbParentPath: application.keystoreRoot & "data" & application.pathSep & "derby" & application.pathSep,
            databasePath: application.keystoreRoot & "data" & application.pathSep & "derby" & application.pathSep & "keystoredb",
            masterKeyPath: application.keystoreRoot & "data" & application.pathSep & "keystore-master.key"
        };
        application.cairoiConfig = {
            appId: "donut-rag",
            environment: "conference",
            collectorUrl: "https://adobecoldfusion.com/cairoi/api/telemetry.cfm",
            apiKey: "cairoi-donut-rag-dev-key",
            failSilently: true,
            debug: true,
            asyncTelemetry: true,
            durableTelemetry: true,
            telemetryQueueDir: application.appRoot & "data" & application.pathSep & "cairoi-telemetry-queue",
            telemetryTimeout: 2,
            telemetryBatchSize: 25,
            telemetryMaxAttempts: 20,
            datasource: "embedded-derby"
        };
        application.cairoiDashboardUrl = "https://adobecoldfusion.com/cairoi/dashboard/index.cfm";
        application.cairoiTraceUrl = "https://adobecoldfusion.com/cairoi/dashboard/trace.cfm";

        application.openAiApiKey = getConfiguredOpenAiApiKey();

        application.chatConfig = {
            provider: "openAi",
            apiKey: application.openAiApiKey,
            modelName: "gpt-4o-mini",
            temperature: 0.2,
            maxTokens: 900,
            timeout: 60
        };

        application.embeddingModelName = "text-embedding-3-small";
        application.vectorDimension = 1536;
        application.dataFile = expandPath("./data/donut_catalog_rag_demo.txt");
        application.vectorClient = "";
        application.ingestStatus = {
            ready: false,
            sourceFile: "",
            sourceName: "No menu ingested",
            chunkCount: 0,
            addedCount: 0,
            ingestedAt: "",
            collectionName: "",
            message: "Not ingested yet."
        };
    }

    private void function touchDemoTracking() {
        try {
            createObject("component", "demotracking.DemoTrackingService")
                .init(application.demoTrackingConfig)
                .getCurrentSession(true);
        } catch (any ignored) {
        }
    }

    private string function getParentDirectory(required string directoryPath) {
        var dirFile = createObject("java", "java.io.File").init(arguments.directoryPath);
        var parentPath = dirFile.getParent();
        if (isNull(parentPath)) {
            return arguments.directoryPath;
        }
        parentPath = toString(parentPath);
        if (right(parentPath, 1) != application.pathSep) {
            parentPath &= application.pathSep;
        }
        return parentPath;
    }

    private string function getConfiguredOpenAiApiKey() {
        return readKeystoreApiKey(application.keystoreKeyIds.openAi);
    }

    private string function readKeystoreApiKey(required string keyId) {
        if (!structKeyExists(application, "keystoreApiKeyCache")) {
            application.keystoreApiKeyCache = {};
        }

        if (structKeyExists(application.keystoreApiKeyCache, arguments.keyId)) {
            return application.keystoreApiKeyCache[arguments.keyId];
        }

        try {
            var keyRecord = new keystore.KeystoreService(application.keystoreConfig).getKey(arguments.keyId, true);
            if (
                structKeyExists(keyRecord, "ok") &&
                keyRecord.ok &&
                structKeyExists(keyRecord, "value")
            ) {
                application.keystoreApiKeyCache[arguments.keyId] = cleanApiKey(keyRecord.value);
                return application.keystoreApiKeyCache[arguments.keyId];
            }
        } catch (any ignored) {
        }

        return "";
    }

    private string function cleanApiKey(required string keyValue) {
        var cleaned = trim(replace(arguments.keyValue, chr(65279), "", "all"));

        if (
            len(cleaned) >= 2 &&
            (
                (left(cleaned, 1) == """" && right(cleaned, 1) == """") ||
                (left(cleaned, 1) == "'" && right(cleaned, 1) == "'")
            )
        ) {
            var innerLength = len(cleaned) - 2;
            cleaned = innerLength > 0 ? mid(cleaned, 2, innerLength) : "";
        }

        return trim(cleaned);
    }

    private void function refreshAiConfig() {
        application.openAiApiKey = getConfiguredOpenAiApiKey();

        if (structKeyExists(application, "chatConfig")) {
            application.chatConfig.apiKey = application.openAiApiKey;
        }
    }
}
