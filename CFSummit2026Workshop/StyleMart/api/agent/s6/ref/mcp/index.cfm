<cfscript>
mcpServer = MCPServer({
    serverInfo: {
        name: "stylemart-commerce-ops",
        version: "1.0.0"
    },
    TOOLS: [{cfc: "api.agent.s6.ref.mcp.CommerceOpsServer"}],
    cfcCaching: false,
    reloadConfigOnPageRefresh: true
});
mcpServer.handleRequest();
</cfscript>
