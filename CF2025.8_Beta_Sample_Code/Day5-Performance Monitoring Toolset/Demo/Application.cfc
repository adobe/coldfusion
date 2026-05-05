component {

    this.name = "MintuBabyCare" & hash(getCurrentTemplatePath());
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 4, 0, 0);

    function onApplicationStart() {
        // OpenAI
        application.openaiKey = "open_api_key";

        // Anthropic
        application.anthropicKey = "anthropicKey";

        // Mistral
        application.mistralkey = "mistralkey";

        // Azure OpenAI
        application.azureopenaikey    = "azureopenaikey";
        application.azureopenaiEndpoint = "https://camp-azr2603-vatuq.openai.azure.com/";
        application.azureModelName    = "gpt-5.3-chat";

        // Ollama (local)
        application.ollamaurl = "http://localhost:11434";

        // Default models
        application.openaiModel    = "gpt-4o-mini";
        application.anthropicModel = "claude-sonnet-4-5";
        application.mistralModel   = "mistral-large-latest";
        application.ollamaModel    = "llama3.2";
        application.ollamaEmbedModel = "all-minilm";

        // Data directory
        application.dataDir = expandPath("/mintu_baby/data/");
        if (!directoryExists(application.dataDir)) {
            directoryCreate(application.dataDir);
        }
    }

    function onSessionStart() {
        session.asyncFuture   = "";
        session.asyncStart    = 0;
        session.ragService    = "";
        session.ragServiceBad = "";
        session.fullAgent     = "";
        session.agentBefore   = "";
        session.agentAfter    = "";
    }
}
