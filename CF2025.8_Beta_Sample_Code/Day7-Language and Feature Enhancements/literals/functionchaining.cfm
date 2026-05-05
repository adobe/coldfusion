<cfscript>
    mappedStruct = { foo:'bar'}
    .append({ bum:'baz'})
    .append({ gang:'gaaz'})
    .append({ bang:'barley'})    
    .map(function(key, value) {
        return ucase(value);
    }
    );

    writeDump(mappedStruct);

    result = [1,[23,24,25],3,4,5][2]
    .append([43,44,45])[4]
    .append({ bum:{ bang:'barley'}})[4];

    writeDump(result);
</cfscript>

<cfscript>
writeOutput("<div class='demo'>");
writeOutput("<h2>Deep Nested Access</h2>");

// Access deeply nested data
config = {
    "app": {
        "database": {
            "host": "localhost",
            "port": 3306,
            "name": "myappDB"
        },
        "cache": {
            "enabled": true,
            "ttl": 3600
        }
    }
}.app["database"];

writeOutput("<div class='result'>");
writeOutput("<p><strong>DB Host:</strong> " & config.host & "</p>");
writeOutput("<p><strong>DB Port:</strong> " & config.port & "</p>");
writeOutput("<p><strong>DB Name:</strong> " & config.name & "</p>");
writeOutput("</div>");
writeOutput("</div>"); 
</cfscript>

<cfscript>
writeOutput("<div class='demo'>");
writeOutput("<h2>Nested Array Access and Chaining</h2>");

// Access nested array and append more data
result = [1,[23,24,25],3,4,5][2]
.append([43,44,45])[4]
.append({ bum:{ bang:'barley'}})[4];

writeOutput("<div class='result'>");
writeDump(result);
writeOutput("</div>");
writeOutput("</div>");
</cfscript>

