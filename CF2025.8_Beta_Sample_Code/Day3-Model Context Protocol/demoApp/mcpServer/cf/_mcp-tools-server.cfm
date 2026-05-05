<cfscript>
    serverConfig = {
        serverInfo: {
            name:    "webdemo_cfserver_tools",
            version: "1.0.0"
        },
        capabilities: {
            tools:     true,
            resources: false
        },
        tools: [
            { cfc: "cfsuite.AI.MCP.demoApp.mcpServer.cf.tools.echo" }
        ],
        resources: [],
        prompts:   [],
        cfcCaching: false,
        reloadConfigOnPageRefresh: true
    };

    mcpServer = McpServer(serverConfig);
    mcpServer.handleRequest();
</cfscript>
