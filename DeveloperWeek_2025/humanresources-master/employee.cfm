<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <title>PeopleForge &mdash; Free Business Website Template by Colorlib</title>
  <link rel="stylesheet" href="css/style.css">
  <!-- amCharts scripts -->
  <script src="https://www.amcharts.com/lib/3/amcharts.js"></script>
  <script src="https://www.amcharts.com/lib/3/serial.js"></script>
  <script src="https://www.amcharts.com/lib/3/pie.js"></script>
  <script src="https://www.amcharts.com/lib/3/plugins/export/export.min.js"></script>
  <link rel="stylesheet" href="https://www.amcharts.com/lib/3/plugins/export/export.css" type="text/css" media="all" />
  <style>
      .analytics-container {
        padding: 3rem 0;
        background-color: #f8fafc;
      }
      .analytics-header {
        text-align: center;
        margin-bottom: 3rem;
      }
      .analytics-header h2 {
        font-size: 2.25rem;
        font-weight: 600;
        color: #1a202c;
      }
      .charts-wrapper {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
        gap: 2rem;
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 1rem;
      }
      .chart-card {
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 0.75rem;
        padding: 1.5rem;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.1);
        display: flex;
        flex-direction: column;
        align-items: center;
      }
      .chart-card h3 {
        font-size: 1.25rem;
        font-weight: 600;
        margin-bottom: 1.5rem;
        text-align: center;
      }
      .chart-div {
        width: 100%;
        height: 400px;
      }
      .payslips-section {
        padding: 3rem 0;
      }
      .payslips-header {
        text-align: center;
        margin-bottom: 3rem;
      }
      .payslips-header h2 {
        font-size: 2.25rem;
        font-weight: 600;
        color: #1a202c;
      }
      .payslips-wrapper {
        display: grid;
        grid-template-columns: 1fr 2fr;
        gap: 2rem;
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 1rem;
        align-items: flex-start;
      }
      .payslip-form-card, .payslip-viewer-card {
        background: white;
        border: 1px solid #e2e8f0;
        border-radius: 0.75rem;
        padding: 2rem;
        box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1);
      }
      .payslip-form-card h3, .payslip-viewer-card h3 {
        font-size: 1.25rem;
        font-weight: 600;
        margin-bottom: 1.5rem;
        border-bottom: 1px solid #e2e8f0;
        padding-bottom: 1rem;
      }
      .employee-info-table {
        width: 100%;
        margin-bottom: 1.5rem;
      }
      .employee-info-table th {
        text-align: left;
        font-weight: 600;
        padding: 0.5rem 0;
        color: #4a5568;
      }
      .form-group {
        margin-bottom: 1.5rem;
      }
      .form-group label {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 600;
        color: #4a5568;
      }
      .month-dropdown {
        width: 100%;
        padding: 0.75rem;
        border-radius: 0.375rem;
        border: 1px solid #d1d5db;
        font-size: 1rem;
      }
      .generate-button {
        width: 100%;
        padding: 0.75rem;
        background-color: #4338ca;
        color: white;
        border: none;
        border-radius: 0.375rem;
        font-size: 1rem;
        font-weight: 600;
        cursor: pointer;
        transition: background-color 0.2s;
      }
      .generate-button:hover {
        background-color: #3730a3;
      }
      .export-button {
        display: inline-block;
        padding: 0.75rem 2rem;
        background-color: #4338ca;
        color: white;
        border: none;
        border-radius: 0.375rem;
        font-size: 1rem;
        font-weight: 600;
        cursor: pointer;
        transition: background-color 0.2s;
        text-decoration: none;
        text-align: center;
      }
      .export-button:hover {
        background-color: #3730a3;
        color: white;
        text-decoration: none;
      }
      .payslip-iframe {
        width: 100%;
        height: 600px;
        border: 1px solid #e2e8f0;
        border-radius: 0.5rem;
      }
    </style>
</head>
<body>

<cfscript>
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

    function getEmployeeById(id) {
        for (var emp in employees) {
            if (emp.id == id) {
                return emp;
            }
        }
        return employees[0]; // Default to first employee
    }
</cfscript>

  <div class="js-animsition animsition" id="site-wrap" data-animsition-in-class="fade-in" data-animsition-out-class="fade-out">


    <header class="templateux-navbar" role="banner">

      <div class="container"  data-aos="fade-down">
        <div class="row">

          <div class="col-3 templateux-logo">
            <a href="index.html" class="animsition-link" style="display: flex; align-items: center; text-decoration: none; gap: 20px; background-color: #f1f5f9; padding: 5px 4px; border-radius: 6px; opacity: 0.7;">
                <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" padding-left: 10px; viewBox="0 0 24 24" fill="none" stroke="#4338ca" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
                <span style="font-size: 28px; font-style: italic; color:black;">PeopleForge</span>
            </a>
          </div>
          <nav class="col-9 site-nav">
            <button class="d-block d-md-none hamburger hamburger--spin templateux-toggle templateux-toggle-light ml-auto templateux-toggle-menu" data-toggle="collapse" data-target="#mobile-menu" aria-controls="mobile-menu" aria-expanded="false" aria-label="Toggle navigation">
              <span class="hamburger-box">
                <span class="hamburger-inner"></span>
              </span>
            </button> <!-- .templateux-toggle -->

            <ul class="sf-menu templateux-menu d-none d-md-block">
              <li class="active">
                <a href="index.html" class="animsition-link">Home</a>
              </li>
              <li><a href="candidate.html" class="animsition-link">Candidate</a></li>
              <li><a href="employee.cfm" class="animsition-link">Employee</a></li>
              <li><a href="about.html" class="animsition-link">About</a></li>
              <li><a href="contact.html" class="animsition-link">Contact</a></li>
            </ul> <!-- .templateux-menu -->

          </nav> <!-- .site-nav -->
          

        </div> <!-- .row -->
      </div> <!-- .container -->
    </header> <!-- .templateux-navba -->
    
    <div class="templateux-cover" style="background-image: url(images/hero_1.jpg);">
      <div class="container">
        <div class="row align-items-lg-center">

          <div class="col-lg-6 order-lg-1 text-center mx-auto">
            <h1 class="heading mb-3 text-white" data-aos="fade-up">Employee Management</h1>
            <p class="lead mb-5 text-white" data-aos="fade-up"  data-aos-delay="100">Manage your employees with ease and efficiency.</p>
          </div>
          
        </div>
      </div>
    </div> <!-- .templateux-cover -->



    <div class="analytics-container">
      <div class="container">
        <div class="analytics-header">
          <h2>Employee Analytics Dashboard</h2>
        </div>
        <div class="charts-wrapper">
          <div class="chart-card">
            <h3>Department Distribution</h3>
            <div id="department-chart" class="chart-div"></div>
          </div>
          <div class="chart-card">
            <h3>Employee Tenure</h3>
            <div id="tenure-chart" class="chart-div"></div>
          </div>
          <!--- <div class="chart-card">
            <h3>Employee Satisfaction</h3>
            <div class="chart-div">
                <cfchart type="horizontalbar" title="Satisfaction Levels (%)" style="blue" width="500" height="400">
                    <cfchartseries type="bar">
                        <cfchartdata item="Highly Satisfied" value="75">
                        <cfchartdata item="Neutral" value="15">
                        <cfchartdata item="Dissatisfied" value="10">
                    </cfchartseries>
                </cfchart>
            </div>
          </div>
          <div class="chart-card">
            <h3>Gender Distribution</h3>
            <div class="chart-div">
                <cfchart type="pie" title="Gender Distribution" style="blue" width="500" height="400">
                    <cfchartseries>
                        <cfchartdata item="Male" value="62">
                        <cfchartdata item="Female" value="38">
                        <cfchartdata item="Other/Prefer not to say" value="5">
                    </cfchartseries>
                </cfchart>
            </div> --->
          </div>
        </div>
        <div class="text-center mt-4">
          <a href="analytics_export.cfm" target="_blank" class="export-button">
            <i class="fas fa-download mr-2"></i>Export Analytics to PDF
          </a>
        </div>
      </div>
    </div>

    <div class="payslips-section">
      <div class="container">
          <div class="payslips-header">
              <h2>View Payslips</h2>
          </div>
          <div class="payslips-wrapper">
              <div class="payslip-form-card">
                  <h3>Generate Employee Payslip</h3>
                  <form action="payslip_generator.cfm" method="post" target="payslip_frame" id="payslipForm">
                    <div class="form-group">
                        <label for="employee-select">Select Employee:</label>
                        <select name="employeeId" id="employee-select" class="month-dropdown">
                            <cfloop array="#employees#" index="emp">
                                <cfoutput><option value="#emp.id#">#emp.name#</option></cfoutput>
                            </cfloop>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Employee ID:</label>
                        <div style="display: inline-block; padding: 8px 12px; background-color: #f7fafc; border: 1px solid #e2e8f0; border-radius: 6px; margin-left: 8px;">
                            <span id="employee-id-display" style="font-weight: bold; color: #2d3748;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="month-select">Select Month:</label>
                        <select name="month" id="month-select" class="month-dropdown">
                            <cfloop from="1" to="12" index="i">
                                <cfset monthName = MonthAsString(i)>
                                <cfoutput><option value="#monthName#">#monthName#</option></cfoutput>
                            </cfloop>
                        </select>
                    </div>
                    <input type="hidden" name="employeeName" id="hiddenEmployeeName">
                    <input type="hidden" name="employeeId" id="hiddenEmployeeId">
                    <button type="submit" class="generate-button">Generate Payslip</button>
                  </form>
              </div>
              <div class="payslip-viewer-card">
                  <h3>Payslip Preview</h3>
                  <iframe name="payslip_frame" id="payslip_frame" class="payslip-iframe" src="payslip_generator.cfm"></iframe>
              </div>
          </div>
      </div>
  </div>



    <div class="templateux-section">

      <div class="container"  data-aos="fade-up">
        <div class="row">
          <div class="col-lg-7">
            <h2 class="mb-5">Our Agency</h2>
            <div class="owl-carousel wide-slider">
              <div class="item">
                <img src="images/slider-1.jpg" alt="Free template by TemplateUX.com" class="img-fluid">
              </div>
              <div class="item">
                <img src="images/slider-2.jpg" alt="Free template by TemplateUX.com" class="img-fluid">
              </div>
              <div class="item">
                <img src="images/slider-3.jpg" alt="Free template by TemplateUX.com" class="img-fluid">
              </div>
            </div> <!-- .owl-carousel -->
          </div>
          <div class="col-lg-5 pl-lg-5">
            <h2 class="mb-5">Why Us?</h2>
            <div class="accordion" id="accordionExample">


              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" data-toggle="collapse" data-target="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
                  Provident alias</a>
                </h2>

                <div id="collapseOne" class="collapse show" aria-labelledby="headingOne" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Lorem ipsum dolor sit amet, <a href="#">Cnsectetur adipisicing</a> elit. Eos quos incidunt, perspiciatis, ad saepe, magnam error adipisci vitae ut provident alias! Odio debitis error ipsum molestiae voluptas accusantium quibusdam animi, soluta explicabo asperiores aliquid, modi natus suscipit deleniti. Corrupti, autem.</p>
                  </div>
                </div>
              </div>
              
              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" class="collapsed" data-toggle="collapse" data-target="#collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
                    Debitis ad similique tempore
                  </a>
                </h2>
                
                <div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Repellat voluptate animi hic quasi sequi odio, vitae dolorum soluta sapiente debitis ad similique tempore, aliquam quae nam deserunt dicta ullam perspiciatis minima, quam. Quis repellat corporis aperiam, veritatis nemo iure inventore.</p>
                  </div>
                </div>
              </div>
              
              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" class="collapsed" data-toggle="collapse" data-target="#collapseThree" aria-expanded="false" aria-controls="collapseThree">
                    Lorem ipsum dolor sit amet
                  </a>
                </h2>
                
                <div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Ipsum et dolorum libero consequuntur facere molestias beatae quod labore quidem ad quasi eius pariatur quae nam quo soluta optio dicta, doloribus ullam fugit nulla! Itaque necessitatibus eum sed quam eos id!</p>
                  </div>
                </div>
              </div>
              
              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" class="collapsed" data-toggle="collapse" data-target="#collapseFour" aria-expanded="false" aria-controls="collapseFour">
                    Modi natus suscipit
                  </a>
                </h2>

                <div id="collapseFour" class="collapse" aria-labelledby="headingFour" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Lorem ipsum dolor sit amet, consectetur adipisicing elit. Eos quos incidunt, perspiciatis, ad saepe, magnam error adipisci vitae ut provident alias! Odio debitis error ipsum molestiae voluptas accusantium quibusdam animi, soluta explicabo asperiores aliquid, modi natus suscipit deleniti. Corrupti, autem.</p>
                  </div>
                </div>
              </div>
              
            </div>
          </div>
        </div>
      </div>
    </div> <!-- .templateux-section -->
    

    <footer class="templateux-footer bg-light">
      <div class="container">

        <div class="row mb-5">
          <div class="col-md-4 pr-md-5">
            <div class="block-footer-widget">
              <h3>About</h3>
              <p></p>
            </div>
          </div>

          <div class="col-md-8">
            <div class="row">
              <div class="col-md-3">
                <div class="block-footer-widget">
                  <h3>Learn More</h3>
                  <ul class="list-unstyled">
                    <li><a href="#">How it works?</a></li>
                    <li><a href="#">Useful Tools</a></li>
                    <li><a href="#">Pricing</a></li>
                    <li><a href="#">Sitemap</a></li>
                  </ul>
                </div>
              </div>
              <div class="col-md-3">
                <div class="block-footer-widget">
                  <h3>Support</h3>
                  <ul class="list-unstyled">
                    <li><a href="#">FAQ</a></li>
                    <li><a href="#">Contact Us</a></li>
                    <li><a href="#">Help Desk</a></li>
                    <li><a href="#">Knowledgebase</a></li>
                  </ul>
                </div>
              </div>
              <div class="col-md-3">
                <div class="block-footer-widget">
                  <h3>About Us</h3>
                  <ul class="list-unstyled">
                    <li><a href="#">About Us</a></li>
                    <li><a href="#">Careers</a></li>
                    <li><a href="#">Terms of Service</a></li>
                    <li><a href="#">Privacy Policy</a></li>
                  </ul>
                </div>
              </div>

              <div class="col-md-3">
                <div class="block-footer-widget">
                  <h3>Connect With Us</h3>
                  <ul class="list-unstyled block-social">
                    <li><a href="#" class="p-1"><span class="icon-facebook-square"></span></a></li>
                    <li><a href="#" class="p-1"><span class="icon-twitter"></span></a></li>
                    <li><a href="#" class="p-1"><span class="icon-github"></span></a></li>
                  </ul>
                </div>
              </div>
            </div> <!-- .row -->

          </div>
        </div> <!-- .row -->

        <div class="row pt-5 text-center">
          <div class="col-md-12 text-center"><p>
            <!-- Link back to Colorlib can't be removed. Template is licensed under CC BY 3.0. -->
            Copyright &copy;<script>document.write(new Date().getFullYear());</script> All rights reserved | This template is made with <i class="icon-heart text-danger" aria-hidden="true"></i> by <a href="https://colorlib.com" target="_blank" class="text-primary">Colorlib</a>
            <!-- Link back to Colorlib can't be removed. Template is licensed under CC BY 3.0. -->
          </p></div>
        </div> <!-- .row -->

      </div>
    </footer> <!-- .templateux-footer -->


  </div> <!-- .js-animsition -->


  <script src="js/scripts-all.js"></script>
  <script src="js/main.js"></script>

  <script>
    document.addEventListener("DOMContentLoaded", function() {
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

        const employeeSelect = document.getElementById('employee-select');
        const employeeIdDisplay = document.getElementById('employee-id-display');

        function updateEmployeeInfo() {
            employeeIdDisplay.textContent = employeeSelect.value;
        }

        // Add event listener
        employeeSelect.addEventListener('change', updateEmployeeInfo);

        // Set initial state on page load
        updateEmployeeInfo();
    });
    </script>
</body>
</html>