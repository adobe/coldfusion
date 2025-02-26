<cfscript>
    CFReleaseCN = {
        CF_2025: "CF_NEXT",
        CF_2023: "Fortuna",
        CF_2021: "Project Stratus",
        CF_2018: "Aether",
        CF_2016: "Raijin"
        };

        function printCFReleaseNames(CF_2025, CF_2023) {
            writeOutput("2025:" & CF_2025);
            writeOutput("<br>****************************<br>");
            writeOutput("2023:" & CF_2023);
            writeOutput("<br>****************************<br>");
        }

        writeOutput("<br>****************************<br>");
        //Ordering Matters Here
        printCFReleaseNames(CFReleaseCN.CF_2025, CFReleaseCN.CF_2023);
        printCFReleaseNames(CFReleaseCN.CF_2023, CFReleaseCN.CF_2025);

        //Extract whats relevant and discard rest
        function printCFReleaseNamesNew({CF_2025, CF_2023, ...rest}) {
            writeOutput("2025:" & CF_2025);
            writeOutput("<br>");
            writeOutput("2023:" & CF_2023);
            writeOutput("<br>");
            writeOutput("<b>Older Versions:");
            writeDump(rest);
        }


        writeOutput("<br>****************************<br>");
        writeOutput("<br>");
        printCFReleaseNamesNew(CFReleaseCN);
</cfscript>