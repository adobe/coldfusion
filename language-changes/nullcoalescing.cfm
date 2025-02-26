<!---Elvis Operator--->
<!---<cfscript>
local.vals = [0, false, "no", null];
writeDump(local.vals.map(
function(val){
    return arguments.val ?? "true";
    }));
</cfscript>--->

<cfscript>
foo = rand("SHA1PRNG") ?: 'default string';
writeOutput(foo);
writeOutput("<br>");
baz = 0 ?: rand("SHA1PRNG");
writeOutput(baz);
</cfscript>