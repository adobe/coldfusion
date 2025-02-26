<cfscript>
    CFReleaseCN = {
        CF_2025: "CF_Next",
        CF_2023: "Fortuna",
        CF_2021: "Project Stratus",
        CF_2018: "Aether",
        CF_2016: "Raijin"
        };

({CF_2021,CF_2023,CF_2018,CF_2019="Not Released in this year"} = CFReleaseCN);

writeOutput("ColdFusion Release Code Name :");
writeOutput("<br>2019:");
writeDump(CF_2019);
writeOutput("<br>2021:");
writeDump(CF_2021);
writeOutput("<br>2023:");
writeDump(CF_2023);
writeOutput("<br>****************************");
//Changing the Release Name
writeOutput("<br>Changing the Variable Value<br>")
CF_LAST = 'Aether';
({CF_2021,CF_2018,CF_2023:CF_LAST} = CFReleaseCN);
writeOutput("<br>CF_LAST:");
writeDump(CF_LAST);

writeOutput("<br>****************************");
//Out Of Support Versions
({CF_2021,CF_2023,CF_2025, ...outoFSupport} = CFReleaseCN);
writeOutput("<br>Not Supported Versions:");
writeDump(outoFSupport);
</cfscript>