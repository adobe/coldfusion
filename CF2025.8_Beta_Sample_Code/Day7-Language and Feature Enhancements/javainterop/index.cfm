<cfscript>
    fruits = ["apple", "apricot", "banana", "blueberry", "cherry"];
    stream = fruits.stream();

    collector = createObject("java", "java.util.stream.Collectors");
    predicate = createDynamicProxy(
        new pred(), ["java.util.function.Predicate"]
        );
    filteredList = stream.filter(predicate).
        collect(collector.toList());

    filteredListUsingLambdas = fruits.stream().filter(input => {return len(input) == 7}).
        collect(collector.toList());;

    writeOutput("Filtered List using Dynamic Proxy <br>");
    writeDump(filteredList);// ["banana", "cherry"]
    writeOutput("<br>Filtered List using CFML Lambdas <br>");
    writeDump(filteredListUsingLambdas);
</cfscript>

