<cfscript>
	boolean function filterBySize (fileObj) {

	var sizeLimit = 1024; //more than 10 KB
	var extensionList = "cfm";
	if(fileObj.type is "dir") return false;

	if(DateDiff("m",fileObj.lastmodifieddate,now())<10)
	{ 
		var fileInfo = getFileInfo(fileObj.path); 
		if(fileObj.size <= sizeLimit) 
			return true;
	}
	return false;
	}

	filteredResults = directorylist(expandPath("./../.."), true, "path", filterBySize);
	writeOutput("Listing Files with filtering on Size, Type and Modified Date");
	writeDump(filteredResults);
</cfscript>