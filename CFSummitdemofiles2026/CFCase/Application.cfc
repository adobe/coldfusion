component output=false {
    variables.appRoot = getDirectoryFromPath(getCurrentTemplatePath());
    variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
    variables.trackingComponentsPath = createObject("java", "java.io.File")
        .init(variables.appRoot & ".." & variables.pathSep & "usertracking" & variables.pathSep & "components")
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
    if (right(variables.cairoiPath, 1) != variables.pathSep) {
        variables.cairoiPath &= variables.pathSep;
    }

    this.name = "CFCaseMysteryEngine";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 10, 0);
    this.applicationTimeout = createTimeSpan(1, 0, 0, 0);
    this.setClientCookies = true;
    this.mappings = {
        "/cfc": variables.appRoot & "cfc",
        "/demotracking": variables.trackingComponentsPath,
        "/cairoi": variables.cairoiPath,
        "/CAIROI": variables.cairoiPath,
        "/cairoiLive": variables.cairoiPath
    };

    public boolean function onApplicationStart() {
        application.caseRoot = getDirectoryFromPath(getCurrentTemplatePath());
        application.pathSep = variables.pathSep;
        application.demosRoot = getParentDirectory(application.caseRoot);
        application.demoTrackingConfig = {
            appRoot: application.demosRoot,
            dataRoot: application.demosRoot & "usertracking" & application.pathSep & "data" & application.pathSep,
            dbParentPath: application.demosRoot & "usertracking" & application.pathSep & "data" & application.pathSep & "derby" & application.pathSep,
            databasePath: application.demosRoot & "usertracking" & application.pathSep & "data" & application.pathSep & "derby" & application.pathSep & "trackingdb",
            sessionMinutes: 10,
            cookieName: "cfsummit_demo_session",
            cookiePath: "/CFSummit2026/demos/"
        };
        application.scenarioCache = {};
        application.caseAiStrict = true;
        application.caseUseAiParserFallback = true;
        application.cairoiConfig = {
            appId: "cfcase",
            environment: "conference",
            collectorUrl: "https://adobecoldfusion.com/cairoi/api/telemetry.cfm",
            apiKey: "cairoi-cfcase-dev-key",
            failSilently: true,
            debug: true,
            asyncTelemetry: true,
            durableTelemetry: true,
            telemetryQueueDir: application.caseRoot & "data" & application.pathSep & "cairoi-telemetry-queue",
            telemetryTimeout: 2,
            telemetryBatchSize: 25,
            telemetryMaxAttempts: 20,
            datasource: "embedded-derby"
        };
        application.cairoiDashboardUrl = "https://adobecoldfusion.com/cairoi/dashboard/index.cfm";
        application.cairoiTraceUrl = "https://adobecoldfusion.com/cairoi/dashboard/trace.cfm";
        return true;
    }

    public boolean function onRequestStart(required string targetPage) {
        if (
            !structKeyExists(application, "caseRoot") ||
            !structKeyExists(application, "demoTrackingConfig") ||
            !structKeyExists(application.demoTrackingConfig, "sessionMinutes") ||
            val(application.demoTrackingConfig.sessionMinutes) != 10
        ) {
            onApplicationStart();
        }

        if (structKeyExists(url, "reload") && url.reload == "1") {
            onApplicationStart();
        }

        touchDemoTracking();
        return true;
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
        if (right(parentPath, 1) != variables.pathSep) {
            parentPath &= variables.pathSep;
        }
        return parentPath;
    }
}
