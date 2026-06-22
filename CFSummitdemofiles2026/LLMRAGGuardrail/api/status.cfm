<cfsetting showdebugoutput="false" requesttimeout="300">
<cfscript>
apiUtil = new onboardrag.ApiUtil();
service = new onboardrag.OnboardingService();

try {
    service.ensureIngested(false);
    apiUtil.sendJson(service.getStatus());
} catch (any error) {
    statusCode = structKeyExists(error, "errorCode") ? val(error.errorCode) : 500;
    if (statusCode < 400) {
        statusCode = 500;
    }
    apiUtil.sendJson({
        ok: false,
        message: "Status failed: " & error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, statusCode);
}
</cfscript>
