<cfscript>
mcpServerConfig = {
    SERVERINFO: {
        NAME:    "MintuBabySuppliesServer-Legacy",
        VERSION: "1.0.0"
    },
    CAPABILITIES: {
        TOOLS:     true,
        PROMPTS:   false,
        RESOURCES: false
    },
    TOOLS: [{
        cfc: "mintu_baby.helpers.BabySuppliesServiceSlow",
        methods: [
            { method: "searchProducts",  description: "Search baby products catalog. SLOW uncached response (~3000ms)." },
            { method: "checkInventory",  description: "Check stock level for a baby product. SLOW uncached response (~2500ms)." },
            { method: "getOrderStatus",  description: "Track baby supplies order. SLOW uncached response (~4000ms)." }
        ]
    }],
    CORSENABLED: true,
    CFCCACHING:  false
};

mcpServer = McpServer(mcpServerConfig);
mcpServer.handleRequest();
</cfscript>
