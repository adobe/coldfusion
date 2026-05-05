<cfscript>
// Initialize Healthcare MCP server
cap = McpServerCapabilitiesBuilder().tools(true).build();

serverConfig = {
        serverInfo: {
            name: "Demo MCP Server",
            version: "1.0.0"
        },
        capabilities: {
            tools: true,
            prompts: false,
            resources: false
        },
        tools: [
            { cfc: "india-summit.mcp.weatherTool"}
        ],
        cfcCaching: false
    };

application.healthcareMcpServer = createMCPServer(serverConfig);
/*application.healthcareMcpServer = mcpServerBuilder()
    .capabilities(cap)
    .tools([
     // { cfc: "mcp.mathsTools"},
      { cfc: "india-summit.mcp.weatherTool"}
    ])
    .cfcCaching(false)
    .build();*/

application.healthcareMcpServer.handleRequestAndWriteResponse();
</cfscript>

