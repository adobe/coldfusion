<cfscript>
user = { 
    'name': 'Alex',
    'address': '15th Park Avenue',
    'age': 33,
    'company': 'xyz'
}

user1 = {
  name1: 'Sam',
  address1: '20th Park Avenue',
  age1: 32,
  company1: 'xyz'
};

function logDetails({name, age,...rest},{ name1, age1, ...rest1 }, name2) {
	writeOutput(name &' is '& age &' year(s) old!');
	writeOutput(name1 &' is '& age1 &' year(s) old!');
	writeDump(rest1);
	writeOutput(name2);
}
logDetails(user, user1,"John")
</cfscript>