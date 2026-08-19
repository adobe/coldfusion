<cfscript>
try {
    restInitApplication(expandPath("."), "agent");
    writeOutput("REST service 'agent' registered successfully at: " & expandPath("."));
} catch (any e) {
    writeOutput("Error: " & e.message & "<br>" & e.detail);
}
</cfscript>
