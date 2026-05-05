<cfscript>
    setA = setNew("ordered");
    setA.add(1);
    setA.add(2);
    setA.add(3);
    setA.add(4);

    setB = setNew("ordered");
    setB.add(3);
    setB.add(4);
    setB.add(5);
    setB.add(6);
	
    writeOutput("Union of SetA and SetB");
	union = setUnion(setA, setB);
	writeDump(union);

    writeOutput("<br> Representing Set in Array Form:");
    writeDump(union.ToArray());
	
	intersection = setintersection(setA,setB);
    writeOutput("<br> Intersection of SetA and SetB:");
	writeDump(intersection);

    setDifference = SetDifference(setA,setB);
    writeOutput("<br> Difference of SetA and SetB:");
	writeDump(setDifference);

    symDiffSet = setSymmetricDifference(setA, setB);
    writeOutput("<br> Symmetric Difference of SetA and SetB:");
	writeDump(symDiffSet);
      
    arr = [1,2,3,4,5,5,4,3,2,1,23];
    writeOutput("<br> Creating Set from Arrays");
    uniqueVals = setNew(arr);
    writeDump(uniqueVals);
</cfscript>