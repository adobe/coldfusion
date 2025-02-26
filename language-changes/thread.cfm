<cfscript>
        testThread1 = "TH1"
        testThread2 = "TH2"
        variables.t1msg = ""
        variables.t2msg = ""
		thread action="run" name="#testThread1#" {
			writeOutput("#thread.name# started.<br>") 
            while(!threadInterrupted()){
                variables.t1msg = "Thread #thread.name# isInterrupted:" & isThreadInterrupted(testThread1) & "." ///5
            }
			writeOutput("Thread #thread.name# exiting.<br>") 
		} 
        sleep(300)
        writeOutput("Thread #evaluate(testThread1).NAME# is #evaluate(testThread1).STATUS#.<br>") ////1
        //writeOutput("#evaluate(testThread1).NAME# Output: #evaluate(testThread1).Output#<br>") //.. doesnt output anything.. expected?.. maybe because the thread is not finished running.
        thread action="run" name="#testThread2#" {
            try{
                variables.t2msg &= "interrupting #testThread1#..."  ///6
                writeOutput("In #thread.name#,<br>#testThread1# isInterrupted:#isThreadInterrupted(testThread1)#; status:#evaluate(testThread1).STATUS#.<br>")
                interruptThread(testThread1);
            }
            catch(any e){
                writeOutput("error interrupting. #e.message#<br>");
                writeDump(e);
                variables.t2msg &= "error interrupting #testThread1#: #e.message#"
                cfthrow(message="this is not expected", type="myexception")
            }
		} 
        
        thread action="join" name="#testThread2#,#testThread1#"{}       
        writeOutput("Thread #evaluate(testThread1).NAME# is #evaluate(testThread1).STATUS#.<br>") ///2
        writeOutput("Thread #evaluate(testThread1).NAME# Output:#evaluate(testThread1).Output#") ///3
		
        writeOutput("#evaluate(testThread2).NAME#; status:#evaluate(testThread2).STATUS#; Output:#evaluate(testThread2).Output#") ///4
        writeOutput("#testThread1#: " & variables.t1msg & "<br>")
        writeOutput("#testThread2#: " & variables.t2msg & "<br>")
    </cfscript>
        
    <cf_expectedresults>
        <cfscript>
            writeOutput("Thread #testThread1# is RUNNING.<br>") ///1
            writeOutput("Thread #testThread1# is COMPLETED.<br>") ///2
            writeOutput("Thread #testThread1# Output:#testThread1# started.<br>Thread #testThread1# exiting.<br>") ///3
            writeOutput("#testThread2#; status:COMPLETED; Output:In #testThread2#,<br>#testThread1# isInterrupted:NO; status:RUNNING.<br>") ///4
            writeOutput("#testThread1#: Thread #testThread1# isInterrupted:NO.<br>") ///5 /// returns NO sometimes
            writeOutput("#testThread2#: interrupting #testThread1#...<br>")
            //writeOutput("isInterrupted:" & isThreadInterrupted(testThread1) & "<br>")
        </cfscript>