<cfscript>
	variables.message = "start...<br>"
	testThreadName = "test-thread1"
    e = ""
	thread action="run" name="#testThreadName#" {
	    loopcount = 10;
        for(count=0; count <= 5;count++){
			variables.message &= count & ",";
        }
        variables.message &= "Thread NOT interrupted. count-#count# exiting...";
	} 
    try{
        thread action="terminate" name="#testThreadName#"{}
    }
    catch(any e){
        writeoutput(e.message & "<br>")
        writeoutput(e.Method & "<br>")
    }
</cfscript>