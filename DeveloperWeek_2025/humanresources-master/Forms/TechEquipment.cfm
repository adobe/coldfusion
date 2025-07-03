<cfhtmltopdf>
<cfhtmltopdfitem type="header">
    <div style="display: flex; justify-content: space-between; align-items: center; width: 100%; border-bottom: 1px solid #e2e8f0; padding-bottom: 10px; font-family: sans-serif;">
        <div style="display: flex; align-items: center; gap: 8px;">
            <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
            <span style="font-size: 20px; font-style: italic; color: #1a202c;">PeopleForge</span>
        </div>
        <div style="font-size: 16px; font-weight: 600; color: #4a5568;">
            Technology Equipment Form
        </div>
    </div>
</cfhtmltopdfitem>

<cfhtmltopdfitem type="footer">
    <div style="display: flex; justify-content: space-between; align-items: center; width: 100%; font-family: Arial, sans-serif; font-size: 10px; color: #777; border-top: 1px solid #e2e8f0; padding-top: 10px;">
        <div style="display: flex; align-items: center; gap: 4px;">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="#4a5568" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
            </svg>
            <span>&copy; <cfoutput>#Year(Now())#</cfoutput> PeopleForge. All rights reserved.</span>
        </div>
        <div>
            Page _PAGENUMBER of _LASTPAGENUMBER | Generated on <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput>
        </div>
    </div>
</cfhtmltopdfitem>

<html>
<head>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            color: #333; 
            background: #fff;
            line-height: 1.6;
        }
        .form-container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .form-header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #4338ca;
        }
        .form-header h1 {
            color: #4338ca;
            margin-bottom: 10px;
        }
        .form-section {
            margin-bottom: 30px;
            padding: 20px;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            background: #f9fafb;
        }
        .section-title {
            font-size: 18px;
            font-weight: bold;
            color: #2d3748;
            margin-bottom: 15px;
            padding-bottom: 8px;
            border-bottom: 1px solid #e2e8f0;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: inline-block;
            font-weight: 600;
            margin-bottom: 8px;
            color: #374151;
            width: 100%;
        }
        .radio-group, .checkbox-group {
            margin-left: 0;
        }
        .radio-option, .checkbox-option {
            margin-bottom: 8px;
            display: flex;
            align-items: center;
        }
        .radio-option label, .checkbox-option label {
            display: inline;
            margin-left: 8px;
            font-weight: normal;
            margin-bottom: 0;
        }
        .radio-option input[type="radio"], .checkbox-option input[type="checkbox"] {
            margin-right: 0;
            width: auto;
        }
        .text-input {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #d1d5db;
            border-radius: 4px;
            font-size: 14px;
            box-sizing: border-box;
        }
        .textarea {
            width: 100%;
            padding: 8px 12px;
            border: 1px solid #d1d5db;
            border-radius: 4px;
            font-size: 14px;
            min-height: 80px;
            resize: vertical;
            box-sizing: border-box;
        }
        .employee-info {
            background: #e0f2fe;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 20px;
        }
        .required {
            color: #dc2626;
        }
        .note {
            font-size: 12px;
            color: #6b7280;
            font-style: italic;
            margin-top: 5px;
        }
        input[type="radio"], input[type="checkbox"] {
            transform: scale(1.2);
            margin: 0 8px 0 0;
        }
        input[type="text"], input[type="tel"], input[type="date"], textarea {
            border: 2px solid #d1d5db;
            background-color: #ffffff;
        }
        input[type="text"]:focus, input[type="tel"]:focus, input[type="date"]:focus, textarea:focus {
            border-color: #4338ca;
            outline: none;
            box-shadow: 0 0 0 3px rgba(67, 56, 202, 0.1);
        }
        .form-row {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        .form-row label {
            margin-bottom: 0;
            margin-right: 10px;
            min-width: 200px;
        }
    </style>
</head>
<body>
    <div class="form-container">
        <div class="form-header">
    <h1>Technology Equipment Preference Form</h1>
            <p>Please complete this form to specify your technology equipment preferences for your new role.</p>
        </div>

        <div class="employee-info">
            <h3>Employee Information</h3>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <div class="form-group">
                    <label>Employee Name: <span class="required">*</span></label>
                    <input type="text" class="text-input" name="employeeName" value="John Smith" required>
                </div>
                <div class="form-group">
                    <label>Employee ID: <span class="required">*</span></label>
                    <input type="text" class="text-input" name="employeeId" value="E12345" required>
                </div>
                <div class="form-group">
                    <label>Department: <span class="required">*</span></label>
                    <input type="text" class="text-input" name="department" value="Engineering" required>
                </div>
                <div class="form-group">
                    <label>Start Date: <span class="required">*</span></label>
                    <input type="date" class="text-input" name="startDate" value="2024-02-15" required>
                </div>
            </div>
            <div style="text-align: center;">
                <img src="../images/John_Smith.png" alt="john_smith" style="width: 200px; height: 200px;">
            </div>
        </div>

        <cfhtmltopdfitem type="pagebreak" />

        <div style="padding-top: 40px;">
        </div>

        <div class="form-section">
            <div class="section-title">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: inline-block; margin-right: 8px; vertical-align: middle;">
                    <rect x="2" y="3" width="20" height="14" rx="2" ry="2"></rect>
                    <line x1="8" y1="21" x2="16" y2="21"></line>
                    <line x1="12" y1="17" x2="12" y2="21"></line>
                </svg>
                Computer/Laptop Preferences
            </div>
            
            <div class="form-group">
                <label>Preferred Operating System: <span class="required">*</span></label>
                <div class="radio-group">
                    <div class="form-row">
                        <input type="radio" name="os" value="windows" id="windows" checked>
                        <label for="windows">Windows</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="os" value="mac" id="mac">
                        <label for="mac">macOS</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="os" value="linux" id="linux">
                        <label for="linux">Linux</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label>Computer Type: <span class="required">*</span></label>
                <div class="radio-group">
                    <div class="form-row">
                        <input type="radio" name="computerType" value="laptop" id="laptop" checked>
                        <label for="laptop">Laptop (Portable)</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="computerType" value="desktop" id="desktop">
                        <label for="desktop">Desktop (Fixed workstation)</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="computerType" value="both" id="both">
                        <label for="both">Both (Laptop + Desktop)</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label>Additional Computer Accessories (Check all that apply):</label>
                <div class="checkbox-group">
                    <div class="form-row">
                        <input type="checkbox" name="accessories" value="externalMonitor" id="monitor" checked>
                        <label for="monitor">External Monitor (24" or larger)</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessories" value="dockingStation" id="docking" checked>
                        <label for="docking">Docking Station</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessories" value="wirelessMouse" id="mouse" checked>
                        <label for="mouse">Wireless Mouse</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessories" value="wirelessKeyboard" id="keyboard">
                        <label for="keyboard">Wireless Keyboard</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessories" value="webcam" id="webcam" checked>
                        <label for="webcam">Webcam</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessories" value="headset" id="headset" checked>
                        <label for="headset">Noise-canceling Headset</label>
                    </div>
                </div>
            </div>
        </div>
        
        <cfhtmltopdfitem type="pagebreak" />
        <div style="padding-top: 40px;">
        </div>

        <div class="form-section">
            <div class="section-title">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: inline-block; margin-right: 8px; vertical-align: middle;">
                    <rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect>
                    <line x1="12" y1="18" x2="12.01" y2="18"></line>
                </svg>
                Mobile Device Preferences
            </div>
            
            <div class="form-group">
                <label>Mobile Device Requirements:</label>
                <div class="checkbox-group">
                    <div class="form-row">
                        <input type="checkbox" name="mobileDevices" value="smartphone" id="smartphone" checked>
                        <label for="smartphone">Company Smartphone</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="mobileDevices" value="tablet" id="tablet">
                        <label for="tablet">Tablet/iPad</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="mobileDevices" value="mobileHotspot" id="hotspot">
                        <label for="hotspot">Mobile Hotspot Device</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label>Preferred Mobile Platform:</label>
                <div class="radio-group">
                    <div class="form-row">
                        <input type="radio" name="mobileOS" value="ios" id="ios">
                        <label for="ios">iOS (iPhone/iPad)</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="mobileOS" value="android" id="android" checked>
                        <label for="android">Android</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="mobileOS" value="none" id="none">
                        <label for="none">No preference</label>
                    </div>
                </div>
            </div>
        </div>

        <div class="form-section">
            <div class="section-title">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: inline-block; margin-right: 8px; vertical-align: middle;">
                    <rect x="3" y="3" width="7" height="7"></rect>
                    <rect x="14" y="3" width="7" height="7"></rect>
                    <rect x="14" y="14" width="7" height="7"></rect>
                    <rect x="3" y="14" width="7" height="7"></rect>
                </svg>
                Software & Applications
            </div>
            
            <div class="form-group">
                <label>Required Software (Check all that apply):</label>
                <div class="checkbox-group">
                    <div class="form-row">
                        <input type="checkbox" name="software" value="office365" id="office" checked>
                        <label for="office">Microsoft Office 365</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="software" value="adobe" id="adobe">
                        <label for="adobe">Adobe Creative Suite</label>
                    </div>
                    
                    <div class="form-row">
                        <input type="checkbox" name="software" value="vpn" id="vpn" checked>
                        <label for="vpn">VPN Client</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="software" value="antivirus" id="antivirus" checked>
                        <label for="antivirus">Antivirus Software</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label>Additional Software Requirements:</label>
                <textarea class="textarea" name="additionalSoftware">Visual Studio Code, Git, Docker Desktop, Postman for API testing</textarea>
            </div>
        </div>

        <div style="padding-top: 40px;">
        </div>

        <div class="form-section">
            <div class="section-title">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: inline-block; margin-right: 8px; vertical-align: middle;">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                    <polyline points="9,22 9,12 15,12 15,22"></polyline>
                </svg>
                Work Environment Setup
            </div>
            
            <div class="form-group">
                <label>Work Location Preference: <span class="required">*</span></label>
                <div class="radio-group">
                    <div class="form-row">
                        <input type="radio" name="workLocation" value="office" id="office">
                        <label for="office">Office-based</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="workLocation" value="remote" id="remote">
                        <label for="remote">Remote/Home office</label>
                    </div>
                    <div class="form-row">
                        <input type="radio" name="workLocation" value="hybrid" id="hybrid" checked>
                        <label for="hybrid">Hybrid (Office + Remote)</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label>Home Office Equipment (if applicable):</label>
                <div class="checkbox-group">
                    <div class="form-row">
                        <input type="checkbox" name="homeOffice" value="ergonomicChair" id="chair" checked>
                        <label for="chair">Ergonomic Office Chair</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="homeOffice" value="standingDesk" id="desk">
                        <label for="desk">Standing Desk</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="homeOffice" value="printer" id="printer">
                        <label for="printer">Printer/Scanner</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="homeOffice" value="internet" id="internet" checked>
                        <label for="internet">Internet Reimbursement</label>
                    </div>
                </div>
            </div>
        </div>

        <div class="form-section">
            <div class="section-title">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: inline-block; margin-right: 8px; vertical-align: middle;">
                    <circle cx="12" cy="12" r="3"></circle>
                    <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path>
                </svg>
                Special Requirements & Notes
            </div>
            
            <div class="form-group">
                <label>Accessibility Requirements:</label>
                <div class="checkbox-group">
                    <div class="form-row">
                        <input type="checkbox" name="accessibility" value="screenReader" id="screenReader">
                        <label for="screenReader">Screen Reader Software</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessibility" value="voiceRecognition" id="voiceRecognition">
                        <label for="voiceRecognition">Voice Recognition Software</label>
                    </div>
                    <div class="form-row">
                        <input type="checkbox" name="accessibility" value="ergonomicEquipment" id="ergonomic">
                        <label for="ergonomic">Special Ergonomic Equipment</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label>Additional Comments or Special Requirements:</label>
                <textarea class="textarea" name="additionalComments">I prefer a mechanical keyboard for coding. Also, I would like a second monitor for better productivity when working on multiple projects simultaneously. </textarea>
            </div>
        </div>

        <div style="padding-top: 40px;">
        </div>

        <div class="form-section">
            <div class="section-title">
                <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: inline-block; margin-right: 8px; vertical-align: middle;">
                    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path>
                </svg>
                Emergency Contact Information
            </div>
            
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                <div class="form-group">
                    <label>Emergency Contact Name:</label>
                    <input type="text" class="text-input" name="emergencyContactName" value="Jane Smith">
                </div>
                <div class="form-group">
                    <label>Emergency Contact Phone:</label>
                    <input type="tel" class="text-input" name="emergencyContactPhone" value="+1-555-123-4567">
                </div>
            </div>
        </div>

        <div style="text-align: center; margin-top: 30px; padding: 20px; background: #f0f9ff; border-radius: 8px;">
            <p><strong>Note:</strong> This form will be reviewed by the IT department. Equipment will be provided based on role requirements and company policies.</p>
            <p style="font-size: 12px; color: #6b7280;">Please submit this form at least 5 business days before your start date to ensure timely equipment setup.</p>
        </div>
    </div>
</body>
</html>
</cfhtmltopdf>