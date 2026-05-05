<cfscript>
	throw (message="Message for my Exception ", 
    type="etype2", 
    detail="Forcefully throwing Exception")
	writeOutput("Completed the WorkFlow");
</cfscript>
