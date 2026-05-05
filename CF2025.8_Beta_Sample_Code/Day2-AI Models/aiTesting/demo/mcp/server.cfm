<cfscript>
    /**
     * Demo MCP Server
     * Exposes EcommerceTool and FinancialTool via MCP protocol
     */
    if (!structKeyExists(application, "demoMcpServer")) {   
        serverConfig = {
            serverInfo: {
                name:    "cf-demo-mcp-server",
                version: "1.0.0"
            },
            capabilities: {
                tools:     true,
                prompts:   false,
                resources: false
            },
            tools: [
                { cfc: "aiTesting.demo.tools.EcommerceTool" },
                { cfc: "aiTesting.demo.tools.FinancialTool"  }
            ],
            reloadConfigOnPageRefresh = true,
            cfcCaching: false
        };
        application.demoMcpServer = McpServer(serverConfig);
        //writeDump(application.demoMcpServer)
    }
   application.demoMcpServer.handleRequest();
</cfscript>
