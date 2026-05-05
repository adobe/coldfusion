component {
    this.name = "SimpleRAG_Debug_" & hash(getCurrentTemplatePath());

    public void function onApplicationStart() {
        application.openaiKey = "YOUR_OPENAI_API_KEY";
        application.baseDir = getDirectoryFromPath(getCurrentTemplatePath());
    }

    public boolean function onRequestStart(string targetPage) {
        if (structKeyExists(url, "reinit")) {
            applicationStop();
            location(url=targetPage, addtoken=false);
        }

        if (!structKeyExists(application, "openaiKey")) {
            onApplicationStart();
        }

        return true;
    }
}
