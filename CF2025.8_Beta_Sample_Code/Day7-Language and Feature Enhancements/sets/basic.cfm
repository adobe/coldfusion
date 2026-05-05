<cfscript>
    closure = ()=> 2 + 3;
    set = setNew();
    set.add(closure);
    set.add(2);
    set.add(4);
    set.add(3);
    set.add(4); // Add duplicate
    set.delete(3);

    writeDump(set);
	
	writeOutput("<br> Size:");
    writeOutput(set.size());
	
    writeOutput("<br> Has Element 2:");
    writeOutput(set.has(2));
    writeOutput("<br> Clearing the Set");

    set.clear();
	
	writeOutput("<br> Size:");
    writeOutput(set.size());
</cfscript>