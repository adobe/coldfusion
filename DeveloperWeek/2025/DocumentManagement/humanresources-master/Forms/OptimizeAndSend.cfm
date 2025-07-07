<cfif NOT fileExists(expandPath("../OfferLetter_Encrypted.pdf"))>
    <cfset errorMessage = "Encrypted offer letter not found. Please complete previous steps first.">
<cfelse>
    <!--- Get original file size --->
    <cfset originalFile = GetFileInfo(expandPath("../OfferLetter_Encrypted.pdf"))>
    <cfset originalSize = originalFile.size>
    
    <!--- Optimize the PDF --->
    <cfpdf action="optimize" 
           source="../OfferLetter_Encrypted.pdf" 
      destination="../OfferLetter_Final.pdf"
       password="peopleForgeOwner"
           algo="nearest_neighbour"
           overwrite="yes">
    
    <!--- Get optimized file size --->
    <cfset optimizedFile = GetFileInfo(expandPath("../OfferLetter_Final.pdf"))>
    <cfset optimizedSize = optimizedFile.size>
    <cfset sizeReduction = Round(((originalSize - optimizedSize) / originalSize) * 100)>
    
    <!--- Send email with the final document --->

    <cfmail to="{emailAddress}" from="hr@peopleforge.com"
    subject="Your Employment Offer Letter - PeopleForge Inc." port="587" 
    spoolenable="NO" debug="true">
        <cfmailparam file="#ExpandPath('../OfferLetter_Final.pdf')#" type="application/pdf">
        
Dear Alexandra Thompson,

We are excited to extend this official employment offer to join the PeopleForge team!

Please find your comprehensive offer letter attached to this email. The document contains:
• Complete position details and compensation
• Comprehensive benefits package information  
• Company policies and expectations
• Digital signature for authenticity

IMPORTANT SECURITY INFORMATION:
The attached PDF is password-protected for your security. 
Password: PF2024_Secure

Please review the offer carefully and respond by the deadline specified in the document.

If you have any questions, please don't hesitate to contact us:
• HR Department: hr@peopleforge.com | (555) 123-4567
• Direct Line: (555) 123-4567 ext. 101

We look forward to welcoming you to the PeopleForge family!

Best regards,
Sarah Rodriguez
Head of People & Culture
PeopleForge, Inc.

---
This email contains confidential information. If you received this in error, please delete it immediately.
    </cfmail>
    
    <cfset successMessage = "Document optimized and sent successfully!">
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Optimize & Send Final Document</title>
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
                <h3>❌ Final Processing Failed</h3>
                <p><cfoutput>#errorMessage#</cfoutput></p>
                <p style="margin-top: 15px; font-size: 14px;">Please ensure all previous steps have been completed successfully.</p>
            </div>
        <cfelseif isDefined("successMessage")>
            <div class="pdf-container">
                <iframe src="../OfferLetter_Final.pdf" 
                        class="pdf-iframe"
                        title="Final PDF">
                    <p>Your browser doesn't support PDF viewing. <a href="../OfferLetter_Final.pdf" target="_blank">Download the final PDF</a></p>
                </iframe>
            </div>
        </cfif>
    </div>
</body>
</html>
