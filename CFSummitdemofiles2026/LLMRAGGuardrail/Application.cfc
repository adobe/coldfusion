component {
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

    this.name = "CFSummit2026LLMRAGGuardrail";
    this.applicationTimeout = createTimeSpan(0, 4, 0, 0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 10, 0);
    this.setClientCookies = true;
    this.mappings["/onboardrag"] = getDirectoryFromPath(getCurrentTemplatePath()) & "components";
    this.mappings["/demotracking"] = variables.trackingComponentsPath;
    this.mappings["/cairoi"] = variables.cairoiPath;
    this.mappings["/CAIROI"] = variables.cairoiPath;
    this.mappings["/cairoiLive"] = variables.cairoiPath;

    public boolean function onApplicationStart() {
        initializeDemoState();
        return true;
    }

    public void function onSessionStart() {
        initializeSessionState();
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

        if (!structKeyExists(session, "onboardSessionId")) {
            initializeSessionState();
        }

        refreshAiConfig();
        touchDemoTracking();
        maybeAutoIngest();
    }

    private void function initializeDemoState() {
        application.demoInitialized = true;
        application.appRoot = getDirectoryFromPath(getCurrentTemplatePath());
        application.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
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
        application.docsDir = application.appRoot & "data" & application.pathSep & "onboarding";

        application.ollamaBaseUrl = "http://localhost:11434";
        application.ollamaChatModel = "llama3.2";
        application.ollamaEmbeddingModel = "nomic-embed-text";
        application.vectorDimension = 384;
        application.vectorClient = "";
        application.lastAutoIngestAttempt = "";
        application.autoIngestMinSeconds = 30;
        application.cairoiConfig = {
            appId: "onboardiq",
            environment: "conference",
            collectorUrl: "https://adobecoldfusion.com/cairoi/api/telemetry.cfm",
            apiKey: "cairoi-onboardiq-dev-key",
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

        application.answerSchema = {
            "answer": "String",
            "refusal": "Boolean",
            "guardrailReason": "String?",
            "confidence": "String",
            "citations": ["String"],
            "suggestedQuestions": ["String"]
        };

        application.onboardingSteps = [
            {
                id: "welcome-paperwork",
                label: "Welcome and paperwork",
                phase: "Day 1",
                owner: "People Ops",
                items: [
                    "Confirm preferred name, address, emergency contact, and tax details.",
                    "Review the employment agreement, confidentiality terms, and acknowledgement forms.",
                    "Join the welcome session and meet the onboarding coordinator."
                ],
                prompts: [
                    "What paperwork is due today?",
                    "What should I bring to orientation?",
                    "Who do I contact if a form is wrong?"
                ]
            },
            {
                id: "it-setup",
                label: "IT setup and accounts",
                phase: "Day 1-2",
                owner: "IT Service Desk",
                items: [
                    "Activate SSO, multi-factor authentication, email, chat, and calendar.",
                    "Enroll the laptop in device management and confirm disk encryption.",
                    "Test VPN access and open a ticket for missing software."
                ],
                prompts: [
                    "How do I set up MFA?",
                    "What should I do if VPN fails?",
                    "Which tools are approved?"
                ]
            },
            {
                id: "team-introductions",
                label: "Team introductions",
                phase: "Day 3",
                owner: "Hiring Manager",
                items: [
                    "Meet your manager, buddy, and immediate project team.",
                    "Review team communication norms, working hours, and escalation paths.",
                    "Schedule recurring one-on-ones and join the team channels."
                ],
                prompts: [
                    "Who do I report to?",
                    "What should I ask my onboarding buddy?",
                    "How are team standups run?"
                ]
            },
            {
                id: "role-training",
                label: "Role training",
                phase: "Week 1",
                owner: "Team Lead",
                items: [
                    "Complete the role-specific learning path in the LMS.",
                    "Review job expectations, first-project goals, and quality standards.",
                    "Shadow a teammate and capture open questions for your manager."
                ],
                prompts: [
                    "What training is required this week?",
                    "How are first-week goals measured?",
                    "Where do I find role-specific learning?"
                ]
            },
            {
                id: "benefits-enrollment",
                label: "Benefits enrollment",
                phase: "Week 1",
                owner: "Benefits Team",
                items: [
                    "Choose health, dental, and vision coverage before the enrollment deadline.",
                    "Review PTO, company holidays, sick time, and leave policies.",
                    "Set retirement contribution preferences and beneficiary information."
                ],
                prompts: [
                    "How much vacation do I get?",
                    "When do health benefits start?",
                    "What is the retirement match?"
                ]
            },
            {
                id: "security-compliance",
                label: "Security and compliance",
                phase: "Week 2",
                owner: "Security",
                items: [
                    "Finish security awareness, privacy, code of conduct, and anti-harassment training.",
                    "Confirm clean desk, password manager, and sensitive-data handling practices.",
                    "Review how to report phishing, lost devices, or policy incidents."
                ],
                prompts: [
                    "How do I report phishing?",
                    "Can I store company files on a personal drive?",
                    "What training is mandatory?"
                ]
            },
            {
                id: "first-project",
                label: "First project",
                phase: "Week 2-3",
                owner: "Manager",
                items: [
                    "Review the first-project brief, success criteria, and expected milestones.",
                    "Confirm access to project repositories, documents, dashboards, and ceremonies.",
                    "Share a short weekly update with progress, risks, and support needed."
                ],
                prompts: [
                    "What should my first project brief include?",
                    "How often should I send updates?",
                    "What if I am blocked?"
                ]
            },
            {
                id: "check-ins",
                label: "30-day check-in",
                phase: "Day 30",
                owner: "Manager and People Ops",
                items: [
                    "Complete the new-hire pulse survey before the 30-day meeting.",
                    "Review accomplishments, blockers, training gaps, and role clarity.",
                    "Agree on next goals for the 60-day and 90-day milestones."
                ],
                prompts: [
                    "What happens in the 30-day check-in?",
                    "How should I prepare feedback?",
                    "When is probation reviewed?"
                ]
            }
        ];

        application.ingestStatus = {
            ready: false,
            sourceName: "Onboarding knowledge base",
            chunkCount: 0,
            addedCount: 0,
            ingestedAt: "",
            collectionName: "",
            embeddingProfile: "local",
            message: "Waiting for first startup ingestion."
        };

        refreshAiConfig();
    }

    private void function initializeSessionState() {
        session.onboardSessionId = rereplace(createUUID(), "[^A-Za-z0-9]", "", "all");
        session.selectedStepId = "welcome-paperwork";
        session.chatHistory = [];
        session.metrics = {
            requestCount: 0,
            totalTokens: 0,
            lastTokens: 0,
            lastLatencyMs: 0,
            lastModel: application.ollamaChatModel,
            lastGuardrailStatus: "none",
            lastRagCount: 0
        };
    }

    private void function refreshAiConfig() {
        application.chatConfig = {
            provider: "ollama",
            modelName: application.ollamaChatModel,
            baseUrl: application.ollamaBaseUrl,
            temperature: 0.2,
            maxTokens: 1100,
            timeout: 120
        };

        application.embeddingConfig = {
            provider: "ollama",
            embeddingModel: application.ollamaEmbeddingModel,
            baseUrl: application.ollamaBaseUrl,
            dimension: application.vectorDimension,
            metricType: "COSINE"
        };
    }

    private void function maybeAutoIngest() {
        if (application.ingestStatus.ready && isObject(application.vectorClient)) {
            return;
        }

        var shouldAttempt = true;
        if (isDate(application.lastAutoIngestAttempt)) {
            shouldAttempt = dateDiff("s", application.lastAutoIngestAttempt, now()) >= application.autoIngestMinSeconds;
        }

        if (!shouldAttempt) {
            return;
        }

        lock name="LLMRAGGuardrailAutoIngest" type="exclusive" timeout=2 {
            application.lastAutoIngestAttempt = now();
        }

        try {
            new onboardrag.OnboardingService().ensureIngested(false);
        } catch (any ingestError) {
            lock name="LLMRAGGuardrailIngestState" type="exclusive" timeout=10 {
                application.ingestStatus.ready = false;
                application.ingestStatus.message = "Auto-ingest is waiting: " & ingestError.message;
            }
        }
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
}
