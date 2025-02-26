<cfscript>
		testThreadName = "thread-interrupt-action"
		thread action="run" name="#testThreadName#" {
			while(!isThreadInterrupted(testThreadName)){
				variables.message = "thread #testThreadName# running...";
			}
			variables.message &= "Thread interrupted. exiting.<br>";
		} 
		sleep(100) //allow the thread to start
		writeOutput("Before interrupt, isInterrupted:" & isThreadInterrupted(testThreadName) & "<br>")
		
        thread action="interrupt" name=testThreadName {}
        thread action="join" name=testThreadName {}
		writeOutput("After interrupt, isInterrupted:" & isThreadInterrupted(testThreadName) & "<br>")
		writeOutput(variables.message)
	</cfscript>
