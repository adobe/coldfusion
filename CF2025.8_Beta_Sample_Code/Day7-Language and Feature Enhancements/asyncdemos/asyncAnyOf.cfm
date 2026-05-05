<cfscript>
// asyncAnyOf() - Return first completed future
writeOutput("<h3>asyncAnyOf() Demo</h3>");
writeOutput("<hr>");

// Create parallel futures with different speeds
future1 = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(50);
    return { data: "Data from Local Cache", thread: local.threadName, source: "Local Cache", time: 50 };
});

future2 = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(10);
    return { data: "Data from Redis", thread: local.threadName, source: "Redis", time: 10 };
});

future3 = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(500);
    return { data: "Data from Database", thread: local.threadName, source: "Database", time: 500 };
});

//Executing AsyncAnyOf
startTime = getTickCount();
result = asyncAnyOf([future1, future2, future3]).get();
elapsed = getTickCount() - startTime;

//Response Received 
writeOutput("Source: " & result.source & "<br>");
writeOutput("Source: " & result.thread & "<br>");
writeOutput("Source: " & result.data & "<br>");
writeOutput("Total Time: " & elapsed & "ms (fastest wins)<br>");
</cfscript>
