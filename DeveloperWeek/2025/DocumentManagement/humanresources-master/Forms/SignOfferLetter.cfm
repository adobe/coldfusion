<cfif NOT fileExists(expandPath("../OfferLetter_Watermarked.pdf"))>
    <cfset errorMessage = "Watermarked offer letter not found. Please complete previous steps first.">
<cfelse>
    <cfpdf action="sign" 
           source="../OfferLetter_Watermarked.pdf" 
           destination="../OfferLetter_Signed.pdf"
           keystore="#ExpandPath('../keys/CFUser1.jks')#" 
           keystorepassword="coldfusion" 
           keyalias="1" 
           keypassword="coldfusion"  
           position="100,100" 
           height="50"
           width="120"
           overwrite="yes">
    <cfset successMessage = "Offer letter digitally signed successfully!">
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Digital Signature Application</title>
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
                <h3>❌ Digital Signing Failed</h3>
                <p><cfoutput>#errorMessage#</cfoutput></p>
                <p style="margin-top: 15px; font-size: 14px;">Please ensure the watermarked document exists before applying digital signatures.</p>
            </div>
        <cfelseif isDefined("successMessage")>
            <div class="pdf-container">
                <iframe src="../OfferLetter_Signed.pdf" 
                        class="pdf-iframe"
                        title="Signed PDF">
                    <p>Your browser doesn't support PDF viewing. <a href="../OfferLetter_Signed.pdf" target="_blank">Download the signed PDF</a></p>
                </iframe>
            </div>
        </cfif>
    </div>
</body>
</html>
