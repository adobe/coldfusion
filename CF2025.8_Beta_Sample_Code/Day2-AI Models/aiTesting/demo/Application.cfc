component {

    this.name              = "CFAIDemoApp202511";
    this.sessionManagement = true;
    this.sessionTimeout    = createTimeSpan(0, 2, 0, 0);
    this.wschannels        = [{ name: "aistream" }];

    this.componentpaths    = [getDirectoryFromPath(getCurrentTemplatePath())];
    this.mappings["/demo"] = getDirectoryFromPath(getCurrentTemplatePath());

    function onRequestStart() {
        if (structKeyExists(url, "reload") && url.reload == 1) {
            applicationStop();
            location(url=cgi.script_name, addToken=false);
        }
    }

    function onApplicationStart() {

        // ════════════════════════════════════════════════════════════════
        //  CUSTOMER CONFIG — fill in your API keys below, then restart.
        //  Only fill in the providers you plan to use.
        // ════════════════════════════════════════════════════════════════

        // ── Provider API keys ────────────────────────────────────────
        application.openaiKey           = "YOUR_OPENAI_API_KEY";
        application.anthropicKey        = "YOUR_ANTHROPIC_API_KEY";
        application.mistralkey          = "YOUR_MISTRAL_API_KEY";
        application.azureopenaikey      = "YOUR_AZURE_OPENAI_API_KEY";
        application.azureopenaiEndpoint = "YOUR_AZURE_OPENAI_ENDPOINT";  // e.g. "https://your-resource.openai.azure.com/"
        application.ollamaurl           = "http://localhost:11434";
        application.geminiKey           = "YOUR_GEMINI_API_KEY";

        // ── Default model names per provider ─────────────────────────
        application.openaiModel    = "gpt-5";
        application.anthropicModel = "claude-sonnet-4-5";
        application.mistralModel   = "mistral-large-latest";
        application.azureModelName = "gpt-5.3-chat";
        application.geminiModel    = "gemini-3-flash-preview";

        // ── Embedding model (used by RAG) ────────────────────────────
        application.embedProvider  = "mistral";
        application.embedModelName = "mistral-embed";
        application.embedApiKey    = application.mistralkey;
    }

}
