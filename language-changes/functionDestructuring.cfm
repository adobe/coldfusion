<cfscript>
student = {
    name: 'John Doe',
    age: 16,
    scores: {
        maths: 74,
        english: 63,
        science: 85
    }
};

// Without Destructuring
function displaySummary(student) {
    writeOutput('Hello, ' & student.name & '<br>');
    writeOutput('Your Maths score is ' & (student.scores.maths)& '<br>');
    writeOutput('Your English score is ' & (student.scores.english)& '<br>');
    writeOutput('Your Science score is ' & (student.scores.science)& '<br>');
    writeOutput(student.age);
}

// With Destructuring
function displaySummaryWithDestructuring({name, scores: { maths = 0, english = 0, science = 0, social = 20}}) {
    writeOutput('Hello, ' & name& '<br>');
    writeOutput('Your Maths score is ' & maths& '<br>');
    writeOutput('Your English score is ' & english& '<br>');
    writeOutput('Your Science score is ' & science& '<br>');
    writeOutput('Your Social score is ' & social& '<br>');
    //writeOutput(age);
}

WriteOutput("<b>Displaying the Details without Destructuring</b><br>");
writeOutput("<br>****************************<br>");
displaySummary(student);
writeOutput("<br>****************************<br>");

WriteOutput("<br><b>Displaying the Details with Destructuring</b><br>");
writeOutput("<br>****************************<br>");
displaySummaryWithDestructuring(student);
writeOutput("<br>****************************<br>");
</cfscript>