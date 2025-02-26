<cfscript>
writeoutput("Destructuring objects in function parameter with default values <br>")

function drawChart(arg1,{
  size = "big",
  coords = { x: 0, y: 0 },
  radius = 25
} ,{key1}={},...rest) {
writeoutput("Size:" & size)
writeoutput("<br>")
writeoutput("Coordinates:" & coords['x'] & " " &  coords['y'])
writeoutput("<br>")
writeoutput("Radius :" & radius)
writeoutput("<br>")
writeoutput("key1:")
writeoutput( key1 ?: "undefined")
 writedump(rest)
}

drawChart("test1",{
  coords: { x: 18, y: 30 },
  radius: 31
},{key1:"value1"},"test1","test2",{test3:"bvalue3"},["test4":"value4"],[1,2,3])

</cfscript>