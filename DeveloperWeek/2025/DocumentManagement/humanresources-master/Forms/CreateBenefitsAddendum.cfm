<cfhtmltopdf margintop="0.5" marginbottom="0.5" marginleft="0.75" marginright="0.75" destination="../BenefitsAddendum.pdf" overwrite="yes">
    <cfhtmltopdfitem type="header">
        <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-bottom: 1px solid #ddd; padding-bottom: 5px;">
            <strong>PeopleForge, Inc. - Benefits Addendum - Confidential</strong>
        </div>
    </cfhtmltopdfitem>
    
    <cfhtmltopdfitem type="footer">
        <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-top: 1px solid #ddd; padding-top: 5px;">
            <p>Page _PAGENUMBER of _LASTPAGENUMBER | Generated: <cfoutput>#DateFormat(Now(), "mm/dd/yyyy")# #TimeFormat(Now(), "HH:mm")#</cfoutput></p>
        </div>
    </cfhtmltopdfitem>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Benefits Addendum</title>
    <style>
        body { font-family: Arial; line-height: 1.6; color: #333; padding: 20px; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 3px solid #059669; padding-bottom: 20px; }
        .section { margin-bottom: 25px; }
        .section-title { font-size: 18px; font-weight: bold; color: #059669; border-bottom: 2px solid #e5e7eb; padding-bottom: 5px; margin-bottom: 15px; }
        .benefit-table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        .benefit-table th, .benefit-table td { border: 1px solid #d1d5db; padding: 10px; text-align: left; }
        .benefit-table th { background: #f3f4f6; font-weight: bold; }
        .highlight-box { background: #ecfdf5; border: 1px solid #6ee7b7; padding: 15px; border-radius: 8px; margin: 15px 0; }
        .page-break { page-break-before: always; }
    </style>
</head>
<body>
    <div class="header">
        <h1 style="color: #059669;">🎯 Employee Benefits Addendum</h1>
        <p style="font-style: italic;">Comprehensive Benefits Package Details</p>
    </div>

    <div class="section">
        <h2 class="section-title">Health & Wellness Benefits</h2>
        <div class="highlight-box">
            <p><strong>Effective Date:</strong> First day of employment</p>
        </div>
        
        <table class="benefit-table">
            <tr>
                <th width="30%">Benefit Type</th>
                <th width="40%">Coverage Details</th>
                <th width="30%">Employee Cost</th>
            </tr>
            <tr>
                <td><strong>Medical Insurance</strong></td>
                <td>Blue Cross Blue Shield PPO<br>$500 deductible, 90% coverage</td>
                <td>$0 (100% company paid)</td>
            </tr>
            <tr>
                <td><strong>Dental Insurance</strong></td>
                <td>Delta Dental Premium<br>Preventive care 100% covered</td>
                <td>$0 (100% company paid)</td>
            </tr>
            <tr>
                <td><strong>Vision Insurance</strong></td>
                <td>VSP Premium Plan<br>$150 frame allowance annually</td>
                <td>$0 (100% company paid)</td>
            </tr>
            <tr>
                <td><strong>Life Insurance</strong></td>
                <td>2x annual salary coverage<br>Accidental death & dismemberment</td>
                <td>$0 (100% company paid)</td>
            </tr>
            <tr>
                <td><strong>Disability Insurance</strong></td>
                <td>Short-term: 60% of salary<br>Long-term: 60% of salary</td>
                <td>$0 (100% company paid)</td>
            </tr>
        </table>

        <div class="highlight-box">
            <p><strong>Family Coverage:</strong> Dependents covered at 80% company contribution</p>
            <ul>
                <li>Spouse: $150/month employee contribution</li>
                <li>Children: $100/month per child employee contribution</li>
                <li>Family Plan: $300/month total employee contribution</li>
            </ul>
        </div>
    </div>

    <div class="section">
        <h2 class="section-title">Retirement & Financial Benefits</h2>
        
        <table class="benefit-table">
            <tr>
                <th>Benefit</th>
                <th>Details</th>
                <th>Vesting</th>
            </tr>
            <tr>
                <td><strong>401(k) Plan</strong></td>
                <td>6% company match<br>Fidelity provider<br>Low-cost index funds available</td>
                <td>Immediate vesting</td>
            </tr>
            <tr>
                <td><strong>Stock Options</strong></td>
                <td>Equity participation program<br>Annual grants based on performance</td>
                <td>4-year vesting (25% annually)</td>
            </tr>
            <tr>
                <td><strong>Financial Planning</strong></td>
                <td>Free consultation with financial advisor<br>Quarterly workshops</td>
                <td>Immediate</td>
            </tr>
        </table>
    </div>

    <div class="page-break"></div>
    <div class="section">
        <h2 class="section-title">Time Off & Work-Life Balance</h2>
        
        <table class="benefit-table">
            <tr>
                <th width="25%">Time Off Type</th>
                <th width="35%">Accrual/Allocation</th>
                <th width="40%">Policy Details</th>
            </tr>
            <tr>
                <td><strong>Paid Time Off (PTO)</strong></td>
                <td>25 days annually<br>Prorated first year</td>
                <td>Use it or lose it policy<br>Max carryover: 5 days</td>
            </tr>
            <tr>
                <td><strong>Sick Leave</strong></td>
                <td>Flexible/Unlimited<br>Manager discretion</td>
                <td>No accrual limits<br>Medical documentation for 3+ days</td>
            </tr>
            <tr>
                <td><strong>Personal Days</strong></td>
                <td>3 floating holidays</td>
                <td>Can be used for religious/cultural observances</td>
            </tr>
            <tr>
                <td><strong>Bereavement</strong></td>
                <td>5 days paid leave</td>
                <td>Immediate family members<br>Additional unpaid leave available</td>
            </tr>
            <tr>
                <td><strong>Jury Duty</strong></td>
                <td>Fully paid time off</td>
                <td>No limit on duration</td>
            </tr>
        </table>

        <div class="highlight-box">
            <p><strong>Company Holidays (12 days):</strong></p>
            <ul style="display: flex; flex-wrap: wrap; list-style: none; padding: 0;">
                <li style="width: 50%; margin-bottom: 5px;">• New Year's Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Martin Luther King Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Presidents Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Memorial Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Independence Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Labor Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Indigenous Peoples Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Veterans Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Thanksgiving Day</li>
                <li style="width: 50%; margin-bottom: 5px;">• Day after Thanksgiving</li>
                <li style="width: 50%; margin-bottom: 5px;">• Christmas Eve</li>
                <li style="width: 50%; margin-bottom: 5px;">• Christmas Day</li>
            </ul>
        </div>
    </div>

    <div class="section">
        <h2 class="section-title">Professional Development & Perks</h2>
        
        <table class="benefit-table">
            <tr>
                <th>Category</th>
                <th>Benefit</th>
                <th>Annual Allowance</th>
            </tr>
            <tr>
                <td rowspan="3"><strong>Learning & Development</strong></td>
                <td>Training courses & certifications</td>
                <td>$2,500</td>
            </tr>
            <tr>
                <td>Conference attendance</td>
                <td>Included in training budget</td>
            </tr>
            <tr>
                <td>Books & online learning platforms</td>
                <td>$500 additional</td>
            </tr>
            <tr>
                <td rowspan="4"><strong>Wellness & Lifestyle</strong></td>
                <td>Gym membership reimbursement</td>
                <td>$1,200</td>
            </tr>
            <tr>
                <td>Mental health support (therapy sessions)</td>
                <td>$2,000</td>
            </tr>
            <tr>
                <td>Home office setup allowance</td>
                <td>$1,500 (one-time)</td>
            </tr>
            <tr>
                <td>Technology refresh</td>
                <td>Every 3 years</td>
            </tr>
        </table>

        <div class="highlight-box">
            <p><strong>Additional Perks:</strong></p>
            <ul>
                <li>Free parking at office location</li>
                <li>Catered lunch on Fridays</li>
                <li>Monthly team building activities</li>
                <li>Annual company retreat</li>
                <li>Employee referral bonus: $2,000</li>
                <li>Transit/commute subsidies up to $200/month</li>
                <li>Pet-friendly office environment</li>
            </ul>
        </div>
    </div>

    <div class="section" style="border: 2px solid #059669; padding: 20px; border-radius: 10px; margin-top: 30px;">
        <h3 style="color: #059669; text-align: center;">📋 Benefits Enrollment</h3>
        <p style="text-align: center;"><strong>Enrollment Deadline:</strong> Within 30 days of start date</p>
        <p style="text-align: center;">HR will schedule a benefits orientation session during your first week.</p>
        <p style="text-align: center; font-style: italic;">Questions? Contact: benefits@peopleforge.com | (555) 123-4567 ext. 102</p>
    </div>
</body>
</html>
</cfhtmltopdf>

<div style="text-align: center; margin-top: 30px; font-family: Arial, sans-serif;">
    <h2 style="color: #059669;">✅ Benefits Addendum Generated!</h2>
    <div style="background: #ecfdf5; padding: 20px; border-radius: 10px; margin: 20px 0;">
        <p style="font-size: 18px; color: #047857;">
            <strong>Document:</strong> BenefitsAddendum.pdf<br>
            <strong>Pages:</strong> 2 pages<br>
            <strong>Created:</strong> <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput>
        </p>
    </div>
    <p style="color: #666;">Ready to merge with the main offer letter document</p>
    <button onclick="window.location.href='../offerLetters.cfm'" 
            style="background: #059669; color: white; padding: 15px 30px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px;">
        ← Back to Workflow
    </button>
</div>
