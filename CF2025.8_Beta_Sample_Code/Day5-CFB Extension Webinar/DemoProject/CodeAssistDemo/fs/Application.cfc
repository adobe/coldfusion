component{
this.name ="FS_CRUD_1";
this.enableNullSupport=true;
void function onApplicationStart(){
Application.cred = {
        projectId : "adbe-gcp0318",
        credentialJsonFilePath : #expandPath("./"&"/adbe-gcp0318-c141af8281cb.json")#
    };
Application.conf = {
        serviceName : "firestore",
    };
}
}

