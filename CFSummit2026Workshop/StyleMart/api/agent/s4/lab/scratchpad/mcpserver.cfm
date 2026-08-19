<cfscript>    
    /* MCPServer() creates an MCP-compliant server that exposes CFC methods as tools.
    TOOLS accepts an array of {cfc: "dot.path"} — CF introspects public remote
    methods and registers them as callable tools with their hints as descriptions. */
    mcpServer = MCPServer({
        serverInfo: {
            Name:    "scratchpad-shipment-server",
            Version: "1.0.0"
        },

        /////////////////// register tools ///////////////////
        tools: [
            { cfc: "CFSummit2026Workshop.StyleMart.api.agent.s4.lab.scratchpad.ShipmentTool" }
        ],
        /////////////////// register prompts ///////////////////
        prompts:[{
                name:        "shipment_delay_notice",
                title:       "Shipment Delay Notice",
                description: "Generate a customer-facing message explaining a shipment delay",
                arguments: [
                    {
                        name:        "orderId",
                        description: "The order ID that is delayed",
                        required:    true
                    },
                    {
                        name:        "reason",
                        description: "Reason for the delay",
                        required:    false
                    }
                ],
                template: "Write a brief, friendly customer notification that order {orderId} is delayed. Reason: {reason}. Reassure them it will arrive soon."
            }],

        /////////////////// declare capabilities ///////////////////
        capabilities:{
            tools: true,
            prompts: true,
            resources: false
        },
        
        // Disable CFC caching to avoid stale method signatures
        cfcCaching: false, 
        
        // Reload config on page refresh to pick up new tools
        reloadConfigOnPageRefresh: true 
    });

    /* handleRequest() listens for incoming MCP protocol messages (initialize, tools/list, tools/call) over HTTP and routes them to the registered tools. */
    mcpServer.handleRequest();
 </cfscript>

