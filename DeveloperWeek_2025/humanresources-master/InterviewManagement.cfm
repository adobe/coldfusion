<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
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
</style>
<body>

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
              <li>
              <li><a href="employee.cfm" class="animsition-link">Employee</a></li>
              
              <li><a href="about.html" class="animsition-link">About</a></li>
              <li><a href="contact.html" class="animsition-link">Contact</a></li>
            </ul> <!-- .templateux-menu -->
          </nav> <!-- .site-nav -->
          

        </div> <!-- .row -->
      </div> <!-- .container -->
    </header> <!-- .templateux-navba -->
    
    <div class="templateux-cover" style="background-image: url(images/interviewHero.webp);">
      <div class="container">
        <div class="row align-items-lg-center">

          <div class="col-lg-6 order-lg-1 text-center mx-auto">
            <h1 class="heading mb-3 text-white" data-aos="fade-up">Interview Management</h1>
            <p class="lead mb-5 text-white" data-aos="fade-up"  data-aos-delay="100">Manage all the current interviews and progress of candidates.</p>
          </div>
          
        </div>
      </div>
    </div> <!-- .templateux-cover -->

    <div class="interview-container">
    <div class="position-card">
        <div class="position-header">
            <h2>Senior Manager</h2>
            <button class="report-button" onclick="window.location.href='./Forms/TableExport1.cfm'">Export Data</button>
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
                    <td>John Doe</td>
                    <td>8</td>
                    <td>Tech Solutions Inc.</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-scheduled">Scheduled</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                </tr>
                <tr>
                    <td>Jane Smith</td>
                    <td>10</td>
                    <td>Innovate Corp.</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-scheduled">Scheduled</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                </tr>
                <tr>
                    <td>Peter Jones</td>
                    <td>7</td>
                    <td>Data Systems</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                    <td><span class="status status-pending">Pending</span></td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="position-card">
        <div class="position-header">
            <h2>Content Creator</h2>
            <button class="report-button" onclick="window.location.href='./Forms/TableExport2.cfm'">Export Data</button>
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

    <div class="position-card">
        <div class="position-header">
            <h2>Program Manager</h2>
            <button class="report-button" onclick="window.location.href='./Forms/TableExport3.cfm'">Export Data</button>
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
                    <td>David Lee</td>
                    <td>12</td>
                    <td>Global Tech</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-hired">Hired</span></td>
                </tr>
                <tr>
                    <td>Chris Harris</td>
                    <td>9</td>
                    <td>Enterprise Co.</td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-completed">Completed</span></td>
                    <td><span class="status status-rejected">Rejected</span></td>
                    <td><span class="status status-rejected">Rejected</span></td>
                </tr>
            </tbody>
        </table>
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
                  Streamline Your Hiring Workflow</a>
                </h2>

                <div id="collapseOne" class="collapse show" aria-labelledby="headingOne" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Our platform centralizes all candidate information, from resumes to interview feedback, in one easy-to-access location. Schedule interviews, track progress, and communicate with your team, all without leaving the application.</p>
                  </div>
                </div>
              </div>
              
              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" class="collapsed" data-toggle="collapse" data-target="#collapseTwo" aria-expanded="false" aria-controls="collapseTwo">
                    Enhance Team Collaboration
                  </a>
                </h2>
                
                <div id="collapseTwo" class="collapse" aria-labelledby="headingTwo" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Enable your hiring team to collaborate effectively with shared notes, real-time feedback, and standardized evaluation forms. Ensure every team member is aligned and has the information they need to make the best hiring decisions.</p>
                  </div>
                </div>
              </div>
              
              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" class="collapsed" data-toggle="collapse" data-target="#collapseThree" aria-expanded="false" aria-controls="collapseThree">
                    Make Data-Driven Decisions
                  </a>
                </h2>
                
                <div id="collapseThree" class="collapse" aria-labelledby="headingThree" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Move beyond guesswork. Our analytics dashboard provides key insights into your hiring pipeline, helping you identify bottlenecks, track time-to-hire, and optimize your recruitment process for better outcomes.</p>
                  </div>
                </div>
              </div>
              
              <div class="accordion-item">
                <h2 class="mb-0 rounded mb-2">
                  <a href="#" class="collapsed" data-toggle="collapse" data-target="#collapseFour" aria-expanded="false" aria-controls="collapseFour">
                    Improve the Candidate Experience
                  </a>
                </h2>

                <div id="collapseFour" class="collapse" aria-labelledby="headingFour" data-parent="#accordionExample">
                  <div class="accordion-body">
                    <p>Keep candidates engaged and informed with automated communication and a clear view of their application status. A positive candidate experience is crucial for attracting top talent and strengthening your employer brand.</p>
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
              <p>A small river named Duden flows by their place and supplies it with the necessary regelialia.</p>
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

</body>
</html>
