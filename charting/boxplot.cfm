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
    ex1={
        "key"="Experiment one results",
        "data"= [24, 30, 35, 38, 45, 45, 46, 48, 49, 51, 52, 53, 56, 57, 59, 60, 62, 70]    
    }
    ex2={
        "key"="Experiment two results",
        "data"= [45, 25, 29, 50, 40, 56, 32, 32, 46, 65, 66, 24, 31, 29, 23, 30, 65, 56]    
    }
    ex3={
        "key"="Experiment three results",
        "dataBox"=[35, 50, 45, 40, 55], // [min, q1, median, q3, max]
        "dataOutlier"=[25,60] // outlier array
    }
    // boxplot styling options
    options={
        "box"={
            "bar-width":0.9,
            "background-color": "green"
        },
        "line-min-level": {
            "line-color": "red",
            "line-width":2
        },
        "line-median-level": {
            "line-color": "blue",
            "line-width":2
        },
        "line-max-level": {
            "line-color": "black",
            "line-width":2
        },
        'line-min-connector': {
            'line-width':2,
            'line-color': "##f00"
        },
        'line-max-connector': {
            'line-color': "black",
            'line-width':4
        },
        "outlier":{
            "marker":{
                "type"="circle",
                "background-color": "##ff0"
            }
        }
    }
</cfscript>
<cfchart type="hboxplot"  format="html" title="Tenth boxplot (horizontal)" width="600"  height="400" options="#options#">
    <cfchartseries data="#ex1#">
    <cfchartseries data="#ex2#">
    <cfchartseries data="#ex3#">
</cfchart>