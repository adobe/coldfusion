<cfscript>
mcpServer = MCPServer({
    NAME: "stylemart-commerce-ops",
    VERSION: "1.0.0",
    TOOLS: [{cfc: "api.agent.s6.lab.mcp.CommerceOpsServer"}]
});
mcpServer.handleRequest();
</cfscript>
