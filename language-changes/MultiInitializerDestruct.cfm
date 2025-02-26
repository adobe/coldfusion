<cfscript>
arr = [100, 200, 300, 400, 500];
[firstVal, secondVal, ...rest] = arr;
 
writeDump(firstVal);
writeDump(secondVal);
//assigns [300, 400, 500] to rest
writeDump(rest);
</cfscript>