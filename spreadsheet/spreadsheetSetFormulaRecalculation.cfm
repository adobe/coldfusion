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
    theFile=GetDirectoryFromPath(GetCurrentTemplatePath()) &"BookFormula.xlsx";
    theFile1=GetDirectoryFromPath(GetCurrentTemplatePath()) &"SpreadsheetSetPrintOrientationReadTrue.xlsx";
    // read the first xlsx file
    obj=SpreadsheetRead(#theFile#)
    // set the value 21 to row 3, col 1
    SpreadsheetSetCellValue(obj,21, 3, 1)
    // add formula on cell row 11, col 1
    SpreadsheetSetCellFormula(obj, "SUM(A1:A9)", 11, 1)
    // force formula recalculation
    SpreadsheetSetForceFormulaRecalculation(obj,true)
    value=SpreadsheetGetForceFormulaRecalculation(obj)
    writeoutput(value&"<br>")
    spreadsheetWrite(obj,#theFile1#,"", "yes", "no")
    obj=SpreadsheetRead(#theFile1#)
    theValue=SpreadsheetGetCellValue(obj,11,1);
    writeoutput(#theValue# &"<br>")
    theValue2=SpreadsheetGetCellValue(obj,14,1);
    writeoutput(#theValue2#)
</cfscript>