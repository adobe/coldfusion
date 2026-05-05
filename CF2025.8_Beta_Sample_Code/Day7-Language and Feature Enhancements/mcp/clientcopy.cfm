<cfscript>
clientConfig = {
        transport : {
            type: "http", //HTTP transport to MCP server
            url: "http://#CGI.SERVER_NAME#:#CGI.SERVER_PORT#/india-summit/mcp/mathsMCPServer.cfm"
        },
        clientInfo: {
            name: " workshop-result-storage-client",
            version: "1.0.0"
        },
        capabilities: {
            sampling: false,
            roots: false,
            elicitation: false
        },
        initializationTimeout: 30,
        requestTimeout: 10
    }
    mcpClient = CreateMCPClient(clientConfig)
/*
/// 1. Create HTTP transport
transport = McpTransportBuilder('http')
.url('http://localhost:8500/india-summit/mcp/mathsMCPServer.cfm')
.build();

// 2. Set client capabilities
capabilities = McpClientCapabilitiesBuilder()
.sampling()
.roots()
.build();
 
// 3. Build the client
mcpclient = mcpClientBuilder(transport)
.name('healthcare-client')
.version('1.0.0')
.capabilities(capabilities)
.requestTimeout(30)
.initializationTimeout(10)
.build();*/


//writedump(mcpclient[1].listTools());

toolParams = {
                   name:  "getCurrentWeather" ,
                   arguments: {
                                "city":  "bangalore"        
                   }
                }

result =mcpclient[1].callTool(toolParams);

writedump(result);
</cfscript>

