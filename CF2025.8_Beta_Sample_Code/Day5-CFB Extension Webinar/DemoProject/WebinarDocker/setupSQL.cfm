<cfscript> 
   // Authenticate with ColdFusion Administrator 
   adminObj = createObject("component","CFIDE.adminapi.administrator"); 
   adminObj.login("admin", "admin"); // ColdFusion Admin password 
    
   // Establish a MySQL datasource 
   datasource = createObject("component", "CFIDE.adminapi.datasource"); 
   datasource.setMySQL5("SampleMYSqlDB", "localhost", "/usr/local/mysql/bin/mysql"); 
</cfscript> 