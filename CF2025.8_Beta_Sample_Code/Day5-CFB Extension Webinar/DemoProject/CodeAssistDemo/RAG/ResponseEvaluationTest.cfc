component {

    public struct function runOpenAIResponseEvaluation() {
        var result = {
            success: false,
            message: "",
            expected: "The inflation for the year 1999 is 6%."
        };

        try {
            var chatModel = chatmodel({
                provider: "openai",
                modelName: "gpt-4o-mini",
                apiKey: application.openaiKey,
                temperature: 0.7
            });

            var vectorStoreClient = vectorstore({
                provider: "INMEMORY",
                embeddingModel: {
                    provider: "openai",
                    modelName: "text-embedding-ada-002",
                    apiKey: application.openaiKey
                }
            });

            var dataFilePath = getDirectoryFromPath(getCurrentTemplatePath()) & "test.txt";

            var ragService = simpleRAG(
                dataFilePath,
                chatModel,
                {
                    vectorStore: vectorStoreClient,
                    chunkSize: 500,
                    chunkOverlap: 100,
                    recursive: false
                }
            );

            ragService.ingest();
            var answer = ragService.ask("What is the inflation of year 1999 according to the document?");

            result.message = answer.message;
            result.success = true;
        } catch (any e) {
            result.message = e.message;
            result.success = false;
        }

        return result;
    }
}
