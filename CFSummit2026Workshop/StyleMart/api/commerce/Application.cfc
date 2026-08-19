component {
    this.name = "commerce";
    this.datasource = "stylemart";
    this.sessionManagement = true;
    this.sessionTimeout = createTimespan(0, 2, 0, 0);

    public boolean function onApplicationStart() {
        restInitApplication(expandPath("."), "commerce");
        return true;
    }
    
    public boolean function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reload")) {
            restInitApplication(expandPath("."), "commerce");
        }
        return true;
    }
}
