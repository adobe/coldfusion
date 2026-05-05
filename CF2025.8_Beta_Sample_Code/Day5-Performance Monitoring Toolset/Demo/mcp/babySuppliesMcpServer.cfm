<cfscript>
mcpServerConfig = {
    SERVERINFO: {
        NAME:    "MintuBabySuppliesServer",
        VERSION: "2.0.0"
    },
    CAPABILITIES: {
        TOOLS:     true,
        PROMPTS:   false,
        RESOURCES: false
    },
    TOOLS: [{
        cfc: "mintu_baby.helpers.BabySuppliesService",
        methods: [
            { method: "searchProducts",  description: "Search baby products catalog by keyword. Fast cached response (~150ms)." },
            { method: "checkInventory",  description: "Check stock level for a baby product. Fast cached response (~100ms)." },
            { method: "getOrderStatus",  description: "Track baby supplies order status. Fast cached response (~200ms)." }
        ]
    }],
    CORSENABLED: true,
    CFCCACHING:  false
};

mcpServer = McpServer(mcpServerConfig);
mcpServer.handleRequest();
</cfscript>
