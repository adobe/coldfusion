<cfscript>
    cfheader(name="Content-Type",  value="application/json");
    cfheader(name="Cache-Control", value="no-cache, no-store, must-revalidate");
    cfheader(name="Access-Control-Allow-Origin", value="*");

    logPath = "/Applications/ColdFusion2025/cfusion/logs/demo-stream2.log";
    buffer     = "";
    isDone     = false;
    tokenCount = 0;
    error      = "";
    streamId = "";
    try { streamId = application.streamId; } catch (any e) {}

    if (len(streamId) && fileExists(logPath)) {
        content = fileRead(logPath);

        // Find lines after our START marker
        startPos = find("START:" & streamId, content);
        if (startPos > 0) {
            relevantContent = mid(content, startPos, len(content));

            matcher = createObject("java", "java.util.regex.Pattern")
                .compile('"[^"]*","[^"]*","[^"]*","[^"]*","[^"]*","(.*)"')
                .matcher(relevantContent);

            while (matcher.find()) {
                msg = matcher.group(1);
                if (left(msg, 6) == "CHUNK:") {
                    buffer &= mid(msg, 7, len(msg));
                } else if (left(msg, 5) == "DONE:") {
                    isDone = true;
                    tokenCount = val(mid(msg, 6, len(msg)));
                } else if (left(msg, 12) == "STREAMERROR:") {
                    isDone = true;
                    error = mid(msg, 13, len(msg));
                }
            }
        }
    }

    // If no DONE/ERROR after 30s, the LLM call likely failed silently
    // (onError callback broken due to CF scope bug on ForkJoinPool threads)
    streamStart = 0;
    try { streamStart = application.streamStart; } catch (any e) {}
    if (!isDone && streamStart > 0 && (getTickCount() - streamStart) > 30000) {
        isDone = true;
        if (!len(buffer)) {
            error = "Streaming timed out — the LLM request may have failed. Check that the API key is valid for the selected provider.";
        }
    }

    writeOutput(serializeJSON({
        buffer:     buffer,
        done:       isDone,
        tokenCount: tokenCount,
        error:      error
    }));
</cfscript>
