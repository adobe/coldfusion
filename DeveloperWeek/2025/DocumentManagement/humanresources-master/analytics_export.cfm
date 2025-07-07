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
    <!-- amCharts scripts -->
    <script src="https://www.amcharts.com/lib/3/amcharts.js"></script>
    <script src="https://www.amcharts.com/lib/3/serial.js"></script>
    <script src="https://www.amcharts.com/lib/3/pie.js"></script>
    <script src="https://www.amcharts.com/lib/3/plugins/export/export.min.js"></script>
    <link rel="stylesheet" href="https://www.amcharts.com/lib/3/plugins/export/export.css" type="text/css" media="all" />
    
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 40px; 
            color: #333; 
            background: #fff;
        }
        .header { 
            text-align: center; 
            border-bottom: 2px solid #4338ca; 
            padding-bottom: 15px; 
            margin-bottom: 30px; 
        }
        .header h1 { 
            margin: 0; 
            color: #4338ca; 
            font-size: 28px; 
        }
        .header p { 
            margin: 5px 0; 
            color: #4a5568; 
            font-size: 14px;
        }
        .chart-section {
            margin-bottom: 40px;
            page-break-inside: avoid;
            margin-top: 100px;
            padding-top: 100px;
        }
        .chart-title {
            font-size: 18px;
            font-weight: bold;
            color: #2d3748;
            margin-bottom: 15px;
            text-align: center;
        }
        .chart-container {
            text-align: center;
            margin: 20px 0;
        }
        .chart-div {
            width: 500px;
            height: 400px;
            margin: 0 auto;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 15px;
            border-top: 1px solid #e2e8f0;
            font-size: 12px;
            color: #6b7280;
        }
    </style>
</head>
<body>

    <div class="chart-section">
        <div class="chart-title">Department Distribution</div>
        <div class="chart-container">
            <div id="department-chart" class="chart-div"></div>
        </div>
    </div>

    <div class="chart-section">
        <div class="chart-title">Employee Tenure</div>
        <div class="chart-container">
            <div id="tenure-chart" class="chart-div"></div>
        </div>
    </div>


    <script>
        // Department Distribution Chart (Pie)
        AmCharts.makeChart("department-chart", {
            "type": "pie",
            "theme": "light",
            "colors": ["#4338ca", "#6366f1", "#818cf8", "#a5b4fc", "#c7d2fe"],
            "dataProvider": [{
                "department": "Engineering",
                "count": 45
            }, {
                "department": "Sales & Marketing",
                "count": 25
            }, {
                "department": "Customer Support",
                "count": 15
            }, {
                "department": "Human Resources",
                "count": 8
            }, {
                "department": "Administration",
                "count": 7
            }],
            "titleField": "department",
            "valueField": "count",
            "labelText": "[[title]]<br> ([[percents]]%)",
            "balloonText": "[[title]]<br><span style='font-size:14px'><b>[[value]]</b> ([[percents]]%)</span>",
            "export": {
                "enabled": true
            }
        });

        // Employee Tenure Chart (Column)
        AmCharts.makeChart("tenure-chart", {
            "type": "serial",
            "theme": "light",
            "dataProvider": [{
                "tenure": "< 1 Year",
                "count": 10
            }, {
                "tenure": "1-3 Years",
                "count": 22
            }, {
                "tenure": "3-5 Years",
                "count": 18
            }, {
                "tenure": "5-10 Years",
                "count": 10
            }, {
                "tenure": "10+ Years",
                "count": 2
            }],
            "valueAxes": [{
                "gridColor": "#FFFFFF",
                "gridAlpha": 0.2,
                "dashLength": 0
            }],
            "gridAboveGraphs": true,
            "startDuration": 1,
            "graphs": [{
                "balloonText": "[[category]]: <b>[[value]] employees</b>",
                "fillAlphas": 0.9,
                "lineAlpha": 0.2,
                "type": "column",
                "valueField": "count",
                "fillColors": "#6366f1",
                "lineColor": "#4338ca"
            }],
            "chartCursor": {
                "categoryBalloonEnabled": false,
                "cursorAlpha": 0,
                "zoomable": false
            },
            "categoryField": "tenure",
            "categoryAxis": {
                "gridPosition": "start",
                "gridAlpha": 0
            },
            "export": {
                "enabled": true
            }
        });
    </script>
</body>
</html>
</cfhtmltopdf> 