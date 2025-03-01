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

<cfscript>
    theFile=GetDirectoryFromPath(GetCurrentTemplatePath()) & "sheet-fit-page.xls";
    // create a spreadsheet object
    obj=spreadsheetNew("SheetNew",true)
    // add data
    for (i=1;i<52;i++){
        SpreadsheetSetCellValue(obj,"Value1#i#",#i#,1)
        SpreadsheetSetCellValue(obj,"Value2#i#",#i#,2)
        SpreadsheetSetCellValue(obj,"Value3#i#",#i#,3)
        SpreadsheetSetCellValue(obj,"Value4#i#",#i#,4)
        SpreadsheetSetCellValue(obj,"Value5#i#",#i#,5)
    }
    spreadsheetSetFitToPage(obj,true,2,2)
    spreadsheetWrite(obj, theFile, "", "yes", "no")
</cfscript>