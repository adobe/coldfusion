<cfscript>
writeOutput("<div class='section'>");
writeOutput("<h2>Environment-Specific Logger</h2>");

// Simulate different environments
environments = ["production", "staging", "development"];

for (env in environments) {
    writeOutput("<h3>Environment: #uCase(env)#</h3>");

    param logger = env eq "production"
        ? () => function(msg, level) { 
            return "[PROD] [#uCase(level)#] #msg# (Errors only)"; 
          }
        : env eq "staging"
        ? () => function(msg, level) { 
            return "[STAGE] [#uCase(level)#] #msg# (Errors & Warnings)"; 
          }
        : () => function(msg, level) { 
            return "[DEV] [#uCase(level)#] #msg# (All logs + debug info)"; 
          };
    
    logFunction = logger();
    
    writeOutput("<div class='result'>");
    writeOutput("<p>" & logFunction("User login attempted", "info") & "</p>");
    writeOutput("<p>" & logFunction("Cache miss detected", "warning") & "</p>");
    writeOutput("<p>" & logFunction("Database connection failed", "error") & "</p>");
    writeOutput("</div>");
}
writeOutput("</div>");
</cfscript>