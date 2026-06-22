<cfsetting showdebugoutput="false" requesttimeout="300">
<cfscript>
apiUtil = new onboardrag.ApiUtil();
service = new onboardrag.OnboardingService();

try {
    if (cgi.request_method != "POST") {
        apiUtil.sendJson({ ok: false, message: "POST required." }, 405);
    }

    apiUtil.sendJson(service.resetKnowledgeBase());
} catch (any error) {
    statusCode = structKeyExists(error, "errorCode") ? val(error.errorCode) : 500;
    if (statusCode < 400) {
        statusCode = 500;
    }
    apiUtil.sendJson({
        ok: false,
        message: "Reset failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, statusCode);
}
</cfscript>
