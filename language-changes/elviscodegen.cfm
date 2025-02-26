<cfscript>
	function getfoo() {
		writeoutput("inside foo : ");
		return "foo";	
	}
	function getbar() {
		writeoutput("inside bar :");
		return "bar";	
	}
	elvis = getbar() ?: "hello";
    writeOutput(elvis); 
	writeOutput("<br>");
	ternary = getbar() ? getfoo(): "hello";
    writeOutput(ternary);
</cfscript>

