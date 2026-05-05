component {
    this.name = "RAGPresentationDemos";
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0, 1, 0, 0);

    /**
     * Resolve a configuration value in this order:
     *   1. JVM / system property   -Dkey=value
     *   2. OS environment variable
     *   3. Inline default supplied by the caller
     *
     * Real credentials must NEVER be checked in. Provide them at runtime via
     * environment variables (recommended) or a local, untracked override file.
     */
    private string function getSetting(required string key, string defaultValue = "") {
        try {
            var sysProp = createObject("java", "java.lang.System").getProperty(arguments.key);
            if (!isNull(sysProp) && len(sysProp)) { return sysProp; }
        } catch (any e) {}

        try {
            var envVal = createObject("java", "java.lang.System").getenv(arguments.key);
            if (!isNull(envVal) && len(envVal)) { return envVal; }
        } catch (any e) {}

        return arguments.defaultValue;
    }

    public void function onApplicationStart() {
        // ---------------------------------------------------------------
        // LLM provider credentials (read from env / system property only)
        // ---------------------------------------------------------------
        application.openaiKey = getSetting("OPENAI_API_KEY", "REPLACE_WITH_YOUR_OPENAI_API_KEY");

        // ---------------------------------------------------------------
        // Embedding model service (Ollama). Defaults to localhost.
        // Override with -DOLLAMA_BASE_URL or env var OLLAMA_BASE_URL.
        // ---------------------------------------------------------------
        application.ollamaBaseUrl = getSetting("OLLAMA_BASE_URL", "http://localhost:11434");

        // ---------------------------------------------------------------
        // Vector database connection settings.
        // Each entry is overridable through env / system properties so no
        // host or credential needs to be hard-coded in the source tree.
        // ---------------------------------------------------------------
        application.vectorDB = {
            qdrant: {
                url    : getSetting("QDRANT_URL",     "http://localhost:6333"),
                apiKey : getSetting("QDRANT_API_KEY", "REPLACE_WITH_YOUR_QDRANT_API_KEY")
            },
            chroma: {
                url          : getSetting("CHROMA_URL",          "http://localhost:8000"),
                databaseName : getSetting("CHROMA_DATABASE_NAME","default_database"),
                tenantName   : getSetting("CHROMA_TENANT_NAME",  "default_tenant")
            },
            milvus: {
                url : getSetting("MILVUS_URL", "http://localhost:19530")
            },
            pinecone: {
                apiKey     : getSetting("PINECONE_API_KEY", "REPLACE_WITH_YOUR_PINECONE_API_KEY"),
                index      : getSetting("PINECONE_INDEX",   "test-rag"),
                serverless : { dimension: 384, cloud: "aws", region: "us-east-1" }
            }
        };

        application.baseDir = getDirectoryFromPath(getCurrentTemplatePath());

        // Loud, fail-fast warning if the OpenAI key was never configured.
        // The demos will still load (so users can see the UI) but any call
        // that hits the LLM will surface this message.
        if (application.openaiKey == "REPLACE_WITH_YOUR_OPENAI_API_KEY") {
            writeLog(
                file = "rag-demo",
                type = "warning",
                text = "OPENAI_API_KEY is not set. Set it as an environment variable or JVM system property before invoking any demo."
            );
        }
    }

    public void function onSessionStart() {
        session.demos      = {};
        session.retrievers = {};
        session.prompts    = {};
    }

    public boolean function onRequestStart(string targetPage) {
        if (structKeyExists(url, "reinit")) {
            applicationStop();
            location(url=targetPage, addtoken=false);
        }
        if (!structKeyExists(application, "openaiKey"))  { onApplicationStart(); }
        if (!structKeyExists(session, "demos"))          { session.demos = {}; }
        if (!structKeyExists(session, "retrievers"))     { session.retrievers = {}; }
        if (!structKeyExists(session, "prompts"))        { session.prompts = {}; }
        return true;
    }
}
