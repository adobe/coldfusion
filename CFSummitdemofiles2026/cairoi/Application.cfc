component {
    variables.appRoot = getDirectoryFromPath(getCurrentTemplatePath());
    variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
    variables.publicBaseUrl = "https://adobecoldfusion.com/cairoi";
    variables.diagnosticToken = "cairoi-diagnostics-2026";

    this.name = "CAIROITrackerMVP";
    this.applicationTimeout = createTimeSpan(0, 4, 0, 0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 10, 0);
    this.setClientCookies = true;
    this.mappings["/cairoi"] = variables.appRoot;
    this.mappings["/CAIROI"] = variables.appRoot;

    public boolean function onApplicationStart() {
        initializeCairoi();
        return true;
    }

    public void function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reloadApp") && url.reloadApp == "1") {
            applicationStop();
            location(url = cgi.script_name, addToken = false);
        }

        if (listLast(arguments.targetPage, "/\") == "diagnostics.cfm") {
            return;
        }

        if (!structKeyExists(application, "cairoiConfig")) {
            initializeCairoi();
        }
    }

    public void function onError(required any exception, string eventName = "") {
        var errorId = replace(createUUID(), "-", "", "all");
        var payload = buildErrorPayload(arguments.exception, arguments.eventName, errorId);

        writeDiagnosticLog(payload);

        if (isApiRequest()) {
            cfheader(statuscode = 500);
            cfcontent(type = "application/json; charset=utf-8", reset = true);
            writeOutput(serializeJSON({
                ok: false,
                error: "cairoi_application_error",
                errorId: errorId,
                message: sanitizeText(readExceptionValue(arguments.exception, "message", "CAIROI request failed."), 500),
                diagnostics: "Open /CAIROI/diagnostics.cfm?token=" & variables.diagnosticToken & " for details."
            }));
            abort;
        }

        cfheader(statuscode = 500);
        cfcontent(type = "text/html; charset=utf-8", reset = true);
        writeOutput(renderErrorPage(payload, shouldShowDiagnostics()));
        abort;
    }

    private void function initializeCairoi() {
        application.cairoiRoot = variables.appRoot;
        application.cairoiDataRoot = variables.appRoot & "data" & variables.pathSep;
        application.cairoiDbParentPath = application.cairoiDataRoot & "derby" & variables.pathSep;
        application.cairoiDatabasePath = application.cairoiDbParentPath & "cairoi";
        application.cairoiDsn = "embedded-derby";
        application.cairoiDbConfig = {
            appRoot: variables.appRoot,
            dataRoot: application.cairoiDataRoot,
            dbParentPath: application.cairoiDbParentPath,
            databasePath: application.cairoiDatabasePath
        };
        application.cairoiDb = new cairoi.db.DerbyStore(application.cairoiDbConfig);
        application.cairoiPublicBaseUrl = trimTrailingSlash(variables.publicBaseUrl);
        application.cairoiTelemetryUrl = application.cairoiPublicBaseUrl & "/api/telemetry.cfm";
        application.cairoiDashboardUrl = application.cairoiPublicBaseUrl & "/dashboard/index.cfm";
        application.cairoiTraceUrl = application.cairoiPublicBaseUrl & "/dashboard/trace.cfm";
        application.cairoiCorsEnabled = true;
        application.cairoiCorsAllowedOrigins = [
            "https://adobecoldfusion.com",
            "http://adobecoldfusion.com",
            "http://localhost:8500",
            "http://127.0.0.1:8500"
        ];
        application.cairoiCorsAllowedHeaders = "Content-Type,Accept,X-CAIROI-API-Key,Authorization";
        application.cairoiMaxTelemetryBytes = 262144;
        application.cairoiDevApiKey = "cairoi-dev-key";
        application.cairoiDevApiKeyHash = "cd26c5b1cb98378f63601ce3ea019fed5c9dba1ba9dcbf28146cd0df37adba45";
        application.cairoiInventoryDevApiKey = "cairoi-inventory-dev-key";
        application.cairoiInventoryDevApiKeyHash = "ea3a8732b8f36dafe7b1724dc6acda7c43282e248efd9e38d39a119f2a56031b";
        application.cairoiDemoDevApiKeys = {
            "demo-app": application.cairoiDevApiKey,
            "inventory-ai": application.cairoiInventoryDevApiKey,
            "cfcase": "cairoi-cfcase-dev-key",
            "onboardiq": "cairoi-onboardiq-dev-key",
            "donut-rag": "cairoi-donut-rag-dev-key",
            "code-review-local": "cairoi-code-review-dev-key"
        };
        application.cairoiConfig = {
            dsn: application.cairoiDsn,
            devApiKey: application.cairoiDevApiKey,
            devApiKeyHash: application.cairoiDevApiKeyHash,
            inventoryDevApiKey: application.cairoiInventoryDevApiKey,
            inventoryDevApiKeyHash: application.cairoiInventoryDevApiKeyHash,
            demoDevApiKeys: application.cairoiDemoDevApiKeys,
            appRoot: variables.appRoot,
            databasePath: application.cairoiDatabasePath,
            databaseType: "embedded-derby",
            publicBaseUrl: application.cairoiPublicBaseUrl,
            telemetryUrl: application.cairoiTelemetryUrl,
            dashboardUrl: application.cairoiDashboardUrl,
            traceUrl: application.cairoiTraceUrl,
            corsAllowedOrigins: application.cairoiCorsAllowedOrigins,
            maxTelemetryBytes: application.cairoiMaxTelemetryBytes
        };
    }

    private string function trimTrailingSlash(required string value) {
        var text = trim(arguments.value);
        while (len(text) > 1 && right(text, 1) == "/") {
            text = left(text, len(text) - 1);
        }
        return text;
    }

    private boolean function shouldShowDiagnostics() {
        return structKeyExists(url, "token") && url.token == variables.diagnosticToken;
    }

    private boolean function isApiRequest() {
        return structKeyExists(cgi, "script_name") && findNoCase("/api/", cgi.script_name);
    }

    private struct function buildErrorPayload(required any exception, required string eventName, required string errorId) {
        return {
            errorId: arguments.errorId,
            eventName: arguments.eventName,
            occurredAt: dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            scriptName: structKeyExists(cgi, "script_name") ? cgi.script_name : "",
            pathInfo: structKeyExists(cgi, "path_info") ? cgi.path_info : "",
            queryString: sanitizeText(structKeyExists(cgi, "query_string") ? cgi.query_string : "", 1000),
            httpHost: structKeyExists(cgi, "http_host") ? cgi.http_host : "",
            requestMethod: structKeyExists(cgi, "request_method") ? cgi.request_method : "",
            templatePath: getCurrentTemplatePath(),
            appRoot: variables.appRoot,
            dataRoot: variables.appRoot & "data" & variables.pathSep,
            cfVersion: structKeyExists(server, "coldfusion") && structKeyExists(server.coldfusion, "productVersion") ? server.coldfusion.productVersion : "",
            osName: structKeyExists(server, "os") && structKeyExists(server.os, "name") ? server.os.name : "",
            exception: exceptionSummary(arguments.exception)
        };
    }

    private struct function exceptionSummary(required any exception) {
        return {
            type: sanitizeText(readExceptionValue(arguments.exception, "type", ""), 300),
            message: sanitizeText(readExceptionValue(arguments.exception, "message", ""), 1000),
            detail: sanitizeText(readExceptionValue(arguments.exception, "detail", ""), 2000),
            tagContext: summarizeTagContext(arguments.exception)
        };
    }

    private array function summarizeTagContext(required any exception) {
        var rows = [];
        if (isStruct(arguments.exception) && structKeyExists(arguments.exception, "tagContext") && isArray(arguments.exception.tagContext)) {
            for (var item in arguments.exception.tagContext) {
                arrayAppend(rows, {
                    template: sanitizeText(structKeyExists(item, "template") ? item.template : "", 500),
                    line: structKeyExists(item, "line") ? item.line : "",
                    column: structKeyExists(item, "column") ? item.column : "",
                    codePrintHTML: sanitizeText(structKeyExists(item, "codePrintHTML") ? item.codePrintHTML : "", 1000)
                });
                if (arrayLen(rows) >= 12) {
                    break;
                }
            }
        }
        return rows;
    }

    private string function readExceptionValue(required any exception, required string key, string fallback = "") {
        if (isStruct(arguments.exception) && structKeyExists(arguments.exception, arguments.key)) {
            return toString(arguments.exception[arguments.key]);
        }
        return arguments.fallback;
    }

    private void function writeDiagnosticLog(required struct payload) {
        try {
            var logDir = variables.appRoot & "data" & variables.pathSep & "logs" & variables.pathSep;
            if (!directoryExists(logDir)) {
                directoryCreate(logDir, true, true);
            }
            fileWrite(
                logDir & "cairoi-error-" & arguments.payload.errorId & ".json",
                serializeJSON(arguments.payload),
                "utf-8"
            );
        } catch (any ignored) {
        }
    }

    private string function renderErrorPage(required struct payload, required boolean includeDetails) {
        var html = '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>CAIROI Error</title>';
        html &= '<style>body{font-family:Arial,sans-serif;margin:32px;line-height:1.4;color:##18212f}code,pre{background:##f4f6f8;border:1px solid ##d7dde5;border-radius:6px;padding:12px;display:block;white-space:pre-wrap}dt{font-weight:700;margin-top:10px}.muted{color:##5f6b7a}</style>';
        html &= '</head><body><h1>CAIROI Error</h1>';
        html &= '<p>CAIROI caught an application error. Error id: <strong>' & escapeHtml(arguments.payload.errorId) & '</strong></p>';
        html &= '<p class="muted">A diagnostic JSON file was written under <code>data/logs</code> if the app can write there.</p>';

        if (arguments.includeDetails) {
            html &= '<h2>Diagnostic Details</h2><pre>' & escapeHtml(serializeJSON(arguments.payload)) & '</pre>';
        } else {
            html &= '<p>To show details temporarily, open this same URL with <code>?token=' & escapeHtml(variables.diagnosticToken) & '</code>. Remove this diagnostic helper after troubleshooting.</p>';
        }

        html &= '</body></html>';
        return html;
    }

    private string function sanitizeText(required string value, numeric maxLength = 1000) {
        var text = replace(arguments.value, chr(13), " ", "all");
        text = replace(text, chr(10), " ", "all");
        text = rereplace(text, "(?i)(authorization|api[-_ ]?key|bearer|token|password|secret)([=: ]+)[^&\s<,}]+", "\1\2[redacted]", "all");
        if (len(text) > arguments.maxLength) {
            text = left(text, arguments.maxLength) & "...";
        }
        return text;
    }

    private string function escapeHtml(required string value) {
        var text = replace(arguments.value, "&", "&amp;", "all");
        text = replace(text, "<", "&lt;", "all");
        text = replace(text, ">", "&gt;", "all");
        text = replace(text, chr(34), "&quot;", "all");
        text = replace(text, chr(39), "&##39;", "all");
        return text;
    }
}
