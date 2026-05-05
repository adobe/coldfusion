<cfscript>
// thenCombine() - Combine results from two futures
writeOutput("<h3>thenCombine() Demo</h3>");
writeOutput("<hr>");

// Future 1: Get product price
priceFuture = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(300);
    return { value: 100, thread: local.threadName, time: 300 };
});

// Future 2: Get user discount
discountFuture = runAsync(() => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    sleep(200);
    return { value: 0.15, thread: local.threadName, time: 200 };
});

// Combine both results
startTime = getTickCount();
combined = priceFuture.thenCombine(discountFuture, (priceResult, discountResult) => {
    local.threadName = createObject("java", "java.lang.Thread").currentThread().getName();
    return {
        finalPrice: priceResult.value * (1 - discountResult.value),
        priceThread: priceResult.thread,
        discountThread: discountResult.thread,
        combineThread: local.threadName
    };
}).get();
elapsed = getTickCount() - startTime;

writeOutput("Price fetched on thread: " & combined.priceThread & " (300ms)<br>");
writeOutput("Discount fetched on thread: " & combined.discountThread & " (200ms)<br>");
writeOutput("Combined on thread: " & combined.combineThread & "<br>");
writeOutput("<br><b>Combined result ready!</b><br>");
writeOutput("Total time: " & elapsed & "ms (parallel execution)<br>");
writeOutput("Final Price: $" & combined.finalPrice & "<br>");
</cfscript>
