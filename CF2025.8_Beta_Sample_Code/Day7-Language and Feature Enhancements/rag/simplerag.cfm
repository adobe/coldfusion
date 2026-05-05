<cfscript>
// ============================================================================
// SimpleRAG Comprehensive Configuration Demo
// ============================================================================
// Demonstrates ALL SimpleRAG configuration options including:
// - Chat Memory variations (default, custom window, per-user)
// - Document processing options (chunk size, overlap, recursive)
// - Retrieval parameters (maxResults, minScore)
// - Vector store configurations (NEW: embedding model configured within vectorStore)
// ============================================================================
// 
// IMPORTANT: Embedding Model Configuration Change
// ------------------------------------------------
// SimpleRAG now requires vectorStore to be configured with its embedding model.
// The embeddingModel is NO LONGER passed separately.
// 
// Old approach (deprecated):
//   embeddingModel = getEmbeddingModel({...});
//   ragService = getSimpleRagService(source, chatModel, {
//       embeddingModel: embeddingModel,
//       vectorStore: { provider: "inmemory" }
//   });
//
// New approach (current):
//   vectorStoreClient = GetVectorStoreClient({
//       provider: "INMEMORY",
//       embeddingModel: { 
//           provider: "ollama",
//           modelName: "all-minilm",
//           baseUrl: "http://localhost:11434"
//       }
//   });
//   ragService = getSimpleRagService(source, chatModel, {
//       vectorStore: vectorStoreClient
//   });
// 
// Benefits:
// - Uses local Ollama (no API key needed for embeddings)
// - Ensures embedding model consistency
// - Simpler configuration structure
// ============================================================================

writeOutput("<html><head><style>");
writeOutput("body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: ##f5f5f5; }");
writeOutput(".section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }");
writeOutput(".title { color: ##2c3e50; border-bottom: 3px solid ##3498db; padding-bottom: 10px; }");
writeOutput(".config-box { background: ##ecf0f1; padding: 15px; margin: 10px 0; border-left: 4px solid ##3498db; }");
writeOutput(".success { color: ##27ae60; font-weight: bold; }");
writeOutput(".info { color: ##3498db; }");
writeOutput(".warning { color: ##e67e22; }");
writeOutput("code { background: ##34495e; color: ##ecf0f1; padding: 2px 6px; border-radius: 3px; }");
writeOutput("</style></head><body>");

writeOutput("<div class='section'>");
writeOutput("<h1 class='title'>🚀 SimpleRAG Comprehensive Configuration Demo</h1>");
writeOutput("<p><strong>Purpose:</strong> Demonstrate all configuration options and their effects</p>");
writeOutput("</div>");

try {
    // ========================================
    // Step 1: Create Test Documents
    // ========================================
    writeOutput("<div class='section'>");
    writeOutput("<h2 class='title'>📁 Step 1: Creating Test Documents</h2>");
    
    testDir = expandPath("./test-data");
    if (!directoryExists(testDir)) {
        directoryCreate(testDir);
    }
    
    // Create comprehensive documents with substantial content
    doc1Path = testDir & "/cf-overview.txt";
    doc1Content = "ColdFusion: A Comprehensive Overview" & chr(10) & chr(10) &
        "ColdFusion is a commercial rapid web application development platform created by Adobe Systems. " &
        "Originally developed by Allaire Corporation in 1995, it has evolved into one of the most powerful " &
        "platforms for building enterprise web applications." & chr(10) & chr(10) &
        "Core Technology:" & chr(10) &
        "ColdFusion uses CFML (ColdFusion Markup Language), a tag-based scripting language that combines " &
        "the simplicity of HTML with the power of server-side programming. The platform runs on the Java Virtual Machine (JVM), " &
        "providing excellent performance and scalability. ColdFusion supports both tag-based and script-based syntax, " &
        "giving developers flexibility in their coding approach." & chr(10) & chr(10) &
        "Development Environment:" & chr(10) &
        "ColdFusion includes a comprehensive IDE called ColdFusion Builder, which provides advanced code editing, " &
        "debugging, and deployment capabilities. The platform also integrates seamlessly with popular IDEs like " &
        "Visual Studio Code and IntelliJ IDEA through plugins and extensions." & chr(10) & chr(10) &
        "Architecture:" & chr(10) &
        "ColdFusion applications follow a component-based architecture using CFCs (ColdFusion Components). " &
        "These components support object-oriented programming principles including inheritance, encapsulation, " &
        "and polymorphism. The framework supports both MVC (Model-View-Controller) and event-driven architectures, " &
        "making it suitable for applications of any scale.";
    fileWrite(doc1Path, doc1Content);
    
    doc2Path = testDir & "/cf-features.txt";
    doc2Content = "ColdFusion Platform Features and Capabilities" & chr(10) & chr(10) &
        "Database Integration:" & chr(10) &
        "ColdFusion provides native support for all major relational databases including MySQL, PostgreSQL, Oracle, " &
        "SQL Server, and DB2. The platform's query-of-queries feature allows in-memory manipulation of result sets, " &
        "and the ORM (Object-Relational Mapping) framework simplifies database operations." & chr(10) & chr(10) &
        "Security Features:" & chr(10) &
        "Security is built into every layer of ColdFusion. The platform includes enterprise-grade security features such as " &
        "robust encryption algorithms (AES, DES, RSA), secure authentication mechanisms (LDAP, OAuth, SAML), and comprehensive " &
        "input validation functions. ColdFusion also provides built-in protection against common attacks like SQL injection and XSS." & chr(10) & chr(10) &
        "Web Services and APIs:" & chr(10) &
        "ColdFusion excels at creating and consuming web services. It supports both SOAP and REST protocols with minimal " &
        "configuration. Integration with external APIs is straightforward using built-in HTTP functions and JSON/XML parsers." & chr(10) & chr(10) &
        "Document Handling:" & chr(10) &
        "ColdFusion provides powerful document manipulation features. It can generate PDF files from HTML, merge multiple " &
        "PDFs, add watermarks, and extract text. The platform also supports image manipulation and Excel spreadsheet operations.";
    fileWrite(doc2Path, doc2Content);
    
    doc3Path = testDir & "/cf-enterprise.txt";
    doc3Content = "ColdFusion for Enterprise Applications" & chr(10) & chr(10) &
        "Scalability and High Availability:" & chr(10) &
        "ColdFusion is designed for enterprise-scale deployments. It supports horizontal scaling through server clustering, " &
        "allowing multiple instances to work together as a single system. Load balancing is built-in, and session replication " &
        "ensures seamless failover between servers." & chr(10) & chr(10) &
        "Enterprise Integration:" & chr(10) &
        "ColdFusion integrates with enterprise systems through multiple channels. It supports JMS (Java Message Service) for " &
        "asynchronous messaging, can connect to mainframe systems, and works with enterprise service buses (ESB)." & chr(10) & chr(10) &
        "Development Productivity:" & chr(10) &
        "One of ColdFusion's greatest strengths is development speed. Complex tasks that might take days in other languages " &
        "can often be accomplished in hours with ColdFusion. The extensive built-in function library covers everything from " &
        "string manipulation to cryptography." & chr(10) & chr(10) &
        "Cloud Integration:" & chr(10) &
        "Modern ColdFusion versions include extensive cloud integration capabilities. Direct integration with AWS services " &
        "like S3, SNS, SQS, and Lambda is built into the platform. Azure and Google Cloud integrations are also supported.";
    fileWrite(doc3Path, doc3Content);
    
    totalSize = round((len(doc1Content) + len(doc2Content) + len(doc3Content)) / 1024);
    writeOutput("<p class='success'>✅ Created 3 comprehensive documents (" & totalSize & "KB total)</p>");
    writeOutput("<ul>");
    writeOutput("<li>cf-overview.txt - Core technology and architecture</li>");
    writeOutput("<li>cf-features.txt - Platform features</li>");
    writeOutput("<li>cf-enterprise.txt - Enterprise capabilities</li>");
    writeOutput("</ul>");
    writeOutput("</div>");
    
    // ========================================
    // Step 2: Create Models
    // ========================================
    writeOutput("<div class='section'>");
    writeOutput("<h2 class='title'>🤖 Step 2: Creating AI Models</h2>");
    
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
    ragService = SimpleRag(
        testDir,  // source: directory path
        chatModel,  // model: chat model instance
        {
            // Vector store client (contains embedding model configuration)
            vectorStore: vectorStoreClient,
            
            // Document processing configuration
            chunkSize: 500,
            chunkOverlap: 100,
            recursive: false,
            
            // Retrieval configuration
            maxResults: 3,
            minScore: 0.7
        }  // options struct
    );
    
    writeOutput("   SimpleRAG Service created");
    writedump(ragService)
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 4: Ingest Documents
    // ========================================
    writeOutput("4. INGESTING DOCUMENTS (via RAGPipelineBuilder)");
    writeOutput("<br>");
    writeOutput("   This internally uses RAGPipelineBuilder.performIngestion()");
    writeOutput("<br>");
    
    startTime = getTickCount();
    ingestionStats = ragService.ingest();
    writedump(ingestionStats)
    duration = getTickCount() - startTime;
    
    writeOutput("   Ingestion completed in " & duration & "ms");
    writeOutput("<br>");
    writeOutput("<br>");
    
    writeOutput("   INGESTION STATISTICS:");
    writeOutput("<br>");
    writeOutput("   - Documents loaded: " & ingestionStats.documentsLoaded);
    writeOutput("<br>");
    writeOutput("   - Segments created: " & ingestionStats.segmentsCreated);
    writeOutput("<br>");
    writeOutput("   - Segments ingested: " & ingestionStats.segmentsIngested);
    writeOutput("<br>");
    writeOutput("   - Status: " & ingestionStats.status);
    writeOutput("<br>");
    writeOutput("<br>");
    
    // ========================================
    // Step 5: Test STATELESS ask() Method (No Memory)
    // ========================================
    writeOutput("5. TESTING STATELESS ask() METHOD (No Memory)");
    writeOutput("<br>");
    writeOutput("   Each call is independent - no context remembered");
    writeOutput("<br>");
    writeOutput("<br>");
    
    // Query 1: Ask about ColdFusion
    query1 = "What is ColdFusion?";
    writeOutput("   <strong>Ask 1:</strong> " & query1);
    writeOutput("<br>");
    
    startTime = getTickCount();
    answer1 = ragService.ask(query1);
    duration = getTickCount() - startTime;
    
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
