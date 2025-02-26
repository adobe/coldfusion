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
    plot={"rules":[           
            {
                "rule":"%v<=80",
                "background-color":"yellow"
            }
        ]}
    crosshair={"line-color":"green","line-style":"dashed","alpha"=0.5};
</cfscript>

<cfchart format="html" chartWidth="800" chartHeight="600" show3d="false" plot="#plot#"
showborder="no" title="TitleTest" tipbgcolor="##FF0045" crosshair="#crosshair#">
    <cfchartseries type="hhist" serieslabel="Website Traffic 2016" color="gray">
        <cfchartdata item="January" value="120">
        <cfchartdata item="February" value="80">
        <cfchartdata item="March" value="30">
        <cfchartdata item="April" value="67">
        <cfchartdata item="May" value="50">
        <cfchartdata item="June" value="100">
    </cfchartseries>
</cfchart>
