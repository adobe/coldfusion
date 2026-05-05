<cfscript>

	db= getCloudService(Application.cred,Application.conf);
	docRef=db.collection("orders").document("order1");
	docRef.getDocument().get();


   
</cfscript>