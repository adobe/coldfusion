/*
 * 
 *  MIT License
 * 
 * © Copyright 2025 Adobe, Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

 <cfset slash = IIF(FindNoCase(server.os.name,"unix"), DE("/"), DE("\"))>
<cfscript>
headerNames =["Movie URL","Title","Poster","Release_Year","Length in Min","IMDB_Rating","Rating Count","Plot","Directors","Writers","Stars","Genres"]
    // Define the path to your CSV file
    theFile=GetDirectoryFromPath(GetCurrentTemplatePath()) & "movies.csv";
    //csvFilePath = "#Expandpath(".")##slash#movies.csv"
    // Read the CSV file into a query object
    moviesData = csvRead(theFile,"query",{"skipHeaderRecord":true,"header":"#headerNames#"});
    movieCountPerYear = queryExecute(
        "SELECT Release_Year, COUNT(*) AS movies_count FROM moviesData GROUP BY Release_Year",
        [],
        {dbtype = "query"}
    );
       plot={"rules":[
             {
             "rule":"%v<2000",
             "background-color":"gray"
             },
             {
             "rule":"%v>2000",
             "background-color":"pink"
             }
       ]};
    </cfscript>
<cfchart format="html" chartheight="800" chartwidth="2000" title="A histogram showing the frequency of movies per release year" plot="#plot#">
    <cfchartseries type="histogram" itemcolumn="Release_Year" valuecolumn="movies_count" query="movieCountPerYear" serieslabel="Movies per Year">
    </cfchartseries>
</cfchart>