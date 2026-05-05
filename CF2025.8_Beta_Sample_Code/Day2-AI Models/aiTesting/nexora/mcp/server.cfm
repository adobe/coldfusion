<cfscript>
    /**
     * Nexora Ticket MCP Server
     * Exposes TicketTool via MCP protocol.
     */
    if (!structKeyExists(application, "nexoraTicketMcpServer2")) {
        application.nexoraTicketMcpServer2 = McpServer({
            serverInfo:   { name:"nexora-ticket-server", version:"1.0.0" },
            capabilities: { tools:true, prompts:false, resources:false },
            tools:        [{ cfc:"aiTesting.nexora.TicketTool" }],
            cfcCaching:   true
        });
    }
    application.nexoraTicketMcpServer2.handleRequest();
</cfscript>
