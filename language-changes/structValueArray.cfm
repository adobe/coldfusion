<cfscript>
       myStruct=StructNew("Ordered");
       myStruct.item1="Old Trafford";
       myStruct.item2="Anfield";
       myStruct.item3="Stamford Bridge";
       myStruct.item4="Villa Park";
       myStruct.item5="St James Park";
       myStruct.item6="Emirates Stadium";
       myStruct.item7="Etihad Stadium";
       
       // print the values as array- member function
       writeDump(myStruct.valueArray())
</cfscript>