<cfif NOT fileExists(expandPath("../OfferLetter_Signed.pdf"))>
    <cfset errorMessage = "Signed offer letter not found. Please complete previous steps first.">
<cfelse>
    <cfset encryptionPassword = "peopleForge">
    <cfpdf action="protect" 
           source="../OfferLetter_Signed.pdf" 
           destination="../OfferLetter_Encrypted.pdf"
           newuserpassword="#encryptionPassword#"
           newownerpassword="peopleForgeOwner"
           permissions="all"
           encrypt="AES_128"
           overwrite="yes">
    <cfset successMessage = "Offer letter successfully encrypted with password protection!">
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PDF Encryption & Protection</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f8fafc;
        }
        .container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        .error-box {
            background: #fef2f2;
            border: 1px solid #fca5a5;
            color: #dc2626;
            padding: 20px;
            text-align: center;
        }
        .pdf-container {
            padding: 0;
            height: 100vh;
        }
        .pdf-iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <cfif isDefined("errorMessage")>
            <div class="error-box">
                <h3>❌ Encryption Failed</h3>
                <p><cfoutput>#errorMessage#</cfoutput></p>
                <p style="margin-top: 15px; font-size: 14px;">Please ensure the digitally signed document exists before applying encryption.</p>
            </div>
        <cfelseif isDefined("successMessage")>
            <div class="pdf-container">
                <iframe src="../OfferLetter_Encrypted.pdf" 
                        class="pdf-iframe"
                        title="Encrypted PDF">
                    <p>Your browser doesn't support PDF viewing. <a href="../OfferLetter_Encrypted.pdf" target="_blank">Download the encrypted PDF</a></p>
                </iframe>
            </div>
        </cfif>
    </div>
</body>
</html>
