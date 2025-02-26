<cfscript>
function drawChart({
  size = "big",
  coords = { x: 0, y: 0 },
  radius = 25
}) {

writeOutput("Size: ")
writeoutput(size);
writeOutput("<br>Coordinates: ")
writeDump(coords);
writeOutput("Radius: ")
writeoutput(radius);
 
}

drawChart({
  coords: { x: 18, y: 30 },
  radius: 31
})
</cfscript>