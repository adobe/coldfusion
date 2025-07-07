<cfif fileExists(expandPath("../OfferLetter_Merged.pdf"))>
    <cfpdf action="deletepages" source="../OfferLetter_Merged.pdf" destination="../OfferLetter_Edited.pdf" pages="5-6" overwrite="yes">
    <cfset successMessage = "Pages 5 - 6 successfully removed!">
<cfelse>
    <cfset errorMessage = "Merged offer letter not found.">
</cfif>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Delete PDF Pages</title>
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
            border-bottom: 3px solid #f59e0b;
        }
        .header h1 {
            color: #f59e0b;
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
        .operation-details {
            background: #fefce8;
            border: 1px solid #fde047;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        .page-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(80px, 1fr));
            gap: 10px;
            margin: 20px 0;
            padding: 20px;
            background: #f9fafb;
            border-radius: 8px;
        }
        .page-item {
            background: white;
            border: 2px solid #e5e7eb;
            border-radius: 6px;
            padding: 15px 10px;
            text-align: center;
            font-weight: bold;
            transition: all 0.2s;
        }
        .page-item.deleted {
            background: #fef2f2;
            border-color: #fca5a5;
            color: #dc2626;
            text-decoration: line-through;
            opacity: 0.6;
        }
        .page-item.remaining {
            background: #ecfdf5;
            border-color: #6ee7b7;
            color: #047857;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        .stat-card {
            background: #f8fafc;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #e2e8f0;
        }
        .stat-number {
            font-size: 28px;
            font-weight: bold;
            color: #f59e0b;
        }
        .stat-label {
            color: #64748b;
            font-size: 14px;
            margin-top: 5px;
        }
        .info-section {
            background: #f0f9ff;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
            border-left: 4px solid #3b82f6;
        }
        .back-button {
            background: #f59e0b;
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
            background: #d97706;
        }
        .process-list {
            list-style: none;
            padding: 0;
        }
        .process-item {
            display: flex;
            align-items: center;
            padding: 12px;
            margin: 8px 0;
            background: white;
            border-radius: 6px;
            border-left: 4px solid #f59e0b;
        }
        .process-icon {
            background: #f59e0b;
            color: white;
            border-radius: 50%;
            width: 30px;
            height: 30px;
            display: flex;
            align-items: center;
            justify-content: center;
            margin-right: 15px;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📝 PDF Page Editor</h1>
            <p>Remove unnecessary pages from your merged document</p>
        </div>

        <cfif isDefined("errorMessage")>
            <div class="error-box">
                <h3>❌ Page Deletion Failed</h3>
                <p><cfoutput>#errorMessage#</cfoutput></p>
                <p style="margin-top: 15px; font-size: 14px;">Please ensure the merged document exists before attempting to delete pages.</p>
            </div>
        <cfelseif isDefined("successMessage")>
            <div class="success-box">
                <h3>✅ Pages Successfully Removed!</h3>
                <p style="font-size: 18px; margin: 15px 0;">
                    <strong>Output File:</strong> OfferLetter_Edited.pdf
                </p>
                <p style="font-size: 14px; color: #047857;">
                    Modified: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput>
                </p>
            </div>

            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-number">Page 5-6</div>
                    <div class="stat-label">Pages Removed</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">✅</div>
                    <div class="stat-label">Operation Status</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number">PDF</div>
                    <div class="stat-label">Output Format</div>
                </div>
            </div>
        </cfif>

        <div class="operation-details">
            <h3>🎯 Page Deletion Operation</h3>
            <p><strong>Target Pages:</strong> Page 5-6</p>
            <p><strong>Reason:</strong> Remove unnecessary or redundant content pages</p>
            <p><strong>Impact:</strong> Streamlines document flow and reduces total page count</p>
        </div>



        <div class="info-section">
            <h3>🔧 Technical Details</h3>
            <ul class="process-list">
                <li class="process-item">
                    <div class="process-icon">1</div>
                    <div>
                        <strong>Source Analysis:</strong> Scanned OfferLetter_Merged.pdf
                    </div>
                </li>
                <li class="process-item">
                    <div class="process-icon">2</div>
                    <div>
                        <strong>Target Identification:</strong> Located page 5-6 for removal
                    </div>
                </li>
                <li class="process-item">
                    <div class="process-icon">3</div>
                    <div>
                        <strong>Deletion Process:</strong> Used cfpdf deletepages action with pages="5-6"
                    </div>
                </li>
                <li class="process-item">
                    <div class="process-icon">4</div>
                    <div>
                        <strong>Output Generation:</strong> Created OfferLetter_Edited.pdf
                    </div>
                </li>
            </ul>
        </div>

        <div class="info-section">
            <h3>📊 File Status Overview</h3>
            <div style="background: white; padding: 15px; border-radius: 6px; margin: 10px 0;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <span><strong>OfferLetter_Merged.pdf</strong> (Source)</span>
                    <span style="color: #6b7280;">Input document</span>
                </div>
            </div>
            <div style="background: white; padding: 15px; border-radius: 6px; margin: 10px 0;">
                <div style="display: flex; justify-content: space-between; align-items: center;">
                    <span><strong>OfferLetter_Edited.pdf</strong> (Output)</span>
                    <cfif isDefined("successMessage")>
                        <span style="color: #059669;">Page 12 Removed ✅</span>
                    <cfelse>
                        <span style="color: #6b7280;">Pending</span>
                    </cfif>
                </div>
            </div>
        </div>

        <cfif isDefined("successMessage")>
            <div class="info-section" style="border-left-color: #059669;">
                <h3 style="color: #059669;">🎯 Next Steps</h3>
                <p>Your document has been optimized! The next step is to add company branding through watermarks.</p>
                <ul>
                    <li>Proceed to <strong>Add Watermark</strong> for company branding</li>
                    <li>Apply digital signatures for document authenticity</li>
                    <li>Encrypt for security and confidentiality</li>
                    <li>Optimize file size before final delivery</li>
                </ul>
            </div>
        </cfif>

        <div style="text-align: center; margin-top: 30px;">
            <a href="../offerLetters.cfm" class="back-button">← Back to Offer Letter Workflow</a>
        </div>
    </div>
</body>
</html>
