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

<!--- <cfscript>
    theFile=GetDirectoryFromPath(GetCurrentTemplatePath()) &"sample-file.xlsx"
    obj=SpreadsheetRead(#theFile#)
    new_name="sample-file-renamed.xlsx"
    try{
        spreadsheetRename(obj,new_name)
        writeOutput("Spreadsheet renamed to: " & new_name)
    }
    catch(any e){
        writeOutput(e.message)
    }
</cfscript> --->

<cfscript>
    // set the path of the file
    theFile=GetDirectoryFromPath(GetCurrentTemplatePath()) & "art-source.xls";
    // create the spreadsheet naming the first worksheet as Course
    obj =SpreadsheetNew("Course")
    // create the second worksheet
    SpreadsheetCreateSheet (obj,"Marks");
    // create the third worksheet
    SpreadsheetCreateSheet (obj,"EvaluationSheet");
    spreadsheetWrite(obj, "#theFile#", "", "yes", "no")
    obj1 =SpreadsheetRead(#theFile#)
    spreadsheetRenameSheet(obj1,"Marks","MarksRenamed")
    writeDump(obj1)
    writeOutput(obj1.SUMMARYINFO.SHEETNAMES)
</cfscript>