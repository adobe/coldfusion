component{
    this.name ="gcp"
      void function onApplicationStart(){
    application.gcpCred = {
        projectId : "my-project",
        credentialJsonFilePath : "path-to-creds.json"
    };
    application.gcpConf = {
        serviceName : "STORAGE",                      
          alias : "gcpConfig",
          retrySettings : {
                   initialRetryDelay : "2s",   
                   initialRpcTimeout : "2s",   
                   maxAttempts : 5 ,    
                   maxRetryDelay : "30s", 
                   maxRpcTimeout : "30s", 
                   retryDelayMultiplier : 2 ,  
                   rpcTimeoutMultiplier : 2,  
                   totalTimeOut : "60s"
                  },
         transportOptions : {
                   connectTimeout : "5000",   
                   readTimeout : "5000"  
                   }
    };
    }
}