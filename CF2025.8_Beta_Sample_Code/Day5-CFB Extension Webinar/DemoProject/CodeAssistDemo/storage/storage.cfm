<cfscript >
storageService = getCloudService(application.gcpCred, application.gcpCred)
  createBucketStruct = {
    "name": "bucket_test",
    "storageClass": "STANDARD",
    "location": "US",
    "rules": [{
        "action": {
            "type": "delete"
        },
        "condition": {
            "daysSinceNoncurrentTime": 7
        }
    }],
    "acl": [{
        "entity": {
            "project": {
                projectrole: "EDITORS",
                projectid: "101345678996"
            }
        },
        "role": "READER"
    }],
    "defaultAcl": [{
        "entity": {
            "user": "test@xyz.com"
        },
        "role": "OWNER"
    }]
}
  //rootObj2 = storageService.createBucket(createBucketStruct); 

  
</cfscript>