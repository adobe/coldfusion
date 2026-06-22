component output="false" {
    public any function init(struct config = {}) {
        variables.pathSep = findNoCase("windows", server.OS.name) ? "\" : "/";
        variables.componentRoot = getDirectoryFromPath(getCurrentTemplatePath());
        variables.appRoot = structKeyExists(arguments.config, "appRoot")
            ? arguments.config.appRoot
            : getParentDirectory(variables.componentRoot);
        variables.dataRoot = ensureTrailingSlash(
            structKeyExists(arguments.config, "dataRoot")
                ? arguments.config.dataRoot
                : variables.appRoot & "data" & variables.pathSep
        );
        variables.dbParentPath = ensureTrailingSlash(
            structKeyExists(arguments.config, "dbParentPath")
                ? arguments.config.dbParentPath
                : variables.dataRoot & "derby" & variables.pathSep
        );
        variables.databasePath = structKeyExists(arguments.config, "databasePath")
            ? arguments.config.databasePath
            : variables.dbParentPath & "keystoredb";
        variables.masterKeyPath = structKeyExists(arguments.config, "masterKeyPath")
            ? arguments.config.masterKeyPath
            : variables.dataRoot & "keystore-master.key";
        variables.connectionUrl = "jdbc:derby:" & normalizeDerbyPath(variables.databasePath);
        return this;
    }

    public struct function bootstrap() {
        var conn = "";
        var createdSchema = false;

        ensureDirectory(variables.dataRoot);
        ensureDirectory(variables.dbParentPath);
        ensureMasterKey();

        try {
            conn = getConnection(true);
            if (!tableExists(conn, "api_keys")) {
                createSchema(conn);
                createdSchema = true;
            }

            return {
                ok: true,
                createdSchema: createdSchema,
                keyCount: getKeyCount(conn),
                databasePath: variables.databasePath,
                masterKeyPath: variables.masterKeyPath
            };
        } finally {
            closeQuietly(conn);
        }
    }

    public array function listKeys() {
        var conn = "";
        var ps = "";
        var rs = "";
        var keys = [];

        bootstrap();

        try {
            conn = getConnection();
            ps = conn.prepareStatement("
                SELECT key_id, display_name, fingerprint, value_hint, notes, created_at,
                    updated_at, last_retrieved_at, retrieval_count
                FROM api_keys
                ORDER BY lower(display_name), key_id
            ");
            rs = ps.executeQuery();

            while (rs.next()) {
                arrayAppend(keys, rowFromResultSet(rs));
            }
        } finally {
            closeQuietly(rs);
            closeQuietly(ps);
            closeQuietly(conn);
        }

        return keys;
    }

    public struct function saveKey(
        required string keyId,
        required string displayName,
        required string secretValue,
        string notes = ""
    ) {
        var normalizedId = normalizeKeyId(arguments.keyId);
        var cleanName = trim(arguments.displayName);
        var cleanSecret = cleanSecretValue(arguments.secretValue);
        var conn = "";
        var ps = "";
        var encrypted = {};
        var wasUpdate = false;

        if (!len(normalizedId)) {
            throw(type = "Keystore.Validation", message = "Key ID is required.");
        }
        if (!len(cleanName)) {
            throw(type = "Keystore.Validation", message = "Name is required.");
        }
        if (!len(cleanSecret)) {
            throw(type = "Keystore.Validation", message = "API key value is required.");
        }

        bootstrap();
        encrypted = encryptValue(cleanSecret);

        try {
            conn = getConnection();
            wasUpdate = keyExists(conn, normalizedId);

            if (wasUpdate) {
                ps = conn.prepareStatement("
                    UPDATE api_keys
                    SET display_name = ?, encrypted_value = ?, encryption_iv = ?, fingerprint = ?,
                        value_hint = ?, notes = ?, updated_at = CURRENT_TIMESTAMP
                    WHERE key_id = ?
                ");
                ps.setString(1, left(cleanName, 180));
                ps.setString(2, encrypted.encryptedValue);
                ps.setString(3, encrypted.iv);
                ps.setString(4, fingerprint(cleanSecret));
                ps.setString(5, maskedHint(cleanSecret));
                ps.setString(6, left(trim(arguments.notes), 4000));
                ps.setString(7, normalizedId);
            } else {
                ps = conn.prepareStatement("
                    INSERT INTO api_keys (
                        key_id, display_name, encrypted_value, encryption_iv, fingerprint,
                        value_hint, notes, created_at, updated_at, retrieval_count
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 0)
                ");
                ps.setString(1, normalizedId);
                ps.setString(2, left(cleanName, 180));
                ps.setString(3, encrypted.encryptedValue);
                ps.setString(4, encrypted.iv);
                ps.setString(5, fingerprint(cleanSecret));
                ps.setString(6, maskedHint(cleanSecret));
                ps.setString(7, left(trim(arguments.notes), 4000));
            }

            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
            closeQuietly(conn);
        }

        return {
            ok: true,
            saved: true,
            updated: wasUpdate,
            key: getPublicKey(normalizedId),
            message: wasUpdate ? "Key updated." : "Key added."
        };
    }

    public struct function getPublicKey(required string keyId) {
        var conn = "";
        var keyRecord = {};

        bootstrap();

        try {
            conn = getConnection();
            keyRecord = findKeyRecord(conn, normalizeKeyId(arguments.keyId), false);
        } finally {
            closeQuietly(conn);
        }

        return keyRecord;
    }

    public struct function getKey(required string keyId, boolean markRetrieved = true) {
        var conn = "";
        var keyRecord = {};

        bootstrap();

        try {
            conn = getConnection();
            keyRecord = findKeyRecord(conn, normalizeKeyId(arguments.keyId), true);

            if (structIsEmpty(keyRecord)) {
                return { ok: false, message: "Key not found." };
            }

            keyRecord.value = decryptValue(keyRecord.encryptedValue, keyRecord.iv);
            structDelete(keyRecord, "encryptedValue");
            structDelete(keyRecord, "iv");
            keyRecord.ok = true;

            if (arguments.markRetrieved) {
                recordRetrieval(conn, keyRecord.keyId);
            }

            return keyRecord;
        } finally {
            closeQuietly(conn);
        }
    }

    public boolean function deleteKey(required string keyId) {
        var normalizedId = normalizeKeyId(arguments.keyId);
        var conn = "";
        var ps = "";
        var deleted = 0;

        if (!len(normalizedId)) {
            return false;
        }

        bootstrap();

        try {
            conn = getConnection();
            ps = conn.prepareStatement("DELETE FROM api_keys WHERE key_id = ?");
            ps.setString(1, normalizedId);
            deleted = ps.executeUpdate();
        } finally {
            closeQuietly(ps);
            closeQuietly(conn);
        }

        return deleted > 0;
    }

    public string function normalizeKeyId(required string keyId) {
        var normalized = lcase(trim(arguments.keyId));
        normalized = reReplace(normalized, "[^a-z0-9_\-.]+", "-", "all");
        normalized = reReplace(normalized, "-{2,}", "-", "all");
        normalized = reReplace(normalized, "^-+|-+$", "", "all");
        return left(normalized, 80);
    }

    private struct function findKeyRecord(required any conn, required string keyId, boolean includeSecret = false) {
        var ps = "";
        var rs = "";
        var sql = "
            SELECT key_id, display_name, fingerprint, value_hint, notes, created_at,
                updated_at, last_retrieved_at, retrieval_count
        ";

        if (arguments.includeSecret) {
            sql &= ", encrypted_value, encryption_iv";
        }

        sql &= " FROM api_keys WHERE key_id = ?";

        try {
            ps = arguments.conn.prepareStatement(sql);
            ps.setString(1, arguments.keyId);
            rs = ps.executeQuery();

            if (!rs.next()) {
                return {};
            }

            return rowFromResultSet(rs, arguments.includeSecret);
        } finally {
            closeQuietly(rs);
            closeQuietly(ps);
        }
    }

    private struct function rowFromResultSet(required any rs, boolean includeSecret = false) {
        var row = {
            keyId: arguments.rs.getString("key_id"),
            name: arguments.rs.getString("display_name"),
            fingerprint: arguments.rs.getString("fingerprint"),
            hint: arguments.rs.getString("value_hint"),
            notes: safeString(arguments.rs.getString("notes")),
            createdAt: timestampToString(arguments.rs.getTimestamp("created_at")),
            updatedAt: timestampToString(arguments.rs.getTimestamp("updated_at")),
            lastRetrievedAt: timestampToString(arguments.rs.getTimestamp("last_retrieved_at")),
            retrievalCount: arguments.rs.getInt("retrieval_count")
        };

        if (arguments.includeSecret) {
            row.encryptedValue = arguments.rs.getString("encrypted_value");
            row.iv = arguments.rs.getString("encryption_iv");
        }

        return row;
    }

    private boolean function tableExists(required any conn, required string tableName) {
        var st = "";
        var rs = "";

        try {
            st = arguments.conn.createStatement();
            rs = st.executeQuery("SELECT COUNT(*) FROM " & arguments.tableName);
            return true;
        } catch (any tableError) {
            return false;
        } finally {
            closeQuietly(rs);
            closeQuietly(st);
        }
    }

    private void function createSchema(required any conn) {
        executeUpdate(arguments.conn, "
            CREATE TABLE api_keys (
                key_id VARCHAR(80) NOT NULL PRIMARY KEY,
                display_name VARCHAR(180) NOT NULL,
                encrypted_value CLOB NOT NULL,
                encryption_iv VARCHAR(120) NOT NULL,
                fingerprint VARCHAR(128) NOT NULL,
                value_hint VARCHAR(120) NOT NULL,
                notes CLOB,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                last_retrieved_at TIMESTAMP,
                retrieval_count INT NOT NULL DEFAULT 0
            )
        ");
        executeUpdate(arguments.conn, "CREATE INDEX idx_api_keys_display_name ON api_keys (display_name)");
    }

    private numeric function getKeyCount(required any conn) {
        var st = "";
        var rs = "";

        try {
            st = arguments.conn.createStatement();
            rs = st.executeQuery("SELECT COUNT(*) FROM api_keys");
            rs.next();
            return rs.getInt(1);
        } finally {
            closeQuietly(rs);
            closeQuietly(st);
        }
    }

    private boolean function keyExists(required any conn, required string keyId) {
        return !structIsEmpty(findKeyRecord(arguments.conn, arguments.keyId, false));
    }

    private void function recordRetrieval(required any conn, required string keyId) {
        var ps = "";
        try {
            ps = arguments.conn.prepareStatement("
                UPDATE api_keys
                SET last_retrieved_at = CURRENT_TIMESTAMP,
                    retrieval_count = retrieval_count + 1
                WHERE key_id = ?
            ");
            ps.setString(1, arguments.keyId);
            ps.executeUpdate();
        } finally {
            closeQuietly(ps);
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
            // Modern JDBC drivers can auto-register; DriverManager will raise a useful error if not.
        }
    }

    private void function ensureMasterKey() {
        var keyValue = "";

        if (fileExists(variables.masterKeyPath)) {
            keyValue = trim(fileRead(variables.masterKeyPath, "utf-8"));
        }

        if (!len(keyValue)) {
            keyValue = generateAesKey();
            fileWrite(variables.masterKeyPath, keyValue, "utf-8");
        }
    }

    private string function generateAesKey() {
        var keyGenerator = createObject("java", "javax.crypto.KeyGenerator").getInstance("AES");
        keyGenerator.init(javaCast("int", 128));
        return base64EncodeBytes(keyGenerator.generateKey().getEncoded());
    }

    private struct function encryptValue(required string plainValue) {
        var ivBytes = createObject("java", "java.security.SecureRandom").init().generateSeed(12);
        var cipher = createObject("java", "javax.crypto.Cipher").getInstance("AES/GCM/NoPadding");
        var keySpec = createObject("java", "javax.crypto.spec.SecretKeySpec").init(masterKeyBytes(), "AES");
        var gcmSpec = createObject("java", "javax.crypto.spec.GCMParameterSpec").init(javaCast("int", 128), ivBytes);
        var plainBytes = createObject("java", "java.lang.String").init(arguments.plainValue).getBytes("UTF-8");

        cipher.init(javaCast("int", 1), keySpec, gcmSpec);

        return {
            encryptedValue: base64EncodeBytes(cipher.doFinal(plainBytes)),
            iv: base64EncodeBytes(ivBytes)
        };
    }

    private string function decryptValue(required string encryptedValue, required string iv) {
        var cipher = createObject("java", "javax.crypto.Cipher").getInstance("AES/GCM/NoPadding");
        var keySpec = createObject("java", "javax.crypto.spec.SecretKeySpec").init(masterKeyBytes(), "AES");
        var gcmSpec = createObject("java", "javax.crypto.spec.GCMParameterSpec").init(javaCast("int", 128), base64DecodeBytes(arguments.iv));
        var plainBytes = "";

        cipher.init(javaCast("int", 2), keySpec, gcmSpec);
        plainBytes = cipher.doFinal(base64DecodeBytes(arguments.encryptedValue));
        return createObject("java", "java.lang.String").init(plainBytes, "UTF-8").toString();
    }

    private any function masterKeyBytes() {
        return base64DecodeBytes(trim(fileRead(variables.masterKeyPath, "utf-8")));
    }

    private string function base64EncodeBytes(required any bytes) {
        return createObject("java", "java.util.Base64").getEncoder().encodeToString(arguments.bytes);
    }

    private any function base64DecodeBytes(required string value) {
        return createObject("java", "java.util.Base64").getDecoder().decode(arguments.value);
    }

    private string function cleanSecretValue(required string secretValue) {
        var cleaned = trim(replace(arguments.secretValue, chr(65279), "", "all"));

        if (
            len(cleaned) >= 2 &&
            (
                (left(cleaned, 1) == """" && right(cleaned, 1) == """") ||
                (left(cleaned, 1) == "'" && right(cleaned, 1) == "'")
            )
        ) {
            cleaned = mid(cleaned, 2, len(cleaned) - 2);
        }

        return trim(cleaned);
    }

    private string function maskedHint(required string secretValue) {
        var cleaned = cleanSecretValue(arguments.secretValue);
        var suffixLength = min(4, max(len(cleaned) - 4, 0));
        var suffix = suffixLength > 0 ? right(cleaned, suffixLength) : "";
        return repeatString("*", max(8, min(len(cleaned), 16))) & suffix & " (" & len(cleaned) & " chars)";
    }

    private string function fingerprint(required string secretValue) {
        return lcase(hash(cleanSecretValue(arguments.secretValue), "SHA-256"));
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
