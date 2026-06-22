<cfsetting showdebugoutput="false" requesttimeout="300">
<cfscript>
apiUtil = new onboardrag.ApiUtil();
service = new onboardrag.OnboardingService();

try {
    if (cgi.request_method != "POST") {
        apiUtil.sendJson({ ok: false, message: "POST required." }, 405);
    }

    payload = apiUtil.getRequestJson();
    result = service.ask(payload);

    apiUtil.sendJson({
        ok: true,
        answer: result.answer,
        refusal: result.refusal,
        guardrailReason: result.guardrailReason,
        confidence: result.confidence,
        citations: result.citations,
        suggestedQuestions: result.suggestedQuestions,
        sources: result.sources,
        usage: result.usage,
        trace: result.trace,
        metrics: result.metrics,
        memory: result.memory,
        history: result.history
    });
} catch (any error) {
    statusCode = structKeyExists(error, "errorCode") ? val(error.errorCode) : 500;
    if (statusCode < 400) {
        statusCode = 500;
    }
    apiUtil.sendJson({
        ok: false,
        message: error.message,
        detail: structKeyExists(error, "detail") ? error.detail : ""
    }, statusCode);
}
</cfscript>
