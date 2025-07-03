<cfset uploadDir = expandPath('./uploads/')>
<cfif NOT directoryExists(uploadDir)>
    <cfdirectory action="create" directory="#uploadDir#">
</cfif>

<cfif structKeyExists(form, "myFile") OR structKeyExists(form, "myFile[]")>
    <cffile action="uploadAll" filefield="myFile" destination="#uploadDir#" result="uploadResults"  nameconflict="overwrite">
    <cfoutput>
        <html><body style="font-family:Segoe UI,Tahoma,Geneva,Verdana,sans-serif;background:##f8f9fa;text-align:center;padding:40px;">
        <h2 style="color:##059669;">Files uploaded successfully!</h2>
        <ul style="list-style:none;">
        <cfloop array="#uploadResults#" index="f">
            <li><strong>File name:</strong> #f.serverFile#</li>
        </cfloop>
        </ul>
        <p><a href="SignOfferLetter.cfm">Upload more files</a></p>
        </body></html>
    </cfoutput>
<cfelse>
    <cfoutput>
        <html><body style="font-family:Segoe UI,Tahoma,Geneva,Verdana,sans-serif;background:##f8f9fa;text-align:center;padding:40px;">
        <h2 style="color:##dc2626;">No files uploaded.</h2>
        <p><a href="SignOfferLetter.cfm">Try again</a></p>
        </body></html>
    </cfoutput>
</cfif>