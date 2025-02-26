<cfscript>
arrayVar = [
  {name: "Hank"},
  {name: "Dale"},
];
 writedump(arrayVar)
 </cfscript>

 <cfscript>
   o = {
  p: 42,
  q: true,
};

({ p, q, } = o);
writedump(p)
</cfscript>