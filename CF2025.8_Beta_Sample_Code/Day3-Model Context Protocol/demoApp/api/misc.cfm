<cfsetting requestTimeOut="30" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.action" default="basicAuth";
    param name="url.username" default="mcp-client-user";
    param name="url.password" default="s3cr3tP@$$";

    baseUrl = "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##len(trim(CGI.CONTEXT_PATH)) ? '/' & CGI.CONTEXT_PATH : ''#"

    AUTH_SERVER_URL    = baseUrl & "/cfsuite/AI/MCP/mcpServers/cf/basicAuth/_mcp-cfserver-basicauth.cfm"
    CORS_SERVER_URL    = baseUrl & "/cfsuite/AI/MCP/mcpServers/cf/cors/_mcp-svr-cors-enabled.cfm"
    MAXSIZE_SERVER_URL = baseUrl & "/cfsuite/AI/MCP/mcpServers/cf/maxReqSize/_mcp-cfserver-maxreqsize.cfm"

    result = {}
    mcpClient = ""

    try {
        // ── Basic Auth: valid credentials ──
        if (url.action == "basicAuth") {
            credentials  = toBase64(url.username & ":" & url.password)
            authHeader   = "Basic " & credentials

            mcpClient = MCPClient({
                transport: {
                    type:    "HTTP",
                    URL:     AUTH_SERVER_URL,
                    headers: { "Authorization": authHeader }
                },
                clientInfo: { name: "demo-auth-client", version: "1.0.0" },
                initializationTimeout: 15,
                requestTimeout:        15
            })

            toolsResp = mcpClient.listTools()
            toolResp  = mcpClient.callTool({
                name:      "echoMessage",
                arguments: { messageText: "Hello from basicAuth demo!" }
            })
            mcpClient.close()

            result = {
                success:       true,
                action:        "basicAuth",
                serverUrl:     AUTH_SERVER_URL,
                username:      url.username,
                authHeader:    authHeader,
                toolCount:     arrayLen(toolsResp.tools),
                toolResponse:  deserializeJSON(toolResp.content[1].text)
            }
        }

        // ── Basic Auth: invalid credentials ──
        else if (url.action == "basicAuthInvalid") {
            try {
                credentials = toBase64("wrong-user:wrong-pass")
                mcpClient = MCPClient({
                    transport: {
                        type:    "HTTP",
                        URL:     AUTH_SERVER_URL,
                        headers: { "Authorization": "Basic " & credentials }
                    },
                    clientInfo: { name: "demo-auth-bad-client", version: "1.0.0" },
                    initializationTimeout: 15,
                    requestTimeout:        15
                })
                mcpClient.listTools()
                mcpClient.close()
                result = { success: false, action: "basicAuthInvalid", error: "No exception thrown - unexpected" }
            } catch (any e) {
                result = {
                    success:      true,
                    action:       "basicAuthInvalid",
                    serverUrl:    AUTH_SERVER_URL,
                    rejected:     true,
                    errorType:    e.type,
                    errorMessage: e.message
                }
            }
        }

        // ── CORS ──
        else if (url.action == "cors") {
            mcpClient = MCPClient({
                transport: { type: "HTTP", URL: CORS_SERVER_URL },
                clientInfo: { name: "demo-cors-client", version: "1.0.0" },
                initializationTimeout: 15,
                requestTimeout:        15
            })
            toolsResp = mcpClient.listTools()
            mcpClient.close()

            // Preflight OPTIONS to expose CORS headers
            cfhttp(url=CORS_SERVER_URL, method="OPTIONS", result="preflightResp") {
                cfhttpparam(type="header", name="Origin", value="http://localhost:#CGI.SERVER_PORT#")
                cfhttpparam(type="header", name="Access-Control-Request-Method", value="POST")
                cfhttpparam(type="header", name="Access-Control-Request-Headers", value="Content-Type")
            }

            corsHeaders = {}
            for (h in preflightResp.responseHeader) {
                if (lcase(h) contains "access-control") {
                    corsHeaders[h] = preflightResp.responseHeader[h]
                }
            }

            result = {
                success:        true,
                action:         "cors",
                serverUrl:      CORS_SERVER_URL,
                toolCount:      arrayLen(toolsResp.tools),
                preflightStatus: preflightResp.statusCode,
                corsHeaders:    corsHeaders
            }
        }

        // ── maxRequestBodySize: small payload (within 512-byte limit) ──
        else if (url.action == "maxBodySmall") {
            mcpClient = MCPClient({
                transport: { type: "HTTP", URL: MAXSIZE_SERVER_URL },
                clientInfo: { name: "demo-maxsize-client", version: "1.0.0" },
                initializationTimeout: 15,
                requestTimeout:        15
            })
            toolResp = mcpClient.callTool({
                name:      "echoMessage",
                arguments: { messageText: "Hello" }
            })
            mcpClient.close()

            result = {
                success:      true,
                action:       "maxBodySmall",
                serverUrl:    MAXSIZE_SERVER_URL,
                maxBodySize:  "512 bytes",
                payloadSize:  "5 bytes (Hello)",
                withinLimit:  true,
                toolResponse: deserializeJSON(toolResp.content[1].text)
            }
        }

        // ── maxRequestBodySize: large payload (exceeds 512-byte limit) ──
        else if (url.action == "maxBodyLarge") {
            try {
                mcpClient = MCPClient({
                    transport: { type: "HTTP", URL: MAXSIZE_SERVER_URL },
                    clientInfo: { name: "demo-maxsize-client-large", version: "1.0.0" },
                    initializationTimeout: 15,
                    requestTimeout:        15
                })
                largeMsg = repeatString("A", 400)
                toolResp = mcpClient.callTool({
                    name:      "echoMessage",
                    arguments: { messageText: largeMsg }
                })
                mcpClient.close()
                result = { success: false, action: "maxBodyLarge", error: "No rejection - expected size limit error" }
            } catch (any e) {
                result = {
                    success:      true,
                    action:       "maxBodyLarge",
                    serverUrl:    MAXSIZE_SERVER_URL,
                    maxBodySize:  "512 bytes",
                    payloadSize:  "400+ bytes",
                    rejected:     true,
                    errorType:    e.type,
                    errorMessage: e.message
                }
            }
        }

        else {
            result = { success: false, error: "Unknown action: " & url.action }
        }
    }
    catch (any e) {
        result = { success: false, error: e.message, action: url.action }
        if (isObject(mcpClient)) try { mcpClient.close() } catch (any ignore) {}
    }

    writeOutput(serializeJSON(result))
</cfscript>
