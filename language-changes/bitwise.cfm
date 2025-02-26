<cfset myQuery = QueryNew('foo,bar','integer,integer',[[3,2]]) >

<cfdump var="#myQuery#">

<CFQUERY name="getQuery" dbtype="query">
select foo^bar as bitwiseXorRes,bar
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">


<cfset myQuery = QueryNew('foo,bar','integer,integer',[[3,2]]) >

<CFQUERY name="getQuery" dbtype="query">
select foo&bar as bitwiseAndRes,bar
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">

<cfset myQuery = QueryNew('foo,bar','integer,integer',[[3,2]]) >

<CFQUERY name="getQuery" dbtype="query">
select ~foo as bitwiseNotRes,bar
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">

<cfset myQuery = QueryNew('foo,bar','integer,integer',[[3,2]]) >

<CFQUERY name="getQuery" dbtype="query">
select foo|bar as bitwiseOrRes,bar
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">

<cfset myQuery = QueryNew('foo,bar','integer,integer',[[3,2]]) >

<CFQUERY name="getQuery" dbtype="query">
select bar<<1 as bitwiseLeftShift
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">
<cfset myQuery = QueryNew('foo,bar','integer,integer',[[3,2]]) >

<CFQUERY name="getQuery" dbtype="query">
select bar>>1 as bitwiseRightShift,bar
from myQuery
</CFQUERY>

<cfdump var="#getQuery#">