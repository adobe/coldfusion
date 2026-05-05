docker Application
<cfdump var="#now()#" >
<cfset  a = "Hello, Docker!this is new text">
<cfoutput>#a#</cfoutput>
<cfset osComp = createObject("component", "osComp")>
<cfset b = osComp.someMethod()>
<cfoutput>#b#</cfoutput>    
<cfset  result = 5 + 10>
<cfoutput>#result#</cfoutput>
