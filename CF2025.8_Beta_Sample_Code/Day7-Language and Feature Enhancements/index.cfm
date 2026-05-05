<cfprocessingdirective suppressWhitespace="true">
<cfscript>
    baseUrl = "http://" & CGI.SERVER_NAME & ":" & CGI.SERVER_PORT & "/webinar";
</cfscript>
</cfprocessingdirective>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ColdFusion Language Webinar - Sample Demos</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: rgb(240,244,248); color: rgb(45,55,72); }
        .hero { background: linear-gradient(135deg, rgb(26,54,93) 0%, rgb(43,108,176) 50%, rgb(49,130,206) 100%); color: white; padding: 60px 40px; text-align: center; }
        .hero h1 { font-size: 2.4em; margin-bottom: 12px; }
        .hero p { font-size: 1.15em; opacity: 0.9; max-width: 700px; margin: 0 auto; line-height: 1.6; }
        .container { max-width: 1100px; margin: 0 auto; padding: 40px 20px; }
        .section-title { font-size: 1.5em; color: rgb(26,54,93); margin: 30px 0 16px; padding-bottom: 8px; border-bottom: 3px solid rgb(49,130,206); display: inline-block; }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; margin-bottom: 40px; }
        .card { background: white; border-radius: 10px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.08); transition: transform 0.2s, box-shadow 0.2s; border-left: 5px solid rgb(49,130,206); cursor: pointer; }
        .card:hover { transform: translateY(-4px); box-shadow: 0 6px 20px rgba(0,0,0,0.12); }
        .card h3 { font-size: 1.1em; color: rgb(45,55,72); margin-bottom: 8px; }
        .card p { font-size: 0.9em; color: rgb(113,128,150); line-height: 1.5; margin-bottom: 14px; }
        .btn { display: inline-block; background: rgb(49,130,206); color: white; text-decoration: none; padding: 8px 18px; border-radius: 5px; font-size: 0.85em; font-weight: 600; transition: background 0.2s; }
        .btn:hover { background: rgb(43,108,176); }
        .tag { display: inline-block; background: rgb(235,248,255); color: rgb(43,108,176); padding: 2px 10px; border-radius: 12px; font-size: 0.75em; font-weight: 600; margin-bottom: 10px; }
        .card.ai { border-left-color: rgb(128,90,213); }
        .card.ai .tag { background: rgb(250,245,255); color: rgb(128,90,213); }
        .card.ai .btn { background: rgb(128,90,213); }
        .card.ai .btn:hover { background: rgb(107,70,193); }
        .card.lang { border-left-color: rgb(56,161,105); }
        .card.lang .tag { background: rgb(240,255,244); color: rgb(56,161,105); }
        .card.lang .btn { background: rgb(56,161,105); }
        .card.lang .btn:hover { background: rgb(47,133,90); }
        .card.async { border-left-color: rgb(221,107,32); }
        .card.async .tag { background: rgb(255,250,240); color: rgb(221,107,32); }
        .card.async .btn { background: rgb(221,107,32); }
        .card.async .btn:hover { background: rgb(192,86,33); }
        .card.data { border-left-color: rgb(214,158,46); }
        .card.data .tag { background: rgb(255,255,240); color: rgb(214,158,46); }
        .card.data .btn { background: rgb(214,158,46); }
        .card.data .btn:hover { background: rgb(183,121,31); }
        .footer { text-align: center; padding: 30px; color: rgb(160,174,192); font-size: 0.85em; }
    </style>
</head>
<body>

<div class="hero">
    <h1>ColdFusion Language Webinar</h1>
    <p>Sample Demos &amp; Interactive Examples showcasing the latest ColdFusion features &mdash; from AI-powered NLP and vector databases to modern language constructs and async programming.</p>
</div>

<cfoutput>
<div class="container">

    <div class="section-title">AI &amp; Machine Learning</div>
    <div class="grid">
        <div class="card ai" onclick="window.open('#baseUrl#/bifcallback/reviews.cfm','_blank')">
            <span class="tag">NLP</span>
            <h3>Sentiment Analysis &mdash; Review Classifier</h3>
            <p>Analyze customer reviews using Apache OpenNLP. Classifies text as positive, negative, or neutral with confidence scores. Includes an interactive form to try your own reviews.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card ai" onclick="window.open('#baseUrl#/bifcallback/entityrecognition.cfm','_blank')">
            <span class="tag">NLP</span>
            <h3>Named Entity Recognition</h3>
            <p>Extract people, locations, and organizations from any text using NER models. Paste your own sentences and see entities highlighted with color-coded badges.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card ai" onclick="window.open('#baseUrl#/vectordatabases/query.cfm','_blank')">
            <span class="tag">Vector DB</span>
            <h3>Vector Database &mdash; Semantic Search</h3>
            <p>Ingest documents into an in-memory vector store, run semantic queries, and compare similarity scores across a cross-query comparison matrix.</p>
            <span class="btn">Run Demo</span>
        </div>
        <!---<div class="card ai" onclick="window.open('#baseUrl#/rag/simplerag.cfm','_blank')">
            <span class="tag">RAG</span>
            <h3>Retrieval-Augmented Generation</h3>
            <p>Combine vector search with LLM generation for context-aware AI responses grounded in your own documents.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card ai" onclick="window.open('#baseUrl#/rag/minimalrag.cfm','_blank')">
            <span class="tag">RAG</span>
            <h3>Minimal RAG Pipeline</h3>
            <p>A stripped-down RAG example demonstrating the core retrieve-then-generate pattern with minimal setup.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card ai" onclick="window.open('#baseUrl#/mcp/mathsMCPServer.cfm','_blank')">
            <span class="tag">MCP</span>
            <h3>MCP Server &mdash; Math Operations</h3>
            <p>A Model Context Protocol server exposing math operations as tools that AI agents can discover and invoke.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card ai" onclick="window.open('#baseUrl#/mcp/clientcopy.cfm','_blank')">
            <span class="tag">MCP</span>
            <h3>MCP Client</h3>
            <p>Demonstrates how ColdFusion can act as an MCP client, connecting to and consuming tools from MCP servers.</p>
            <span class="btn">Run Demo</span>
        </div>--->
    </div>

    <div class="section-title">Language Features</div>
    <div class="grid">
        <div class="card lang" onclick="window.open('#baseUrl#/literals/complexexp.cfm','_blank')">
            <span class="tag">Literals</span>
            <h3>Complex Expressions</h3>
            <p>Explore enhanced expression syntax including complex literals, inline struct/array definitions, and more expressive CFML.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card lang" onclick="window.open('#baseUrl#/literals/functionchaining.cfm','_blank')">
            <span class="tag">Literals</span>
            <h3>Function Chaining</h3>
            <p>Demonstrate fluent-style function chaining for cleaner, more readable data transformation pipelines.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card lang" onclick="window.open('#baseUrl#/javainterop/index.cfm','_blank')">
            <span class="tag">Java</span>
            <h3>Java Interop</h3>
            <p>Seamless Java integration using the <code>java{}</code> block &mdash; define inline Java classes and use them directly in CFML.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card lang" onclick="window.open('#baseUrl#/bifcallback/udfcallback.cfm','_blank')">
            <span class="tag">Callbacks</span>
            <h3>UDF Callbacks</h3>
            <p>Pass user-defined functions as callbacks to built-in functions for flexible, functional-style data processing.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card lang" onclick="window.open('#baseUrl#/exception/customexception.cfm','_blank')">
            <span class="tag">Exceptions</span>
            <h3>Custom Exception Handling</h3>
            <p>Advanced exception types, structured error handlers, and exception-type-specific routing.</p>
            <span class="btn">Run Demo</span>
        </div>
    </div>

    <div class="section-title">Built-in Functions</div>
    <div class="grid">
        <div class="card" onclick="window.open('#baseUrl#/BIF/fileMismatch.cfm','_blank')">
            <span class="tag">File I/O</span>
            <h3>FileMismatch &mdash; Log Drift Detector</h3>
            <p>Compare two server log files byte-by-byte, pinpoint where they diverge, and visualize the differences with a side-by-side view.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card" onclick="window.open('#baseUrl#/BIF/fileReadLines.cfm','_blank')">
            <span class="tag">File I/O</span>
            <h3>FileReadLines</h3>
            <p>Read file contents line-by-line with the new <code>FileReadLines()</code> BIF for efficient text processing.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card" onclick="window.open('#baseUrl#/BIF/directoryCreate.cfm','_blank')">
            <span class="tag">File I/O</span>
            <h3>DirectoryCreate</h3>
            <p>Demonstrates the enhanced <code>DirectoryCreate()</code> function with new options and behaviors.</p>
            <span class="btn">Run Demo</span>
        </div>
    </div>

    <div class="section-title">Sets &amp; Data Structures</div>
    <div class="grid">
        <div class="card data" onclick="window.open('#baseUrl#/sets/basic.cfm','_blank')">
            <span class="tag">Sets</span>
            <h3>Set Basics</h3>
            <p>Introduction to the native Set data type &mdash; creation, membership, union, intersection, and difference operations.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card data" onclick="window.open('#baseUrl#/sets/advanced.cfm','_blank')">
            <span class="tag">Sets</span>
            <h3>Advanced Set Operations</h3>
            <p>Dive deeper with subset checks, symmetric difference, power sets, and set-based algorithms.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card data" onclick="window.open('#baseUrl#/sets/performance.cfm','_blank')">
            <span class="tag">Sets</span>
            <h3>Set Performance Benchmarks</h3>
            <p>Compare Set vs Array lookup performance at scale and see why Sets matter for large data operations.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card data" onclick="window.open('#baseUrl#/sets/ecommerce.cfm','_blank')">
            <span class="tag">Sets</span>
            <h3>E-Commerce &mdash; Set Use Case</h3>
            <p>Real-world e-commerce scenario using Sets for product filtering, category intersections, and recommendation logic.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card data" onclick="window.open('#baseUrl#/sets/friendsuggestion.cfm','_blank')">
            <span class="tag">Sets</span>
            <h3>Friend Suggestion Engine</h3>
            <p>Social network friend-of-a-friend suggestions powered by Set intersection and difference operations.</p>
            <span class="btn">Run Demo</span>
        </div>
    </div>

    <div class="section-title">Async &amp; Concurrency</div>
    <div class="grid">
        <div class="card async" onclick="window.open('#baseUrl#/asyncdemos/asyncAllOf.cfm','_blank')">
            <span class="tag">Async</span>
            <h3>asyncAllOf</h3>
            <p>Run multiple async tasks in parallel and wait for all to complete before proceeding.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card async" onclick="window.open('#baseUrl#/asyncdemos/asyncAnyOf.cfm','_blank')">
            <span class="tag">Async</span>
            <h3>asyncAnyOf</h3>
            <p>Fire multiple async tasks and proceed as soon as the first one completes &mdash; ideal for racing strategies.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card async" onclick="window.open('#baseUrl#/asyncdemos/thenCombine.cfm','_blank')">
            <span class="tag">Async</span>
            <h3>thenCombine</h3>
            <p>Combine results from two independent async operations into a single result using <code>thenCombine</code>.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card async" onclick="window.open('#baseUrl#/asyncdemos/completeOnTimeout.cfm','_blank')">
            <span class="tag">Async</span>
            <h3>completeOnTimeout</h3>
            <p>Set a fallback value that kicks in if an async operation doesn't complete within a time limit.</p>
            <span class="btn">Run Demo</span>
        </div>
        <div class="card async" onclick="window.open('#baseUrl#/asyncdemos/orTimeout.cfm','_blank')">
            <span class="tag">Async</span>
            <h3>orTimeout</h3>
            <p>Cancel an async task if it exceeds a deadline, throwing a timeout exception for clean error handling.</p>
            <span class="btn">Run Demo</span>
        </div>
    </div>

    <div class="section-title">Query of Queries</div>
    <div class="grid">
        <div class="card" onclick="window.open('#baseUrl#/qoq/opeval.cfm','_blank')">
            <span class="tag">QoQ</span>
            <h3>Operator Evaluation</h3>
            <p>Demonstrates enhanced operator evaluation and expression handling in ColdFusion Query of Queries.</p>
            <span class="btn">Run Demo</span>
        </div>
    </div>

</div>
</cfoutput>

<div class="footer">
    ColdFusion Language Webinar &mdash; Sample Demos
</div>

</body>
</html>
