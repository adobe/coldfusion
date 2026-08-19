<cfscript>
try {
    restInitApplication(expandPath("."), "logistics");
    writeOutput("REST service 'logistics' registered at: " & expandPath("."));
} catch (any e) {
    writeOutput("Error: " & e.message & "<br>" & e.detail);
}
</cfscript>
