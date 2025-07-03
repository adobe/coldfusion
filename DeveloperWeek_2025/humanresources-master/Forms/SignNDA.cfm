<cfparam name="url.action" default="view">
<cfparam name="url.signed" default="false">

<cfif url.action EQ "sign">
    <!--- Process the signing request --->
    <cfset pdfFileName = "NDA_Signed_" & DateFormat(Now(), "yyyymmdd") & "_" & TimeFormat(Now(), "HHmmss") & ".pdf">
    <cfset pdfFilePath = ExpandPath("./uploads/#pdfFileName#")>
    <cfset signedPdfFileName = "NDA_Signed_" & DateFormat(Now(), "yyyymmdd") & "_" & TimeFormat(Now(), "HHmmss") & "_FINAL.pdf">
    <cfset signedPdfFilePath = ExpandPath("./uploads/#signedPdfFileName#")>
    
    <!--- Ensure uploads directory exists --->
    <cfif not DirectoryExists(ExpandPath("./uploads/"))>
        <cfdirectory action="create" directory="#ExpandPath('./uploads/')#">
    </cfif>
    
    <!--- Convert HTML to PDF --->
    <cfhtmltopdf destination="#pdfFilePath#" overwrite="true" margintop="0.5" marginbottom="0.5" marginleft="0.5" marginright="0.5">
        <!--- Include the full NDA content here for PDF generation --->
        <cfhtmltopdfitem type="header">
            <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-bottom: 1px solid #ddd; padding-bottom: 5px;">
                <strong>PeopleForge, Inc. - Confidential Document</strong>
            </div>
        </cfhtmltopdfitem>
        
        <cfhtmltopdfitem type="footer">
            <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-top: 1px solid #ddd; padding-top: 5px;">
                <p>Page _PAGENUMBER of _LASTPAGENUMBER | Signed on: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput></p>
            </div>
        </cfhtmltopdfitem>
        
        <!--- PDF Content --->
        <html>
        <head>
            <style>
                body { font-family: 'Times New Roman', serif; line-height: 1.4; margin: 20px; color: #333; }
                .nda-header { text-align: center; margin-bottom: 25px; border-bottom: 2px solid #4338ca; padding-bottom: 15px; }
                .nda-title { font-size: 20px; font-weight: bold; color: #4338ca; margin-bottom: 8px; text-transform: uppercase; }
                .nda-subtitle { font-size: 14px; color: #666; font-style: italic; }
                .section { margin-bottom: 20px; }
                .section-title { font-size: 16px; font-weight: bold; color: #4338ca; margin-bottom: 8px; border-left: 4px solid #4338ca; padding-left: 12px; }
                .subsection { margin-bottom: 12px; margin-left: 15px; }
                .subsection-title { font-weight: bold; margin-bottom: 6px; color: #2d3748; font-size: 14px; }
                .clause { margin-bottom: 10px; text-align: justify; text-indent: 15px; }
                .info-box { background-color: #f0f9ff; border: 1px solid #bfdbfe; padding: 12px; margin: 15px 0; color: #1e40af; font-size: 12px; }
                .warning-box { background-color: #fef2f2; border: 1px solid #fecaca; padding: 12px; margin: 15px 0; color: #b91c1c; font-size: 12px; }
                .signature-box { background-color: #f0f9ff; border: 2px solid #4338ca; padding: 20px; margin-top: 30px; text-align: center; }
                ol { margin-left: 0; padding-left: 15px; }
                ol li { margin-bottom: 6px; font-size: 14px; }
                .date-field { margin-top: 15px; font-weight: bold; color: #4338ca; }
            </style>
        </head>
        <body>
            <div class="nda-header">
                <div class="nda-title">Non-Disclosure Agreement</div>
                <div class="nda-subtitle">Confidential Information Protection Agreement</div>
                <div class="date-field">Effective Date: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")#</cfoutput></div>
            </div>
            
            <div class="info-box">
                <strong>Important Notice:</strong> This Non-Disclosure Agreement is a legally binding contract. This document has been electronically signed and is legally enforceable.
            </div>
            
            <!--- All the sections from the original NDA --->
            <div class="section">
                <div class="section-title">1. PARTIES TO THE AGREEMENT</div>
                <div class="clause">
                    This Non-Disclosure Agreement ("Agreement") is entered into on <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")#</cfoutput> by and between PeopleForge, Inc., a Delaware corporation with its principal place of business at 123 Innovation Drive, Tech Valley, CA 94000 ("Company"), and the undersigned individual ("Employee" or "Recipient").
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">2. DEFINITIONS</div>
                <div class="subsection">
                    <div class="subsection-title">2.1 Confidential Information</div>
                    <div class="clause">
                        "Confidential Information" means any and all non-public, proprietary, or confidential information disclosed by the Company to the Employee, whether orally, in writing, electronically, visually, or in any other form, including but not limited to:
                    </div>
                    <ol>
                        <li>Technical information, including software source code, algorithms, architectural designs, system configurations, database schemas, API specifications, and technical documentation</li>
                        <li>Business information, including financial data, revenue figures, profit margins, business plans, marketing strategies, customer lists, supplier information, and pricing models</li>
                        <li>Product information, including product roadmaps, feature specifications, development timelines, user interface designs, and beta versions</li>
                        <li>Personnel information, including employee records, compensation data, organizational charts, and performance evaluations</li>
                        <li>Customer and vendor information, including contact details, contract terms, usage patterns, and relationship history</li>
                        <li>Intellectual property, including patents, trademarks, copyrights, trade secrets, know-how, and proprietary processes</li>
                        <li>Strategic information, including merger and acquisition plans, partnership negotiations, competitive intelligence, and market research</li>
                        <li>Any other information that is marked, designated, or reasonably understood to be confidential or proprietary</li>
                    </ol>
                </div>

                <div style="page-break-after: always;"></div>
                
                <div class="subsection">
                    <div class="subsection-title">2.2 Excluded Information</div>
                    <div class="clause">
                        Confidential Information does not include information that: (a) is publicly available through no breach of this Agreement; (b) was rightfully known to Employee prior to disclosure; (c) is received from a third party without breach of confidentiality obligations; or (d) is independently developed without use of Confidential Information.
                    </div>
                </div>
            </div>
            
            <!--- Continue with all other sections... --->
            <div class="section">
                <div class="section-title">3. CONFIDENTIALITY OBLIGATIONS</div>
                <div class="subsection">
                    <div class="subsection-title">3.1 Non-Disclosure</div>
                    <div class="clause">
                        Employee agrees to hold in strict confidence and not disclose, publish, or disseminate any Confidential Information to any third party without the prior written consent of the Company.
                    </div>
                </div>
                <div class="subsection">
                    <div class="subsection-title">3.2 Non-Use</div>
                    <div class="clause">
                        Employee agrees not to use any Confidential Information for any purpose other than performing duties as an employee of the Company.
                    </div>
                </div>
                <div class="subsection">
                    <div class="subsection-title">3.3 Limited Access</div>
                    <div class="clause">
                        Employee agrees to access Confidential Information only as necessary for the performance of assigned duties and to limit access to authorized personnel.
                    </div>
                </div>
                <div class="subsection">
                    <div class="subsection-title">3.4 Security Measures</div>
                    <div class="clause">
                        Employee agrees to implement and maintain reasonable security measures to protect Confidential Information.
                    </div>
                </div>
            </div>
            
            <!--- Additional abbreviated sections for PDF --->
            <div class="section">
                <div class="section-title">4. RETURN OF MATERIALS</div>
                <div class="clause">
                    Upon termination of employment, Employee agrees to immediately return all materials containing Confidential Information.
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">5. INTELLECTUAL PROPERTY</div>
                <div class="clause">
                    All work product created during employment shall be the exclusive property of the Company.
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">6. NON-COMPETE AND NON-SOLICITATION</div>
                <div class="clause">
                    Employee agrees to non-compete and non-solicitation obligations as detailed in the full agreement terms.
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">7. REMEDIES AND ENFORCEMENT</div>
                <div class="clause">
                    Company shall be entitled to seek injunctive relief and monetary damages for any breach of this Agreement.
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">8. LEGAL DISCLOSURE</div>
                <div class="clause">
                    Nothing prevents Employee from reporting suspected violations of law to governmental authorities.
                </div>
            </div>
            
            <div class="section">
                <div class="section-title">9. GENERAL PROVISIONS</div>
                <div class="clause">
                    This Agreement is governed by California law and constitutes the entire agreement between the parties.
                </div>
            </div>
            
            <div class="signature-box">
                <h3 style="color: #4338ca; margin-bottom: 15px;">ELECTRONIC SIGNATURE CONFIRMATION</h3>
                <p><strong>✓ DIGITALLY SIGNED AND VERIFIED</strong></p>
                <p>This document has been electronically signed on:</p>
                <p><strong><cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput></strong></p>
                <p style="font-size: 12px; margin-top: 15px; color: #666;">
                    This electronic signature is legally binding and has the same legal effect as a handwritten signature.
                </p>
            </div>
        </body>
        </html>
    </cfhtmltopdf>
    
    <!--- Now digitally sign the PDF --->
    <!--- Note: Ensure CFUser1.jks keystore file exists in the keys directory --->
    <cftry>
        <cfpdf action="sign" 
               source="#pdfFilePath#" 
               destination="#signedPdfFilePath#"
               author="false"
               keystore="#ExpandPath('../keys/CFUser1.jks')#" 
               keystorepassword="coldfusion" 
               keyalias="1" 
               keypassword="coldfusion" 
               position="400,50" 
               height="50"
               width="120"
               overwrite="true">
        
        <!--- Clean up the unsigned PDF --->
        <cffile action="delete" file="#pdfFilePath#">
        
        <!--- Redirect to view the signed PDF --->
        <cflocation url="SignNDA.cfm?action=viewpdf&file=#signedPdfFileName#" addtoken="false">
        
        <cfcatch type="any">
            <!--- If signing fails, still show the unsigned PDF --->
            <cflocation url="SignNDA.cfm?action=viewpdf&file=#pdfFileName#&error=signing_failed" addtoken="false">
        </cfcatch>
    </cftry>
    
<cfelseif url.action EQ "viewpdf">
    <!--- Display the signed PDF --->
    <cfparam name="url.file" default="">
    <cfif len(url.file) AND FileExists(ExpandPath("./uploads/#url.file#"))>
        <cfheader name="Content-Type" value="application/pdf">
        <cfcontent type="application/pdf" file="#ExpandPath('./uploads/#url.file#')#" deletefile="false">
    <cfelse>
        <html>
        <body>
            <div style="text-align: center; padding: 50px; font-family: Arial, sans-serif;">
                <h2 style="color: #dc2626;">PDF Not Found</h2>
                <p>The requested PDF file could not be found.</p>
                <button onclick="window.location.href='SignNDA.cfm'" style="background: #4338ca; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer;">Return to NDA</button>
            </div>
        </body>
        </html>
    </cfif>
    <cfabort>
    
<cfelse>
    <!--- Show the HTML NDA for initial viewing and signing --->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Non-Disclosure Agreement</title>
    <style>
        body {
            font-family: 'Times New Roman', serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #ffffff;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
        }
        
        .nda-header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #4338ca;
            padding-bottom: 20px;
        }
        
        .nda-title {
            font-size: 24px;
            font-weight: bold;
            color: #4338ca;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .nda-subtitle {
            font-size: 16px;
            color: #666;
            font-style: italic;
        }
        
        .section {
            margin-bottom: 25px;
        }
        
        .section-title {
            font-size: 18px;
            font-weight: bold;
            color: #4338ca;
            margin-bottom: 10px;
            border-left: 4px solid #4338ca;
            padding-left: 15px;
        }
        
        .subsection {
            margin-bottom: 15px;
            margin-left: 20px;
        }
        
        .subsection-title {
            font-weight: bold;
            margin-bottom: 8px;
            color: #2d3748;
        }
        
        .clause {
            margin-bottom: 12px;
            text-align: justify;
            text-indent: 20px;
        }
        
        .definition {
            background-color: #f7fafc;
            padding: 10px;
            border-left: 3px solid #4338ca;
            margin: 10px 0;
            font-style: italic;
        }
        
        .signature-section {
            background-color: #f0f9ff;
            border: 2px solid #4338ca;
            border-radius: 8px;
            padding: 30px;
            margin-top: 40px;
            text-align: center;
        }
        
        .checkbox-container {
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 20px 0;
            gap: 10px;
        }
        
        .agreement-checkbox {
            width: 20px;
            height: 20px;
            cursor: pointer;
        }
        
        .checkbox-label {
            font-size: 16px;
            font-weight: 500;
            color: #2d3748;
            cursor: pointer;
        }
        
        .sign-button {
            background: linear-gradient(135deg, #4338ca 0%, #3730a3 100%);
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(67, 56, 202, 0.3);
            margin-top: 15px;
        }
        
        .sign-button:hover {
            background: linear-gradient(135deg, #3730a3 0%, #312e81 100%);
            transform: translateY(-2px);
            box-shadow: 0 6px 12px rgba(67, 56, 202, 0.4);
        }
        
        .sign-button:disabled {
            background: #9ca3af;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        
        .date-field {
            margin-top: 20px;
            font-weight: bold;
            color: #4338ca;
        }
        
        ol {
            margin-left: 0;
            padding-left: 20px;
        }
        
        ol li {
            margin-bottom: 8px;
        }
        
        .highlight {
            background-color: #fef3cd;
            padding: 2px 4px;
            border-radius: 3px;
        }
        
        .warning-box {
            background-color: #fef2f2;
            border: 1px solid #fecaca;
            border-radius: 6px;
            padding: 15px;
            margin: 20px 0;
            color: #b91c1c;
        }
        
        .info-box {
            background-color: #eff6ff;
            border: 1px solid #bfdbfe;
            border-radius: 6px;
            padding: 15px;
            margin: 20px 0;
            color: #1e40af;
        }
    </style>
</head>
<body>
    <div class="nda-header">
        <div class="nda-title">Non-Disclosure Agreement</div>
        <div class="nda-subtitle">Confidential Information Protection Agreement</div>
        <div class="date-field">Effective Date: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")#</cfoutput></div>
    </div>

    <div class="info-box">
        <strong>Important Notice:</strong> This Non-Disclosure Agreement is a legally binding contract. Please read all sections carefully before signing. If you have any questions, please contact the Legal Department at legal@peopleforge.com.
    </div>

    <div class="section">
        <div class="section-title">1. PARTIES TO THE AGREEMENT</div>
        <div class="clause">
            This Non-Disclosure Agreement ("Agreement") is entered into on <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")#</cfoutput> by and between PeopleForge, Inc., a Delaware corporation with its principal place of business at 123 Innovation Drive, Tech Valley, CA 94000 ("Company"), and the undersigned individual ("Employee" or "Recipient").
        </div>
    </div>

    <div class="section">
        <div class="section-title">2. DEFINITIONS</div>
        <div class="subsection">
            <div class="subsection-title">2.1 Confidential Information</div>
            <div class="clause">
                "Confidential Information" means any and all non-public, proprietary, or confidential information disclosed by the Company to the Employee, whether orally, in writing, electronically, visually, or in any other form, including but not limited to:
            </div>
            <ol>
                <li>Technical information, including but not limited to software source code, algorithms, architectural designs, system configurations, database schemas, API specifications, and technical documentation</li>
                <li>Business information, including but not limited to financial data, revenue figures, profit margins, business plans, marketing strategies, customer lists, supplier information, and pricing models</li>
                <li>Product information, including but not limited to product roadmaps, feature specifications, development timelines, user interface designs, and beta versions</li>
                <li>Personnel information, including but not limited to employee records, compensation data, organizational charts, and performance evaluations</li>
                <li>Customer and vendor information, including but not limited to contact details, contract terms, usage patterns, and relationship history</li>
                <li>Intellectual property, including but not limited to patents, trademarks, copyrights, trade secrets, know-how, and proprietary processes</li>
                <li>Strategic information, including but not limited to merger and acquisition plans, partnership negotiations, competitive intelligence, and market research</li>
                <li>Any other information that is marked, designated, or reasonably understood to be confidential or proprietary</li>
            </ol>
        </div>

        <div class="subsection">
            <div class="subsection-title">2.2 Excluded Information</div>
            <div class="clause">
                Confidential Information does not include information that: (a) is publicly available through no breach of this Agreement; (b) was rightfully known to Employee prior to disclosure; (c) is received from a third party without breach of confidentiality obligations; or (d) is independently developed without use of Confidential Information.
            </div>
        </div>
    </div>

    <div class="section">
        <div class="section-title">3. CONFIDENTIALITY OBLIGATIONS</div>
        <div class="subsection">
            <div class="subsection-title">3.1 Non-Disclosure</div>
            <div class="clause">
                Employee agrees to hold in strict confidence and not disclose, publish, or disseminate any Confidential Information to any third party without the prior written consent of the Company. This obligation applies during the Employee's employment and continues indefinitely after termination of employment, regardless of the reason for termination.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">3.2 Non-Use</div>
            <div class="clause">
                Employee agrees not to use any Confidential Information for any purpose other than performing duties as an employee of the Company. Employee specifically agrees not to use Confidential Information for personal benefit or for the benefit of any third party, including but not limited to competitors, clients, or future employers.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">3.3 Limited Access</div>
            <div class="clause">
                Employee agrees to access Confidential Information only as necessary for the performance of assigned duties and to limit access to such information to authorized personnel who have a legitimate business need to know and who are bound by similar confidentiality obligations.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">3.4 Security Measures</div>
            <div class="clause">
                Employee agrees to implement and maintain reasonable security measures to protect Confidential Information, including but not limited to: using strong passwords, encrypting sensitive data, securing physical documents, limiting access to authorized devices, and reporting any suspected security breaches immediately.
            </div>
        </div>
    </div>

    <div class="section">
        <div class="section-title">4. RETURN OF MATERIALS</div>
        <div class="clause">
            Upon termination of employment or upon request by the Company, Employee agrees to immediately return or destroy all materials containing or relating to Confidential Information, including but not limited to documents, files, computer data, prototypes, samples, and any copies thereof, regardless of the medium on which they are stored.
        </div>
    </div>

    <div class="section">
        <div class="section-title">5. INTELLECTUAL PROPERTY</div>
        <div class="subsection">
            <div class="subsection-title">5.1 Work for Hire</div>
            <div class="clause">
                Employee acknowledges that any work product, inventions, discoveries, or improvements made during employment that relate to the Company's business or use Company resources shall be considered "work for hire" and the exclusive property of the Company.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">5.2 Assignment of Rights</div>
            <div class="clause">
                Employee hereby assigns to the Company all rights, title, and interest in and to any intellectual property created during the course of employment, including but not limited to patents, copyrights, trademarks, trade secrets, and moral rights.
            </div>
        </div>
    </div>

    <div class="section">
        <div class="section-title">6. NON-COMPETE AND NON-SOLICITATION</div>
        <div class="subsection">
            <div class="subsection-title">6.1 Non-Compete</div>
            <div class="clause">
                During employment and for a period of twelve (12) months following termination, Employee agrees not to directly or indirectly engage in any business that competes with the Company within the geographical area where the Company conducts business or markets its products or services.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">6.2 Non-Solicitation of Employees</div>
            <div class="clause">
                For a period of eighteen (18) months following termination, Employee agrees not to solicit, recruit, or induce any employee of the Company to terminate their employment or to join any competing organization.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">6.3 Non-Solicitation of Customers</div>
            <div class="clause">
                For a period of twelve (12) months following termination, Employee agrees not to solicit or attempt to solicit any customer or client of the Company for the purpose of providing competing products or services.
            </div>
        </div>
    </div>

    <div class="section">
        <div class="section-title">7. REMEDIES AND ENFORCEMENT</div>
        <div class="subsection">
            <div class="subsection-title">7.1 Injunctive Relief</div>
            <div class="clause">
                Employee acknowledges that any breach of this Agreement would cause irreparable harm to the Company for which monetary damages would be inadequate. Therefore, the Company shall be entitled to seek injunctive relief, specific performance, and other equitable remedies without the necessity of proving actual damages.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">7.2 Monetary Damages</div>
            <div class="clause">
                In addition to equitable relief, Employee shall be liable for all damages, costs, and expenses incurred by the Company as a result of any breach, including reasonable attorneys' fees and court costs.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">7.3 Liquidated Damages</div>
            <div class="clause">
                For certain breaches, Employee may be subject to liquidated damages as specified in the Employee Handbook or as otherwise agreed upon in writing.
            </div>
        </div>
    </div>

    <div class="section">
        <div class="section-title">8. LEGAL DISCLOSURE</div>
        <div class="clause">
            Nothing in this Agreement shall prevent Employee from: (a) filing a charge or complaint with or participating in any investigation or proceeding conducted by any governmental agency; (b) reporting suspected violations of law to governmental authorities; (c) responding to subpoenas or court orders; or (d) exercising rights under applicable whistleblower statutes.
        </div>
    </div>

    <div class="section">
        <div class="section-title">9. GENERAL PROVISIONS</div>
        <div class="subsection">
            <div class="subsection-title">9.1 Governing Law</div>
            <div class="clause">
                This Agreement shall be governed by and construed in accordance with the laws of the State of California, without regard to conflict of law principles.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">9.2 Jurisdiction and Venue</div>
            <div class="clause">
                Any disputes arising under this Agreement shall be subject to the exclusive jurisdiction of the state and federal courts located in Santa Clara County, California.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">9.3 Severability</div>
            <div class="clause">
                If any provision of this Agreement is found to be unenforceable, the remainder of the Agreement shall remain in full force and effect, and the unenforceable provision shall be modified to the minimum extent necessary to make it enforceable.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">9.4 Amendment</div>
            <div class="clause">
                This Agreement may only be amended by a written document signed by both parties. No verbal modifications or waivers shall be effective.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">9.5 Survival</div>
            <div class="clause">
                The provisions of this Agreement shall survive the termination of Employee's employment and shall remain binding upon Employee, Employee's heirs, successors, and assigns.
            </div>
        </div>

        <div class="subsection">
            <div class="subsection-title">9.6 Entire Agreement</div>
            <div class="clause">
                This Agreement constitutes the entire agreement between the parties regarding confidentiality obligations and supersedes all prior or contemporaneous agreements, whether written or oral, relating to the subject matter hereof.
            </div>
        </div>
    </div>

    <div class="warning-box">
        <strong>Legal Notice:</strong> By signing this agreement, you acknowledge that you have read, understood, and agree to be bound by all terms and conditions set forth herein. This is a legally binding contract that will remain in effect beyond your employment term.
    </div>

    <div class="signature-section">
        <h3 style="margin-bottom: 20px; color: #4338ca;">Electronic Signature and Agreement</h3>
        
        <div class="checkbox-container">
            <input type="checkbox" id="agreeCheckbox" class="agreement-checkbox" onchange="toggleSignButton()">
            <label for="agreeCheckbox" class="checkbox-label">
                I have read, understood, and agree to all terms and conditions of this Non-Disclosure Agreement
            </label>
        </div>
        
        <div style="margin: 15px 0; font-size: 14px; color: #666;">
            By checking the box above and clicking "Sign Agreement," you are providing your electronic signature and agreeing to be legally bound by this contract.
        </div>
        
        <button id="signButton" class="sign-button" onclick="signAgreement()" disabled>
            Sign Agreement
        </button>
        
        <div id="signatureConfirmation" style="display: none; margin-top: 20px; padding: 15px; background-color: #d1fae5; border: 1px solid #a7f3d0; border-radius: 6px; color: #047857;">
            <strong>✓ Agreement Signed Successfully!</strong><br>
            Signed on: <span id="signatureDate"></span><br>
            Your electronic signature has been recorded and this agreement is now in effect.
        </div>
    </div>

    <script>
        function toggleSignButton() {
            const checkbox = document.getElementById('agreeCheckbox');
            const signButton = document.getElementById('signButton');
            
            signButton.disabled = !checkbox.checked;
        }
        
        function signAgreement() {
            const checkbox = document.getElementById('agreeCheckbox');
            
            if (!checkbox.checked) {
                alert('Please check the agreement box before signing.');
                return;
            }
            
            // Show processing message
            const signButton = document.getElementById('signButton');
            signButton.disabled = true;
            signButton.textContent = 'Processing...';
            signButton.style.background = '#9ca3af';
            
            // Show loading message
            const confirmation = document.getElementById('signatureConfirmation');
            confirmation.innerHTML = `
                <div style="color: #2563eb;">
                    <strong>🔄 Processing Your Digital Signature...</strong><br>
                    Converting to PDF and applying digital certificate.<br>
                    Please wait...
                </div>
            `;
            confirmation.style.display = 'block';
            confirmation.style.backgroundColor = '#eff6ff';
            confirmation.style.borderColor = '#bfdbfe';
            
            // Redirect to the signing process
            setTimeout(() => {
                window.location.href = 'SignNDA.cfm?action=sign';
            }, 2000);
        }
        
        // Prevent right-click context menu for document protection
        document.addEventListener('contextmenu', function(e) {
            e.preventDefault();
        });
        
        // Prevent text selection for document protection
        document.addEventListener('selectstart', function(e) {
            e.preventDefault();
        });
    </script>
</body>
</html>
</cfif>
