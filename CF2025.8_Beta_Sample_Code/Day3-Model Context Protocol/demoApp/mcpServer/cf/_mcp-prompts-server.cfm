<cfscript>
    promptsArray = [
        {
            name:        "explain_code",
            title:       "Explain Code",
            description: "Explain how code works",
            arguments: [
                {
                    name:        "code",
                    description: "Code to explain",
                    required:    true
                },
                {
                    name:        "language",
                    description: "Programming language",
                    required:    false
                }
            ],
            template: "Explain the following {language} code: {code}"
        },
        {
            name:        "summarize_text",
            title:       "Summarize Text",
            description: "Generate a concise summary of the provided text",
            arguments: [
                {
                    name:        "text",
                    description: "Text to summarize",
                    required:    true
                },
                {
                    name:        "maxWords",
                    description: "Maximum number of words in the summary",
                    required:    false
                }
            ],
            template: "Summarize the following text in at most {maxWords} words: {text}"
        }
    ];

    configData = {
        serverInfo: {
            name:    "demo_cf_prompts_server",
            version: "1.0.0"
        },
        capabilities: {
            tools:     false,
            prompts:   true,
            resources: false
        },
        tools:     [],
        prompts:   promptsArray,
        resources: [],
        cfcCaching: false
    };

    mcpServer = McpServer(configData);
    mcpServer.handleRequest();
</cfscript>
