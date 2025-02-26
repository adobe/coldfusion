<cfscript>
	company = [
		 /* {
		 	 employees: [
		 	 	 { 
                    Name: "John",
                    Department: "Payroll"
                 }
		 	 ]
		 } */
	];
    writeOutput("Employee Department:");
    department = company[1].employees[1].Department ?: "No Information";
	WriteOutput(department);
</cfscript>

