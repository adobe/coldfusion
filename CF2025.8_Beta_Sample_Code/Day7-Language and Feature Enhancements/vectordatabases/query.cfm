<cfscript>
//try {
    local.docs = [
        {"id": createUUID(), "text": "Welcome to ColdFusion Language Webinar", "metadata": {"category": "Conference", "year": "2026"}},
        {"id": createUUID(), "text": "I like watching the sunset every evening", "metadata": {"category": "Nature", "year": "2026"}},
        {"id": createUUID(), "text": "ColdFusion 2025 introduces native vector database support", "metadata": {"category": "Technology", "year": "2026"}},
        {"id": createUUID(), "text": "Machine learning models convert text into numerical embeddings", "metadata": {"category": "AI", "year": "2026"}},
        {"id": createUUID(), "text": "The annual developer conference in Bangalore was a huge success", "metadata": {"category": "Conference", "year": "2025"}},
        {"id": createUUID(), "text": "Sunrise over the mountains is a breathtaking sight", "metadata": {"category": "Nature", "year": "2026"}},
        {"id": createUUID(), "text": "CFML scripting makes rapid web application development easy", "metadata": {"category": "Technology", "year": "2025"}},
        {"id": createUUID(), "text": "Semantic search finds results by meaning rather than exact keywords", "metadata": {"category": "AI", "year": "2026"}}
    ];

    /*local.vectorStoreClient = VectorStore({
        "provider": "milvus",
        "url": "http://localhost:19530",
        "databaseName": "default",
        "collectionName": "sanity",
        "dimension": 384,
        "indexType": "HNSW",
        "metricType": "COSINE",
        "embeddingModel": {"provider": "ollama","modelName": "all-minilm:latest",
        "baseUrl": "http://localhost:11434","maxRetries": 3
        }
    });*/

    local.vectorStoreClient = VectorStore({
        "provider": "inmemory",
        "embeddingModel": {
            "provider": "ollama",
            "modelName": "all-minilm:latest",
            "baseUrl": "http://127.0.0.1:11434",
            "maxRetries": 3
        }
    });

    local.resultIds = local.vectorStoreClient.addAll(local.docs);

    writeOutput("<h2>Vector Database &mdash; Ingest &amp; Query Demo</h2>");

    // --- Ingested Documents Summary ---
    writeOutput("<h3>Ingested Documents (#arrayLen(local.docs)#)</h3>");
    writeOutput("<table border='1' cellpadding='8' cellspacing='0' style='border-collapse:collapse; width:100%; margin-bottom:20px;'>");
    writeOutput("<tr style='background:##e2e8f0;'><th>##</th><th>Text</th><th>Category</th></tr>");
    for (local.i = 1; local.i <= arrayLen(local.docs); local.i++) {
        writeOutput("<tr><td>#local.i#</td><td>#encodeForHTML(local.docs[local.i].text)#</td><td>#encodeForHTML(local.docs[local.i].metadata.category)#</td></tr>");
    }
    writeOutput("</table>");

    // --- Queries to compare ---
    local.queries = [
        {"text": "Sun always sets to rise again", "description": "Nature / sunset theme"},
        {"text": "ColdFusion conference in India", "description": "Conference theme"},
        {"text": "How do vector embeddings work in AI", "description": "AI / embeddings theme"},
        {"text": "Building web apps quickly with scripting languages", "description": "Web development theme"}
    ];

    for (local.q = 1; local.q <= arrayLen(local.queries); local.q++) {
        local.query = local.queries[local.q];

        writeOutput("<h3>Query #local.q#: <em>&ldquo;#encodeForHTML(local.query.text)#&rdquo;</em></h3>");
        writeOutput("<p style='color:##555;'>Expected affinity: #encodeForHTML(local.query.description)#</p>");

        local.searchResults = local.vectorStoreClient.search({
            "text": local.query.text,
            "topK": arrayLen(local.docs),
            "minscore": 0.0
        });

        //Uncomment below to print the vector Embeddings
        //writeDump(local.searchResults[1]);

        writeOutput("<table border='1' cellpadding='8' cellspacing='0' style='border-collapse:collapse; width:100%; margin-bottom:10px;'>");
        writeOutput("<tr style='background:##e2e8f0;'><th>Rank</th><th>Score</th><th>Document Text</th><th>Category</th><th>Relevance</th></tr>");

        for (local.r = 1; local.r <= arrayLen(local.searchResults); local.r++) {
            local.result = local.searchResults[local.r];
            local.score = local.result.score;

            if (local.score >= 0.63) {
                local.badge = "<span style='background:##38a169;color:white;padding:2px 8px;border-radius:4px;'>High</span>";
            } else if (local.score >= 0.3) {
                local.badge = "<span style='background:##d69e2e;color:white;padding:2px 8px;border-radius:4px;'>Medium</span>";
            } else {
                local.badge = "<span style='background:##e53e3e;color:white;padding:2px 8px;border-radius:4px;'>Low</span>";
            }

            writeOutput("<tr>");
            writeOutput("<td style='text-align:center;'>#local.r#</td>");
            writeOutput("<td style='text-align:center;font-weight:bold;'>#numberFormat(local.score, '__.00')#</td>");
            writeOutput("<td>#encodeForHTML(local.result.text)#</td>");
            writeOutput("<td>#encodeForHTML(local.result.metadata.category)#</td>");
            writeOutput("<td style='text-align:center;'>#local.badge#</td>");
            writeOutput("</tr>");
        }
        writeOutput("</table>");
    }

    // --- Cross-query score comparison matrix ---
    writeOutput("<h3>Cross-Query Score Comparison Matrix</h3>");
    writeOutput("<p style='color:##555;'>Each cell shows the similarity score of a document (row) against a query (column).</p>");
    writeOutput("<table border='1' cellpadding='6' cellspacing='0' style='border-collapse:collapse; width:100%; margin-bottom:20px; font-size:0.9em;'>");
    writeOutput("<tr style='background:##e2e8f0;'><th>Document</th>");
    for (local.q = 1; local.q <= arrayLen(local.queries); local.q++) {
        writeOutput("<th style='max-width:180px;'>Q#local.q#: #encodeForHTML(left(local.queries[local.q].text, 30))#&hellip;</th>");
    }
    writeOutput("</tr>");

    local.scoreMatrix = {};
    for (local.q = 1; local.q <= arrayLen(local.queries); local.q++) {
        local.results = local.vectorStoreClient.search({
            "text": local.queries[local.q].text,
            "topK": arrayLen(local.docs),
            "minscore": 0.0
        });
        local.scoreMatrix[local.q] = {};
        for (local.r = 1; local.r <= arrayLen(local.results); local.r++) {
            local.scoreMatrix[local.q][local.results[local.r].text] = local.results[local.r].score;
        }
    }

    for (local.d = 1; local.d <= arrayLen(local.docs); local.d++) {
        local.docText = local.docs[local.d].text;
        writeOutput("<tr><td style='font-size:0.85em;'>#encodeForHTML(local.docText)#</td>");
        for (local.q = 1; local.q <= arrayLen(local.queries); local.q++) {
            local.cellScore = structKeyExists(local.scoreMatrix[local.q], local.docText) ? local.scoreMatrix[local.q][local.docText] : 0;
            if (local.cellScore >= 0.63) {
                local.bg = "##c6f6d5";
            } else if (local.cellScore >= 0.3) {
                local.bg = "##fefcbf";
            } else {
                local.bg = "##fed7d7";
            }
            writeOutput("<td style='text-align:center;background:#local.bg#;'>#numberFormat(local.cellScore, '__.00')#</td>");
        }
        writeOutput("</tr>");
    }
    writeOutput("</table>");

/*} catch (any e) {
    writeOutput("<div style='background-color: ##f8d7da; padding: 15px; margin: 20px 0; border-radius: 5px;'>");
    writeOutput("<p style='color: ##721c24; margin: 0;'><strong>✗ Test Failed:</strong> #encodeForHTML(e.message)#</p>");
}*/
</cfscript>
