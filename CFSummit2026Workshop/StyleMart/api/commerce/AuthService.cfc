component rest="true" restpath="/auth" produces="application/json" {

    // ---- internal: deterministic password hash ----------------------------------
    // MD5 hex (CF built-in). Workshop demo only — NOT production-safe.
    private string function hashPassword(required string plain) {
        return lCase(hash(arguments.plain, "MD5"));
    }

    private boolean function checkPassword(required string plain, required string stored) {
        return arguments.stored == hashPassword(arguments.plain);
    }

    private void function httpError(required numeric status, required string code, required string title) {
        var resp = getPageContext().getResponse();
        resp.setStatus(arguments.status);
        resp.setContentType("application/json");
        writeOutput(serializeJSON({"code": arguments.code, "title": arguments.title, "status": arguments.status}));
        abort;
    }

    remote struct function login() httpmethod="POST" restpath="login" {
        cflog(text="[AuthService.login] entered", file="auth-debug");
        var body = {};
        try {
            body = deserializeJSON(toString(getHttpRequestData().content));
            cflog(text="[AuthService.login] body parsed: #serializeJSON(structKeyList(body))#", file="auth-debug");
        } catch (any e) {
            cflog(text="[AuthService.login] body parse error: #e.message#", file="auth-debug");
            throw(type="RestError", errorcode="400", message="Invalid request body");
        }

        if (!structKeyExists(body, "username") || !structKeyExists(body, "password")) {
            cflog(text="[AuthService.login] missing username/password", file="auth-debug");
            throw(type="RestError", errorcode="400", message="Username and password required");
        }

        var dsn = "stylemart";
        cflog(text="[AuthService.login] querying user: #body.username#", file="auth-debug");

        try {
            var qUser = queryExecute("
                SELECT user_id, username, password_hash, display_name, email, loyalty_tier_id
                FROM users
                WHERE username = :username
            ", {username: {value: body.username, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});
            cflog(text="[AuthService.login] query returned #qUser.recordCount# rows", file="auth-debug");
        } catch (any e) {
            cflog(text="[AuthService.login] DB error: #e.message#", type="error", file="auth-debug");
            rethrow;
        }

        if (qUser.recordCount == 0) {
            cflog(text="[AuthService.login] user not found: #body.username#", file="auth-debug");
            httpError(401, "invalid_credentials", "Invalid username or password");
        }

        cflog(text="[AuthService.login] stored hash prefix: #left(qUser.password_hash, 20)#... len=#len(qUser.password_hash)#", file="auth-debug");
        cflog(text="[AuthService.login] computed hash prefix: #left(hashPassword(body.password), 20)#...", file="auth-debug");
        if (!checkPassword(body.password, qUser.password_hash)) {
            cflog(text="[AuthService.login] password mismatch for: #body.username#", file="auth-debug");
            httpError(401, "invalid_credentials", "Invalid username or password");
        }

        cflog(text="[AuthService.login] auth success, setting session for: #qUser.user_id#", file="auth-debug");
        session.authenticated = true;
        session.userId        = qUser.user_id;
        session.username      = qUser.username;
        session.displayName   = qUser.display_name;
        session.email         = qUser.email;
        session.loyaltyTierId = qUser.loyalty_tier_id;

        return {
            "success": true,
            "user": {
                "userId":        qUser.user_id,
                "username":      qUser.username,
                "displayName":   qUser.display_name,
                "email":         qUser.email,
                "loyaltyTierId": qUser.loyalty_tier_id
            }
        };
    }

    remote struct function register() httpmethod="POST" restpath="register" {
        var body = {};
        try {
            body = deserializeJSON(toString(getHttpRequestData().content));
        } catch (any e) {
            throw(type="RestError", errorcode="400", message="Invalid request body");
        }

        if (!structKeyExists(body, "username") || !structKeyExists(body, "password") || !structKeyExists(body, "displayName")) {
            throw(type="RestError", errorcode="400", message="Username, password, and displayName required");
        }

        var dsn = "stylemart";

        var qCheck = queryExecute("
            SELECT user_id FROM users WHERE username = :username
        ", {username: {value: body.username, cfsqltype: "cf_sql_varchar"}}, {datasource: dsn});

        if (qCheck.recordCount > 0) {
            throw(type="RestError", errorcode="409", message="Username already exists");
        }

        var passwordHash = hashPassword(body.password);
        var userId       = "usr_" & lCase(replace(createUUID(), "-", "", "all"));

        queryExecute("
            INSERT INTO users (user_id, username, password_hash, display_name, email, loyalty_tier_id, created_at)
            VALUES (:uid, :username, :hash, :name, :email, :tier, :created)
        ", {
            uid:      {value: userId,                    cfsqltype: "cf_sql_varchar"},
            username: {value: body.username,             cfsqltype: "cf_sql_varchar"},
            hash:     {value: passwordHash,              cfsqltype: "cf_sql_varchar"},
            name:     {value: body.displayName,          cfsqltype: "cf_sql_varchar"},
            email:    {value: body.email ?: "",          cfsqltype: "cf_sql_varchar"},
            tier:     {value: "tier_bronze",             cfsqltype: "cf_sql_varchar"},
            created:  {value: now(),                     cfsqltype: "cf_sql_timestamp"}
        }, {datasource: dsn});

        return {
            "success": true,
            "userId":  userId,
            "username": body.username
        };
    }

    remote struct function logout() httpmethod="POST" restpath="logout" {
        structClear(session);
        return {"success": true};
    }

    remote struct function getSession() httpmethod="GET" restpath="session" {
        if (structKeyExists(session, "authenticated") && session.authenticated) {
            return {
                "authenticated": true,
                "user": {
                    "userId":        session.userId,
                    "username":      session.username,
                    "displayName":   session.displayName,
                    "email":         session.email,
                    "loyaltyTierId": session.loyaltyTierId
                }
            };
        }
        return {"authenticated": false};
    }
}
