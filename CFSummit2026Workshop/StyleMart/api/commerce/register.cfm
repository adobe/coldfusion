<cfscript>
try {
    restInitApplication(expandPath("."), "commerce");
    writeOutput("REST service 'commerce' registered successfully at: " & expandPath("."));
} catch (any e) {
    writeOutput("Error: " & e.message & "<br>" & e.detail);
}
</cfscript>
