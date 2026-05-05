<cfscript>
try {
        throw(message="Custom message", type="Expression");
        writeOutput("[PASS] <br>");
    } catch (any e) {
        writeOutput("[FAIL]  #e.message# (#e.type#)<br>");
    }
</cfscript>
