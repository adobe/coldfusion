component output=false {
    variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
    variables.appRoot = "";
    variables.dataRoot = "";
    variables.dbParentPath = "";
    variables.databasePath = "";
    variables.connectionUrl = "";
    variables.bootstrapped = false;

    public DerbyStore function init(struct config = {}) {
        variables.appRoot = ensureTrailingSlash(readKey(arguments.config, "appRoot", getParentDirectory(getDirectoryFromPath(getCurrentTemplatePath()))));
        variables.dataRoot = ensureTrailingSlash(readKey(arguments.config, "dataRoot", variables.appRoot & "data" & variables.pathSep));
        variables.dbParentPath = ensureTrailingSlash(readKey(arguments.config, "dbParentPath", variables.dataRoot & "derby" & variables.pathSep));
        variables.databasePath = readKey(arguments.config, "databasePath", variables.dbParentPath & "cairoi");
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
            if (!tableExistsWithConnection(conn, "cairoi_applications")) {
                createSchema(conn);
                createdSchema = true;
            }
            variables.bootstrapped = true;

            return {
                ok: true,
                createdSchema: createdSchema,
                databasePath: variables.databasePath,
                applicationCount: countRows("cairoi_applications"),
                keyCount: countRows("cairoi_api_keys"),
                priceCount: countRows("cairoi_model_prices"),
                traceCount: countRows("cairoi_traces"),
                spanCount: countRows("cairoi_spans")
            };
        } finally {
            closeQuietly(conn);
        }
    }

    public query function execute(required string sql, struct params = {}) {
        var parsed = parseNamedSql(arguments.sql);
        var conn = "";
        var ps = "";
        var rs = "";

        ensureBootstrapped();

        try {
            conn = getConnection();
            ps = conn.prepareStatement(parsed.sql);
            bindParams(ps, parsed.paramNames, arguments.params);

            if (ps.execute()) {
                rs = ps.getResultSet();
                return resultSetToQuery(rs);
            }

            return queryNew("");
        } finally {
            closeQuietly(rs);
            closeQuietly(ps);
            closeQuietly(conn);
        }
    }

    public boolean function tableExists(required string tableName) {
        var conn = "";
        try {
            ensureBootstrapped();
            conn = getConnection();
            return tableExistsWithConnection(conn, arguments.tableName);
        } finally {
            closeQuietly(conn);
        }
    }

    public numeric function countRows(required string tableName) {
        var q = execute("SELECT COUNT(*) AS item_count FROM " & safeIdentifier(arguments.tableName));
        return q.recordCount ? val(q.item_count[1]) : 0;
    }

    public struct function getConfig() {
        return {
            appRoot: variables.appRoot,
            dataRoot: variables.dataRoot,
            dbParentPath: variables.dbParentPath,
            databasePath: variables.databasePath,
            connectionUrl: variables.connectionUrl
        };
    }

    private void function ensureBootstrapped() {
        if (!variables.bootstrapped) {
            bootstrap();
        }
    }

    private void function createSchema(required any conn) {
        executeUpdate(arguments.conn, "
            CREATE TABLE cairoi_applications (
                app_id VARCHAR(100) NOT NULL PRIMARY KEY,
                app_name VARCHAR(200) NOT NULL,
                owner_name VARCHAR(200),
                environment VARCHAR(50) NOT NULL DEFAULT 'dev',
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                is_active SMALLINT NOT NULL DEFAULT 1
            )
        ");

        executeUpdate(arguments.conn, "
            CREATE TABLE cairoi_traces (
                trace_id VARCHAR(80) NOT NULL PRIMARY KEY,
                app_id VARCHAR(100) NOT NULL,
                environment VARCHAR(50) NOT NULL DEFAULT 'dev',
                workflow_name VARCHAR(200) NOT NULL,
                user_hash VARCHAR(80),
                session_hash VARCHAR(80),
                request_id VARCHAR(120),
                started_at TIMESTAMP NOT NULL,
                ended_at TIMESTAMP,
                duration_ms INT,
                status VARCHAR(40) NOT NULL DEFAULT 'success',
                total_input_tokens INT NOT NULL DEFAULT 0,
                total_output_tokens INT NOT NULL DEFAULT 0,
                total_tokens INT NOT NULL DEFAULT 0,
                estimated_cost DECIMAL(19, 8) NOT NULL DEFAULT 0,
                metadata_json CLOB,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ");

        executeUpdate(arguments.conn, "
            CREATE TABLE cairoi_spans (
                span_id VARCHAR(80) NOT NULL PRIMARY KEY,
                trace_id VARCHAR(80) NOT NULL,
                parent_span_id VARCHAR(80),
                app_id VARCHAR(100) NOT NULL,
                environment VARCHAR(50) NOT NULL DEFAULT 'dev',
                workflow_name VARCHAR(200) NOT NULL,
                operation_type VARCHAR(80) NOT NULL,
                operation_name VARCHAR(200),
                provider VARCHAR(100),
                model_name VARCHAR(200),
                started_at TIMESTAMP NOT NULL,
                ended_at TIMESTAMP,
                duration_ms INT,
                status VARCHAR(40) NOT NULL DEFAULT 'success',
                input_tokens INT NOT NULL DEFAULT 0,
                output_tokens INT NOT NULL DEFAULT 0,
                total_tokens INT NOT NULL DEFAULT 0,
                input_token_source VARCHAR(40),
                output_token_source VARCHAR(40),
                total_token_source VARCHAR(40),
                estimated_cost DECIMAL(19, 8) NOT NULL DEFAULT 0,
                cost_source VARCHAR(80),
                prompt_hash VARCHAR(80),
                response_hash VARCHAR(80),
                prompt_chars INT NOT NULL DEFAULT 0,
                response_chars INT NOT NULL DEFAULT 0,
                request_bytes INT NOT NULL DEFAULT 0,
                response_bytes INT NOT NULL DEFAULT 0,
                error_type VARCHAR(200),
                error_message VARCHAR(2000),
                metadata_json CLOB,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ");

        executeUpdate(arguments.conn, "
            CREATE TABLE cairoi_api_keys (
                api_key_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                app_id VARCHAR(100) NOT NULL,
                api_key_hash VARCHAR(80) NOT NULL UNIQUE,
                api_key_preview VARCHAR(40) NOT NULL,
                is_active SMALLINT NOT NULL DEFAULT 1,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                last_used_at TIMESTAMP
            )
        ");

        executeUpdate(arguments.conn, "
            CREATE TABLE cairoi_model_prices (
                price_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                provider VARCHAR(100) NOT NULL,
                model_name VARCHAR(200) NOT NULL,
                input_cost_per_1m DECIMAL(19, 8) NOT NULL DEFAULT 0,
                output_cost_per_1m DECIMAL(19, 8) NOT NULL DEFAULT 0,
                currency VARCHAR(10) NOT NULL DEFAULT 'USD',
                effective_start TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                effective_end TIMESTAMP,
                is_active SMALLINT NOT NULL DEFAULT 1,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        ");

        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_spans_trace_started ON cairoi_spans(trace_id, started_at)");
        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_spans_reporting ON cairoi_spans(app_id, environment, workflow_name, provider, model_name, operation_type, started_at)");
        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_spans_status ON cairoi_spans(status, started_at)");
        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_traces_reporting ON cairoi_traces(app_id, environment, workflow_name, started_at)");
        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_traces_status ON cairoi_traces(status, started_at)");
        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_api_keys_app ON cairoi_api_keys(app_id, is_active)");
        executeUpdate(arguments.conn, "CREATE INDEX ix_cairoi_model_prices_lookup ON cairoi_model_prices(provider, model_name, is_active, effective_start, effective_end)");
    }

    private struct function parseNamedSql(required string sql) {
        var source = trim(arguments.sql);
        var output = "";
        var paramNames = [];
        var startAt = 1;
        var match = {};

        while (startAt <= len(source)) {
            match = reFindNoCase(":[A-Za-z][A-Za-z0-9_]*", source, startAt, true);
            if (!arrayLen(match.pos) || match.pos[1] == 0) {
                output &= mid(source, startAt, len(source) - startAt + 1);
                break;
            }

            output &= mid(source, startAt, match.pos[1] - startAt) & "?";
            arrayAppend(paramNames, mid(source, match.pos[1] + 1, match.len[1] - 1));
            startAt = match.pos[1] + match.len[1];
        }

        return { sql: output, paramNames: paramNames };
    }

    private void function bindParams(required any ps, required array paramNames, required struct params) {
        for (var i = 1; i <= arrayLen(arguments.paramNames); i++) {
            var paramName = arguments.paramNames[i];
            var param = findParam(arguments.params, paramName);
            bindParam(arguments.ps, i, param);
        }
    }

    private struct function findParam(required struct params, required string paramName) {
        for (var key in structKeyArray(arguments.params)) {
            if (compareNoCase(key, arguments.paramName) == 0) {
                var value = arguments.params[key];
                return isStruct(value) ? value : { value: value };
            }
        }
        throw(type = "CAIROI.Derby.MissingParam", message = "Missing SQL parameter: " & arguments.paramName);
    }

    private void function bindParam(required any ps, required numeric index, required struct param) {
        var value = readKey(arguments.param, "value", "");
        var type = lcase(readKey(arguments.param, "cfsqltype", "cf_sql_varchar"));
        var isNullValue = toBoolean(readKey(arguments.param, "null", false), false);

        if (isNullValue) {
            arguments.ps.setNull(javaCast("int", arguments.index), jdbcType(type));
            return;
        }

        if (listFindNoCase("cf_sql_integer,cf_sql_smallint,cf_sql_tinyint", type)) {
            arguments.ps.setInt(javaCast("int", arguments.index), javaCast("int", val(value)));
            return;
        }

        if (type == "cf_sql_bit" || type == "cf_sql_boolean") {
            arguments.ps.setInt(javaCast("int", arguments.index), javaCast("int", toBoolean(value, false) ? 1 : 0));
            return;
        }

        if (listFindNoCase("cf_sql_decimal,cf_sql_numeric,cf_sql_float,cf_sql_double,cf_sql_real", type)) {
            arguments.ps.setDouble(javaCast("int", arguments.index), javaCast("double", numericValue(value)));
            return;
        }

        if (listFindNoCase("cf_sql_timestamp,cf_sql_date,cf_sql_time", type)) {
            arguments.ps.setTimestamp(javaCast("int", arguments.index), timestampValue(value));
            return;
        }

        arguments.ps.setString(javaCast("int", arguments.index), toString(value));
    }

    private numeric function jdbcType(required string cfsqltype) {
        var type = lcase(arguments.cfsqltype);
        if (listFindNoCase("cf_sql_integer,cf_sql_smallint,cf_sql_tinyint,cf_sql_bit,cf_sql_boolean", type)) {
            return 4;
        }
        if (listFindNoCase("cf_sql_decimal,cf_sql_numeric", type)) {
            return 3;
        }
        if (listFindNoCase("cf_sql_float,cf_sql_double,cf_sql_real", type)) {
            return 8;
        }
        if (listFindNoCase("cf_sql_timestamp,cf_sql_date,cf_sql_time", type)) {
            return 93;
        }
        if (listFindNoCase("cf_sql_longvarchar,cf_sql_clob", type)) {
            return 2005;
        }
        return 12;
    }

    private query function resultSetToQuery(required any rs) {
        var metadata = arguments.rs.getMetaData();
        var columnCount = metadata.getColumnCount();
        var columns = [];
        var types = [];

        for (var i = 1; i <= columnCount; i++) {
            var label = metadata.getColumnLabel(javaCast("int", i));
            arrayAppend(columns, len(label) ? label : metadata.getColumnName(javaCast("int", i)));
            arrayAppend(types, metadata.getColumnType(javaCast("int", i)));
        }

        var q = queryNew(arrayToList(columns));
        while (arguments.rs.next()) {
            queryAddRow(q);
            for (var c = 1; c <= columnCount; c++) {
                querySetCell(q, columns[c], cellValue(arguments.rs, c, types[c]));
            }
        }

        return q;
    }

    private any function cellValue(required any rs, required numeric columnIndex, required numeric jdbcTypeValue) {
        var index = javaCast("int", arguments.columnIndex);
        var type = val(arguments.jdbcTypeValue);
        var value = "";

        if (listFind("-1,1,12,2005", type)) {
            value = arguments.rs.getString(index);
        } else if (listFind("91,92,93", type)) {
            value = timestampToString(arguments.rs.getTimestamp(index));
        } else if (listFind("-5,4,5", type)) {
            value = arguments.rs.getInt(index);
        } else if (listFind("2,3,6,7,8", type)) {
            value = arguments.rs.getDouble(index);
        } else {
            value = arguments.rs.getObject(index);
        }

        if (arguments.rs.wasNull()) {
            return "";
        }

        return isNull(value) ? "" : value;
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

    private boolean function tableExistsWithConnection(required any conn, required string tableName) {
        var st = "";
        var rs = "";

        try {
            st = arguments.conn.createStatement();
            rs = st.executeQuery("SELECT COUNT(*) FROM " & safeIdentifier(arguments.tableName));
            return true;
        } catch (any ignored) {
            return false;
        } finally {
            closeQuietly(rs);
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

    private any function timestampValue(any value = "") {
        if (isDate(arguments.value)) {
            return createObject("java", "java.sql.Timestamp").valueOf(dateTimeFormat(arguments.value, "yyyy-mm-dd HH:nn:ss"));
        }

        var text = trim(toString(arguments.value));
        if (!len(text)) {
            text = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
        }
        text = replace(text, "T", " ", "one");
        text = replace(text, "Z", "", "one");
        if (find(".", text)) {
            text = listFirst(text, ".");
        }
        return createObject("java", "java.sql.Timestamp").valueOf(text);
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

    private string function safeIdentifier(required string value) {
        var cleaned = trim(arguments.value);
        if (!reFindNoCase("^[A-Za-z][A-Za-z0-9_]*$", cleaned)) {
            throw(type = "CAIROI.Derby.InvalidIdentifier", message = "Invalid database identifier.");
        }
        return cleaned;
    }

    private string function normalizeDerbyPath(required string path) {
        return replace(arguments.path, "\", "/", "all");
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

    private string function getParentDirectory(required string directoryPath) {
        var dirFile = createObject("java", "java.io.File").init(arguments.directoryPath);
        var parentPath = dirFile.getParent();
        if (isNull(parentPath)) {
            return ensureTrailingSlash(arguments.directoryPath);
        }
        parentPath = toString(parentPath);
        return ensureTrailingSlash(parentPath);
    }

    private any function readKey(any value = "", required string key, any fallback = "") {
        if (!isStruct(arguments.value)) {
            return arguments.fallback;
        }
        for (var candidate in structKeyArray(arguments.value)) {
            if (compareNoCase(candidate, arguments.key) == 0) {
                return arguments.value[candidate];
            }
        }
        return arguments.fallback;
    }

    private boolean function toBoolean(any value = "", boolean fallback = false) {
        if (isBoolean(arguments.value)) {
            return arguments.value;
        }
        if (!isSimpleValue(arguments.value)) {
            return arguments.fallback;
        }
        var text = lcase(trim(toString(arguments.value)));
        if (listFindNoCase("true,1,yes,on", text)) {
            return true;
        }
        if (listFindNoCase("false,0,no,off", text)) {
            return false;
        }
        return arguments.fallback;
    }

    private numeric function numericValue(any value = 0) {
        if (isNull(arguments.value)) {
            return 0;
        }
        try {
            return createObject("java", "java.lang.Double").parseDouble(trim(toString(arguments.value)));
        } catch (any ignored) {
            return val(arguments.value);
        }
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
