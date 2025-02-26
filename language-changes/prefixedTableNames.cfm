<cfset myQuery = QueryNew('foo,bar','integer,varchar',[[40,'hello']]) >

<CFQUERY name="getQuery" dbtype="query">
select myQuery.foo +7 as res, myQuery.bar
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">
<cfset foo = getQuery.res>
<cfoutput>
<br>
#foo.toString()#
</cfoutput>