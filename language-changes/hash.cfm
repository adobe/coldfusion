<cfscript>
    string="This is a string to be encoded."
    writeOutput(hash(string=string, algorithm="SHA-256", encoding="UTF-8",outputEncoding="base64"))
</cfscript>