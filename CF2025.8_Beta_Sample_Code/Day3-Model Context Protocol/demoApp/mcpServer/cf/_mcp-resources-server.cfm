<cfscript>
    serverConfig = {
        serverInfo: {
            name:    "demo_cf_resources_server",
            version: "1.0.0"
        },
        capabilities: {
            tools:     false,
            prompts:   false,
            resources: true
        },
        tools:     [],
        prompts:   [],
        resources: getResources(),
        cfcCaching: false
    };

    mcpServer = McpServer(serverConfig);
    mcpServer.handleRequest();

    private array function getResources() {
        resText = application.demoResourceRegistry.resText;

        var fileInfo = getFileInfo(resText.filePath);
        var actualSize = fileInfo.size;

        return [
            {
                uri:         resText.uri,
                name:        "Application Logs",
                description: "Application log file containing runtime events and warnings.",
                mimeType:    "text/plain",
                size:        actualSize,
                readResourceHandler: function(readResourceReq) {
                    return fileRead(resText.filePath);
                }
            }
        ];
    }
</cfscript>
