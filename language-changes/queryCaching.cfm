<cfset application.cachetm = CreateOdbcDateTime(dateformat(now(),'yyyy-mm-dd') & ' 15:55:20')/>

<cfquery datasource="cfartgallery" name="RS" cachemaxidletime="#createtimespan(0,0,0,5)#" cachedafter="#application.cachetm#" MAXROWS="1">
select * from ART
</cfquery>

<cfdump var ="#RS#">
<cfoutput>#now()#</cfoutput>