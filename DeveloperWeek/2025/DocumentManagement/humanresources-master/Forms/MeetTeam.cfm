<cfhtmltopdf margintop="0.5" marginbottom="0.5" marginleft="0.5" marginright="0.5">
    <cfhtmltopdfitem type="header">
        <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-bottom: 1px solid #ddd; padding-bottom: 5px;">
            <strong>PeopleForge, Inc. - Confidential Document</strong>
        </div>
    </cfhtmltopdfitem>
    
    <cfhtmltopdfitem type="footer">
        <div style="text-align: center; font-family: Arial, sans-serif; font-size: 10px; color: #666; border-top: 1px solid #ddd; padding-top: 5px;">
            <p>Page _PAGENUMBER of _LASTPAGENUMBER | Signed on: <cfoutput>#DateFormat(Now(), "mmmm d, yyyy")# at #TimeFormat(Now(), "h:mm:ss tt")#</cfoutput></p>
        </div>
    </cfhtmltopdfitem>

<!DOCTYPE html>
<html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Meet the PeopleForge Team</title>
    <style>
        /* Modern CSS3 Reset and Base Styles */
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        :root {
            --primary-color: #4338ca;
            --secondary-color: #059669;
            --accent-color: #dc2626;
            --text-dark: #1a202c;
            --text-light: #718096;
            --bg-light: #f7fafc;
            --shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            --gradient-primary: linear-gradient(135deg, #4338ca 0%, #7c3aed 100%);
            --gradient-secondary: linear-gradient(135deg, #059669 0%, #0891b2 100%);
        }

        .qrcode {    -ro-replacedelement: qrcode;}
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            line-height: 1.6;
            color: var(--text-dark);
            background: linear-gradient(135deg, #f0f9ff 0%, #e0e7ff 100%);
            overflow-x: hidden;
        }
        
        /* HTML5 Semantic Layout with CSS Grid */
                 .page-container {
             display: grid;
             grid-template-areas: 
                 "header header"
                 "sidebar main"
                 "footer footer";
             grid-template-columns: 280px 1fr;
             grid-template-rows: auto 1fr auto;
             min-height: 100vh;
             gap: 15px;
             padding: 15px;
         }
        
                 /* Header Section */
         header {
             grid-area: header;
             background: var(--gradient-primary);
             padding: 1.5rem;
             border-radius: 15px;
             color: white;
             text-align: center;
             position: relative;
             overflow: hidden;
             box-shadow: var(--shadow);
         }
        
        header::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: repeating-linear-gradient(
                45deg,
                transparent,
                transparent 10px,
                rgba(255,255,255,0.05) 10px,
                rgba(255,255,255,0.05) 20px
            );
            animation: slide 20s linear infinite;
        }
        
        @keyframes slide {
            0% { transform: translateX(-100px); }
            100% { transform: translateX(100px); }
        }
        
        .header-content {
            position: relative;
            z-index: 2;
        }
        
        .company-logo {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 15px;
            margin-bottom: 1rem;
        }
        
        .logo-canvas {
            border-radius: 50%;
            box-shadow: 0 0 20px rgba(255,255,255,0.3);
        }
        
                 h1 {
             font-size: 2rem;
             font-weight: 700;
             margin-bottom: 0.3rem;
             text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
         }
         
         .subtitle {
             font-size: 1rem;
             opacity: 0.9;
             font-weight: 300;
         }
        
                 /* Sidebar with Company Info */
         aside {
             grid-area: sidebar;
             background: white;
             padding: 1.5rem;
             border-radius: 15px;
             box-shadow: var(--shadow);
             height: fit-content;
         }
        
                 .company-stats {
             display: flex;
             flex-direction: column;
             gap: 1rem;
         }
         
         .stat-card {
             background: var(--gradient-secondary);
             padding: 1rem;
             border-radius: 10px;
             color: white;
             text-align: center;
             transform: perspective(1000px) rotateY(-5deg);
             box-shadow: 5px 5px 15px rgba(0,0,0,0.1);
         }
         
         .stat-number {
             font-size: 1.5rem;
             font-weight: 700;
             display: block;
         }
         
         .stat-label {
             font-size: 0.8rem;
             opacity: 0.9;
         }
        
                 /* Main Content with Flexbox */
         main {
             grid-area: main;
             background: white;
             padding: 1.5rem;
             border-radius: 15px;
             box-shadow: var(--shadow);
         }
         
         .section-title {
             font-size: 1.6rem;
             color: var(--primary-color);
             margin-bottom: 1.2rem;
             text-align: center;
             position: relative;
         }
        
        .section-title::after {
            content: '';
            position: absolute;
            bottom: -10px;
            left: 50%;
            transform: translateX(-50%);
            width: 100px;
            height: 4px;
            background: var(--gradient-primary);
            border-radius: 2px;
        }
        
                 /* Team Grid Layout */
         .team-grid {
             display: grid;
             grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
             gap: 1.2rem;
             margin-bottom: 2rem;
         }
         
         .team-member {
             background: linear-gradient(145deg, #ffffff 0%, #f8fafc 100%);
             border-radius: 15px;
             padding: 1.3rem;
             text-align: center;
             transition: all 0.3s ease;
             box-shadow: 0 5px 15px rgba(0,0,0,0.08);
             border: 1px solid rgba(67, 56, 202, 0.1);
             position: relative;
             overflow: hidden;
         }
        
        .team-member::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: var(--gradient-primary);
        }
        
        .team-member:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(67, 56, 202, 0.2);
        }
        
                 .member-photo {
             width: 80px;
             height: 80px;
             border-radius: 50%;
             margin: 0 auto 1rem;
             background: var(--gradient-primary);
             display: flex;
             align-items: center;
             justify-content: center;
             color: white;
             font-size: 1.5rem;
             font-weight: bold;
             box-shadow: 0 8px 20px rgba(67, 56, 202, 0.3);
             position: relative;
             overflow: hidden;
         }
        
        .member-photo::before {
            content: '';
            position: absolute;
            top: -50%;
            left: -50%;
            width: 200%;
            height: 200%;
            background: repeating-conic-gradient(
                from 0deg,
                transparent 0deg,
                rgba(255,255,255,0.1) 90deg,
                transparent 180deg
            );
            animation: rotate 3s linear infinite;
        }
        
        @keyframes rotate {
            100% { transform: rotate(360deg); }
        }
        
                 .member-name {
             font-size: 1.2rem;
             font-weight: 600;
             color: var(--text-dark);
             margin-bottom: 0.3rem;
         }
         
         .member-role {
             color: var(--primary-color);
             font-weight: 500;
             margin-bottom: 0.8rem;
             font-size: 0.95rem;
         }
         
         .member-bio {
             color: var(--text-light);
             line-height: 1.4;
             margin-bottom: 1rem;
             font-size: 0.85rem;
         }
        
        .member-skills {
            display: flex;
            flex-wrap: wrap;
            gap: 0.5rem;
            justify-content: center;
        }
        
        .skill-tag {
             background: var(--gradient-secondary);
             color: white;
             padding: 0.2rem 0.6rem;
             border-radius: 15px;
             font-size: 0.7rem;
             font-weight: 500;
         }
        
        /* Company Culture Section */
        .culture-section {
            background: var(--gradient-primary);
            color: white;
            padding: 3rem;
            border-radius: 20px;
            margin-top: 3rem;
            text-align: center;
        }
        
        .culture-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 2rem;
            margin-top: 2rem;
        }
        
        .culture-item {
            background: rgba(255, 255, 255, 0.1);
            padding: 2rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .culture-icon {
            font-size: 3rem;
            margin-bottom: 1rem;
            display: block;
        }
        
        /* Media Elements */
        .media-section {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 2rem;
            margin: 3rem 0;
        }
        
        .audio-player, .video-player {
            background: var(--bg-light);
            padding: 2rem;
            border-radius: 15px;
            text-align: center;
            border: 2px dashed var(--primary-color);
        }
        
        audio, video {
            width: 100%;
            max-width: 300px;
            border-radius: 10px;
        }
        
        /* Footer */
        footer {
            grid-area: footer;
            background: var(--text-dark);
            color: white;
            padding: 2rem;
            border-radius: 15px;
            text-align: center;
        }
        
        .footer-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 1rem;
        }
        
        .contact-info {
            display: flex;
            gap: 2rem;
            flex-wrap: wrap;
        }
        
        .contact-item {
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }
        
        /* Responsive Design */
        @media (max-width: 768px) {
            .page-container {
                grid-template-areas: 
                    "header"
                    "sidebar"
                    "main"
                    "footer";
                grid-template-columns: 1fr;
            }
            
            .media-section {
                grid-template-columns: 1fr;
            }
            
            .footer-content {
                flex-direction: column;
                text-align: center;
            }
        }
        
                 /* Print Optimizations for PDF */
         @media print {
             body {
                 background: white !important;
             }
             
             .page-container {
                 display: block;
                 padding: 0;
                 gap: 10px;
             }
             
             header {
                 padding: 1rem;
                 margin-bottom: 0.5rem;
             }
             
             aside {
                 padding: 1rem;
                 margin-bottom: 0.5rem;
             }
             
             main {
                 padding: 1rem;
                 break-inside: avoid;
             }
             
             .team-grid {
                 gap: 0.8rem;
                 margin-bottom: 1rem;
             }
             
             .team-member {
                 padding: 2rem;
                 break-inside: avoid;
                 page-break-inside: avoid;
             }
             
             .section-title {
                 margin-bottom: 0.8rem;
             }
             
             footer {
                 margin-top: 0.5rem;
                 padding: 1rem;
             }
         }
    </style>
    </head>
    <body>
    <div class="page-container">
        <!-- HTML5 Semantic Header -->
        <header>
            <div class="header-content">
                <div class="company-logo">
                    <canvas id="logoCanvas" class="logo-canvas" width="60" height="60"></canvas>
                    <div>
                        <h1>PeopleForge</h1>
                        <p class="subtitle">Where Great People Build Great Things</p>
        </div>
                </div>
                <p style="margin-top: 1rem; font-size: 1.1rem;">Welcome to our team! Get to know the amazing people who make PeopleForge a special place to work.</p>
            </div>
        </header>
        
        <!-- HTML5 Semantic Aside -->
        <aside>
            <h2 style="color: var(--primary-color); margin-bottom: 1.5rem; text-align: center;">Company at a Glance</h2>
            <div class="company-stats">
                <div class="stat-card">
                    <span class="stat-number">50+</span>
                    <span class="stat-label">Team Members</span>
                </div>
                <div class="stat-card">
                    <span class="stat-number">5</span>
                    <span class="stat-label">Years in Business</span>
                </div>
                <div class="stat-card">
                    <span class="stat-number">200+</span>
                    <span class="stat-label">Happy Clients</span>
          </div>
                <div class="stat-card">
                    <span class="stat-number">15</span>
                    <span class="stat-label">Countries Served</span>
                </div>
            </div>
            
            <!-- HTML5 Audio Element -->
            <div class="audio-player" style="margin-top: 2rem;">
                <h3 style="margin-bottom: 1rem; color: var(--primary-color);">Welcome Message</h3>
                <audio controls>
                    <source src="../media/audio.mp3" type="audio/mpeg">
                    Your browser does not support the audio element.
                </audio>
                <p style="font-size: 0.9rem; margin-top: 1rem; color: var(--text-light);">Listen to our CEO's welcome message</p>
            </div>
        </aside>
        
        <!-- HTML5 Semantic Main Content -->
        <main>
            <section>
                <h2 class="section-title">Meet Our Leadership Team</h2>
                
                <div class="team-grid">
                    <article class="team-member">
                        <div class="member-photo">BM</div>
                        <h3 class="member-name">Bob Miller</h3>
                        <p class="member-role">CEO & Co-Founder</p>
                        <p class="member-bio">Visionary leader with 15+ years in tech. Bob founded PeopleForge with a mission to revolutionize how companies manage their most valuable asset - their people. He's passionate about creating inclusive workplaces where everyone can thrive.</p>
                        <div class="member-skills">
                            <span class="skill-tag">Leadership</span>
                            <span class="skill-tag">Strategy</span>
                            <span class="skill-tag">Innovation</span>
                        </div>
                    </article>
                    
                    <article class="team-member">
                        <div class="member-photo">JS</div>
                        <h3 class="member-name">Jean Smith</h3>
                        <p class="member-role">CTO & Co-Founder</p>
                        <p class="member-bio">Technology pioneer and software architect. Jean leads our technical vision and ensures we're always at the cutting edge of HR technology. She's an advocate for clean code, scalable systems, and user-centered design.</p>
                        <div class="member-skills">
                            <span class="skill-tag">Software Architecture</span>
                            <span class="skill-tag">AI/ML</span>
                            <span class="skill-tag">Cloud Computing</span>
                        </div>
                    </article>
                    
                    <article class="team-member">
                        <div class="member-photo">DW</div>
                        <h3 class="member-name">David Wilson</h3>
                        <p class="member-role">VP of Product</p>
                        <p class="member-bio">Product visionary with a deep understanding of user experience. David ensures our platform solves real problems for real people. He bridges the gap between complex technology and intuitive user experiences.</p>
                        <div class="member-skills">
                            <span class="skill-tag">Product Strategy</span>
                            <span class="skill-tag">UX Design</span>
                            <span class="skill-tag">Data Analytics</span>
                        </div>
                    </article>
                    
                    <article class="team-member">
                        <div class="member-photo">SR</div>
                        <h3 class="member-name">Sarah Rodriguez</h3>
                        <p class="member-role">Head of People & Culture</p>
                        <p class="member-bio">People-first leader who practices what we preach. Sarah creates the amazing culture at PeopleForge and ensures every team member feels valued, supported, and empowered to do their best work.</p>
                        <div class="member-skills">
                            <span class="skill-tag">Culture Building</span>
                            <span class="skill-tag">Talent Development</span>
                            <span class="skill-tag">Employee Engagement</span>
                        </div>
                    </article>
                    
                    <!--- <article class="team-member">
                        <div class="member-photo">MJ</div>
                        <h3 class="member-name">Michael Johnson</h3>
                        <p class="member-role">Head of Engineering</p>
                        <p class="member-bio">Technical excellence champion who leads our engineering team. Michael ensures we build robust, scalable, and secure systems while maintaining a culture of continuous learning and innovation.</p>
                        <div class="member-skills">
                            <span class="skill-tag">System Architecture</span>
                            <span class="skill-tag">DevOps</span>
                            <span class="skill-tag">Security</span>
                        </div>
                    </article>
                    
                    <article class="team-member">
                        <div class="member-photo">AK</div>
                        <h3 class="member-name">Amanda Kim</h3>
                        <p class="member-role">Head of Customer Success</p>
                        <p class="member-bio">Customer advocate who ensures our clients achieve their goals. Amanda builds lasting relationships and helps our customers maximize the value they get from PeopleForge.</p>
                        <div class="member-skills">
                            <span class="skill-tag">Customer Relations</span>
                            <span class="skill-tag">Success Strategy</span>
                            <span class="skill-tag">Training</span>
                        </div>
                    </article>--->
                </div>
            </section>
            
                         <!-- Team Growth Chart Section -->
             <section class="media-section">
                 <div class="video-player">
                     <h3 style="margin-bottom: 1rem; color: var(--primary-color);">Office Tour</h3>
                     <video controls poster="../images/office-poster.jpg">
                         <source src="../media/video.mp4" type="video/mp4">
                         Your browser does not support the video tag.
                     </video>
                     <p style="font-size: 0.9rem; margin-top: 1rem; color: var(--text-light);">Take a virtual tour of our offices</p>
                 </div>
                 
                 <div style="background: var(--bg-light); padding: 2rem; border-radius: 15px; text-align: center;">
                     <h3 style="margin-bottom: 1rem; color: var(--primary-color);">Team Growth Over Time</h3>
                     <cfchart 
                         format="svg" 
                         chartheight="250" 
                         chartwidth="350"
                         title="Team Growth"
                         backgroundcolor="##ffffff"
                         databackgroundcolor="##f0f9ff"
                         show3d="no"
                         rotated="no"
                         showlegend="no"
                         showborder="yes"
                         gridlines="4"
                         seriesplacement="default"
                         tipstyle="MouseOver"
                         showmarkers="yes"
                         markersize="6"
                         foregroundcolor="##059669">
                         
                         <cfchartseries 
                             type="area" 
                             seriescolor="##10b981"
                             paintstyle="gradient">
                             <cfchartdata item="2021" value="20">
                             <cfchartdata item="2022" value="35">
                             <cfchartdata item="2023" value="42">
                             <cfchartdata item="2024" value="50">
                         </cfchartseries>
                     </cfchart>
                     <p style="font-size: 0.9rem; margin-top: 1rem; color: var(--text-light);">Our team has grown consistently year over year</p>
                 </div>
             </section>
            
            <!-- Company Culture Section -->
            <section class="culture-section">
                <h2 style="font-size: 2.5rem; margin-bottom: 1rem;">Our Culture & Values</h2>
                <p style="font-size: 1.2rem; opacity: 0.9;">The principles that guide everything we do</p>
                
                <div class="culture-grid">
                    <div class="culture-item">
                        <span class="culture-icon">🎯</span>
                        <h3>Innovation First</h3>
                        <p>We constantly push boundaries and embrace new technologies to solve complex problems.</p>
                    </div>
                    <div class="culture-item">
                        <span class="culture-icon">🤝</span>
                        <h3>People Matter</h3>
                        <p>Every decision we make considers the human impact. Our people are our greatest strength.</p>
                    </div>
                    <div class="culture-item">
                        <span class="culture-icon">🌱</span>
                        <h3>Growth Mindset</h3>
                        <p>We believe in continuous learning, both personal and professional development for everyone.</p>
                    </div>
                    <div class="culture-item">
                        <span class="culture-icon">🎨</span>
                        <h3>Creative Solutions</h3>
                        <p>We approach challenges with creativity and think outside the box to find better ways.</p>
                    </div>
                </div>
            </section>
        </main>

                <!-- HTML5 QR Code Section -->
        <section style="background: white; padding: 1.5rem; border-radius: 15px; box-shadow: var(--shadow); margin-top: 1rem; margin-bottom: 1rem;">
            <h2 style="text-align: center; color: var(--primary-color); margin-bottom: 1.5rem; font-size: 1.6rem;">Know More about HR</h2>
            
            <div style="display: flex; justify-content: center;">
                <!-- QR Code Section -->
                <div style="text-align: center; padding: 1.5rem; background: var(--bg-light); border-radius: 15px; border: 2px dashed var(--primary-color); max-width: 400px;">
                    <h3 style="color: var(--primary-color); margin-bottom: 1rem;">QR Code</h3>
                    
                    <p><b>QR Code:</b></p><a href="https://en.wikipedia.org/wiki/Human_resource_management" class="qrcode"></a>
                    <!--- <span class="qrcode">
                    BEGIN:VCARDVERSION:2.1N:DoeFN:JohnTEL:+1-555-123-456TEL;FAX:+1-555-123-457EMAIL:johndoe@johndoe.comURL:https://www.johndoe.comEND:VCARD</span> --->
                    
                    <p style="margin-top: 1rem; color: var(--text-light); font-size: 0.9rem;">
                        Scan to learn more about HR: <strong>Wikipedia</strong>
                    </p>
                </div>
            </div>
        </section>
        
        <!-- HTML5 Semantic Footer -->
        <footer>
            <div class="footer-content">
                <div>
                    <h3 style="margin-bottom: 0.5rem;">Ready to Get Started?</h3>
                    <p>Your journey with PeopleForge begins now!</p>
                </div>
                <div class="contact-info">
                    <div class="contact-item">
                        <span>📧</span>
                        <span>hello@peopleforge.com</span>
                    </div>
                    <div class="contact-item">
                        <span>📱</span>
                        <span>+1 (555) 123-4567</span>
                    </div>
                    <div class="contact-item">
                        <span>🌐</span>
                        <span>www.peopleforge.com</span>
          </div>
                </div>
            </div>
        </footer>
          </div>

        </section>
    
    <!-- Canvas and JavaScript for Interactive Elements -->
    <script>
        // Logo Canvas Animation
        function drawLogo() {
            const canvas = document.getElementById('logoCanvas');
            const ctx = canvas.getContext('2d');
            
            // Clear canvas
            ctx.clearRect(0, 0, 60, 60);
            
            // Create gradient
            const gradient = ctx.createLinearGradient(0, 0, 60, 60);
            gradient.addColorStop(0, '#ffffff');
            gradient.addColorStop(1, 'rgba(255,255,255,0.7)');
            
            // Draw stylized "P" for PeopleForge
            ctx.fillStyle = gradient;
            ctx.font = 'bold 32px sans-serif';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('P', 30, 30);
            
            // Add decorative elements
            ctx.strokeStyle = 'rgba(255,255,255,0.8)';
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(30, 30, 25, 0, Math.PI * 2);
            ctx.stroke();
        }
        
        
        
                 // Initialize canvas elements
         document.addEventListener('DOMContentLoaded', function() {
             drawLogo();
         });
    </script>
    </body>
</html>
</cfhtmltopdf>

