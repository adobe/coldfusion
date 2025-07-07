<cfif structKeyExists(form, "employeeId") and structKeyExists(form, "month")>
    <cfscript>
        // This should ideally come from a database or a shared model
        employees = [
            {id: "E12345", name: "John Doe"},
            {id: "E67890", name: "Jane Smith"},
            {id: "E11223", name: "Peter Jones"},
            {id: "E44556", name: "Emily White"},
            {id: "E77889", name: "Michael Brown"},
            {id: "E99001", name: "Sarah Green"},
            {id: "E22334", name: "David Lee"},
            {id: "E55667", name: "Chris Harris"},
            {id: "E88990", name: "Jessica Miller"},
            {id: "E12121", name: "Robert Wilson"}
        ];

        employeeId = form.employeeId;
        employeeName = "";

        for (emp in employees) {
            if (emp.id == employeeId) {
                employeeName = emp.name;
                break;
            }
        }

        month = form.month;
        year = Year(Now());

        basicPay = 5000;
        hra = 2000;
        otherAllowances = 1000;
        totalEarnings = basicPay + hra + otherAllowances;

        tax = 800;
        providentFund = 500;
        totalDeductions = tax + providentFund;

        netSalary = totalEarnings - totalDeductions;
    </cfscript>

    <cfhtmltopdf>
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; color: #333; }
                .payslip-container { border: 1px solid #e2e8f0; padding: 25px; border-radius: 10px; background: #fff; }
                .header { text-align: center; border-bottom: 2px solid #e2e8f0; padding-bottom: 15px; margin-bottom: 25px; }
                .header h1 { margin: 0; color: #4338ca; font-size: 24px; }
                .header p { margin: 5px 0; color: #4a5568; }
                .details-table { width: 100%; margin-bottom: 25px; font-size: 14px; }
                .details-table td { padding: 8px 0; }
                .details-table strong { color: #2d3748; }
                .salary-table { width: 100%; border-collapse: collapse; font-size: 14px; }
                .salary-table th, .salary-table td { border: 1px solid #e2e8f0; padding: 12px; text-align: left; }
                .salary-table th { background-color: #f7fafc; font-weight: 600; color: #4a5568; }
                .salary-table .amount { text-align: right; }
                .summary { text-align: right; margin-top: 25px; }
                .net-pay { font-weight: bold; font-size: 1.2em; color: #4338ca; }
            </style>
        </head>
        <body>
            <div class="payslip-container">
                <div class="header">
                    <h1>PeopleForge Inc.</h1>
                    <p>Payslip for the month of <cfoutput>#month# #year#</cfoutput></p>
                </div>

                <table class="details-table">
                    <tr>
                        <td><strong>Employee Name:</strong> <cfoutput>#employeeName#</cfoutput></td>
                        <td><strong>Employee ID:</strong> <cfoutput>#employeeId#</cfoutput></td>
                    </tr>
                </table>

                <table class="salary-table">
                    <thead>
                        <tr>
                            <th>Earnings</th>
                            <th class="amount">Amount ($)</th>
                            <th>Deductions</th>
                            <th class="amount">Amount ($)</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Basic Pay</td>
                            <td class="amount"><cfoutput>#NumberFormat(basicPay, '9,999.00')#</cfoutput></td>
                            <td>Income Tax</td>
                            <td class="amount"><cfoutput>#NumberFormat(tax, '9,999.00')#</cfoutput></td>
                        </tr>
                        <tr>
                            <td>House Rent Allowance (HRA)</td>
                            <td class="amount"><cfoutput>#NumberFormat(hra, '9,999.00')#</cfoutput></td>
                            <td>Provident Fund (PF)</td>
                            <td class="amount"><cfoutput>#NumberFormat(providentFund, '9,999.00')#</cfoutput></td>
                        </tr>
                        <tr>
                            <td>Other Allowances</td>
                            <td class="amount"><cfoutput>#NumberFormat(otherAllowances, '9,999.00')#</cfoutput></td>
                            <td></td>
                            <td class="amount"></td>
                        </tr>
                        <tr>
                            <th>Total Earnings</th>
                            <th class="amount"><cfoutput>#NumberFormat(totalEarnings, '9,999.00')#</cfoutput></th>
                            <th>Total Deductions</th>
                            <th class="amount"><cfoutput>#NumberFormat(totalDeductions, '9,999.00')#</cfoutput></th>
                        </tr>
                    </tbody>
                </table>

                <div class="summary">
                    <p class="net-pay">Net Salary: $<cfoutput>#NumberFormat(netSalary, '9,999.00')#</cfoutput></p>
                </div>
            </div>
        </body>
        </html>
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
                    Interview Report
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
    </cfhtmltopdf>

<cfelse>
    <div style="font-family: Arial, sans-serif; padding: 20px;">
        <p>Please select an employee and a month, then click "Generate Payslip" to see the preview.</p>
    </div>
</cfif> 