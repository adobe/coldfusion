<cfhtmltopdf orientation="landscape">

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

<html>
    <head>
        <title>PeopleForge</title>
        <link rel="stylesheet" href="css/style.css">
    </head>
    <style>
    .interview-container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 2rem 1rem;
      background-color: #f8fafc;
    }
    .position-card {
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 0.75rem;
      padding: 1.5rem;
      margin-bottom: 2rem;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
    }
    .position-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1.5rem;
      padding-bottom: 1rem;
      border-bottom: 1px solid #e2e8f0;
    }
    .position-card h2 {
      font-size: 1.75rem;
      font-weight: 600;
      color: #1a202c;
      margin-bottom: 0;
      padding-bottom: 0;
      border-bottom: none;
    }
    .report-button {
        background: #4338ca;
        color: white;
        padding: 0.5rem 1rem;
        border-radius: 0.375rem;
        border: none;
        cursor: pointer;
    }
    .report-button:hover {
        background: #3730a3;;
    }
    .interview-table {
      width: 100%;
      border-collapse: collapse;
      font-size: 0.95rem;
    }
    .interview-table th, 
    .interview-table td {
      padding: 1rem;
      text-align: left;
      border-bottom: 1px solid #e2e8f0;
    }
    .interview-table thead th {
      font-size: 0.8rem;
      font-weight: 600;
      color: #4a5568;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      background-color: #f7fafc;
    }
    .interview-table tbody tr:hover {
      background-color: #f7fafc;
    }
    .interview-table td {
        color: #2d3748;
    }
    .status {
        padding: 0.25rem 0.75rem;
        border-radius: 9999px;
        font-size: 0.8rem;
        font-weight: 600;
        display: inline-block;
        white-space: nowrap;
    }
    .status-scheduled {
        background-color: #ebf8ff;
        color: #3182ce;
    }
    .status-completed {
        background-color: #e6fffa;
        color: #38a169;
    }
    .status-pending {
        background-color: #fffaf0;
        color: #dd6b20;
    }
    .status-hired {
        background-color: #c6f6d5;
        color: #2f855a;
    }
    .status-rejected {
        background-color: #fed7d7;
        color: #c53030;
    }
    .image-container {
        margin-top: 2rem;
        padding-top: 1rem;
        page-break-inside: avoid;
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 2rem;
        justify-items: center;
    }
    .image-container svg {
        opacity: 0.75;
    }
</style>
    <body>
        <div class="position-card">
        <div class="position-header">
            <h2>Program Manager</h2>
        </div>
        <table class="interview-table">
            <thead>
                <tr>
                    <th>Candidate Name</th>
                    <th>Years of Exp.</th>
                    <th>Company</th>
                    <th>Round 1</th>
                    <th>Round 2</th>
                    <th>Round 3</th>
                    <th>Final Verdict</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>Emily White</td>
                    <td>4</td>
                    <td>Creative Agency</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-hired">Hired</span></td>
                </tr>
                <tr>
                    <td>Michael Brown</td>
                    <td>3</td>
                    <td>Media House</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-rejected">Rejected</span></td>
                </tr>
                 <tr>
                    <td>Sarah Green</td>
                    <td>5</td>
                    <td>Digital Marketing LLC</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-scheduled">Scheduled</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="image-container">
        <svg width="250" height="150" viewBox="0 0 250 150" xmlns="http://www.w3.org/2000/svg">
            <rect x="20" y="70" width="40" height="60" fill="#a5b4fc" rx="4"/>
            <rect x="70" y="40" width="40" height="90" fill="#818cf8" rx="4"/>
            <rect x="120" y="20" width="40" height="110" fill="#6366f1" rx="4"/>
            <rect x="170" y="50" width="40" height="80" fill="#4f46e5" rx="4"/>
            <line x1="10" y1="130" x2="220" y2="130" stroke="#94a3b8" stroke-width="2"/>
        </svg>
        <svg width="250" height="150" viewBox="0 0 200 150" xmlns="http://www.w3.org/2000/svg">
            <g opacity="0.9">
                <circle cx="60" cy="50" r="20" fill="#a5b4fc"/>
                <path d="M40,110 C40,80 80,80 80,110 Z" fill="#c7d2fe"/>
                <circle cx="140" cy="50" r="20" fill="#a5b4fc"/>
                <path d="M120,110 C120,80 160,80 160,110 Z" fill="#c7d2fe"/>
                <circle cx="100" cy="75" r="25" fill="#818cf8"/>
                <path d="M75,130 C75,95 125,95 125,130 Z" fill="#a5b4fc"/>
            </g>
        </svg>
    </div>
    </body>
</html>
</cfhtmltopdf>