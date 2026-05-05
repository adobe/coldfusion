<cfscript>
try {
    // Create chat model
    chatModel = ChatModel({
        PROVIDER: "openAi",
        APIKEY: "YOUR_OPENAI_API_KEY_HERE",
        MODELNAME: "gpt-4o-mini",
        TEMPERATURE: 0.7
    });
    
    writeOutput("   Chat Model: gpt-4o-mini (OpenAI)");
    writeOutput("<br>");
    
    // Create vector store client with embedded embedding model configuration
    // Note: Instead of creating embeddingModel separately, we configure it within vectorStore
    // Using Ollama for embedding model (local, no API key needed)
    vectorStoreClient = VectorStore({
        "provider": "INMEMORY",
        "embeddingModel": {
            "provider": "ollama",
            "modelName": "all-minilm",
            "baseUrl": "http://localhost:11434"
        }
    });
    
    writeOutput("   Vector Store: In-Memory with all-minilm (Ollama - Local)");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 3: Create SimpleRAG Service
    // ========================================
    writeOutput("3. CREATING SIMPLE RAG SERVICE");
    writeOutput("<br>");
    
    // SimpleRAG takes 3 parameters: source, model, options
        ragService = SimpleRAG(testDir, chatModel, 
        {
            vectorStore = vectorStoreClient, chunkSize = 500, 
            chunkOverlap = 100, recursive = false, 
            maxResults = 3, minScore = 0.7
        });
        ingestionStats = ragService.ingest();
        query = "What is ColdFusion?";
    
        answer = ragService.ask(query);
        writeOutput(answer1.message);

    writeOutput("   <strong>Answer:</strong> " & answer1.message);
    writeOutput("<br>");
    writeOutput("   <em>Response time: " & duration & "ms | Tokens: " & (answer1.metadata.input_token + answer1.metadata.output_token) & " | Model: " & answer1.metadata.model_name & "</em>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Query 2: Follow-up (should NOT remember context)
    query2 = "Tell me more about it";
    writeOutput("   <strong>Ask 2:</strong> " & query2 & " <em>(should NOT know what 'it' refers to)</em>");
    writeOutput("<br>");
    
    startTime = getTickCount();
    answer2 = ragService.ask(query2);
    duration = getTickCount() - startTime;
    
    writeOutput("   <strong>Answer:</strong> " & answer2.message);
    writeOutput("<br>");
    writeOutput("   <em>Response time: " & duration & "ms | Notice: Answer is generic - no memory of previous question!</em>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 6: Test STATEFUL chat() Method (With Memory)
    // ========================================
    writeOutput("6. TESTING STATEFUL chat() METHOD (With Memory - Intelligent Defaults)");
    writeOutput("<br>");
    writeOutput("   Using intelligent defaults: messageWindowChatMemory, maxMessages=10, perUser=false");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Query 1: Start conversation
    query3 = "What security features does ColdFusion provide?";
    writeOutput("   <strong>Chat 1:</strong> " & query3);
    writeOutput("<br>");
    
    startTime = getTickCount();
    answer3 = ragService.chat(query3);
    duration = getTickCount() - startTime;
    
    writeOutput("   <strong>Answer:</strong> " & answer3.message);
    writeOutput("<br>");
    writeOutput("   <em>Response time: " & duration & "ms | Tokens: " & (answer3.metadata.input_token + answer3.metadata.output_token) & "</em>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Query 2: Follow-up (SHOULD remember context)
    query4 = "Can you list those in bullet points?";
    writeOutput("   <strong>Chat 2:</strong> " & query4 & " <em>(should remember 'those' = security features)</em>");
    writeOutput("<br>");
    
    startTime = getTickCount();
    answer4 = ragService.chat(query4);
    duration = getTickCount() - startTime;
    
    writeOutput("   <strong>Answer:</strong> " & answer4.message);
    writeOutput("<br>");
    writeOutput("   <em>Response time: " & duration & "ms | Notice: Remembers context from previous message!</em>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Query 3: Another follow-up
    query5 = "Which of these is most important for enterprise applications?";
    writeOutput("   <strong>Chat 3:</strong> " & query5 & " <em>(continues the conversation)</em>");
    writeOutput("<br>");
    
    startTime = getTickCount();
    answer5 = ragService.chat(query5);
    duration = getTickCount() - startTime;
    
    writeOutput("   <strong>Answer:</strong> " & answer5.message);
    writeOutput("<br>");
    writeOutput("   <em>Response time: " & duration & "ms | Still remembers the security features discussion!</em>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 7: Compare ask() vs chat() Side-by-Side
    // ========================================
    writeOutput("7. SIDE-BY-SIDE COMPARISON: ask() vs chat()");
    writeOutput("<br>");
    writeOutput("<br>");
    
    writeOutput("   <strong>Test Question:</strong> What is CFML?");
    writeOutput("<br>");
    writeOutput("   <strong>Follow-up:</strong> What are its main advantages?");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Using ask() - should lose context
    writeOutput("   <u>Using ask() (stateless):</u>");
    writeOutput("<br>");
    askResp1 = ragService.ask("What is CFML?");
    writeOutput("   Q1: What is CFML?");
    writeOutput("<br>");
    writeOutput("   A1: " & left(askResp1.message, 100) & "...");
    writeOutput("<br>");
    
    askResp2 = ragService.ask("What are its main advantages?");
    writeOutput("   Q2: What are its main advantages?");
    writeOutput("<br>");
    writeOutput("   A2: " & left(askResp2.message, 100) & "... <strong>(Lost context!)</strong>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Using chat() - should maintain context
    writeOutput("   <u>Using chat() (stateful):</u>");
    writeOutput("<br>");
    chatResp1 = ragService.chat("What is CFML?");
    writeOutput("   Q1: What is CFML?");
    writeOutput("<br>");
    writeOutput("   A1: " & left(chatResp1.message, 100) & "...");
    writeOutput("<br>");
    
    chatResp2 = ragService.chat("What are its main advantages?");
    writeOutput("   Q2: What are its main advantages?");
    writeOutput("<br>");
    writeOutput("   A2: " & left(chatResp2.message, 100) & "... <strong>(Remembers CFML context!)</strong>");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 8: Test Configuration Introspection
    // ========================================
    writeOutput("8. CONFIGURATION INTROSPECTION");
    writeOutput("<br>");
    writeOutput("   Checking chat memory configuration...");
    writeOutput("<br>");
    writeOutput("<br>");
    
    config = ragService.getConfiguration();
    
    writeOutput("   <strong>Chat Memory Settings:</strong>");
    writeOutput("<br>");
    writeOutput("   - Enabled: " & config.chatMemoryEnabled);
    writeOutput("<br>");
    writeOutput("   - Type: " & config.chatMemoryType);
    writeOutput("<br>");
    writeOutput("   - Max Messages: " & config.chatMemoryMaxMessages);
    writeOutput("<br>");
    writeOutput("   - Per User: " & config.chatMemoryPerUser);
    writeOutput("<br>");
    writeOutput("   - Source: " & config.chatMemorySource);
    writeOutput("<br>");
    writeOutput("<br>");
    
    stats = ragService.getStatistics();
    writeOutput("   <strong>Statistics:</strong>");
    writeOutput("<br>");
    writeOutput("   - Ask Queries: " & (structKeyExists(stats, "askQueryCount") ? stats.askQueryCount : 0));
    writeOutput("<br>");
    writeOutput("   - Chat Queries: " & (structKeyExists(stats, "chatQueryCount") ? stats.chatQueryCount : 0));
    writeOutput("<br>");
    writeOutput("   - Has Stateless Service: " & stats.hasStatelessService);
    writeOutput("<br>");
    writeOutput("   - Has Stateful Service: " & stats.hasStatefulService);
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 9: Cleanup
    // ========================================
    writeOutput("9. CLEANUP");
    writeOutput("<br>");
    
    // Clean up test files (SimpleRAG service doesn't need explicit cleanup)
    if (fileExists(doc1Path)) fileDelete(doc1Path);
    if (fileExists(doc2Path)) fileDelete(doc2Path);
    if (fileExists(doc3Path)) fileDelete(doc3Path);
    if (directoryExists(testDir)) {
        directoryDelete(testDir, true); // recursive=true to delete all contents
    }
    
    writeOutput("   Test files cleaned up");
    writeOutput("<br>");
    writeOutput("<br>");
    
    writeOutput("========================================");
    writeOutput("<br>");
    writeOutput("DEMO COMPLETED SUCCESSFULLY!");
    writeOutput("<br>");
    writeOutput("========================================");
    writeOutput("<br>");
    
} catch (any e) {
    writeOutput("<br>");
    writeOutput("========================================");
    writeOutput("<br>");
    writeOutput("ERROR OCCURRED");
    writeOutput("<br>");
    writeOutput("========================================");
    writeOutput("<br>");
    writeOutput("Message: " & e.message);
    writeOutput("<br>");
    writeOutput("Detail: " & e.detail);
    writeOutput("<br>");
    writeOutput("<br>");
    writeDump(var=e, label="Exception Details");
}
</cfscript>
