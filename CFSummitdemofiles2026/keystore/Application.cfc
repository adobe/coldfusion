component {
    variables.appRoot = getDirectoryFromPath(getCurrentTemplatePath());
    variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";

    this.name = "CFSummit2026Keystore";
    this.applicationTimeout = createTimeSpan(0, 4, 0, 0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 10, 0);
    this.setClientCookies = true;
    this.serialization.preserveCaseForStructKey = true;
    this.mappings["/keystore"] = variables.appRoot & "components";

    public boolean function onApplicationStart() {
        initializeKeystore();
        return true;
    }

    public void function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reloadApp") && url.reloadApp == "1") {
            applicationStop();
            location(url = cgi.script_name, addToken = false);
        }

        if (
            !structKeyExists(application, "keystoreInitialized") ||
            !structKeyExists(application, "keystoreConfig") ||
            !directoryExists(application.keystoreConfig.dbParentPath)
        ) {
            initializeKeystore();
        }
    }

    private void function initializeKeystore() {
        var dataRoot = variables.appRoot & "data" & variables.pathSep;
        var dbParentPath = dataRoot & "derby" & variables.pathSep;

        application.appRoot = variables.appRoot;
        application.pathSep = variables.pathSep;
        application.keystoreConfig = {
            appRoot: variables.appRoot,
            dataRoot: dataRoot,
            dbParentPath: dbParentPath,
            databasePath: dbParentPath & "keystoredb",
            masterKeyPath: dataRoot & "keystore-master.key"
        };

        application.keystoreStatus = new keystore.KeystoreService(application.keystoreConfig).bootstrap();
        application.keystoreInitialized = true;
    }
}
