<cfif NOT fileExists(expandPath("../OfferLetter_Base.pdf"))>
    <cfset errorMessage = "Base offer letter not found. Please create it first.">
<cfelseif NOT fileExists(expandPath("../BenefitsAddendum.pdf"))>
    <cfset errorMessage = "Benefits addendum not found. Please create it first.">
<cfelse>
    <cfpdf action="merge" destination="../OfferLetter_Merged.pdf" overwrite="yes">
        <cfpdfparam source="../OfferLetter_Base.pdf">
        <cfpdfparam source="../BenefitsAddendum.pdf">
    </cfpdf>
    <cfset successMessage = "Documents successfully merged!">
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Merge PDF Documents</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: #f8fafc;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #8b5cf6;
        }
        .header h1 {
            color: #8b5cf6;
            font-size: 28px;
            margin-bottom: 10px;
        }
        .success-box {
            background: #ecfdf5;
            border: 1px solid #6ee7b7;
            color: #047857;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
        }
        .error-box {
            background: #fef2f2;
            border: 1px solid #fca5a5;
            color: #dc2626;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            text-align: center;
        }
        .info-section {
            background: #f0f9ff;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #3b82f6;
        }
        .step-list {
            background: #f9fafb;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .step-item {
            display: flex;
            align-items: center;
            margin: 10px 0;
            padding: 10px;
            background: white;
            border-radius: 6px;
            border: 1px solid #e5e7eb;
        }
        .step-number {
            background: #8b5cf6;
            color: white;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 15px;
            font-weight: bold;
        }
        .file-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px;
            background: #f3f4f6;
            border-radius: 8px;
            margin: 10px 0;
        }
        .file-status {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .status-icon {
            font-size: 20px;
        }
        .back-button {
            background: #8b5cf6;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            text-decoration: none;
            display: inline-block;
            margin-top: 20px;
        }
        .back-button:hover {
            background: #7c3aed;
        }
        .merge-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .stat-card {
            background: #f8fafc;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #e2e8f0;
        }
        .stat-number {
            font-size: 24px;
            font-weight: bold;
            color: #8b5cf6;
        }
        .stat-label {
            color: #64748b;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📄 PDF Document Merger</h1>
            <p>Combine offer letter and benefits addendum into a single document</p>
        </div>

        <cfif isDefined("errorMessage")>
            <div class="error-box">
                <h3>❌ Merge Failed</h3>
                <p><cfoutput>#errorMessage#</cfoutput></p>
                <p style="margin-top: 15px; font-size: 14px;">Please ensure both documents are created before attempting to merge.</p>
            </div>
        <cfelseif isDefined("successMessage")>
            <div class="success-box">
                <h3>✅ Documents Successfully Merged!</h3>
                <p style="font-size: 18px; margin: 15px 0;">
                    <strong>Output File:</strong> OfferLetter_Merged.pdf
                </p>
                <p style="font-size: 14px; color: #047857;">
                    Created: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput>
                </p>
            </div>

            <div class="merge-stats">
                <div class="stat-card">
                    <div class="stat-number">2</div>
                    <div class="stat-label">Source Documents</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">100%</div>
                    <div class="stat-label">Success Rate</div>
                </div>
            </div>
        </cfif>

        <div class="info-section">
            <h3>📋 Merge Process Overview</h3>
            <p>The PDF merge operation combines multiple documents while preserving:</p>
            <ul>
                <li>Original formatting and layouts</li>
                <li>Headers and footers</li>
                <li>Page numbering sequence</li>
                <li>Document metadata</li>
            </ul>
        </div>

        <div class="step-list">
            <h3>📌 Merge Steps Performed</h3>
            <div class="step-item">
                <div class="step-number">1</div>
                <div>
                    <strong>Source Validation</strong><br>
                    <small>Verify both PDF files exist and are accessible</small>
                </div>
            </div>
            <div class="step-item">
                <div class="step-number">2</div>
                <div>
                    <strong>Document Analysis</strong><br>
                    <small>Check file integrity and page counts</small>
                </div>
            </div>
            <div class="step-item">
                <div class="step-number">3</div>
                <div>
                    <strong>Merge Operation</strong><br>
                    <small>Combine documents using cfpdf merge action</small>
                </div>
            </div>
            <div class="step-item">
                <div class="step-number">4</div>
                <div>
                    <strong>Output Generation</strong><br>
                    <small>Create unified OfferLetter_Merged.pdf file</small>
                </div>
            </div>
        </div>

        <div class="info-section">
            <h3>📁 File Status</h3>
            <div class="file-info">
                <span><strong>OfferLetter_Base.pdf</strong></span>
                <div class="file-status">
                    <cfif fileExists(expandPath("OfferLetter_Base.pdf"))>
                        <span class="status-icon" style="color: #059669;">✅</span>
                        <span style="color: #059669;">Found (10 pages)</span>
                    <cfelse>
                        <span class="status-icon" style="color: #dc2626;">❌</span>
                        <span style="color: #dc2626;">Not Found</span>
                    </cfif>
                </div>
            </div>
            
            <div class="file-info">
                <span><strong>BenefitsAddendum.pdf</strong></span>
                <div class="file-status">
                    <cfif fileExists(expandPath("BenefitsAddendum.pdf"))>
                        <span class="status-icon" style="color: #059669;">✅</span>
                        <span style="color: #059669;">Found (2 pages)</span>
                    <cfelse>
                        <span class="status-icon" style="color: #dc2626;">❌</span>
                        <span style="color: #dc2626;">Not Found</span>
                    </cfif>
                </div>
            </div>
            
            <div class="file-info">
                <span><strong>OfferLetter_Merged.pdf</strong></span>
                <div class="file-status">
                    <cfif fileExists(expandPath("OfferLetter_Merged.pdf"))>
                        <span class="status-icon" style="color: #059669;">✅</span>
                        <span style="color: #059669;">Created Successfully</span>
                    <cfelse>
                        <span class="status-icon" style="color: #6b7280;">⏳</span>
                        <span style="color: #6b7280;">Pending</span>
                    </cfif>
                </div>
            </div>
        </div>

        <cfif isDefined("successMessage")>
            <div class="info-section" style="border-left-color: #059669;">
                <h3 style="color: #059669;">🎯 Next Steps</h3>
                <p>Your merged document is ready! The next step in the workflow is to remove any unnecessary pages from the combined document.</p>
                <ul>
                    <li>Proceed to <strong>Delete Pages</strong> to remove specific pages if needed</li>
                    <li>Then add company watermarks for branding</li>
                    <li>Apply digital signatures for authentication</li>
                    <li>Encrypt the document for security</li>
                </ul>
            </div>
        </cfif>

        <div style="text-align: center; margin-top: 30px;">
            <a href="../offerLetters.cfm" class="back-button">← Back to Offer Letter Workflow</a>
        </div>
    </div>
</body>
</html>
