<cfscript>

   serverUrl = "http://localhost:" & CGI.SERVER_PORT & "/CFSummit2026Workshop/StyleMart/api/agent/s4/lab/scratchpad/mcpserver.cfm";
   writeOutput("connecting to server: " & serverUrl & "<br>");

   /* MCPClient() connects to an MCP server over HTTP (or stdio for local processes).
      Pass {url: "..."} for HTTP transport. Returns an array if multiple servers are
      configured (via configFile); a single client object for inline config. */
   mcpClient = MCPClient({ 
               transport: {
               type: "HTTP",
               URL: serverUrl
            },
            clientInfo: {
               name: "scratchpad-shipment-client",
               version: "1.0.0"
            }
      });
   writeDump(var=mcpClient, label="MCP Client");
   /* listTools() asks the server what tools are available. Returns a struct with a
      "tools" array — each entry has name, description, and inputSchema. */
   tools = mcpClient.listTools();
   writeDump(var=tools, label="Available Tools");

   /* Pass the orderId as an argument to the tool:
      Sample orderIds: ord_001 (shipped), ord_002 (processing), ord_003 (delivered*/
   orderId = "ord_001";

   /* callTool() invokes a specific tool on the server by name, passing arguments.
      Returns a struct with "content" array — each entry has type ("text") and text. */
   result = mcpClient.callTool({
      name: "getShipmentStatus",
      arguments: { orderId: orderId } // Pass the orderId as an argument to the tool: example: ord_001
   });
   writeDump(var=result, label="getShipmentStatus(#orderId#)");

   /* getPrompt() fetches a server-registered prompt template with arguments substituted.
      Returns a struct with description + messages array ready to feed to a ChatModel. */
   promptParams = {
         name: "shipment_delay_notice",
         arguments: {
            orderId: "ord_001",
            reason: "weather disruption at distribution center"
         }
   }
   promptResponse = mcpClient.getPrompt(promptParams)
   writeDump(var=promptResponse, label="promptResponse - shipment_delay_notice");

   writeOutput("description: "    & promptResponse.description        & "<br>")
   writeOutput("messages count: " & arrayLen(promptResponse.messages) & "<br>")

   msg = promptResponse.messages[1]
   writeOutput("role: "              & msg.role         & "<br>")
   writeOutput("content type: "      & msg.content.type & "<br>")
   writeOutput("content not empty: " & (len(trim(msg.content.text)) > 0 ? "YES" : "NO") & "<br>")

   mcpClient.close()
</cfscript>