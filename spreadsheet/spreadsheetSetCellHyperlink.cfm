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

<cfquery name="art" datasource="cfartgallery">
    SELECT * FROM ART
</cfquery>
<cfscript>
    theFile=GetDirectoryFromPath(GetCurrentTemplatePath()) & "art.xls";
    // create a spreadsheet object
    theSheet=spreadsheetNew("SampleData")
    // add rows from query
    spreadsheetAddRows(theSheet,art)
    // hyperlink struct
    hStruct={
        row:1,
        column:4,
        address: "https://www.adobe.com",
        type:"URL"
    }
    // set hyperlink on cell 11,4
    spreadsheetSetCellHyperlink(theSheet,hStruct)
    spreadsheetWrite(theSheet,theFile,"yes")
    getHyperLink=spreadsheetGetCellHyperlink(theSheet,1,4)
    //getHyperLink=spreadsheetGetCellHyperlink(theSheet,hStruct)
    writeDump(getHyperLink)
</cfscript>