<cfscript>
// ============================================================
// Session 5, Phase A: simpleRAG() — RAG in 5 lines
// ============================================================
// Cache the bot in application scope so concurrent page loads
// don't each re-embed policy PDFs. Double-check lock prevents races.


writeOutput("<h1>SimpleRAG Demo — Policy Q&A</h1>");
writeOutput("<hr>");

if (!structKeyExists(application, "simpleRagBot")) {
    lock name="simpleRagBot_init" type="exclusive" timeout="60" {
        if (!structKeyExists(application, "simpleRagBot")) {
            // 0. Load config for API key
            configDir = getDirectoryFromPath(getCurrentTemplatePath()) & "../config/";
            side = (findNoCase("/lab/", getCurrentTemplatePath()) || findNoCase("\lab\", getCurrentTemplatePath())) ? "lab" : "ref";
            aiConfig = deserializeJSON(fileRead(configDir & "ai." & side & ".json"));

            // 1. Chat model (OpenAI)
            chatModel = ChatModel({
                provider: "openai",
                modelName: "gpt-4o-mini",
                apiKey: aiConfig.apiKey,
                temperature: 0.3
            });

            // 2. Policy documents directory (resolved without .. for pathfilter compatibility)
            policyDir = reReplace(getDirectoryFromPath(getCurrentTemplatePath()), "(lab|ref)[/\\]$", "data/rag/policy/");

            // 3. Create the simpleRAG bot — handles load + chunk + embed + store
            application.simpleRagBot = simpleRAG(policyDir, chatModel, {
                vectorStore: VectorStore({
                    provider: "INMEMORY",
                    embeddingModel: {
                        provider: "openai",
                        modelName: "text-embedding-3-small",
                        apiKey: aiConfig.apiKey
                    }
                }),
                chunkSize: 500,
                chunkOverlap: 100,
                splitterType: "recursive",
                maxResults: 4,
                minScore: 0.5
            });

            // 4. Ingest once — subsequent page loads skip this
            writedump(var = application.simpleRagBot.ingest(), label = 'Ingestion result');
        }
    }
}

// 5. Ask questions!
questions = [
    "Can the wool blazer be machine-washed?",
    "What is the return policy for sale items?",
    "What size should I get if I'm between M and L for a slim fit top?"
];


for (q in questions) {
    result = application.simpleRagBot.chat(q);
    writeoutput("Query " & q)
    writedump(var = result, label = "Answer to query")
}
</cfscript>
