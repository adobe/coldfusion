component output=false {
    variables.collectorUrl = "";
    variables.apiKey = "";
    variables.failSilently = true;
    variables.timeout = 2;
    variables.debug = false;
    variables.asyncMode = true;
    variables.durable = true;
    variables.queueDir = "";
    variables.batchSize = 25;
    variables.maxAttempts = 20;
    variables.retryBaseSeconds = 5;
    variables.retryMaxSeconds = 300;
    variables.maxQueueFiles = 2000;

    public TelemetryClient function init(
        required string collectorUrl,
        string apiKey = "",
        boolean failSilently = true,
        numeric timeout = 2,
        boolean debug = false,
        boolean asyncMode = true,
        boolean durable = true,
        string queueDir = "",
        numeric batchSize = 25,
        numeric maxAttempts = 20,
        numeric retryBaseSeconds = 5,
        numeric retryMaxSeconds = 300,
        numeric maxQueueFiles = 2000
    ) {
        variables.collectorUrl = arguments.collectorUrl;
        variables.apiKey = arguments.apiKey;
        variables.failSilently = arguments.failSilently;
        variables.timeout = arguments.timeout;
        variables.debug = arguments.debug;
        variables.asyncMode = arguments.asyncMode;
        variables.durable = arguments.durable;
        variables.queueDir = len(trim(arguments.queueDir)) ? normalizeDirectory(arguments.queueDir) : buildDefaultQueueDir();
        variables.batchSize = max(1, val(arguments.batchSize));
        variables.maxAttempts = max(1, val(arguments.maxAttempts));
        variables.retryBaseSeconds = max(1, val(arguments.retryBaseSeconds));
        variables.retryMaxSeconds = max(1, val(arguments.retryMaxSeconds));
        variables.maxQueueFiles = max(25, val(arguments.maxQueueFiles));
        return this;
    }

    public struct function sendTrace(required struct traceStruct, array spansArray = []) {
        return dispatchPayload({ trace: arguments.traceStruct, spans: arguments.spansArray });
    }

    public struct function sendSpan(required struct spanStruct) {
        return dispatchPayload({ span: arguments.spanStruct });
    }

    public struct function flushQueue(numeric maxItems = 0) {
        if (!len(trim(variables.collectorUrl))) {
            return failResult("collectorUrl is not configured.");
        }

        try {
            ensureQueueDir();
            var result = {
                ok: true,
                sent: 0,
                failed: 0,
                skipped: 0,
                deadLettered: 0,
                queueDepth: 0,
                queueDir: variables.queueDir
            };
            var lockName = "cairoiTelemetryQueue_" & left(lcase(hash(variables.queueDir, "SHA-256", "UTF-8")), 48);

            lock name=lockName type="exclusive" timeout=1 {
                result = processQueue(arguments.maxItems);
            }

            return result;
        } catch (any e) {
            logWarning("Telemetry queue flush skipped: " & e.message);
            return failResult(e.message);
        }
    }

    public struct function postNow(required struct payload) {
        return postJsonNow(arguments.payload);
    }

    public struct function getQueueStatus() {
        try {
            ensureQueueDir();
            return {
                ok: true,
                queueDir: variables.queueDir,
                queueDepth: arrayLen(getQueueFiles()),
                deadLetterDepth: directoryExists(deadLetterDir()) ? arrayLen(directoryList(deadLetterDir(), false, "path", "*.json")) : 0
            };
        } catch (any e) {
            return failResult(e.message);
        }
    }

    private struct function dispatchPayload(required struct payload) {
        if (!len(trim(variables.collectorUrl))) {
            return failResult("collectorUrl is not configured.");
        }

        if (variables.durable) {
            var enqueueResult = enqueuePayload(arguments.payload);
            if (!enqueueResult.ok) {
                if (!variables.failSilently) {
                    throw(message = enqueueResult.message);
                }
                return enqueueResult;
            }

            if (variables.asyncMode) {
                startAsyncFlush();
                return {
                    ok: true,
                    queued: true,
                    async: true,
                    queueId: enqueueResult.queueId,
                    queueDepth: enqueueResult.queueDepth
                };
            }

            return flushQueue();
        }

        if (variables.asyncMode) {
            startAsyncPost(arguments.payload);
            return { ok: true, queued: false, async: true };
        }

        return postJsonNow(arguments.payload);
    }

    private struct function enqueuePayload(required struct payload) {
        try {
            ensureQueueDir();

            var queueDepth = arrayLen(getQueueFiles());
            if (queueDepth >= variables.maxQueueFiles) {
                return failResult("Telemetry queue is full.");
            }

            var queueId = "q_" & dateTimeFormat(now(), "yyyymmddHHnnsslll") & "_" & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all"));
            var finalPath = variables.queueDir & pathSep() & queueId & ".json";
            var tempPath = finalPath & ".tmp";
            var envelope = {
                version: 1,
                queueId: queueId,
                createdAt: formatDate(now()),
                attempts: 0,
                nextAttemptAt: "",
                payload: arguments.payload
            };

            fileWrite(tempPath, serializeJSON(envelope), "utf-8");
            fileMove(tempPath, finalPath);

            return {
                ok: true,
                queued: true,
                queueId: queueId,
                queueDepth: queueDepth + 1
            };
        } catch (any e) {
            logWarning("Telemetry enqueue failed: " & e.message);
            return failResult(e.message);
        }
    }

    private void function startAsyncFlush() {
        try {
            var threadName = "cairoiFlush_" & left(lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")), 24);
            var clientConfig = workerConfig();

            cfthread(action = "run", name = threadName, clientConfig = clientConfig) {
                try {
                    var worker = "";
                    try {
                        worker = createObject("component", "cairoiLive.sdk.TelemetryClient").init(
                            collectorUrl = attributes.clientConfig.collectorUrl,
                            apiKey = attributes.clientConfig.apiKey,
                            failSilently = true,
                            timeout = attributes.clientConfig.timeout,
                            debug = attributes.clientConfig.debug,
                            asyncMode = false,
                            durable = true,
                            queueDir = attributes.clientConfig.queueDir,
                            batchSize = attributes.clientConfig.batchSize,
                            maxAttempts = attributes.clientConfig.maxAttempts,
                            retryBaseSeconds = attributes.clientConfig.retryBaseSeconds,
                            retryMaxSeconds = attributes.clientConfig.retryMaxSeconds,
                            maxQueueFiles = attributes.clientConfig.maxQueueFiles
                        );
                    } catch (any aliasError) {
                        worker = createObject("component", "cairoi.sdk.TelemetryClient").init(
                            collectorUrl = attributes.clientConfig.collectorUrl,
                            apiKey = attributes.clientConfig.apiKey,
                            failSilently = true,
                            timeout = attributes.clientConfig.timeout,
                            debug = attributes.clientConfig.debug,
                            asyncMode = false,
                            durable = true,
                            queueDir = attributes.clientConfig.queueDir,
                            batchSize = attributes.clientConfig.batchSize,
                            maxAttempts = attributes.clientConfig.maxAttempts,
                            retryBaseSeconds = attributes.clientConfig.retryBaseSeconds,
                            retryMaxSeconds = attributes.clientConfig.retryMaxSeconds,
                            maxQueueFiles = attributes.clientConfig.maxQueueFiles
                        );
                    }
                    worker.flushQueue();
                } catch (any ignored) {
                }
            }
        } catch (any e) {
            logWarning("Telemetry async flush start failed: " & e.message);
        }
    }

    private void function startAsyncPost(required struct payload) {
        try {
            var threadName = "cairoiPost_" & left(lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")), 25);
            var clientConfig = workerConfig();
            var payloadCopy = duplicate(arguments.payload);

            cfthread(action = "run", name = threadName, clientConfig = clientConfig, telemetryPayload = payloadCopy) {
                try {
                    var worker = "";
                    try {
                        worker = createObject("component", "cairoiLive.sdk.TelemetryClient").init(
                            collectorUrl = attributes.clientConfig.collectorUrl,
                            apiKey = attributes.clientConfig.apiKey,
                            failSilently = true,
                            timeout = attributes.clientConfig.timeout,
                            debug = attributes.clientConfig.debug,
                            asyncMode = false,
                            durable = false,
                            queueDir = attributes.clientConfig.queueDir
                        );
                    } catch (any aliasError) {
                        worker = createObject("component", "cairoi.sdk.TelemetryClient").init(
                            collectorUrl = attributes.clientConfig.collectorUrl,
                            apiKey = attributes.clientConfig.apiKey,
                            failSilently = true,
                            timeout = attributes.clientConfig.timeout,
                            debug = attributes.clientConfig.debug,
                            asyncMode = false,
                            durable = false,
                            queueDir = attributes.clientConfig.queueDir
                        );
                    }
                    worker.postNow(attributes.telemetryPayload);
                } catch (any ignored) {
                }
            }
        } catch (any e) {
            logWarning("Telemetry async post start failed: " & e.message);
        }
    }

    private struct function processQueue(numeric maxItems = 0) {
        var files = getQueueFiles();
        var limit = arguments.maxItems > 0 ? arguments.maxItems : variables.batchSize;
        var result = {
            ok: true,
            sent: 0,
            failed: 0,
            skipped: 0,
            deadLettered: 0,
            queueDepth: arrayLen(files),
            queueDir: variables.queueDir
        };

        for (var filePath in files) {
            if ((result.sent + result.failed + result.deadLettered) >= limit) {
                break;
            }

            var readResult = readEnvelope(filePath);
            if (!readResult.ok) {
                moveToDeadLetter(filePath, { message: readResult.message }, "invalid_queue_file");
                result.deadLettered++;
                continue;
            }

            var item = readResult.envelope;
            if (!isDue(item)) {
                result.skipped++;
                continue;
            }

            var postResult = postJsonNow(readKey(item, "payload", {}));
            if (postResult.ok) {
                fileDelete(filePath);
                result.sent++;
                continue;
            }

            result.failed++;
            updateRetry(filePath, item, postResult);

            if (!postResult.statusCode || postResult.statusCode >= 500) {
                break;
            }
        }

        result.queueDepth = arrayLen(getQueueFiles());
        return result;
    }

    private struct function readEnvelope(required string filePath) {
        try {
            var content = fileRead(arguments.filePath, "utf-8");
            if (!isJSON(content)) {
                return failResult("Queue file is not JSON.");
            }

            var envelope = deserializeJSON(content);
            if (!isStruct(envelope) || !structKeyExists(envelope, "payload") || !isStruct(envelope.payload)) {
                return failResult("Queue file does not contain a payload struct.");
            }

            return { ok: true, envelope: envelope };
        } catch (any e) {
            return failResult(e.message);
        }
    }

    private boolean function isDue(required struct envelope) {
        var text = cleanString(readKey(arguments.envelope, "nextAttemptAt", ""), 40);
        if (!len(text)) {
            return true;
        }

        try {
            return dateCompare(parseDateTime(text), now()) <= 0;
        } catch (any ignored) {
            return true;
        }
    }

    private void function updateRetry(required string filePath, required struct envelope, required struct postResult) {
        try {
            var attempts = val(readKey(arguments.envelope, "attempts", 0)) + 1;
            arguments.envelope.attempts = attempts;
            arguments.envelope.lastAttemptAt = formatDate(now());
            arguments.envelope.lastStatusCode = val(readKey(arguments.postResult, "statusCode", 0));
            arguments.envelope.lastError = cleanString(readKey(arguments.postResult, "message", "Telemetry post failed."), 500);

            if (attempts >= variables.maxAttempts) {
                moveToDeadLetter(arguments.filePath, arguments.envelope, "max_attempts");
                return;
            }

            arguments.envelope.nextAttemptAt = formatDate(dateAdd("s", retryDelaySeconds(attempts), now()));
            fileWrite(arguments.filePath, serializeJSON(arguments.envelope), "utf-8");
        } catch (any e) {
            logWarning("Telemetry retry update failed: " & e.message);
        }
    }

    private numeric function retryDelaySeconds(required numeric attempts) {
        var exponent = min(6, max(0, arguments.attempts - 1));
        var delay = variables.retryBaseSeconds * (2 ^ exponent);
        return min(variables.retryMaxSeconds, delay);
    }

    private void function moveToDeadLetter(required string filePath, required struct envelope, required string reason) {
        try {
            ensureDirectory(deadLetterDir());
            arguments.envelope.deadLetterReason = arguments.reason;
            arguments.envelope.deadLetteredAt = formatDate(now());

            var targetPath = deadLetterDir() & pathSep() & getFileFromPath(arguments.filePath);
            if (fileExists(targetPath)) {
                targetPath = deadLetterDir() & pathSep() & lcase(reReplace(createUUID(), "[^A-Za-z0-9]", "", "all")) & ".json";
            }

            fileWrite(targetPath, serializeJSON(arguments.envelope), "utf-8");
            fileDelete(arguments.filePath);
        } catch (any e) {
            logWarning("Telemetry dead-letter move failed: " & e.message);
        }
    }

    private struct function postJsonNow(required struct payload) {
        if (!len(trim(variables.collectorUrl))) {
            return failResult("collectorUrl is not configured.");
        }

        try {
            var body = serializeJSON(arguments.payload);
            cfhttp(method = "POST", url = variables.collectorUrl, timeout = variables.timeout, result = "httpResult") {
                cfhttpparam(type = "header", name = "Content-Type", value = "application/json");
                cfhttpparam(type = "header", name = "X-CAIROI-API-Key", value = variables.apiKey);
                cfhttpparam(type = "body", value = body);
            }

            var statusCode = structKeyExists(httpResult, "statusCode") ? val(httpResult.statusCode) : 0;
            var responseBody = structKeyExists(httpResult, "fileContent") ? httpResult.fileContent : "";
            var responsePayload = isJSON(responseBody) ? deserializeJSON(responseBody) : { raw: responseBody };
            var ok = statusCode >= 200 && statusCode < 300;

            if (!ok) {
                logWarning("Telemetry post returned HTTP " & statusCode & ".");
            }

            return {
                ok: ok,
                statusCode: statusCode,
                response: responsePayload,
                message: ok ? "" : cleanString(responseBody, 500)
            };
        } catch (any e) {
            logWarning("Telemetry post failed: " & e.message);
            if (variables.failSilently) {
                return failResult(e.message);
            }
            rethrow;
        }
    }

    private struct function workerConfig() {
        return {
            collectorUrl: variables.collectorUrl,
            apiKey: variables.apiKey,
            timeout: variables.timeout,
            debug: variables.debug,
            queueDir: variables.queueDir,
            batchSize: variables.batchSize,
            maxAttempts: variables.maxAttempts,
            retryBaseSeconds: variables.retryBaseSeconds,
            retryMaxSeconds: variables.retryMaxSeconds,
            maxQueueFiles: variables.maxQueueFiles
        };
    }

    private string function buildDefaultQueueDir() {
        var namespace = left(lcase(hash(variables.collectorUrl & ":" & variables.apiKey, "SHA-256", "UTF-8")), 16);
        return normalizeDirectory(getTempDirectory() & pathSep() & "cairoi-telemetry-" & namespace);
    }

    private void function ensureQueueDir() {
        ensureDirectory(variables.queueDir);
    }

    private void function ensureDirectory(required string directoryPath) {
        if (!directoryExists(arguments.directoryPath)) {
            directoryCreate(arguments.directoryPath, true, true);
        }
    }

    private array function getQueueFiles() {
        if (!directoryExists(variables.queueDir)) {
            return [];
        }

        var files = directoryList(variables.queueDir, false, "path", "*.json");
        arraySort(files, "textnocase");
        return files;
    }

    private string function deadLetterDir() {
        return variables.queueDir & pathSep() & "dead-letter";
    }

    private string function normalizeDirectory(required string directoryPath) {
        var cleaned = trim(arguments.directoryPath);
        if (right(cleaned, 1) == "/" || right(cleaned, 1) == "\") {
            return left(cleaned, len(cleaned) - 1);
        }
        return cleaned;
    }

    private string function pathSep() {
        return findNoCase("windows", server.OS.name) ? "\" : "/";
    }

    private string function formatDate(required date value) {
        return dateTimeFormat(arguments.value, "yyyy-mm-dd HH:nn:ss");
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

    private string function cleanString(any value = "", numeric maxLength = 4000) {
        if (isNull(arguments.value)) {
            return "";
        }
        var text = isSimpleValue(arguments.value) ? toString(arguments.value) : serializeJSON(arguments.value);
        text = reReplace(text, "(?i)(bearer\s+)[A-Za-z0-9._\-]+", "\1[redacted]", "all");
        text = reReplace(text, "(?i)(api[_-]?key\s*[:=]\s*)[A-Za-z0-9._\-]+", "\1[redacted]", "all");
        text = reReplace(text, "(?i)(password\s*[:=]\s*)\S+", "\1[redacted]", "all");
        return left(text, arguments.maxLength);
    }

    private void function logWarning(required string message) {
        if (variables.debug) {
            writeLog(file = "cairoi", type = "warning", text = cleanString(arguments.message, 1000));
        }
    }

    private struct function failResult(required string message) {
        return {
            ok: false,
            statusCode: 0,
            message: arguments.message
        };
    }
}
