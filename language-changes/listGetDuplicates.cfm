<cfscript>
  list1 = "one,one,ONE,two,three,,four,THREE,FOUR,FIVE,";
  newList1 = listgetduplicates(list=list1);
  writeOutput(newlist1)
</cfscript>

<cfscript> 
  list1 = "1, 2, 22, 3, 2, 5, 5, 1"; 
  newList1 = listgetduplicates(list=list1); 
  writeOutput(newlist1) 
</cfscript> 

<cfscript> 
  list1 = "1-2-22-3-2-5-5-1"; 
  newList1 = listgetduplicates(list=list1, delimiter="-"); 
  writeOutput(newlist1) 
</cfscript> 

<cfscript> 
  cityList = "San Jose:New York:Boston:Las Vegas::San Jose";
  newList1 = listgetduplicates(cityList, ":"); 
  writeOutput(newlist1) 
</cfscript>  