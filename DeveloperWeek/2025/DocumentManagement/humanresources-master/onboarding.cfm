<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
  <title>PeopleForge</title>
  <link rel="stylesheet" href="css/style.css">
</head>
<style>
    .task-list {
      max-width: 800px;
      margin: 2rem auto;
      padding: 0 1rem;
    }
    .task-item {
      background: white;
      border: 1px solid #e2e8f0;
      border-radius: 0.5rem;
      padding: 1rem;
      margin-bottom: 1rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .task-info {
      flex-grow: 1;
    }
    .task-title {
      font-size: 1rem;
      font-weight: 500;
      color: #1a202c;
      margin-bottom: 0.25rem;
    }
    .task-timing {
      font-size: 0.875rem;
      color: #718096;
    }
    .done-button {
      background: #4338ca;
      color: white;
      padding: 0.5rem 1rem;
      border-radius: 0.375rem;
      border: none;
      cursor: pointer;
    }
    .done-button:hover {
      background: #3730a3;
    }
    .tabs {
      max-width: 800px;
      margin: 2rem auto 0;
      padding: 0 1rem;
      display: flex;
      gap: 1rem;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 0.5rem;
    }
    .tab {
      padding: 0.75rem 1.5rem;
      border-radius: 0.375rem;
      cursor: pointer;
      border: none;
      background: none;
      color: #4a5568;
      font-size: 1rem;
      transition: all 0.2s;
    }
    .tab:hover {
      background: #f7fafc;
    }
    .tab.active {
      background: #4338ca;
      color: white;
    }
    .onboarding-container {
      padding: 2rem 0;
      background: #f8fafc;
    }
    .main-content {
      display: flex;
      gap: 2rem;
      max-width: 1400px;
      margin: 0 auto;
      padding: 0 1rem;
    }
    .task-section {
      flex: 1;
    }
    .upload-section {
      flex: 1.5;
      background: white;
      border-radius: 0.5rem;
      padding: 1.5rem;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      display: none;
      min-height: 750px;
    }
    .upload-section.show {
      display: block;
    }
    .upload-iframe {
      width: 100%;
      height: 700px;
      border: none;
      border-radius: 0.375rem;
    }
    .upload-title {
      font-size: 1.25rem;
      font-weight: 600;
      color: #1a202c;
      margin: 0;
      text-align: left;
    }
    .upload-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
    }
    .close-button {
      background: #dc2626;
      color: white;
      border: none;
      border-radius: 50%;
      width: 30px;
      height: 30px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 18px;
      transition: background-color 0.2s;
    }
    .close-button:hover {
      background: #b91c1c;
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
    
    <div class="templateux-cover" style="background-image: url(images/hero_3.jpg);">
      <div class="container">
        <div class="row align-items-lg-center">

          <div class="col-lg-6 order-lg-1 text-center mx-auto">
            <h1 class="heading mb-3 text-white" data-aos="fade-up">Onboarding Tasks</h1>
            <p class="lead mb-5 text-white" data-aos="fade-up"  data-aos-delay="100">Welcome to your onboarding journey. Let's get you started with everything you need.</p>
          </div>
          
        </div>
      </div>
    </div> <!-- .templateux-cover -->

    <div class="onboarding-container">
      <div class="tabs">
        <button class="tab active" onclick="openTab('beforeFirstDay')">On your first day</button>
      </div>

      <div class="main-content">
        <div class="task-section">
          <div id="beforeFirstDay" class="task-list">
            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Fill out the technology equipment preference form</div>
                <div class="task-timing">Before your first day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/TechEquipment.cfm'">Fill Out</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Sign your NDA</div>
                <div class="task-timing">Before your first day</div>
              </div>
              <button class="done-button" onclick="showNDASection()">Sign</button>
            </div>

            <!--- <div class="task-item">
              <div class="task-info">
                <div class="task-title">Upload your signed offer letter to server</div>
                <div class="task-timing">Before your first day</div>
              </div>
              <button class="done-button" onclick="showUploadSection()">Upload</button>
            </div> --->

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Get a quick intro to the team</div>
                <div class="task-timing">Before your first day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/MeetTeam.cfm'">Meet</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Read through the new employee handbook</div>
                <div class="task-timing">Before your first day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/Handbook.cfm'">Read</button>
            </div>

          </div>

          <div id="firstDay" class="task-list" style="display:none">
            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Read through the new employee handbook</div>
                <div class="task-timing">First day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/Handbook.cfm'">Read</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Initial check-in with your manager</div>
                <div class="task-timing">First day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/ManagerCheckin.cfm'">Check-in</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Send out a welcome mail to your team</div>
                <div class="task-timing">First day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/WelcomeMail.cfm'">Send</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Pick up your laptop & devices from Jean</div>
                <div class="task-timing">First day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/DevicePickup.cfm'">Pickup</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Get set up with all of your benefits (health, vision, dental, etc.)</div>
                <div class="task-timing">First day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/Benefits.cfm'">Setup</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Get a tour of the office</div>
                <div class="task-timing">First day</div>
              </div>
              <button class="done-button" onclick="window.location.href='./Forms/OfficeTour.cfm'">Tour</button>
            </div>
          </div>
        </div>

        <div class="upload-section" id="uploadSection">
          <div class="upload-header">
            <h3 class="upload-title">📤 Upload Your Signed Offer Letter</h3>
            <button class="close-button" onclick="closeUploadSection()" title="Close">×</button>
          </div>
          <iframe src="./Forms/SignOfferLetter.cfm" class="upload-iframe" title="File Upload"></iframe>
        </div>

        <div class="upload-section" id="ndaSection">
          <div class="upload-header">
            <h3 class="upload-title">📋 Non-Disclosure Agreement</h3>
            <button class="close-button" onclick="closeNDASection()" title="Close">×</button>
          </div>
          <iframe src="./Forms/SignNDA.cfm" class="upload-iframe" title="NDA Agreement" id="ndaFrame"></iframe>
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

  <script>
    function openTab(tabName) {
      console.log('Opening tab:', tabName); // Debug log
      
      // Hide all task lists
      var taskLists = document.querySelectorAll('.task-list');
      taskLists.forEach(function(list) {
        list.style.display = 'none';
      });
      
      // Show the selected task list
      var selectedList = document.getElementById(tabName);
      if (selectedList) {
        selectedList.style.display = 'block';
      }
      
      // Update active tab styling
      var tabs = document.querySelectorAll('.tab');
      tabs.forEach(function(tab) {
        tab.classList.remove('active');
      });
      event.currentTarget.classList.add('active');
    }

    // Add click handlers for done buttons
    document.querySelectorAll('.done-button').forEach(button => {
      button.addEventListener('click', () => {
        button.style.backgroundColor = '#059669'; // Change to green when clicked
      });
    });

    function showUploadSection() {
      // Show the upload section
      var uploadSection = document.getElementById('uploadSection');
      if (uploadSection) {
        uploadSection.classList.add('show');
      }
      
      // Change the button color to indicate it's been clicked
      event.currentTarget.style.backgroundColor = '#059669';
      event.currentTarget.textContent = 'Uploading...';
    }

    function closeUploadSection() {
      // Hide the upload section
      var uploadSection = document.getElementById('uploadSection');
      if (uploadSection) {
        uploadSection.classList.remove('show');
      }
      
      // Find and reset the Upload button
      var uploadButton = document.querySelector('.done-button[onclick="showUploadSection()"]');
      if (uploadButton) {
        uploadButton.style.backgroundColor = '#4338ca';
        uploadButton.textContent = 'Upload';
      }
    }

    function showNDASection() {
      // Show the NDA section
      var ndaSection = document.getElementById('ndaSection');
      if (ndaSection) {
        ndaSection.classList.add('show');
      }
      
      // Change the button color to indicate it's been clicked
      event.currentTarget.style.backgroundColor = '#059669';
      event.currentTarget.textContent = 'Reading...';
      
      // Start monitoring the iframe for PDF completion
      setTimeout(() => {
        monitorNDAFrame();
      }, 1000);
    }

    function closeNDASection() {
      // Hide the NDA section
      var ndaSection = document.getElementById('ndaSection');
      if (ndaSection) {
        ndaSection.classList.remove('show');
      }
      
      // Find and reset the Sign button (but only if not already signed)
      var signButton = document.querySelector('.done-button[onclick="showNDASection()"]');
      if (signButton && !signButton.classList.contains('signed')) {
        signButton.style.backgroundColor = '#4338ca';
        signButton.textContent = 'Sign';
      }
    }

    // Listen for messages from the NDA iframe
    window.addEventListener('message', function(event) {
      if (event.data && event.data.type === 'ndaSigned') {
        // NDA has been signed successfully
        var signButton = document.querySelector('.done-button[onclick="showNDASection()"]');
        if (signButton) {
          signButton.style.backgroundColor = '#16a34a'; // Green for completed
          signButton.textContent = '✓ Signed';
          signButton.classList.add('signed');
          signButton.onclick = null; // Remove click handler
          signButton.style.cursor = 'default';
        }
        
        // Optionally show a notification
        console.log('NDA signed successfully at:', event.data.timestamp);
        
        // Auto-close the NDA section after a brief delay
        setTimeout(() => {
          closeNDASection();
        }, 2000);
      }
    });

    // Monitor iframe for PDF loading (alternative method)
    function monitorNDAFrame() {
      var iframe = document.getElementById('ndaFrame');
      if (iframe) {
        iframe.onload = function() {
          // Check if URL contains viewpdf action (indicating successful signing)
          try {
            var iframeSrc = iframe.contentWindow.location.href;
            if (iframeSrc && iframeSrc.includes('action=viewpdf')) {
              // PDF is loaded, mark as signed
              var signButton = document.querySelector('.done-button[onclick="showNDASection()"]');
              if (signButton && !signButton.classList.contains('signed')) {
                signButton.style.backgroundColor = '#16a34a';
                signButton.textContent = '✓ Signed (PDF)';
                signButton.classList.add('signed');
                signButton.onclick = null;
                signButton.style.cursor = 'default';
                
                // Show a success notification
                showNDASuccessMessage();
              }
            }
          } catch (e) {
            // Cross-origin restrictions might prevent access
            console.log('Cannot access iframe URL due to cross-origin policy');
          }
        };
      }
    }

    function showNDASuccessMessage() {
      // Create a temporary success message
      var message = document.createElement('div');
      message.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #d1fae5;
        border: 1px solid #a7f3d0;
        color: #047857;
        padding: 15px 20px;
        border-radius: 8px;
        font-weight: 500;
        z-index: 1000;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
      `;
      message.innerHTML = '✓ NDA Successfully Signed & Digitally Certified!';
      document.body.appendChild(message);
      
      // Remove message after 5 seconds
      setTimeout(() => {
        document.body.removeChild(message);
      }, 5000);
    }
  </script>


  <script src="js/scripts-all.js"></script>
  <script src="js/main.js"></script>

</body>
</html>
