<cfscript>
person = {
    name: 'John Doe',
    age: 25,
    location: {
        country: 'Canada',
        city: 'Vancouver',
        coordinates: [49.2827, -123.1207]
    }
};
 
({name, location: {country, city, coordinates: [lat, lng]}} = person);
 
writeDump(name);
writeOutput("<br>****************************<br>");
writeDump(city)
writeOutput("<br>****************************<br>");
writeDump(lat);
writeOutput("<br>****************************<br>");
writeDump(lng);
writeOutput("<br>****************************<br>");
//writeDump(coordinates);
writeDump(country);
</cfscript>