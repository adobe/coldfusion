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
    .pdf-viewer {
      flex: 1.8;
      background: white;
      border-radius: 0.5rem;
      padding: 1.5rem;
      box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      min-height: 800px;
      display: none;
    }
    .pdf-viewer.show {
      display: block;
    }
    .pdf-iframe {
      width: 100%;
      height: 750px;
      border: 1px solid #e5e7eb;
      border-radius: 0.375rem;
    }
    .pdf-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 1rem;
      padding-bottom: 1rem;
      border-bottom: 2px solid #e5e7eb;
    }
    .pdf-title {
      font-size: 1.25rem;
      font-weight: 600;
      color: #1a202c;
    }
    .refresh-button {
      background: #4338ca;
      color: white;
      border: none;
      border-radius: 0.375rem;
      padding: 0.5rem 1rem;
      cursor: pointer;
      font-size: 14px;
      display: flex;
      align-items: center;
      gap: 0.5rem;
    }
    .refresh-button:hover {
      background: #3730a3;
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
    
    <div class="templateux-cover" style="background-image: url(images/offerLetter.jpg);">
      <div class="container">
        <div class="row align-items-lg-center">

          <div class="col-lg-6 order-lg-1 text-center mx-auto">
            <h1 class="heading mb-3 text-white" data-aos="fade-up">Offer Letters</h1>
            <p class="lead mb-5 text-white" data-aos="fade-up"  data-aos-delay="100">Generate, customize, and send offer letters quickly with built-in templates and tracking.</p>
          </div>
          
        </div>
      </div>
    </div> <!-- .templateux-cover -->

    <div class="onboarding-container">
      <div class="tabs">
        <button class="tab active" onclick="openTab('creation')">Document Creation</button>
        <button class="tab" onclick="openTab('processing')">Processing & Delivery</button>
      </div>

      <div class="main-content">
        <div class="task-section">
          <div id="creation" class="task-list">
            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Create comprehensive offer letter</div>
                <div class="task-timing">Step 1: Generate base document using cfhtmltopdf</div>
              </div>
              <button class="done-button" onclick="createOfferLetter()">Create</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Generate benefits addendum</div>
                <div class="task-timing">Step 2: Create additional PDF content</div>
              </div>
              <button class="done-button" onclick="createBenefitsAddendum()">Generate</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Merge documents together</div>
                <div class="task-timing">Step 3: Combine PDFs using cfpdf merge</div>
              </div>
              <button class="done-button" onclick="mergePDFs()">Merge</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Remove unnecessary pages</div>
                <div class="task-timing">Step 4: Delete specific pages using cfpdf</div>
              </div>
              <button class="done-button" onclick="deletePages()">Edit</button>
            </div>
          </div>

          <div id="processing" class="task-list" style="display:none">
            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Add company watermark</div>
                <div class="task-timing">Step 5: Brand document with watermark</div>
              </div>
              <button class="done-button" onclick="addWatermark()">Watermark</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Digitally sign the offer letter</div>
                <div class="task-timing">Step 6: Apply digital signature for authenticity</div>
              </div>
              <button class="done-button" onclick="signDocument()">Sign</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Encrypt with password protection</div>
                <div class="task-timing">Step 7: Secure document with encryption</div>
              </div>
              <button class="done-button" onclick="encryptDocument()">Encrypt</button>
            </div>

            <div class="task-item">
              <div class="task-info">
                <div class="task-title">Optimize file size and send via email</div>
                <div class="task-timing">Step 8: Compress and deliver final document</div>
              </div>
              <button class="done-button" onclick="optimizeAndSend()">Deliver</button>
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

        <div class="upload-section" id="watermarkSection">
          <div class="upload-header">
            <h3 class="upload-title">🏷️ Add Company Watermark</h3>
            <button class="close-button" onclick="closeWatermarkSection()" title="Close">×</button>
          </div>
          <iframe src="./Forms/AddWatermark.cfm" class="upload-iframe" title="Watermark Application" id="watermarkFrame"></iframe>
        </div>

        <div class="upload-section" id="signSection">
          <div class="upload-header">
            <h3 class="upload-title">🔐 Digital Signature Application</h3>
            <button class="close-button" onclick="closeSignSection()" title="Close">×</button>
          </div>
          <iframe src="./Forms/SignOfferLetter.cfm" class="upload-iframe" title="Digital Signature" id="signFrame"></iframe>
        </div>

        <div class="upload-section" id="encryptSection">
          <div class="upload-header">
            <h3 class="upload-title">🔒 PDF Encryption & Security</h3>
            <button class="close-button" onclick="closeEncryptSection()" title="Close">×</button>
          </div>
          <iframe src="./Forms/EncryptPDF.cfm" class="upload-iframe" title="PDF Encryption" id="encryptFrame"></iframe>
        </div>

        <div class="upload-section" id="deliverSection">
          <div class="upload-header">
            <h3 class="upload-title">📤 Optimize & Send Final Document</h3>
            <button class="close-button" onclick="closeDeliverSection()" title="Close">×</button>
          </div>
          <iframe src="./Forms/OptimizeAndSend.cfm" class="upload-iframe" title="Optimize & Send" id="deliverFrame"></iframe>
        </div>
        
        <div class="pdf-viewer">
          <div class="pdf-header">
            <h3 class="pdf-title">📄 Click "Create" to generate and view the offer letter</h3>
            <button onclick="closePDFViewer()" class="refresh-btn">× Close</button>
          </div>
          <iframe id="pdfFrame" class="pdf-iframe" src=""></iframe>
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

    function closePDFViewer() {
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.remove('show');
      }
      
      // Clear the iframe source
      var iframe = document.getElementById('pdfFrame');
      if (iframe) {
        iframe.src = '';
      }
      
      // Reset the PDF title
      var pdfTitle = document.querySelector('.pdf-title');
      if (pdfTitle) {
        pdfTitle.innerHTML = '📄 Click "Create" to generate and view the offer letter';
      }
    }

    // Auto-refresh PDF when workflow steps are completed
    function updatePDFSource(filename) {
      var iframe = document.getElementById('pdfFrame');
      if (iframe) {
        iframe.src = './' + filename + '?t=' + new Date().getTime();
      }
    }

    function createOfferLetter() {
      // Show the PDF viewer
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.add('show');
      }
      
      // Update button state
      var createButton = event.currentTarget;
      createButton.style.backgroundColor = '#059669';
      createButton.textContent = 'Creating...';
      createButton.disabled = true;
      
      // Create the offer letter by opening it in a hidden iframe
      var hiddenFrame = document.createElement('iframe');
      hiddenFrame.style.display = 'none';
      hiddenFrame.src = './Forms/CreateOfferLetter.cfm';
      document.body.appendChild(hiddenFrame);
      
      // Wait for creation and then update the PDF viewer
      setTimeout(() => {
        updatePDFSource('OfferLetter_Base.pdf');
        createButton.style.backgroundColor = '#16a34a';
        createButton.textContent = '✓ Created';
        createButton.disabled = false;
        
        // Update PDF title
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Offer Letter - Base Document (10 pages)';
        }
        
        // Remove hidden iframe after processing
        setTimeout(() => {
          document.body.removeChild(hiddenFrame);
        }, 2000);
      }, 3000);
    }

    function showPDFViewer() {
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.add('show');
      }
    }

    function hidePDFViewer() {
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.remove('show');
      }
    }

    function createBenefitsAddendum() {
      // Show the PDF viewer
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.add('show');
      }
      
      // Update button state
      var createButton = event.currentTarget;
      createButton.style.backgroundColor = '#059669';
      createButton.textContent = 'Creating...';
      createButton.disabled = true;
      
      // Create the benefits addendum by opening it in a hidden iframe
      var hiddenFrame = document.createElement('iframe');
      hiddenFrame.style.display = 'none';
      hiddenFrame.src = './Forms/CreateBenefitsAddendum.cfm';
      document.body.appendChild(hiddenFrame);
      
      // Wait for creation and then update the PDF viewer
      setTimeout(() => {
        updatePDFSource('BenefitsAddendum.pdf');
        createButton.style.backgroundColor = '#16a34a';
        createButton.textContent = '✓ Created';
        createButton.disabled = false;
        
        // Update PDF title
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Benefits Addendum';
        }
        
        // Remove hidden iframe after processing
        setTimeout(() => {
          document.body.removeChild(hiddenFrame);
        }, 2000);
      }, 3000);
    }

    function mergePDFs() {
      // Show the PDF viewer
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.add('show');
      }
      
      // Update button state
      var mergeButton = event.currentTarget;
      mergeButton.style.backgroundColor = '#059669';
      mergeButton.textContent = 'Merging...';
      mergeButton.disabled = true;
      
      // Merge PDFs by opening it in a hidden iframe
      var hiddenFrame = document.createElement('iframe');
      hiddenFrame.style.display = 'none';
      hiddenFrame.src = './Forms/MergePDFs.cfm';
      document.body.appendChild(hiddenFrame);
      
      // Wait for merging and then update the PDF viewer
      setTimeout(() => {
        updatePDFSource('OfferLetter_Merged.pdf');
        mergeButton.style.backgroundColor = '#16a34a';
        mergeButton.textContent = '✓ Merged';
        mergeButton.disabled = false;
        
        // Update PDF title
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Merged Offer Letter (12 pages)';
        }
        
        // Remove hidden iframe after processing
        setTimeout(() => {
          document.body.removeChild(hiddenFrame);
        }, 2000);
      }, 3000);
    }

    function deletePages() {
      // Show the PDF viewer
      var pdfViewer = document.querySelector('.pdf-viewer');
      if (pdfViewer) {
        pdfViewer.classList.add('show');
      }
      
      // Update button state
      var deleteButton = event.currentTarget;
      deleteButton.style.backgroundColor = '#059669';
      deleteButton.textContent = 'Deleting...';
      deleteButton.disabled = true;
      
      // Delete pages by opening it in a hidden iframe
      var hiddenFrame = document.createElement('iframe');
      hiddenFrame.style.display = 'none';
      hiddenFrame.src = './Forms/DeletePages.cfm';
      document.body.appendChild(hiddenFrame);
      
      // Wait for deletion and then update the PDF viewer
      setTimeout(() => {
        updatePDFSource('OfferLetter_Edited.pdf');
        deleteButton.style.backgroundColor = '#16a34a';
        deleteButton.textContent = '✓ Deleted';
        deleteButton.disabled = false;
        
        // Update PDF title
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Edited Offer Letter (Pages Removed)';
        }
        
        // Remove hidden iframe after processing
        setTimeout(() => {
          document.body.removeChild(hiddenFrame);
        }, 2000);
      }, 3000);
    }

    function addWatermark() {
      // Show the watermark section
      var watermarkSection = document.getElementById('watermarkSection');
      if (watermarkSection) {
        watermarkSection.classList.add('show');
      }
      
      // Change the button color to indicate it's been clicked
      var watermarkButton = event.currentTarget;
      watermarkButton.style.backgroundColor = '#059669';
      watermarkButton.textContent = 'Processing...';
      
      // Auto-update PDF viewer after processing
      setTimeout(() => {
        updatePDFSource('OfferLetter_Watermarked.pdf');
        watermarkButton.style.backgroundColor = '#16a34a';
        watermarkButton.textContent = '✓ Watermarked';
        
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Watermarked Offer Letter with Company Branding';
        }
      }, 2000);
    }

    function closeWatermarkSection() {
      // Hide the watermark section
      var watermarkSection = document.getElementById('watermarkSection');
      if (watermarkSection) {
        watermarkSection.classList.remove('show');
      }
      
      // Find and optionally reset the Watermark button (but keep it as completed if watermarked)
      var watermarkButton = document.querySelector('.done-button[onclick="addWatermark()"]');
      if (watermarkButton && watermarkButton.textContent === 'Processing...') {
        watermarkButton.style.backgroundColor = '#4338ca';
        watermarkButton.textContent = 'Watermark';
      }
    }

    function signDocument() {
      // Show the sign section
      var signSection = document.getElementById('signSection');
      if (signSection) {
        signSection.classList.add('show');
      }
      
      // Change the button color to indicate it's been clicked
      var signButton = event.currentTarget;
      signButton.style.backgroundColor = '#059669';
      signButton.textContent = 'Processing...';
      
      // Auto-update PDF viewer after processing
      setTimeout(() => {
        updatePDFSource('OfferLetter_Signed.pdf');
        signButton.style.backgroundColor = '#16a34a';
        signButton.textContent = '✓ Signed';
        
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Digitally Signed Offer Letter with Certificate';
        }
      }, 2000);
    }

    function closeSignSection() {
      // Hide the sign section
      var signSection = document.getElementById('signSection');
      if (signSection) {
        signSection.classList.remove('show');
      }
      
      // Find and optionally reset the Sign button (but keep it as completed if signed)
      var signButton = document.querySelector('.done-button[onclick="signDocument()"]');
      if (signButton && signButton.textContent === 'Processing...') {
        signButton.style.backgroundColor = '#4338ca';
        signButton.textContent = 'Sign';
      }
    }

    function encryptDocument() {
      // Show the encrypt section
      var encryptSection = document.getElementById('encryptSection');
      if (encryptSection) {
        encryptSection.classList.add('show');
      }
      
      // Change the button color to indicate it's been clicked
      var encryptButton = event.currentTarget;
      encryptButton.style.backgroundColor = '#059669';
      encryptButton.textContent = 'Processing...';
      
      // Auto-update PDF viewer after processing
      setTimeout(() => {
        updatePDFSource('OfferLetter_Encrypted.pdf');
        encryptButton.style.backgroundColor = '#16a34a';
        encryptButton.textContent = '✓ Encrypted';
        
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Encrypted Offer Letter (Password Protected)';
        }
      }, 2000);
    }

    function closeEncryptSection() {
      // Hide the encrypt section
      var encryptSection = document.getElementById('encryptSection');
      if (encryptSection) {
        encryptSection.classList.remove('show');
      }
      
      // Find and optionally reset the Encrypt button (but keep it as completed if encrypted)
      var encryptButton = document.querySelector('.done-button[onclick="encryptDocument()"]');
      if (encryptButton && encryptButton.textContent === 'Processing...') {
        encryptButton.style.backgroundColor = '#4338ca';
        encryptButton.textContent = 'Encrypt';
      }
    }

    function optimizeAndSend() {
      // Show the deliver section
      var deliverSection = document.getElementById('deliverSection');
      if (deliverSection) {
        deliverSection.classList.add('show');
      }
      
      // Change the button color to indicate it's been clicked
      var deliverButton = event.currentTarget;
      deliverButton.style.backgroundColor = '#059669';
      deliverButton.textContent = 'Processing...';
      
      // Auto-update PDF viewer after processing
      setTimeout(() => {
        updatePDFSource('OfferLetter_Final.pdf');
        deliverButton.style.backgroundColor = '#16a34a';
        deliverButton.textContent = '✓ Delivered';
        
        var pdfTitle = document.querySelector('.pdf-title');
        if (pdfTitle) {
          pdfTitle.innerHTML = '📄 Final Offer Letter (Optimized & Sent)';
        }
        
        // Show completion message
        showCompletionMessage();
      }, 2000);
    }

    function closeDeliverSection() {
      // Hide the deliver section
      var deliverSection = document.getElementById('deliverSection');
      if (deliverSection) {
        deliverSection.classList.remove('show');
      }
      
      // Find and optionally reset the Deliver button (but keep it as completed if delivered)
      var deliverButton = document.querySelector('.done-button[onclick="optimizeAndSend()"]');
      if (deliverButton && deliverButton.textContent === 'Processing...') {
        deliverButton.style.backgroundColor = '#4338ca';
        deliverButton.textContent = 'Deliver';
      }
    }

    function showCompletionMessage() {
      var message = document.createElement('div');
      message.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #d1fae5;
        border: 1px solid #a7f3d0;
        color: #047857;
        padding: 20px 25px;
        border-radius: 10px;
        font-weight: 600;
        z-index: 1000;
        box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
        font-size: 16px;
      `;
      message.innerHTML = '🎉 Offer Letter Workflow Complete!<br><small style="font-weight: normal;">Document has been optimized and sent via email</small>';
      document.body.appendChild(message);
      
      setTimeout(() => {
        document.body.removeChild(message);
      }, 8000);
    }
  </script>


  <script src="js/scripts-all.js"></script>
  <script src="js/main.js"></script>

</body>
</html>
