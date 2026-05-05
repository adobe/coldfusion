<cfscript>
// completeOnTimeout() - Graceful fallback with default value
writeOutput("<h3>completeOnTimeout() Demo</h3>");
writeOutput("<hr>");

writeOutput("<b>Test 1: Slow task (1000ms) with 500ms timeout</b><br><br>");

future = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(1000);
    return { shipping: "2-3 business days", thread: local.threadName, isDefault: false };
});

startTime = getTickCount();
result = future.completeOnTimeout({ shipping: "5-7 business days", isDefault: true }, 500).get();
elapsed = getTickCount() - startTime;

if (result.isDefault) {
    writeOutput("<span style='color:orange'><b>FALLBACK!</b> Used default value</span><br>");
} else {
    writeOutput("<span style='color:green'><b>ACTUAL!</b> Got real value</span><br>");
}
writeOutput("Shipping: " & result.shipping & "<br>");
writeOutput("Time: " & elapsed & "ms<br>");
</cfscript>
