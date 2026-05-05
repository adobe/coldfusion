component {

    this.name            = "NexoraSupport123";
    this.sessionManagement = true;
    this.sessionTimeout  = createTimeSpan(0, 2, 0, 0);
    this.serialization.preservecaseforstructkey = true;

    this.componentpaths  = [getDirectoryFromPath(getCurrentTemplatePath())];
    this.mappings["/nexora"] = getDirectoryFromPath(getCurrentTemplatePath());

    this.companyName     = "Nexora";
    this.companyTagline  = "Shop Smarter. Ship Faster.";

    function onApplicationStart() {

        // ════════════════════════════════════════════════════════════════
        //  CUSTOMER CONFIG — fill in your API keys below, then restart.
        //  Only the chat provider key + embedding provider key are needed.
        // ════════════════════════════════════════════════════════════════

        // ── Chat model (powers all AI conversations) ─────────────────
        application.provider      = "anthropic";              // "anthropic" | "openai" | "mistral"
        application.modelName     = "claude-sonnet-4-5";      // model name for your provider
        application.apiKey        = "YOUR_ANTHROPIC_API_KEY";  // API key for the chat provider

        // ── Embedding model (used by RAG vector store) ───────────────
        application.embedProvider  = "mistral";               // "mistral" | "openai"
        application.embedModelName = "mistral-embed";         // embedding model name
        application.embedApiKey    = "YOUR_MISTRAL_API_KEY";   // API key for the embedding provider

        // ── Email (used by MCP TicketTool for escalation emails) ─────
        application.supportEmail  = "your-email@example.com"; // receives escalation ticket emails
        application.fromEmail     = "noreply@example.com";    // sender address for cfmail

        // ── Company identity ─────────────────────────────────────────
        application.companyName    = "Nexora";
        application.companyTagline = "Shop Smarter. Ship Faster.";
    }

    function onSessionStart() {
    }

    function onError( exception, eventName ) {
        writeLog(
            text = "Nexora App Error [" & eventName & "]: " & exception.message,
            type = "error",
            log  = "nexora"
        );
    }

}
