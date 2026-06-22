component output="false" {
    public any function init(struct config = {}) {
        variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
        variables.componentRoot = getDirectoryFromPath(getCurrentTemplatePath());
        variables.appRoot = structKeyExists(arguments.config, "appRoot")
            ? arguments.config.appRoot
            : getParentDirectory(getParentDirectory(variables.componentRoot));
        variables.dataRoot = ensureTrailingSlash(
            structKeyExists(arguments.config, "dataRoot")
                ? arguments.config.dataRoot
                : variables.appRoot & "usertracking" & variables.pathSep & "data" & variables.pathSep
        );
        variables.dbParentPath = ensureTrailingSlash(
            structKeyExists(arguments.config, "dbParentPath")
                ? arguments.config.dbParentPath
                : variables.dataRoot & "derby" & variables.pathSep
        );
        variables.databasePath = structKeyExists(arguments.config, "databasePath")
            ? arguments.config.databasePath
            : variables.dbParentPath & "trackingdb";
        variables.sessionMinutes = structKeyExists(arguments.config, "sessionMinutes")
            ? val(arguments.config.sessionMinutes)
            : 10;
        variables.cookieName = structKeyExists(arguments.config, "cookieName")
            ? arguments.config.cookieName
            : "cfsummit_demo_session";
        variables.cookiePath = structKeyExists(arguments.config, "cookiePath")
            ? arguments.config.cookiePath
            : "/CFSummit2026/demos/";
        variables.connectionUrl = "jdbc:derby:" & normalizeDerbyPath(variables.databasePath);
        return this;
    }

    public struct function bootstrap() {
        var conn = "";
        var createdSchema = false;

        ensureDirectory(variables.dataRoot);
        ensureDirectory(variables.dbParentPath);

        try {
            conn = getConnection(true);
            if (!tableExists(conn, "tracking_sessions")) {
                createSchema(conn);
                createdSchema = true;
            } else if (!tableExists(conn, "tracking_events")) {
                createEventsTable(conn);
                createdSchema = true;
            }

            return {
                ok: true,
                createdSchema: createdSchema,
                sessionCount: countRows(conn, "tracking_sessions"),
                eventCount: countRows(conn, "tracking_events"),
                databasePath: variables.databasePath
            };
        } finally {
            closeQuietly(conn);
        }
    }

    public struct function login(
        required string fullName,
        required string email,
        required string company,
        string userAgent = "",
        string remoteAddr = ""
    ) {
        var cleanName = left(trim(arguments.fullName), 180);
        var cleanEmail = left(lcase(trim(arguments.email)), 220);
        var cleanCompany = left(trim(arguments.company), 180);
        var sessionId = rereplace(createUUID(), "[^A-Za-z0-9]", "", "all");
        var conn = "";
        var ps = "";

        if (!len(cleanName) || !len(cleanEmail) || !len(cleanCompany)) {
            throw(type = "DemoTracking.Validation", message = "Name, email, and company are required.");
        }
        if (!isValid("email", cleanEmail)) {
            throw(type = "DemoTracking.Validation", message = "Enter a valid email address.");
        }

        bootstrap();

        try {
            conn = getConnection();
            ps = conn.prepareStatement("
                INSERT INTO tracking_sessions (
                    session_id, full_name, email, company, logged_in_at,
                    last_activity_at, user_agent, remote_addr
                )
                VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, ?, ?)
            ");
            ps.setString(1, sessionId);
            ps.setString(2, cleanName);
            ps.setString(3, cleanEmail);
            ps.setString(4, cleanCompany);
            ps.setString(5, left(arguments.userAgent, 4000));
            ps.setString(6, left(arguments.remoteAddr, 80));
            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
            closeQuietly(conn);
        }

        return {
            ok: true,
            sessionId: sessionId,
            attendee: {
                name: cleanName,
                email: cleanEmail,
                company: cleanCompany
            },
            expiresAfterMinutes: variables.sessionMinutes
        };
    }

    public struct function getCurrentSession(boolean touch = false) {
        var sessionId = getCookieSessionId();
        if (!len(sessionId)) {
            return { ok: false, active: false, reason: "missing" };
        }

        return getSession(sessionId, arguments.touch);
    }

    public struct function getSession(required string sessionId, boolean touch = false) {
        var conn = "";
        var row = {};

        bootstrap();

        try {
            conn = getConnection();
            row = findSession(conn, arguments.sessionId);

            if (structIsEmpty(row)) {
                return { ok: false, active: false, reason: "missing" };
            }
            if (len(row.expiredAt) || len(row.resetAt)) {
                return { ok: true, active: false, reason: len(row.resetAt) ? "reset" : "expired", attendee: sessionAttendee(row) };
            }
            if (isExpired(row.lastActivityAt)) {
                expireSession(conn, arguments.sessionId);
                row.expiredAt = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
                return { ok: true, active: false, reason: "expired", attendee: sessionAttendee(row) };
            }

            if (arguments.touch) {
                touchSession(conn, arguments.sessionId);
                row.lastActivityAt = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
            }

            return {
                ok: true,
                active: true,
                attendee: sessionAttendee(row),
                session: row,
                expiresAfterMinutes: variables.sessionMinutes
            };
        } finally {
            closeQuietly(conn);
        }
    }

    public struct function trackEvent(
        required string eventType,
        string demoKey = "",
        string demoName = "",
        string scenarioId = "",
        string scenarioTitle = "",
        string scenarioFile = "",
        boolean solved = false,
        string payload = ""
    ) {
        var sessionId = getCookieSessionId();
        var status = {};
        var conn = "";
        var ps = "";

        if (!len(sessionId)) {
            return { ok: false, tracked: false, reason: "missing-session" };
        }

        bootstrap();

        try {
            conn = getConnection();
            status = getSessionWithConnection(conn, sessionId, true);
            if (!status.active) {
                return { ok: false, tracked: false, reason: status.reason };
            }

            ps = conn.prepareStatement("
                INSERT INTO tracking_events (
                    session_id, event_type, demo_key, demo_name, scenario_id,
                    scenario_title, scenario_file, solved, event_payload, created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            ");
            ps.setString(1, sessionId);
            ps.setString(2, left(trim(arguments.eventType), 80));
            ps.setString(3, left(trim(arguments.demoKey), 80));
            ps.setString(4, left(trim(arguments.demoName), 180));
            ps.setString(5, left(trim(arguments.scenarioId), 180));
            ps.setString(6, left(trim(arguments.scenarioTitle), 220));
            ps.setString(7, left(trim(arguments.scenarioFile), 260));
            ps.setInt(8, arguments.solved ? 1 : 0);
            ps.setString(9, left(trim(arguments.payload), 8000));
            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
            closeQuietly(conn);
        }

        return { ok: true, tracked: true };
    }

    public struct function resetCurrentSession() {
        var sessionId = getCookieSessionId();
        if (len(sessionId)) {
            resetSession(sessionId);
        }
        return { ok: true, reset: true };
    }

    public void function resetSession(required string sessionId) {
        var conn = "";
        var ps = "";

        bootstrap();

        try {
            conn = getConnection();
            ps = conn.prepareStatement("
                UPDATE tracking_sessions
                SET reset_at = CURRENT_TIMESTAMP, last_activity_at = CURRENT_TIMESTAMP
                WHERE session_id = ? AND reset_at IS NULL
            ");
            ps.setString(1, arguments.sessionId);
            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
            closeQuietly(conn);
        }
    }

    public struct function dashboardData(numeric maxRows = 250) {
        var conn = "";
        var sessions = [];
        var events = [];

        bootstrap();

        try {
            conn = getConnection();
            sessions = listSessions(conn, arguments.maxRows);
            events = listEvents(conn, arguments.maxRows);
        } finally {
            closeQuietly(conn);
        }

        return {
            ok: true,
            sessions: sessions,
            events: events,
            databasePath: variables.databasePath
        };
    }

    private struct function getSessionWithConnection(required any conn, required string sessionId, boolean touch = false) {
        var row = findSession(arguments.conn, arguments.sessionId);

        if (structIsEmpty(row)) {
            return { ok: false, active: false, reason: "missing" };
        }
        if (len(row.expiredAt) || len(row.resetAt)) {
            return { ok: true, active: false, reason: len(row.resetAt) ? "reset" : "expired" };
        }
        if (isExpired(row.lastActivityAt)) {
            expireSession(arguments.conn, arguments.sessionId);
            return { ok: true, active: false, reason: "expired" };
        }
        if (arguments.touch) {
            touchSession(arguments.conn, arguments.sessionId);
        }
        return { ok: true, active: true, session: row };
    }

    private struct function findSession(required any conn, required string sessionId) {
        var ps = "";
        var rs = "";

        try {
            ps = arguments.conn.prepareStatement("
                SELECT session_id, full_name, email, company, logged_in_at,
                    last_activity_at, expired_at, reset_at, user_agent, remote_addr
                FROM tracking_sessions
                WHERE session_id = ?
            ");
            ps.setString(1, arguments.sessionId);
            rs = ps.executeQuery();

            if (!rs.next()) {
                return {};
            }
            return sessionRow(rs);
        } finally {
            closeQuietly(rs);
            closeQuietly(ps);
        }
    }

    private array function listSessions(required any conn, required numeric maxRows) {
        var ps = "";
        var rs = "";
        var rows = [];

        try {
            ps = arguments.conn.prepareStatement("
                SELECT s.session_id, s.full_name, s.email, s.company, s.logged_in_at,
                    s.last_activity_at, s.expired_at, s.reset_at, s.remote_addr,
                    COUNT(e.event_id) AS event_count,
                    SUM(CASE WHEN e.event_type = 'demo_launch' THEN 1 ELSE 0 END) AS demo_launch_count,
                    SUM(CASE WHEN e.event_type = 'cfcase_mystery_start' THEN 1 ELSE 0 END) AS mystery_start_count,
                    SUM(CASE WHEN e.event_type = 'cfcase_mystery_solved' THEN 1 ELSE 0 END) AS mystery_solved_count
                FROM tracking_sessions s
                LEFT JOIN tracking_events e ON s.session_id = e.session_id
                GROUP BY s.session_id, s.full_name, s.email, s.company, s.logged_in_at,
                    s.last_activity_at, s.expired_at, s.reset_at, s.remote_addr
                ORDER BY s.logged_in_at DESC
            ");
            ps.setMaxRows(javaCast("int", arguments.maxRows));
            rs = ps.executeQuery();

            while (rs.next()) {
                arrayAppend(rows, {
                    sessionId: rs.getString("session_id"),
                    name: rs.getString("full_name"),
                    email: rs.getString("email"),
                    company: rs.getString("company"),
                    loggedInAt: timestampToString(rs.getTimestamp("logged_in_at")),
                    lastActivityAt: timestampToString(rs.getTimestamp("last_activity_at")),
                    expiredAt: timestampToString(rs.getTimestamp("expired_at")),
                    resetAt: timestampToString(rs.getTimestamp("reset_at")),
                    remoteAddr: safeString(rs.getString("remote_addr")),
                    eventCount: rs.getInt("event_count"),
                    demoLaunchCount: rs.getInt("demo_launch_count"),
                    mysteryStartCount: rs.getInt("mystery_start_count"),
                    mysterySolvedCount: rs.getInt("mystery_solved_count")
                });
            }
        } finally {
            closeQuietly(rs);
            closeQuietly(ps);
        }

        return rows;
    }

    private array function listEvents(required any conn, required numeric maxRows) {
        var ps = "";
        var rs = "";
        var rows = [];

        try {
            ps = arguments.conn.prepareStatement("
                SELECT e.event_id, e.session_id, s.full_name, s.email, s.company,
                    e.event_type, e.demo_key, e.demo_name, e.scenario_id,
                    e.scenario_title, e.scenario_file, e.solved, e.event_payload, e.created_at
                FROM tracking_events e
                INNER JOIN tracking_sessions s ON e.session_id = s.session_id
                ORDER BY e.created_at DESC, e.event_id DESC
            ");
            ps.setMaxRows(javaCast("int", arguments.maxRows));
            rs = ps.executeQuery();

            while (rs.next()) {
                arrayAppend(rows, {
                    eventId: rs.getLong("event_id"),
                    sessionId: rs.getString("session_id"),
                    name: rs.getString("full_name"),
                    email: rs.getString("email"),
                    company: rs.getString("company"),
                    eventType: rs.getString("event_type"),
                    demoKey: safeString(rs.getString("demo_key")),
                    demoName: safeString(rs.getString("demo_name")),
                    scenarioId: safeString(rs.getString("scenario_id")),
                    scenarioTitle: safeString(rs.getString("scenario_title")),
                    scenarioFile: safeString(rs.getString("scenario_file")),
                    solved: rs.getInt("solved") == 1,
                    payload: safeString(rs.getString("event_payload")),
                    createdAt: timestampToString(rs.getTimestamp("created_at"))
                });
            }
        } finally {
            closeQuietly(rs);
            closeQuietly(ps);
        }

        return rows;
    }

    private struct function sessionAttendee(required struct row) {
        return {
            name: row.name,
            email: row.email,
            company: row.company,
            loggedInAt: row.loggedInAt,
            lastActivityAt: row.lastActivityAt
        };
    }

    private struct function sessionRow(required any rs) {
        return {
            sessionId: arguments.rs.getString("session_id"),
            name: arguments.rs.getString("full_name"),
            email: arguments.rs.getString("email"),
            company: arguments.rs.getString("company"),
            loggedInAt: timestampToString(arguments.rs.getTimestamp("logged_in_at")),
            lastActivityAt: timestampToString(arguments.rs.getTimestamp("last_activity_at")),
            expiredAt: timestampToString(arguments.rs.getTimestamp("expired_at")),
            resetAt: timestampToString(arguments.rs.getTimestamp("reset_at")),
            userAgent: safeString(arguments.rs.getString("user_agent")),
            remoteAddr: safeString(arguments.rs.getString("remote_addr"))
        };
    }

    private boolean function isExpired(required string timestampValue) {
        if (!isDate(arguments.timestampValue)) {
            return true;
        }
        return dateDiff("n", parseDateTime(arguments.timestampValue), now()) >= variables.sessionMinutes;
    }

    private void function touchSession(required any conn, required string sessionId) {
        var ps = "";
        try {
            ps = arguments.conn.prepareStatement("
                UPDATE tracking_sessions
                SET last_activity_at = CURRENT_TIMESTAMP
                WHERE session_id = ? AND expired_at IS NULL AND reset_at IS NULL
            ");
            ps.setString(1, arguments.sessionId);
            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
        }
    }

    private void function expireSession(required any conn, required string sessionId) {
        var ps = "";
        try {
            ps = arguments.conn.prepareStatement("
                UPDATE tracking_sessions
                SET expired_at = CURRENT_TIMESTAMP
                WHERE session_id = ? AND expired_at IS NULL AND reset_at IS NULL
            ");
            ps.setString(1, arguments.sessionId);
            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
        }
    }

    private string function getCookieSessionId() {
        if (!structKeyExists(cookie, variables.cookieName)) {
            return "";
        }
        return left(reReplace(trim(cookie[variables.cookieName]), "[^A-Za-z0-9]", "", "all"), 64);
    }

    private boolean function tableExists(required any conn, required string tableName) {
        var st = "";
        var rs = "";

        try {
            st = arguments.conn.createStatement();
            rs = st.executeQuery("SELECT COUNT(*) FROM " & arguments.tableName);
            return true;
        } catch (any ignored) {
            return false;
        } finally {
            closeQuietly(rs);
            closeQuietly(st);
        }
    }

    private void function createSchema(required any conn) {
        executeUpdate(arguments.conn, "
            CREATE TABLE tracking_sessions (
                session_id VARCHAR(64) NOT NULL PRIMARY KEY,
                full_name VARCHAR(180) NOT NULL,
                email VARCHAR(220) NOT NULL,
                company VARCHAR(180) NOT NULL,
                logged_in_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                last_activity_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                expired_at TIMESTAMP,
                reset_at TIMESTAMP,
                user_agent CLOB,
                remote_addr VARCHAR(80)
            )
        ");
        executeUpdate(arguments.conn, "CREATE INDEX idx_tracking_sessions_login ON tracking_sessions (logged_in_at)");
        executeUpdate(arguments.conn, "CREATE INDEX idx_tracking_sessions_email ON tracking_sessions (email)");
        createEventsTable(arguments.conn);
    }

    private void function createEventsTable(required any conn) {
        executeUpdate(arguments.conn, "
            CREATE TABLE tracking_events (
                event_id BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1) PRIMARY KEY,
                session_id VARCHAR(64) NOT NULL,
                event_type VARCHAR(80) NOT NULL,
                demo_key VARCHAR(80),
                demo_name VARCHAR(180),
                scenario_id VARCHAR(180),
                scenario_title VARCHAR(220),
                scenario_file VARCHAR(260),
                solved SMALLINT NOT NULL DEFAULT 0,
                event_payload CLOB,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ");
        executeUpdate(arguments.conn, "CREATE INDEX idx_tracking_events_session ON tracking_events (session_id)");
        executeUpdate(arguments.conn, "CREATE INDEX idx_tracking_events_type ON tracking_events (event_type)");
        executeUpdate(arguments.conn, "CREATE INDEX idx_tracking_events_created ON tracking_events (created_at)");
    }

    private numeric function countRows(required any conn, required string tableName) {
        var st = "";
        var rs = "";

        try {
            st = arguments.conn.createStatement();
            rs = st.executeQuery("SELECT COUNT(*) FROM " & arguments.tableName);
            rs.next();
            return rs.getInt(1);
        } finally {
            closeQuietly(rs);
            closeQuietly(st);
        }
    }

    private void function executeUpdate(required any conn, required string sql) {
        var st = "";
        try {
            st = arguments.conn.createStatement();
            st.executeUpdate(trim(arguments.sql));
        } finally {
            closeQuietly(st);
        }
    }

    private any function getConnection(boolean create = false) {
        loadDerbyDriver();
        return createObject("java", "java.sql.DriverManager").getConnection(
            variables.connectionUrl & (arguments.create ? ";create=true" : "")
        );
    }

    private void function loadDerbyDriver() {
        try {
            createObject("java", "java.lang.Class").forName("org.apache.derby.jdbc.EmbeddedDriver");
        } catch (any ignored) {
        }
    }

    private string function timestampToString(any value = "") {
        try {
            if (isNull(arguments.value)) {
                return "";
            }
        } catch (any ignored) {
            return "";
        }
        return dateTimeFormat(arguments.value, "yyyy-mm-dd HH:nn:ss");
    }

    private string function safeString(any value = "") {
        try {
            if (isNull(arguments.value)) {
                return "";
            }
        } catch (any ignored) {
            return "";
        }
        return toString(arguments.value);
    }

    private void function ensureDirectory(required string path) {
        if (!directoryExists(arguments.path)) {
            directoryCreate(arguments.path, true, true);
        }
    }

    private string function ensureTrailingSlash(required string path) {
        if (!len(arguments.path)) {
            return arguments.path;
        }
        if (right(arguments.path, 1) == "/" || right(arguments.path, 1) == "\") {
            return arguments.path;
        }
        return arguments.path & variables.pathSep;
    }

    private string function normalizeDerbyPath(required string path) {
        return replace(arguments.path, "\", "/", "all");
    }

    private string function getParentDirectory(required string directoryPath) {
        var dirFile = createObject("java", "java.io.File").init(arguments.directoryPath);
        var parentPath = dirFile.getParent();

        if (isNull(parentPath)) {
            return ensureTrailingSlash(arguments.directoryPath);
        }

        parentPath = toString(parentPath);
        if (right(parentPath, 1) != variables.pathSep) {
            parentPath &= variables.pathSep;
        }
        return parentPath;
    }

    private void function closeQuietly(any resource = "") {
        try {
            if (isObject(arguments.resource)) {
                arguments.resource.close();
            }
        } catch (any ignored) {
        }
    }
}
