<cfscript>
configDir = getDirectoryFromPath(getCurrentTemplatePath()) & "../config/";

mcpServer = MCPServer({
    serverInfo: {
        name: "prologics-logistics",
        version: "1.0.0"
    },
    capabilities: {
        tools: true,
        prompts: true
    },
    /*
    basicAuth: {
        username: "stylemart-agent",
        password: "changeme"
    },
    */
    tools: [
        {cfc: "CFSummit2026Workshop.externalservices.prologics.mcp.ShipmentTool"}
    ],
    prompts: [
        {
            name: "logistics_shipment_status",
            description: "Instructions for how an AI agent should use prologics shipping tools",
            arguments: [],
            template: fileRead(configDir & "logistics-shipment-status-prompt.txt")
        }
    ],
    cfcCaching: false,
    reloadConfigOnPageRefresh: true
});
mcpServer.handleRequest();
</cfscript>
