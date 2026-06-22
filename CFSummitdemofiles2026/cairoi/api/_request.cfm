<cfscript>
function cairoiHeader(required string name, string fallback = "") {
    var requestData = getHttpRequestData();
    if (structKeyExists(requestData, "headers")) {
        for (var headerName in structKeyArray(requestData.headers)) {
            if (compareNoCase(headerName, arguments.name) == 0) {
                return toString(requestData.headers[headerName]);
            }
        }
    }
    return arguments.fallback;
}

function cairoiRequestOrigin() {
    return trim(cairoiHeader("Origin", ""));
}

function cairoiAllowedOrigins() {
    if (structKeyExists(application, "cairoiCorsAllowedOrigins") && isArray(application.cairoiCorsAllowedOrigins)) {
        return application.cairoiCorsAllowedOrigins;
    }
    return [];
}

function cairoiOriginAllowed(required string origin) {
    if (!len(trim(arguments.origin))) {
        return false;
    }
    for (var allowedOrigin in cairoiAllowedOrigins()) {
        if (compareNoCase(trim(allowedOrigin), trim(arguments.origin)) == 0) {
            return true;
        }
    }
    return false;
}

function cairoiApplyCors(string methods = "GET,POST,OPTIONS") {
    if (!structKeyExists(application, "cairoiCorsEnabled") || !application.cairoiCorsEnabled) {
        return;
    }

    var origin = cairoiRequestOrigin();
    if (cairoiOriginAllowed(origin)) {
        cfheader(name = "Access-Control-Allow-Origin", value = origin);
        cfheader(name = "Vary", value = "Origin");
        cfheader(name = "Access-Control-Allow-Methods", value = arguments.methods);
        cfheader(name = "Access-Control-Allow-Headers", value = application.cairoiCorsAllowedHeaders ?: "Content-Type,Accept,X-CAIROI-API-Key,Authorization");
        cfheader(name = "Access-Control-Max-Age", value = "600");
    }
}

function cairoiHandleOptions(string methods = "GET,POST,OPTIONS") {
    cairoiApplyCors(arguments.methods);
    if (compareNoCase(cgi.request_method, "OPTIONS") == 0) {
        cfheader(statuscode = 204);
        cfcontent(type = "text/plain; charset=utf-8", reset = true);
        abort;
    }
}

function cairoiBearerToken() {
    var authHeader = trim(cairoiHeader("Authorization", ""));
    if (len(authHeader) > 7 && compareNoCase(left(authHeader, 7), "Bearer ") == 0) {
        return trim(mid(authHeader, 8, len(authHeader) - 7));
    }
    return "";
}

function cairoiTelemetryApiKey() {
    var apiKey = trim(cairoiHeader("X-CAIROI-API-Key", ""));
    if (len(apiKey)) {
        return apiKey;
    }
    return cairoiBearerToken();
}

function cairoiPublicBaseUrl() {
    if (structKeyExists(application, "cairoiPublicBaseUrl")) {
        return application.cairoiPublicBaseUrl;
    }
    return "";
}

function cairoiTraceUrl(required string traceId) {
    return len(cairoiPublicBaseUrl())
        ? cairoiPublicBaseUrl() & "/dashboard/trace.cfm?traceId=" & urlEncodedFormat(arguments.traceId)
        : "";
}

function cairoiDashboardUrl() {
    return len(cairoiPublicBaseUrl())
        ? cairoiPublicBaseUrl() & "/dashboard/index.cfm"
        : "";
}

function cairoiMaxTelemetryBytes() {
    return structKeyExists(application, "cairoiMaxTelemetryBytes")
        ? val(application.cairoiMaxTelemetryBytes)
        : 262144;
}
</cfscript>
