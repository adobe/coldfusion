 <cfscript>
            //variables.message  = ""
            testThreadName = "T1"
            thread action="run" name="#testThreadName#" {
                  count = 0;
                  while(!isThreadInterrupted(testThreadName)){
                        variables.message = count++;
                  }
                  writeOutput("Thread #testThreadName# interrupted. exiting.");
            }
            writeOutput(now() &"<br>");
            writeOutput("isInterrupted:" & isThreadInterrupted(testThreadName) & "<br>") //expect: no
            sleep(1000) //let the thread above startup.
            interruptThread(testThreadName);
            writeOutput(now() &"<br>");
            writeOutput("after interrupt, isInterrupted:" & isThreadInterrupted(testThreadName) & "<br>") //expect: yes
            
            thread action="join" name="#testThreadName#"{} // without this the status is intermittently RUNNING after interruption
            writeOutput("Thread #evaluate(testThreadName).NAME# is #evaluate(testThreadName).STATUS#<br>")
            writeOutput("Thread output: #evaluate(testThreadName).OUTPUT#<br>") // after join
      </cfscript>