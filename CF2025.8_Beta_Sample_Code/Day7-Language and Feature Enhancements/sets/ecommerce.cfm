<cfscript>
// Products with different features
wirelessProducts = SetNew(["Laptop A","Mouse X","Keyboard Y","Headphones Z"]);

bluetoothProducts = SetNew(["Mouse X","Headphones Z","Speaker Q"]);

usbCProducts = SetNew(["Laptop A","Charger B","Hub C"]);

// Find products with BOTH wireless AND Bluetooth
wirelessBluetoothProducts = setIntersection(wirelessProducts, bluetoothProducts);
writeOutput("Wireless + Bluetooth: ");
writeDump(wirelessBluetoothProducts);
// Find wireless products that DON'T have Bluetooth
wirelessOnlyProducts = setDifference(wirelessProducts, bluetoothProducts);
writeOutput("<br>Wireless-only: ");
writeDump(wirelessOnlyProducts);

// Find products with wireless OR USB-C
modernProducts = setUnion(wirelessProducts, usbCProducts);
writeOutput("<br>Wireless OR USB-C: ");
writeDump(modernProducts);

// Check if two feature sets have no overlap
if (setIsDisjointFrom(bluetoothProducts, usbCProducts)) {
    writeOutput("<br>Bluetooth and USB-C are separate categories");
}
</cfscript>