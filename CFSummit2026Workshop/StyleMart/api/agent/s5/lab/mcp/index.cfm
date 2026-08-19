<cfscript>
mcpServer = MCPServer({
    serverInfo: {
        name: "stylemart-commerce-ops",
        version: "1.0.0"
    },
    TOOLS: [{cfc: "api.agent.s5.lab.mcp.CommerceOpsServer"}],
    cfcCaching: false,
    reloadConfigOnPageRefresh: true
});
mcpServer.handleRequest();
</cfscript>
