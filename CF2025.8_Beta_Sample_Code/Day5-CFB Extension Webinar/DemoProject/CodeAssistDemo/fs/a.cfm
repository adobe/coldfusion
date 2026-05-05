<cfscript>

    db = getCloudService(Application.cred, Application.conf);
    students = db.collection("students_p");

    query = students.whereIn("age", [16, 17, 25, 7]);

    results = query.runQuery().then((res) => return res);

    results = results.get();

    flag = 1;

       writeDump(results.getDocuments()[1].getData()["age"]); //works

    writeDump(results.getDocuments()[1].getData().age); //fails
   
</cfscript>