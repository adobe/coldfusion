<cfif NOT fileExists(expandPath("../OfferLetter_Edited.pdf"))>
    <cfset errorMessage = "Edited offer letter not found. Please complete previous steps first.">
<cfelse>
    <cfpdf action="addwatermark" 
           source="../OfferLetter_Edited.pdf" 
           destination="../OfferLetter_Watermarked.pdf" 
           image="Watermark_confidential.png"
           foreground="yes"
           overwrite="yes">
    <cfset successMessage = "Company watermark successfully applied to all pages!">
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Add PDF Watermark</title>
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
                <h3>❌ Watermark Application Failed</h3>
                <p><cfoutput>#errorMessage#</cfoutput></p>
                <p style="margin-top: 15px; font-size: 14px;">Please complete the previous steps in the workflow before adding watermarks.</p>
            </div>
        <cfelseif isDefined("successMessage")>
            <div class="pdf-container">
                <iframe src="../OfferLetter_Watermarked.pdf" 
                        class="pdf-iframe"
                        title="Watermarked PDF">
                    <p>Your browser doesn't support PDF viewing. <a href="../OfferLetter_Watermarked.pdf" target="_blank">Download the watermarked PDF</a></p>
                </iframe>
            </div>
        </cfif>
    </div>
</body>
</html>
