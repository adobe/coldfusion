<cfscript>
    cfheader(name="Content-Type", value="application/json");
    cfheader(name="Access-Control-Allow-Origin", value="*");
    cfheader(name="Access-Control-Allow-Methods", value="POST, OPTIONS");
    cfheader(name="Access-Control-Allow-Headers", value="Content-Type");
    if (cgi.REQUEST_METHOD == "OPTIONS") { writeOutput("{}"); return; }

    try {
        data     = deserializeJSON(toString(getHTTPRequestData().content));
        prompt   = data.prompt   ?: "Find ColdFusion software products available, then track order ORD-5004";
        toolset  = data.toolset ?: data.tools ?: "ecommerce";
        provider = data.provider ?: "anthropic";

        switch (provider) {
            case "anthropic": apiKey = application.anthropicKey; modelName = application.anthropicModel; break;
            case "mistral":   apiKey = application.mistralkey;   modelName = application.mistralModel; break;
            default:          apiKey = application.openaiKey;    modelName = application.openaiModel;
        }

        // Tools are CFC paths (dot-delimited, relative from wwwroot).
        // CFC methods MUST be `remote` with hint/param/return metadata —
        // CF sends this metadata to the LLM so it decides which tool to call.
        // NOTE: Do NOT pass CFC objects — pass the path string or {CFC:"path"}.
        toolsArr = [];
        if (toolset == "ecommerce" || toolset == "both") arrayAppend(toolsArr, { CFC: "aiTesting.demo.tools.EcommerceTool" });
        if (toolset == "financial"  || toolset == "both") arrayAppend(toolsArr, { CFC: "aiTesting.demo.tools.FinancialTool" });

        chatModel = ChatModel({ PROVIDER:provider, APIKEY:apiKey, MODELNAME:modelName, temperature:0, logRequests:true, logResponses:true });
        aiService = agent({ CHATMODEL:chatModel, TOOLS:toolsArr });

        writeLog(text="FunctionTool: provider=#provider# model=#modelName# toolset=#toolset# tools=#arrayLen(toolsArr)#", file="demo-debug");
        t0       = getTickCount();
        response = aiService.chat(prompt);
        writeLog(text="FunctionTool: toolCount=#arrayLen(response.toolExecutionRequests ?: [])# message=#left(response.message ?: '', 200)#", file="demo-debug");

        // agent() with properly configured remote CFC tools handles tool execution
        // automatically — no manual 2-turn hack needed. The response.message
        // already contains the final answer with tool results aggregated.

        // toolExecutionRequests is a Java List — convert to CF array
        rawRequests  = response.toolExecutionRequests ?: [];
        toolRequests = [];
        for (req in rawRequests) { arrayAppend(toolRequests, req); }

        // Collect tool execution details for the UI
        execResults = [];
        for (req in toolRequests) {
            row = {
                name:      (req.name ?: ""),
                arguments: isSimpleValue(req.arguments ?: "") ? (len(req.arguments ?: "") ? deserializeJSON(req.arguments) : {}) : (req.arguments ?: {}),
                result:    (req.result ?: req.response ?: "")
            };
            arrayAppend(execResults, row);
        }

        elapsed = getTickCount() - t0;

        result = {
            success:      true,
            message:      response.message ?: "",
            elapsed:      elapsed,
            toolRequests: toolRequests,
            toolResults:  execResults,
            toolCount:    arrayLen(toolRequests),
            toolset:      toolset,
            provider:     provider
        };

    } catch (any e) {
        result = { success:false, error:e.message ?: e.type ?: "Unknown server error", detail:e.detail ?: "" };
    }
    writeOutput(serializeJSON(result));
</cfscript>
