<cfscript>
// asyncAllOf() - Wait for all futures to complete
writeOutput("<h3>asyncAllOf() Demo</h3>");
writeOutput("<hr>");

// Create parallel futures
future1 = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(200);
    return { data: "Profile Data", thread: local.threadName, time: 500 };
});

future2 = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(300);
    return { data: "Activity Data", thread: local.threadName, time: 300 };
});

future3 = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(200);
    return { data: "Notifications", thread: local.threadName, time: 200 };
});

//Executing AsycnAllOf
startTime = getTickCount();
result = asyncAllOf([future1, future2, future3]).get();
elapsed = getTickCount() - startTime;

//Fetch the Results
result1 = future1.get();
result2 = future2.get();
result3 = future3.get();

//Print Information after Completion
writeOutput("Task 1: " & result1.data & " on Thread " & result1.thread & " (" & result1.time & "ms)<br>");
writeOutput("Task 2: " & result2.data & " on Thread " & result2.thread & " (" & result2.time & "ms)<br>");
writeOutput("Task 3: " & result3.data & " on Thread " & result3.thread & " (" & result3.time & "ms)<br>");

writeOutput("All Tasks Completed");
writeOutput("Total time: " & elapsed & "ms (parallel)<br>");
</cfscript>
