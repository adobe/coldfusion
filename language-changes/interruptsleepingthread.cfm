<cfscript>
        threadName = "T2"
        variables.message = ""
        variables.errMessage = ""
        thread action="run" name="#threadName#" {
            try {
                sleep(10000)
                variables.message &= "back from long sleep uninterrupted.<br>"; //this should NOT be reachable.
            }
            catch (any ie) { //com.adobe.coldfusion.ThreadInterruptedException
                variables.message &= "thread #threadName# was interrupted.<br>"
                variables.message &= "thread state for #evaluate(threadName).NAME# is #evaluate(threadName).STATUS#.<br>"
                variables.errMessage &= serializeJSON(ie)
            }
        } 
        sleep(1000)
        writeOutput("Before interrupt...<br>Thread #evaluate(threadName).NAME# is #evaluate(threadName).STATUS#<br>")
        interruptThread(threadName);
        
        sleep(1000)
        writeOutput("After interrupt...<br>Thread #evaluate(threadName).NAME# is #evaluate(threadName).STATUS#<br>")
        writeOutput(variables.message)
        writeOutput("isInterrupted:" & isThreadInterrupted(threadName) & "<br>")
        
        exceptionStruct = deserializeJSON(variables.errMessage)
        writeOutput("exception message:" & exceptionStruct.MESSAGE & "<br>")
        writeOutput("exception type:" & exceptionStruct.TYPE & "<br>")
        
    </cfscript>