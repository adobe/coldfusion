<cfset test = queryNew("qtyOnHand,qty1,qty2",
 "CF_SQL_INTEGER,CF_SQL_INTEGER,CF_SQL_INTEGER")>
<cfset newrow = queryaddrow(test, 1)>
<cfset temp = querysetcell(test, "qtyOnHand", "96", 1)>
<cfset temp = querysetcell(test, "qty1", "64", 1)>
<cfset temp = querysetcell(test, "qty2", "32", 1)>
<cfquery name = "test" dbtype = "query">
    select qtyOnHand-qty1-qty2 as qty3 FROM test
</cfquery>
<cfdump var="#test#" >