<cfsetting showdebugoutput="false">
<cfscript>
apiUtil = new codereview.ApiUtil();
reviewService = new codereview.ReviewService();

try {
    relativePath = structKeyExists(url, "path") ? url.path : "";
    if (!len(trim(relativePath))) {
        apiUtil.sendJson({ ok: false, message: "path query parameter is required." }, 400);
    }

    filePayload = reviewService.readFile(relativePath);
    apiUtil.sendJson({ ok: true, file: filePayload });
} catch (PathGuardError e) {
    apiUtil.sendJson({ ok: false, message: e.message }, val(e.errorCode ?: 400));
} catch (ReviewFileError e) {
    apiUtil.sendJson({ ok: false, message: e.message }, val(e.errorCode ?: 400));
} catch (any error) {
    apiUtil.sendJson({ ok: false, message: "File read failed: " & error.message }, 500);
}
</cfscript>
