<cfscript>
    restInitApplication(expandPath("."), "agent");
    writeOutput("REST service 'agent' registered successfully at: " & expandPath("."));
</cfscript>
