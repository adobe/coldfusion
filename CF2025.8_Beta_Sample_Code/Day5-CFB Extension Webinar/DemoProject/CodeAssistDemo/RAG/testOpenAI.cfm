<cfscript>
testCfc = new ResponseEvaluationTest();
result = testCfc.runOpenAIResponseEvaluation();

writeOutput("<h3>OpenAI Response Evaluation Test</h3>");

if (result.success) {
    writeOutput("<p><strong>Status:</strong> <span style='color:green'>PASSED</span></p>");
} else {
    writeOutput("<p><strong>Status:</strong> <span style='color:red'>FAILED</span></p>");
}

writeOutput("<p><strong>Expected:</strong> #encodeForHTML(result.expected)#</p>");
writeOutput("<p><strong>Actual:</strong> #encodeForHTML(result.message)#</p>");
</cfscript>
