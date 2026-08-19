component {
    this.name = "prologics-logistics";
    this.datasource = "prologics";
    this.sessionManagement = false;

    this.mappings["/commonutils"] = getDirectoryFromPath(getCurrentTemplatePath()) & "../../commonutils";

    public boolean function onApplicationStart() {
        try {
            var configDir = getDirectoryFromPath(getCurrentTemplatePath()) & "config/";
            setSQLiteDBPath(configDir & "db.properties");
            new commonutils.db.DatasourceUtil().register("prologics", configDir & "db.properties");
        } catch (any e) {
            cflog(text="Error in onRequestStart: #e.message#", type="error", file="prologics-debug");
        }
        restInitApplication(expandPath("."), "logistics");
        return true;
    }

    private void function setSQLiteDBPath(required string propsPath) {
        var content = fileRead(arguments.propsPath);
        if (find("prologics.file=", content)) {
            var correctPath = getDirectoryFromPath(getCurrentTemplatePath()) & "db/sqlite/prologics.db";
            var updated = reReplace(content, "prologics\.file=.*", "prologics.file=" & correctPath);
            if (updated != content) fileWrite(arguments.propsPath, updated);
        }
    }

    public boolean function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reload")) {
            restInitApplication(expandPath("."), "logistics");
        }
        return true;
    }
}
