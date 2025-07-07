<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DocuNinja - <cfoutput>#pageTitle#</cfoutput></title>
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <link rel="stylesheet" href="../assets/css/style.css">
    <style>
        /* Ensure content is visible and properly laid out */
        .flex-1 {
            min-height: 0;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        /* Override any conflicting styles */
        .tab-content {
            display: block;
        }
        .tab-content.hidden {
            display: none;
        }
    </style>
</head>
<body class="bg-gray-100">
    <!-- Sidebar -->
    <div class="flex h-screen">
        <div class="w-64 bg-gradient-to-b from-blue-600 to-blue-800 text-white p-6">
            <div class="mb-8">
                <h1 class="text-2xl font-bold">DocuNinja</h1>
            </div>
            
            <nav>
                <a href="../dashboard.cfm" class="block py-2.5 px-4 rounded transition duration-200 hover:bg-blue-700">
                    Dashboard
                </a>
                <a href="../documents/index.cfm" class="block py-2.5 px-4 rounded transition duration-200 hover:bg-blue-700">
                    Documents
                </a>
                <a href="../onboarding.cfm" class="block py-2.5 px-4 rounded transition duration-200 hover:bg-blue-700 bg-blue-700">
                    Onboarding
                </a>
                <a href="../templates.cfm" class="block py-2.5 px-4 rounded transition duration-200 hover:bg-blue-700">
                    Templates
                </a>
                <a href="../reports.cfm" class="block py-2.5 px-4 rounded transition duration-200 hover:bg-blue-700">
                    Reports
                </a>
            </nav>

            <div class="mt-auto pt-8">
                <div class="flex items-center space-x-4">
                    <div class="w-10 h-10 rounded-full bg-blue-400"></div>
                    <div>
                        <div class="font-medium">John Doe</div>
                        <div class="text-sm text-blue-200">HR Manager</div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Content -->
        <div class="flex-1 overflow-auto p-6">
            <cfif isDefined("mainContent")>
                <cfoutput>#mainContent#</cfoutput>
            </cfif>
        </div>
    </div>
</body>
</html> 