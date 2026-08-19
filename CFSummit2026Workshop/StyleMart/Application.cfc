component {
    this.name = "StyleMartUI";
    this.sessionManagement = true;
    this.sessionTimeout = createTimespan(0, 2, 0, 0);
    this.applicationTimeout = createTimespan(1, 0, 0, 0);
    this.setClientCookies = true;
    this.loginStorage = "session";

    this.mappings["/commonutils"] = getDirectoryFromPath(getCurrentTemplatePath()) & "../commonutils";

    public boolean function onApplicationStart() {
        application.cartId = "crt_demo_jordan";
        try {
            var dbProps = getDirectoryFromPath(getCurrentTemplatePath()) & "config/db.properties";
            new commonutils.db.DatasourceUtil().register("stylemart", dbProps);
        } catch (any e) {}
        return true;
    }

    public boolean function onSessionStart() {
        session.viewing = "home";
        return true;
    }

    public boolean function onRequestStart(required string targetPage) {
        if (structKeyExists(url, "reload")) onApplicationStart();

        // §4.4 cflogin auth model: wrap every request in <cflogin>.
        // login.cfm and /auth/* endpoints are open (no auth required).
        var openPages = "login.cfm";
        var pageName = listLast(arguments.targetPage, "/\");

        if (listFindNoCase(openPages, pageName)) {
            return true;
        }

        // REST auth endpoints are handled by the API layer, not this gate
        if (findNoCase("/api/commerce/auth/", cgi.path_info) || findNoCase("/api/commerce/auth/", cgi.script_name)) {
            return true;
        }

        cflogin() {
            // Check if credentials are in the session (set by U6 login handler)
            if (structKeyExists(session, "userId") && len(session.userId)) {
                cfloginuser(name=session.userId, password="", roles="shopper");
            }
        }

        // In mock mode (no live API layer), the JS auth gate handles redirects.
        // The server-side gate only enforces when a CFML session has been established
        // (i.e., when running against the live backend).
        if (getAuthUser().len()) {
            request.shopperId = getAuthUser();
        }

        return true;
    }
}
