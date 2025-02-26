<cfscript> 
 try { 
  //emp = CreateObject("Java", "Employees");
  val = 5/0; 
 }catch(DivideByZero|Expression ex) {
  WriteOutput("The application was unable to perform a required operation.<br> 
  Please try again later.<br> #ex.Message#<br>"); 
 } catch(any anyex) {
   WriteOutput(anyex.Message);
   writeOutput("Any Exception");
 } finally { 
 writeoutput("<br>Thank you for visiting our web site.<br>come back soon!"); 
 } 
</cfscript>


