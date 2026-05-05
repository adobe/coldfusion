<cfsetting requestTimeOut="30" showDebugOutput="false">
<cfcontent type="application/json">
<cfscript>
    param name="url.action"  default="addAndList";
    param name="url.rootDir" default="";

    serverUrl = application.SERVERS.TS_ROOTS
    result    = {}
    mcpClient = ""

    // Default to the APIP knowledge-base dir.
    // expandPath is relative to this file (demoApp/api/), so ../../ reaches MCP root.
    if (!len(url.rootDir)) {
        url.rootDir = expandPath("../../APIP/data/knowledge-base")
    }

    rootUri  = "file://" & url.rootDir
    rootName = listLast(url.rootDir, "/\")

    try {
        mcpClient = MCPClient({
            transport:  { type: "HTTP", URL: serverUrl },
            clientInfo: { name: "demo-roots-client", version: "1.0.0" },
            capabilities: { roots: true },
            initializationTimeout: 15,
            requestTimeout: 15
        })

        // Register the root with the client so the server can fetch it via roots/list.
        // addRoot() sends a roots/list_changed notification; the server re-fetches roots
        // and populates allowedDirsBySession before we call list_directory.
        mcpClient.addRoot(rootUri, rootName)
        rootsResp = mcpClient.listRoots()

        // list_directory validates the path against allowedDirsBySession on the server.
        // Arguments must use quoted keys — unquoted CF struct keys are uppercased ("PATH")
        // and fail Zod's lowercase "path" validation with "received undefined".
        dirResp = mcpClient.callTool({
            "name":      "list_directory",
            "arguments": { "path": url.rootDir }
        })

        mcpClient.close()

        result = {
            success:   true,
            serverUrl: serverUrl,
            rootUri:   rootUri,
            rootName:  rootName,
            roots:     rootsResp,
            directory: dirResp
        }
    }
    catch (any e) {
        result = { success: false, error: e.message }
        if (isObject(mcpClient)) mcpClient.close()
    }
    writeOutput(serializeJSON(result))
</cfscript>
