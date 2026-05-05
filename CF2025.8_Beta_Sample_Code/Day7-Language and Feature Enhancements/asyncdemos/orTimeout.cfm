<cfscript>
// orTimeout() - Fail fast with exception

writeOutput("<h3>orTimeout() Demo</h3>");
writeOutput("<hr>");

// Test 1: Slow operation (will timeout)
writeOutput("<b>Test 1: Slow task (2000ms) with 1000ms timeout</b><br><br>");

future = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(2000);
    return { data: "Exception", thread: local.threadName };
});

try {
    startTime = getTickCount();
    result = future.orTimeout(1000).get();
    elapsed = getTickCount() - startTime;
    writeOutput("<span style='color:green'>SUCCESS: " & result.data & " on " & result.thread & " (" & elapsed & "ms)</span><br>");
} catch (any e) {
    elapsed = getTickCount() - startTime;
    writeOutput("<span style='color:red'><b>TIMEOUT!</b> Task exceeded limit " & elapsed & "ms</span><br>");
    writeOutput("Exception: " & e.message & "<br>");
}

future = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(500);
    return { data: "Payment Success ", thread: local.threadName };
});

try {
    startTime = getTickCount();
    result = future.orTimeout(1000).get();
    elapsed = getTickCount() - startTime;
    writeOutput("<span style='color:green'>SUCCESS: " & result.data & " on " & result.thread & " (" & elapsed & "ms)</span><br>");
    writeOutput("Thread: " & result.thread & "<br>")
    writeOutput("Time : " & elapsed & "<br>")
} catch (any e) {
    elapsed = getTickCount() - startTime;
    writeOutput("<span style='color:red'><b>TIMEOUT!</b> Task exceeded limit " & elapsed & "ms</span><br>");
    writeOutput("Exception: " & e.message & "<br>");
}

writeOutput("<hr>");
</cfscript>
