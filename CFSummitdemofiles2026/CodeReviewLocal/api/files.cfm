<cfsetting showdebugoutput="false">
<cfscript>
apiUtil = new codereview.ApiUtil();
reviewService = new codereview.ReviewService();

try {
    relativePath = structKeyExists(url, "path") ? url.path : "";
    listing = reviewService.listDirectory(relativePath);
    apiUtil.sendJson({ ok: true, path: listing.path, entries: listing.entries });
} catch (PathGuardError e) {
    apiUtil.sendJson({ ok: false, message: e.message }, val(e.errorCode ?: 400));
} catch (any error) {
    apiUtil.sendJson({ ok: false, message: "File listing failed: " & error.message }, 500);
}
</cfscript>
