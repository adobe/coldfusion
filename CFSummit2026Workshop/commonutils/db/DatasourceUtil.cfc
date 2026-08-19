component hint="Shared utility to register a CF datasource (MySQL or SQLite) via the CF Admin API if not already registered" {

    public void function register(required string name, required string propsPath) {
        var props = getPropertyFile(arguments.propsPath);
        var prefix = arguments.name & ".";
        var type   = lCase(props[prefix & "type"] ?: "mysql");

        var adminPassword = props["admin.password"];
        try {
            adminPassword = server.system.environment["CF_ADMIN_PASSWORD"];
        } catch (any e) {
            // CF_ADMIN_PASSWORD not set — fall back to db.properties value.
        }
        createObject("component", "CFIDE.adminapi.administrator").login(adminPassword);
        var ds = createObject("component", "CFIDE.adminapi.datasource");

        if (structKeyExists(ds.getDatasources(), arguments.name)) {
            return;
        }

        if (type == "sqlite") {
            var dbFile = props[prefix & "file"] ?: "";
            if (!len(dbFile)) {
                throw(message="DatasourceUtil: SQLite datasource '#arguments.name#' missing '#prefix#file' in #arguments.propsPath#");
            }
            var sqliteUrl = "jdbc:sqlite:" & dbFile
                          & "?journal_mode=WAL&busy_timeout=5000&foreign_keys=on";
            ds.setOther(
                name:   arguments.name,
                url:    sqliteUrl,
                class:  "org.sqlite.JDBC",
                driver: "Other"
            );
            return;
        }

        ds.setMySQL5(
            name:     arguments.name,
            host:     props[prefix & "host"]     ?: "localhost",
            port:     props[prefix & "port"]     ?: "3306",
            database: props[prefix & "database"] ?: arguments.name,
            username: props[prefix & "username"] ?: "root",
            password: props[prefix & "password"] ?: ""
        );
    }
}
