<cfscript>
  personObj = new Person(firstName = 'Matt', lastName = 'Gifford', 
  address = {"street" : 20,"village": "vikarabad"}
  );

changeAddress = (address) => {
  address["street"] = 22;
  return address;
  }
  
  personObjDeepCopy = duplicate(personObj);
  personObjShallowCopy = duplicate(personObj, false);
  personObj.setAddress(changeAddress(personObj.getAddress()));
  personObj.setFirstName("Brad"); //primitive Type, hence copied.
  writeDump(var=personObj, label="Person");
  writeOutput("<br>");
  writeDump(var = personObjDeepCopy, label="Deep");
  writeOutput("<br>");
  writeDump(var = personObjShallowCopy, label="Shallow");
</cfscript>