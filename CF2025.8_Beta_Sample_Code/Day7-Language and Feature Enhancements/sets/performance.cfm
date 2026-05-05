<cfscript>
// BEFORE (Array approach)
startTime = getTickCount();
arrayData = [];
for (i = 1; i <= 100000; i++) {
    value = randRange(1, 5000);
    // Check if already exists (O(n) search)
    if (!arrayFind(arrayData, value)) {
        arrayAppend(arrayData, value);
    }
}
arrayTime = getTickCount() - startTime;
writeOutput("Array unique values: " & arrayTime & "ms");

// AFTER (Set approach)
startTime = getTickCount();
setData = SetNew();
for (i = 1; i <= 100000; i++) {
    value = randRange(1, 5000);
    // Automatic deduplication (O(1) add)
    setData.add(value);
}
setTime = getTickCount() - startTime;
writeOutput("<br>Set unique values: " & setTime & "ms");

writeOutput("<br>Set is " & numberFormat(arrayTime / setTime, "0.00") & "x faster");
// Typical result: Set is 50-100x faster for large datasets
</cfscript>