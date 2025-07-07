# PeopleForge - Human Resources Management System

![PeopleForge Logo](images/employees.png)

**PeopleForge** is a comprehensive web-based Human Resources management system designed to streamline your entire HR workflow, from candidate recruitment to employee management and onboarding. Built with modern web technologies and ColdFusion, it provides an intuitive platform for HR professionals to manage their workforce efficiently.

## 🚀 Features

### 🎯 Core Modules

#### 1. **Candidate Management**
- **Interview Scheduling**: Streamline interview management with automated scheduling
- **Candidate Tracking**: Centralized tracking of all candidate information
- **Feedback Collection**: Standardized evaluation forms and real-time feedback
- **Application Status**: Clear visibility of candidate progress through the hiring pipeline
- **Resume Management**: Organized storage and retrieval of candidate documents

#### 2. **Employee Management** 
- **Employee Analytics Dashboard**: 
  - Department distribution charts
  - Employee tenure analysis
  - Interactive data visualizations using amCharts
- **Payslip Generation**: 
  - Monthly payslip creation for all employees
  - PDF export functionality
  - Employee-specific payroll data
- **Employee Directory**: Comprehensive employee database with search capabilities
- **Performance Tracking**: Monitor employee performance metrics and KPIs

#### 3. **Offer Letter Management**
- **Document Creation**: Generate comprehensive offer letters using ColdFusion's `cfhtmltopdf`
- **PDF Processing Pipeline**:
  - Create base offer letter documents
  - Generate benefits addendum
  - Merge multiple PDF documents
  - Remove unnecessary pages
  - Add company watermarks
  - Apply digital signatures
  - Encrypt with password protection
  - Optimize file size for delivery
- **Email Integration**: Automated delivery of finalized offer letters

#### 4. **Onboarding System**
- **Task Management**: Structured onboarding checklist for new hires
- **Document Collection**: 
  - Technology equipment preference forms
  - NDA signing workflow
  - Handbook acknowledgment
- **Team Integration**: 
  - Meet the team introductions
  - Manager check-ins
  - Welcome email automation
- **Benefits Setup**: Comprehensive benefits enrollment process

#### 5. **Document Management**
- **PDF Operations**: Advanced PDF manipulation capabilities
  - Merge, split, and modify PDF documents
  - Watermarking and branding
  - Digital signature application
  - Encryption and security features
- **File Upload System**: Secure document upload and storage
- **Version Control**: Track document revisions and changes

### 🎨 User Interface Features
- **Responsive Design**: Mobile-friendly interface that works on all devices
- **Modern UI/UX**: Clean, intuitive design with smooth animations
- **Dashboard Analytics**: Visual data representation with interactive charts
- **Real-time Updates**: Dynamic content updates without page refresh
- **Accessibility**: WCAG compliant design for inclusive user experience

## 🛠️ Technology Stack

### Backend
- **ColdFusion (CFML)**: Server-side application logic
- **PDF Processing**: Advanced PDF manipulation using ColdFusion's built-in PDF functions
- **Database Integration**: Employee and candidate data management
- **Email Services**: Automated email notifications and document delivery

### Frontend
- **HTML5 & CSS3**: Modern web standards with responsive design
- **JavaScript**: Interactive functionality and dynamic UI updates
- **Bootstrap**: Responsive CSS framework for consistent styling
- **amCharts**: Professional data visualization and charting library
- **jQuery**: Enhanced DOM manipulation and AJAX functionality

### Assets & Styling
- **SCSS**: Advanced CSS preprocessing for maintainable styles
- **Custom CSS**: Tailored styling for HR-specific workflows
- **Icon Fonts**: Professional iconography throughout the application
- **Image Optimization**: Optimized images for fast loading

## 📁 Project Structure

```
humanresources-master/
├── README.md                    # Project documentation
├── index.html                   # Main landing page
├── candidate.html               # Candidate management interface
├── employee.cfm                 # Employee management dashboard
├── offerLetters.cfm            # Offer letter processing system
├── onboarding.cfm              # Employee onboarding workflow
├── about.html                  # About page
├── contact.html                # Contact information
├── blog.html                   # Blog/news section
├── 
├── Forms/                      # Interactive forms and workflows
│   ├── CreateOfferLetter.cfm   # Offer letter creation
│   ├── SignNDA.cfm             # NDA signing workflow
│   ├── TechEquipment.cfm       # Equipment preference form
│   ├── MeetTeam.cfm            # Team introduction
│   ├── Handbook.cfm            # Employee handbook
│   ├── AddWatermark.cfm        # PDF watermarking
│   ├── EncryptPDF.cfm          # PDF encryption
│   └── ... (additional forms)
├── 
├── css/                        # Stylesheets
│   ├── style.css               # Main stylesheet (406KB compiled)
│   └── bootstrap/              # Bootstrap framework files
├── 
├── js/                         # JavaScript files
│   ├── main.js                 # Main application logic
│   ├── scripts-all.js          # Compiled JavaScript bundle
│   └── google-map.js           # Map integration
├── 
├── images/                     # Image assets
├── fonts/                      # Custom fonts
├── scss/                       # SCSS source files
├── media/                      # Media files
├── payslips/                   # Generated payslip storage
└── keys/                       # Security keys and certificates
```

## 🚀 Getting Started

### Prerequisites
- **ColdFusion Server**: Version 2018+ recommended
- **Web Server**: Apache, IIS, or built-in ColdFusion server
- **Modern Web Browser**: Chrome, Firefox, Safari, or Edge
- **PDF Processing**: Ensure ColdFusion PDF services are enabled

### Installation

1. **Clone or Download** the project to your ColdFusion web root:
   ```bash
   git clone [repository-url] humanresources-master
   ```

2. **Configure ColdFusion**:
   - Ensure ColdFusion is properly installed and running
   - Verify PDF services are enabled in ColdFusion Administrator
   - Configure mail server settings for email functionality

3. **Set Up Directory Permissions**:
   - Ensure read/write permissions for `payslips/` directory
   - Set appropriate permissions for `Forms/uploads/` directory
   - Verify `keys/` directory has proper security settings

4. **Configure Application Settings**:
   - Review and update email settings in relevant CFM files
   - Configure PDF processing parameters if needed
   - Set up database connections if using external data sources

5. **Access the Application**:
   - Navigate to `http://your-server/humanresources-master/`
   - Verify all pages load correctly
   - Test core functionality (PDF generation, form submissions)

### Configuration

#### Email Settings
Configure SMTP settings in ColdFusion Administrator or update the email configuration in:
- `Forms/OptimizeAndSend.cfm`

#### PDF Security
- Update encryption keys in the `keys/` directory
- Configure digital signature certificates
- Set default password policies for PDF encryption

#### Analytics Configuration
- Customize chart data sources in `employee.cfm`
- Update employee data arrays for testing
- Configure real database connections for production use

## 📖 Usage Guide

### For HR Administrators

1. **Managing Candidates**:
   - Access the Candidate section to view and manage job applicants
   - Schedule interviews and collect feedback
   - Track candidate progress through the hiring pipeline

2. **Employee Analytics**:
   - View department distribution and tenure analysis
   - Generate and export analytical reports
   - Monitor workforce metrics and trends

3. **Generating Offer Letters**:
   - Use the step-by-step workflow in the Offer Letters section
   - Customize templates for different positions
   - Apply digital signatures and encryption
   - Automatically deliver via email

4. **Managing Onboarding**:
   - Set up onboarding checklists for new hires
   - Track completion of required tasks
   - Automate welcome communications

### For New Employees

1. **Complete Onboarding Tasks**:
   - Fill out technology equipment preferences
   - Sign required documents (NDA, handbook acknowledgment)
   - Meet your team through the introduction system

2. **Access Resources**:
   - Read the employee handbook
   - Complete required training modules
   - Set up benefits and payroll information

## 🔧 Advanced Features

### PDF Processing Pipeline
The system includes a comprehensive PDF processing workflow:
1. **Document Creation**: Generate base documents from HTML templates
2. **Content Merging**: Combine multiple documents into single PDFs
3. **Page Management**: Add, remove, or modify specific pages
4. **Branding**: Apply company watermarks and styling
5. **Security**: Add digital signatures and encryption
6. **Optimization**: Compress and optimize for delivery

### Analytics Dashboard
- Real-time data visualization using amCharts
- Exportable reports in PDF format
- Customizable metrics and KPIs
- Department and tenure analysis

### Security Features
- PDF encryption with password protection
- Digital signature verification
- Secure file upload and storage
- Role-based access control

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project uses a template from [Colorlib](https://colorlib.com/wp/templates/) with additional custom functionality. 

**Important**: The base template copyright information cannot be altered/removed unless you purchase a license. More information about the license is available at: https://colorlib.com/wp/licence/

## 🆘 Support

For technical support or questions:
- Check the documentation in individual CFM files
- Review ColdFusion server logs for errors
- Ensure all required ColdFusion services are running
- Verify PDF processing capabilities are enabled

## 🔄 Version History

- **v1.0.0**: Initial release with core HR functionality
- **Current**: Full-featured HR management system with PDF processing, analytics, and onboarding workflows

## 🌟 Key Benefits

- **Streamlined Workflow**: Centralized HR processes in one platform
- **Enhanced Collaboration**: Team-based hiring and feedback systems
- **Data-Driven Decisions**: Analytics and reporting capabilities
- **Improved Experience**: Better candidate and employee experience
- **Document Security**: Advanced PDF security and digital signatures
- **Automation**: Reduced manual work through automated workflows

---

**PeopleForge** - Empowering HR teams to build better workplaces through technology. 