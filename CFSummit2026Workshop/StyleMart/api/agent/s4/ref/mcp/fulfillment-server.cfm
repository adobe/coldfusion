<cfscript>

mcpServer = MCPServer({
    serverInfo: {
        name: "stylemart-fulfillment",
        version: "1.0.0"
        },
        TOOLS: [
            {cfc: "api.agent.s4.ref.mcp.OrderFulfillmentService"}
            ],
            cfcCaching: false,
            reloadConfigOnPageRefresh: true
        });
    mcpServer.handleRequest();
</cfscript>
