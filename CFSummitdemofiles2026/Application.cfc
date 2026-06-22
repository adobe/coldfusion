component {
    variables.appRoot = getDirectoryFromPath(getCurrentTemplatePath());
    variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";

    this.name = "CFSummit2026DemoLauncher";
    this.applicationTimeout = createTimeSpan(0, 4, 0, 0);
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 0, 10, 0);
    this.setClientCookies = true;
    this.mappings["/demotracking"] = variables.appRoot & "usertracking" & variables.pathSep & "components";

    public boolean function onApplicationStart() {
        initializeTracking();
        return true;
    }

    public void function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reloadApp") && url.reloadApp == "1") {
            applicationStop();
            location(url = cgi.script_name, addToken = false);
        }

        if (
            !structKeyExists(application, "demoTrackingConfig") ||
            !structKeyExists(application.demoTrackingConfig, "sessionMinutes") ||
            val(application.demoTrackingConfig.sessionMinutes) != 10
        ) {
            initializeTracking();
        }
    }

    private void function initializeTracking() {
        var dataRoot = variables.appRoot & "usertracking" & variables.pathSep & "data" & variables.pathSep;
        var dbParentPath = dataRoot & "derby" & variables.pathSep;

        application.demoTrackingConfig = {
            appRoot: variables.appRoot,
            dataRoot: dataRoot,
            dbParentPath: dbParentPath,
            databasePath: dbParentPath & "trackingdb",
            sessionMinutes: 10,
            cookieName: "cfsummit_demo_session",
            cookiePath: "/CFSummit2026/demos/"
        };

        application.demoTrackingStatus = new demotracking.DemoTrackingService(application.demoTrackingConfig).bootstrap();
    }
}
