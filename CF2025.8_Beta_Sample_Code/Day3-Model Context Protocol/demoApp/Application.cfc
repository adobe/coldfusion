component output="true" {

    this.name = "mcp-demo-app"

    void function onRequestStart() {
        application.CONSTANTS = new cfsuite.AI.MCP.constants().init()

        // ---- Resource registry for local CF resources server ----
        var resDir = getDirectoryFromPath(getCurrentTemplatePath()) & "mcpServer/cf/resources/"
        application.demoResourceRegistry = {
            resText: { uri: "file:///resources/logs/app.log", filePath: resDir & "logs/app.log" }
        }

        // ---- Server URLs ----
        var baseUrl = "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT##len(trim(CGI.CONTEXT_PATH)) ? '/' & CGI.CONTEXT_PATH : ''#"

        application.SERVERS = {
            // Local CF servers (in demoApp/mcpServer/cf/)
            CF_TOOLS:     baseUrl & "/cfsuite/AI/MCP/demoApp/mcpServer/cf/_mcp-tools-server.cfm",
            CF_RESOURCES: baseUrl & "/cfsuite/AI/MCP/demoApp/mcpServer/cf/_mcp-resources-server.cfm",
            CF_PROMPTS:   baseUrl & "/cfsuite/AI/MCP/demoApp/mcpServer/cf/_mcp-prompts-server.cfm",
            // TypeScript servers
            TS_TOOLS:       "http://#application.CONSTANTS.TYPESCRIPT.SERVER_HOSTNAME#:#application.CONSTANTS.TYPESCRIPT.ASSORTED_TOOLS_SERVER_PORT#/mcp",
            TS_LOGGING:     "http://#application.CONSTANTS.TYPESCRIPT.SERVER_HOSTNAME#:#application.CONSTANTS.TYPESCRIPT.LOGGING_ENABLED_SERVER_PORT#/mcp",
            TS_ELICITATION: "http://#application.CONSTANTS.TYPESCRIPT.SERVER_HOSTNAME#:#application.CONSTANTS.TYPESCRIPT.ELICITATION_SERVER_PORT#/mcp",
            TS_ROOTS:       "http://#application.CONSTANTS.TYPESCRIPT.SERVER_HOSTNAME#:#application.CONSTANTS.TYPESCRIPT.ROOTS_SERVER_PORT#/mcp",
            TS_PROMPTS:     "http://#application.CONSTANTS.TYPESCRIPT.SERVER_HOSTNAME#:#application.CONSTANTS.TYPESCRIPT.PROMPTS_SERVER_PORT#/mcp",
            TS_SAMPLING:    "http://#application.CONSTANTS.TYPESCRIPT.SERVER_HOSTNAME#:#application.CONSTANTS.TYPESCRIPT.SAMPLING_SERVER_PORT#/mcp"
        }
    }
}
