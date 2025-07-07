<cfhtmltopdf margintop="0.5" marginbottom="0.5" marginleft="0.75" marginright="0.75" destination="../OfferLetter_Base.pdf" overwrite="yes">
    <cfhtmltopdfitem type="header">
        <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-bottom: 1px solid #ddd; padding-bottom: 5px;">
            <strong>PeopleForge, Inc. - Official Offer Letter - Confidential</strong>
        </div>
    </cfhtmltopdfitem>
    
    <cfhtmltopdfitem type="footer">
        <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-top: 1px solid #ddd; padding-top: 5px;">
            <p>Page _PAGENUMBER of _LASTPAGENUMBER | Generated on: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput></p>
        </div>
    </cfhtmltopdfitem>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Employment Offer Letter</title>
    <style>
        body { font-family: Arial; line-height: 1.6; color: #333; padding: 15px; }
        .header { text-align: center; margin-bottom: 25px; border-bottom: 3px solid #4338ca; padding-bottom: 15px; }
        .company-logo { font-size: 28px; font-weight: bold; color: #4338ca; margin-bottom: 8px; }
        .section { margin-bottom: 20px; page-break-inside: avoid; }
        .section-title { font-size: 16px; font-weight: bold; color: #4338ca; border-bottom: 2px solid #e5e7eb; padding-bottom: 3px; margin-bottom: 12px; }
        .page-break { page-break-before: always; }
        .table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        .table th, .table td { border: 1px solid #d1d5db; padding: 8px; text-align: left; font-size: 14px; }
        .table th { background: #f3f4f6; font-weight: bold; }
        .content-box { border: 1px solid #d1d5db; padding: 15px; margin: 10px 0; border-radius: 6px; background: #f9fafb; }
        .detail-item { margin-bottom: 8px; }
        .highlight { background: #fef3c7; padding: 10px; border-left: 4px solid #f59e0b; margin: 10px 0; }
        ul { padding-left: 18px; }
        li { margin-bottom: 6px; font-size: 14px; }
        p { font-size: 14px; margin-bottom: 8px; }
    </style>
</head>
<body>
    <!-- Page 1: Header and Introduction -->
    <div class="header">
        <div class="company-logo">🏢 PeopleForge</div>
        <h1 style="font-size: 24px; margin: 10px 0;">Employment Offer Letter</h1>
        <p style="font-size: 14px;">123 Innovation Drive, Suite 500<br>San Francisco, CA 94105<br>Phone: (555) 123-4567 | Email: hr@peopleforge.com</p>
    </div>

    <div class="section">
        <p><strong>Date:</strong> <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")#</cfoutput></p>
        <p><strong>Dear Alexandra Thompson,</strong></p>
        <p>We are delighted to extend this formal offer of employment to you for the position of <strong>Senior Software Engineer</strong> at PeopleForge, Inc. After a comprehensive evaluation process involving multiple interviews with our technical team, leadership, and cultural assessment, we are confident that your skills, experience, and values align perfectly with our company's mission and goals.</p>
        
        <div class="highlight">
            <p><strong>Congratulations!</strong> You stood out among numerous qualified candidates, and we believe you will make significant contributions to our engineering team and help drive our technological innovation forward.</p>
        </div>
        
        <p>This offer is contingent upon successful completion of our standard background verification process, reference checks, and your acceptance of the terms outlined in this comprehensive offer letter. We are excited about the possibility of you joining our team and contributing to our continued success in revolutionizing human resources technology.</p>
    </div>

    <!-- Page 2: Position Details and Reporting Structure -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Position Details & Organizational Structure</h2>
        <div class="content-box">
            <table class="table">
                <tr><th width="35%">Position Title</th><td>Senior Software Engineer</td></tr>
                <tr><th>Department</th><td>Engineering - Platform Development Team</td></tr>
                <tr><th>Reporting Manager</th><td>Jean Smith, Chief Technology Officer</td></tr>
                <tr><th>Direct Reports</th><td>2-3 Junior Software Engineers (within 6 months)</td></tr>
                <tr><th>Start Date</th><td>January 15, 2025</td></tr>
                <tr><th>Work Location</th><td>San Francisco, CA (Hybrid: 3 days in office, 2 remote)</td></tr>
                <tr><th>Employment Type</th><td>Full-time, At-will Employment</td></tr>
                <tr><th>Classification</th><td>Exempt (Salaried)</td></tr>
            </table>
        </div>
        
        <div class="section">
            <h3 style="color: #4338ca; margin-bottom: 8px;">Team Collaboration</h3>
            <p>You will work closely with:</p>
            <ul>
                <li><strong>Product Team:</strong> David Wilson (VP of Product) and product managers</li>
                <li><strong>Design Team:</strong> UX/UI designers for user experience optimization</li>
                <li><strong>QA Team:</strong> Quality assurance engineers for testing and validation</li>
                <li><strong>DevOps Team:</strong> Infrastructure and deployment specialists</li>
                <li><strong>Data Team:</strong> Analytics and data science professionals</li>
                <li><strong>Customer Success:</strong> Direct feedback loop with client-facing teams</li>
            </ul>
        </div>
    </div>

    <!-- Page 3: Comprehensive Compensation Package -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Comprehensive Compensation Package</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Base Salary</h3>
            <p><strong>Annual Salary:</strong> $125,000 (paid bi-weekly: $4,807.69 per pay period)</p>
            <p>Your salary will be reviewed annually as part of our performance evaluation process, with potential increases based on individual performance, market conditions, and company growth.</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Performance-Based Bonus</h3>
            <p><strong>Target Bonus:</strong> 15% of base salary ($18,750 annually)</p>
            <p><strong>Bonus Structure:</strong></p>
            <ul>
                <li>50% based on individual performance metrics and goal achievement</li>
                <li>30% based on team/department performance</li>
                <li>20% based on overall company performance and revenue targets</li>
            </ul>
            <p>Bonus payments are made quarterly, with annual reconciliation in December.</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Equity Compensation</h3>
            <p><strong>Stock Options:</strong> 5,000 shares of PeopleForge common stock</p>
            <p><strong>Vesting Schedule:</strong> 4-year vesting (25% after 1 year, then monthly)</p>
            <p><strong>Exercise Price:</strong> $10.00 per share (current fair market value)</p>
            <p><strong>Option Term:</strong> 10 years from grant date</p>
            <p>Additional equity grants may be awarded annually based on performance and company growth.</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Sign-on Bonus</h3>
            <p><strong>Amount:</strong> $10,000 (paid with first paycheck)</p>
            <p><strong>Repayment Terms:</strong> If employment terminates within 24 months, 50% subject to repayment</p>
        </div>
    </div>

    <!-- Page 4: Comprehensive Benefits Package -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Comprehensive Benefits Package</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Health & Wellness Benefits</h3>
            <table class="table">
                <tr><th>Benefit</th><th>Coverage</th><th>Employee Cost</th></tr>
                <tr><td>Medical Insurance</td><td>Blue Cross Blue Shield PPO</td><td>$0 (100% company paid)</td></tr>
                <tr><td>Dental Insurance</td><td>Delta Dental Premium</td><td>$0 (100% company paid)</td></tr>
                <tr><td>Vision Insurance</td><td>VSP Premium Plan</td><td>$0 (100% company paid)</td></tr>
                <tr><td>Life Insurance</td><td>2x annual salary</td><td>$0 (100% company paid)</td></tr>
                <tr><td>Short-term Disability</td><td>60% of salary up to 26 weeks</td><td>$0 (100% company paid)</td></tr>
                <tr><td>Long-term Disability</td><td>60% of salary until age 65</td><td>$0 (100% company paid)</td></tr>
            </table>
            <p><strong>Family Coverage:</strong> Dependents covered at 80% company contribution</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Retirement & Financial Benefits</h3>
            <p><strong>401(k) Plan:</strong> 6% company match with immediate vesting</p>
            <p><strong>Investment Options:</strong> Low-cost index funds, target-date funds, and ESG options</p>
            <p><strong>Financial Wellness:</strong> Free financial planning consultations quarterly</p>
            <p><strong>Employee Stock Purchase Plan:</strong> Purchase company stock at 15% discount</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Time Off & Work-Life Balance</h3>
            <p><strong>Paid Time Off (PTO):</strong> 25 days annually (prorated first year)</p>
            <p><strong>Holidays:</strong> 12 company holidays plus 3 floating personal days</p>
            <p><strong>Sick Leave:</strong> Unlimited sick time with manager approval</p>
            <p><strong>Parental Leave:</strong> 12 weeks paid leave for new parents</p>
            <p><strong>Sabbatical:</strong> 4-week paid sabbatical after 5 years of service</p>
        </div>
    </div>

    <!-- Page 5: Detailed Job Responsibilities -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Detailed Job Responsibilities & Expectations</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Core Technical Responsibilities</h3>
            <ul>
                <li><strong>Software Development:</strong> Design, develop, and maintain scalable web applications using modern technologies (React, Node.js, Python, PostgreSQL)</li>
                <li><strong>Architecture & Design:</strong> Contribute to system architecture decisions and technical design reviews</li>
                <li><strong>Code Quality:</strong> Write clean, well-documented, and tested code following established coding standards</li>
                <li><strong>Performance Optimization:</strong> Identify and resolve performance bottlenecks in applications and databases</li>
                <li><strong>Security Implementation:</strong> Implement security best practices and participate in security code reviews</li>
                <li><strong>API Development:</strong> Design and implement RESTful APIs and microservices</li>
                <li><strong>Database Management:</strong> Optimize database queries and manage data migrations</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Leadership & Collaboration</h3>
            <ul>
                <li><strong>Code Reviews:</strong> Conduct thorough code reviews and provide constructive feedback</li>
                <li><strong>Mentoring:</strong> Guide and mentor junior developers and interns</li>
                <li><strong>Cross-functional Collaboration:</strong> Work closely with product, design, and QA teams</li>
                <li><strong>Technical Documentation:</strong> Create and maintain technical documentation and system diagrams</li>
                <li><strong>Knowledge Sharing:</strong> Lead technical presentations and participate in engineering forums</li>
                <li><strong>Agile Practices:</strong> Actively participate in sprint planning, stand-ups, and retrospectives</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Innovation & Continuous Improvement</h3>
            <ul>
                <li><strong>Technology Research:</strong> Stay current with emerging technologies and industry trends</li>
                <li><strong>Process Improvement:</strong> Identify and implement improvements to development processes</li>
                <li><strong>Technical Strategy:</strong> Contribute to long-term technical roadmap and technology decisions</li>
                <li><strong>Proof of Concepts:</strong> Develop prototypes and proof-of-concept solutions</li>
            </ul>
        </div>
    </div>

    <!-- Page 6: Professional Development & Growth -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Professional Development & Career Growth</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Learning & Development Budget</h3>
            <p><strong>Annual Allocation:</strong> $2,500 for professional development</p>
            <p><strong>Eligible Expenses:</strong></p>
            <ul>
                <li>Technical conferences and workshops (expenses + travel covered)</li>
                <li>Online courses and certifications (Coursera, Udemy, Pluralsight)</li>
                <li>Technical books and learning materials</li>
                <li>Professional membership fees and subscriptions</li>
                <li>Industry certification exams and preparation materials</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Internal Growth Programs</h3>
            <ul>
                <li><strong>Mentorship Program:</strong> Paired with senior leaders for career guidance</li>
                <li><strong>Technical Leadership Track:</strong> Path to principal engineer and architect roles</li>
                <li><strong>Management Track:</strong> Opportunities to transition into engineering management</li>
                <li><strong>Cross-Department Rotations:</strong> Exposure to product, data science, and DevOps teams</li>
                <li><strong>Speaking Opportunities:</strong> Support for conference presentations and tech talks</li>
                <li><strong>Innovation Time:</strong> 20% time for personal projects and experimentation</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Performance Review & Advancement</h3>
            <p><strong>Review Schedule:</strong> Quarterly check-ins and annual comprehensive reviews</p>
            <p><strong>Promotion Criteria:</strong> Clear technical and leadership competency frameworks</p>
            <p><strong>Career Planning:</strong> Individual development plans with 6-month and annual goals</p>
            <p><strong>360-Degree Feedback:</strong> Multi-source feedback from peers, reports, and management</p>
        </div>
    </div>

    <!-- Page 7: Company Policies & Work Environment -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Company Policies & Work Environment</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Work Schedule & Flexibility</h3>
            <p><strong>Core Hours:</strong> 10:00 AM - 3:00 PM Pacific Time (collaborative time)</p>
            <p><strong>Flexible Hours:</strong> Start time between 8:00 AM - 10:00 AM</p>
            <p><strong>Hybrid Model:</strong> 3 days in office (Tuesday, Wednesday, Thursday), 2 days remote</p>
            <p><strong>Remote Work Policy:</strong> Additional remote work available for special projects</p>
            <p><strong>Compressed Schedule:</strong> Option for 4x10 hour days with manager approval</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Code of Conduct & Ethics</h3>
            <ul>
                <li><strong>Integrity:</strong> Honest and transparent communication in all interactions</li>
                <li><strong>Respect:</strong> Treat all colleagues, clients, and partners with dignity and respect</li>
                <li><strong>Diversity & Inclusion:</strong> Foster an inclusive environment for all team members</li>
                <li><strong>Conflict of Interest:</strong> Disclose any potential conflicts and avoid competing activities</li>
                <li><strong>Anti-Harassment:</strong> Zero tolerance for harassment, discrimination, or retaliation</li>
                <li><strong>Confidentiality:</strong> Protect company and client confidential information</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Technology & Equipment</h3>
            <p><strong>Laptop:</strong> MacBook Pro 16" (M3 Max, 32GB RAM, 1TB SSD) or equivalent PC</p>
            <p><strong>Monitor:</strong> 27" 4K external monitor for office and home setup</p>
            <p><strong>Home Office Stipend:</strong> $1,500 one-time setup allowance</p>
            <p><strong>Software Licenses:</strong> All necessary development tools and software provided</p>
            <p><strong>Mobile Phone:</strong> $100/month stipend for business use of personal device</p>
            <p><strong>Refresh Cycle:</strong> Equipment refreshed every 3 years or as needed</p>
        </div>
    </div>

    <!-- Page 8: Confidentiality & Intellectual Property -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Confidentiality & Intellectual Property</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Confidentiality Obligations</h3>
            <p>During and after your employment with PeopleForge, you agree to:</p>
            <ul>
                <li><strong>Proprietary Information:</strong> Maintain strict confidentiality of all proprietary and confidential information</li>
                <li><strong>Client Data:</strong> Protect all client data and maintain privacy in accordance with regulations</li>
                <li><strong>Business Strategies:</strong> Keep confidential all business plans, strategies, and financial information</li>
                <li><strong>Technical Information:</strong> Protect source code, algorithms, system architectures, and technical documentation</li>
                <li><strong>Personnel Information:</strong> Maintain confidentiality of employee data and internal communications</li>
                <li><strong>Third-Party Information:</strong> Respect confidentiality obligations to partners and vendors</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Intellectual Property Assignment</h3>
            <p>All work products and inventions created during employment belong to PeopleForge, including:</p>
            <ul>
                <li><strong>Software & Code:</strong> All source code, applications, and technical solutions</li>
                <li><strong>Documentation:</strong> Technical specifications, user guides, and process documentation</li>
                <li><strong>Innovations:</strong> New ideas, improvements, and inventions related to our business</li>
                <li><strong>Creative Works:</strong> Marketing materials, content, and visual designs</li>
                <li><strong>Data & Analytics:</strong> Databases, reports, and analytical models</li>
            </ul>
            <p>You agree to assist in obtaining patents, trademarks, or copyrights for any work-related inventions.</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Data Security & Compliance</h3>
            <ul>
                <li><strong>GDPR Compliance:</strong> Adhere to data protection regulations for EU clients</li>
                <li><strong>SOC 2 Requirements:</strong> Follow established security controls and procedures</li>
                <li><strong>Access Controls:</strong> Use only authorized systems and maintain secure credentials</li>
                <li><strong>Incident Reporting:</strong> Report any security incidents or data breaches immediately</li>
            </ul>
        </div>
    </div>

    <!-- Page 9: Employment Terms & Conditions -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Employment Terms & Conditions</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">At-Will Employment</h3>
            <p>Your employment with PeopleForge is at-will, meaning that either you or the company may terminate the employment relationship at any time, with or without cause, and with or without notice. This at-will relationship cannot be changed except in writing signed by both you and an authorized representative of PeopleForge.</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Pre-Employment Requirements</h3>
            <p>This offer is contingent upon successful completion of:</p>
            <ul>
                <li><strong>Background Check:</strong> Criminal history verification</li>
                <li><strong>Employment Verification:</strong> Confirmation of previous employment</li>
                <li><strong>Education Verification:</strong> Degree and certification validation</li>
                <li><strong>Reference Checks:</strong> Professional references from previous managers</li>
                <li><strong>I-9 Verification:</strong> Proof of eligibility to work in the United States</li>
                <li><strong>Technical Assessment:</strong> Final technical validation (if not already completed)</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Offer Validity & Acceptance</h3>
            <p><strong>Offer Expiration:</strong> December 31, 2024 at 5:00 PM Pacific Time</p>
            <p><strong>Start Date Flexibility:</strong> Negotiable within 30 days of January 15, 2025</p>
            <p><strong>Acceptance Process:</strong></p>
            <ul>
                <li>Sign and return this offer letter</li>
                <li>Complete pre-employment requirements</li>
                <li>Coordinate start date with HR and your manager</li>
            </ul>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Termination & Transition</h3>
            <p>In the event of employment termination:</p>
            <ul>
                <li><strong>Notice Period:</strong> Two weeks notice preferred (not required)</li>
                <li><strong>Final Pay:</strong> All accrued salary and unused PTO paid within state requirements</li>
                <li><strong>Benefits Continuation:</strong> COBRA information provided for health coverage</li>
                <li><strong>Equipment Return:</strong> All company property must be returned</li>
                <li><strong>Knowledge Transfer:</strong> Participate in transition activities as requested</li>
            </ul>
        </div>
    </div>

    <!-- Page 10: Acceptance & Next Steps -->
    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Offer Acceptance & Next Steps</h2>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">Welcome to PeopleForge!</h3>
            <p>We are thrilled about the opportunity to have you join our team. Your experience in software engineering, combined with your passion for creating innovative solutions, makes you an ideal fit for our mission of revolutionizing human resources technology.</p>
            
            <p>At PeopleForge, you'll be joining a team of dedicated professionals who are committed to making a positive impact on how companies manage and develop their most valuable asset - their people. We believe that great technology should empower people to do their best work, and we're excited to have you help us build that future.</p>
        </div>
        
        <div class="content-box">
            <h3 style="color: #4338ca; margin-bottom: 10px;">First Day & Onboarding</h3>
            <p>Upon acceptance, you'll receive:</p>
            <ul>
                <li><strong>Welcome Package:</strong> Detailed first-day information and parking instructions</li>
                <li><strong>Equipment Setup:</strong> Technology package shipped to your home address</li>
                <li><strong>Access Credentials:</strong> Email account and system access provisioned</li>
                <li><strong>Buddy Assignment:</strong> Paired with an experienced team member for guidance</li>
                <li><strong>Onboarding Schedule:</strong> Two-week structured orientation program</li>
                <li><strong>Meeting Calendar:</strong> Introductory meetings with key team members</li>
            </ul>
        </div>
        
        <div class="section">
            <h2 style="color: #4338ca; margin-top: 20px;">Signature Section</h2>
            <div style="border: 2px solid #4338ca; padding: 25px; margin-top: 20px; border-radius: 8px;">
                <p><strong>By signing below, I acknowledge that I have read, understood, and agree to all terms and conditions outlined in this employment offer letter.</strong></p>
                
                <table style="width: 100%; margin-top: 30px;">
                    <tr>
                        <td style="width: 60%; padding: 15px 0;">
                            <div style="border-bottom: 2px solid #333; height: 35px; margin-bottom: 8px;"></div>
                            <p><strong>Employee Signature</strong></p>
                        </td>
                        <td style="width: 40%; padding: 15px 0;">
                            <div style="border-bottom: 2px solid #333; height: 35px; margin-bottom: 8px;"></div>
                            <p><strong>Date</strong></p>
                        </td>
                    </tr>
                    <tr>
                        <td style="padding: 15px 0;">
                            <div style="border-bottom: 2px solid #333; height: 35px; margin-bottom: 8px;"></div>
                            <p><strong>Print Name</strong></p>
                        </td>
                        <td></td>
                    </tr>
                </table>
                
                <hr style="margin: 25px 0; border: 1px solid #ddd;">
                
                <p><strong>Company Authorization:</strong></p>
                <table style="width: 100%; margin-top: 15px;">
                    <tr>
                        <td style="width: 60%; padding: 10px 0;">
                            <p><strong>Sarah Rodriguez</strong><br>Head of People & Culture<br>PeopleForge, Inc.</p>
                        </td>
                        <td style="width: 40%; padding: 10px 0;">
                            <p><strong>Date:</strong> <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")#</cfoutput></p>
                        </td>
                    </tr>
                </table>
                
                <div style="text-align: center; margin-top: 25px; padding: 15px; background: #f0f9ff; border-radius: 6px;">
                    <p style="font-size: 12px; color: #1e40af; margin: 0;">
                        <strong>Document ID:</strong> OL-<cfoutput>#DateFormat(Now(), "yyyymmdd")#-#TimeFormat(Now(), "HHMMSS")#</cfoutput><br>
                        <strong>Generated:</strong> <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput>
                    </p>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
</cfhtmltopdf>

<div style="text-align: center; margin-top: 30px; font-family: Arial, sans-serif;">
    <h2 style="color: #4338ca;">✅ Comprehensive Offer Letter Generated!</h2>
    <div style="background: #f0f9ff; padding: 20px; border-radius: 10px; margin: 20px 0;">
        <p style="font-size: 18px; color: #059669;">
            <strong>Document:</strong> OfferLetter_Base.pdf<br>
            <strong>Created:</strong> <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput>
        </p>
    </div>
    <p style="color: #666;">The offer letter is now visible in the PDF viewer on the main page</p>
    <button onclick="window.location.href='../offerLetters.cfm'" 
            style="background: #4338ca; color: white; padding: 15px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px;">
        ← Back to Offer Letter Workflow
    </button>
    
    <script>
        // Auto-refresh the parent page PDF viewer if it exists
        if (window.parent && window.parent.updatePDFSource) {
            window.parent.updatePDFSource('OfferLetter_Base.pdf');
        }
    </script>
</div>
