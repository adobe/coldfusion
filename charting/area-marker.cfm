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
    markers={

        "plot"={
            "type" = "circle", 
            "borderColor"="red",
            "borderWidth"="2",
            "size"=7,
            "borderAlpha"=0.7,
            "shadow"="true",
            "shadowColor"="black",
            "shadowAngle"=240,
            "shadowBlur"=0.7,
            "shadowDistance"=10,
            "shadowAlpha"=1
        },

        "yaxis" = [
        {
            "type"="area",
            "range"=[0,20],
            "alpha"="0.8",
            "label"={
                "text"="Inactive level",
                "backgroundColor"= "white"
            }
        }
        ]
    }
</cfscript>
<cfchart format="html" type = "line" showMarkers = "true" markers="#markers#" 
        showLegend="false" 
        height="600" 
        width="800" 
        title="Average atmospheric level" >
    <cfchartseries>
        <cfchartdata item = "2013" value = 23>
        <cfchartdata item = "2014" value = 93>
        <cfchartdata item = "2015" value = 34>
        <cfchartdata item = "2016" value = 72>
        <cfchartdata item = "2017" value = 96>
        <cfchartdata item = "2018" value = 33>
        <cfchartdata item = "2019" value = 32>
        <cfchartdata item = "2020" value = 27>
        <cfchartdata item = "2021" value = 38>
        <cfchartdata item = "2022" value = 49>
        <cfchartdata item = "2023" value = 75>
        <cfchartdata item = "2024" value = 74>
    </cfchartseries>
</cfchart>