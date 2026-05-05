<!--- Shared sidebar navigation for Mintu's Baby Care. Set variables.currentStep before cfinclude. --->
<cfparam name="variables.currentStep" default="">
<cfparam name="variables.pmtTabs" default="">

<div id="sidebar">
    <div class="brand">
        <h1>Mintu's Baby Care</h1>
        <p>AI-Powered Parenting Assistant</p>
    </div>

    <nav>
        <a href="index.cfm" class='<cfif variables.currentStep EQ "index">active</cfif>'>
            <span class="step-badge">&#127968;</span> Home / Overview
        </a>
        <div class="nav-divider"></div>

        <!--- ChatModel --->
        <div class="nav-section">
            <a href="step1_chatmodel.cfm" class='<cfif variables.currentStep EQ "step1">active</cfif>'>
                <span class="step-badge">1</span> ChatModel
            </a>
        </div>

        <!--- Agent: intro + problem --->
        <div class="nav-section">
            <a href="step2_agent.cfm" class='<cfif variables.currentStep EQ "step2">active</cfif>'>
                <span class="step-badge">2</span> Care Agent
            </a>
            <a href="step2a_agent_problem.cfm" class='<cfif variables.currentStep EQ "step2a">active</cfif> sub'>
                <span class="step-badge">&#x26a0;</span> Agent - Verbose
            </a>
        </div>

        <!--- MCP: intro + problem --->
        <div class="nav-section">
            <a href="step3_mcp.cfm" class='<cfif variables.currentStep EQ "step3">active</cfif>'>
                <span class="step-badge">3</span> MCP - Baby Supplies
            </a>
            <a href="step3a_mcp_problem.cfm" class='<cfif variables.currentStep EQ "step3a">active</cfif> sub'>
                <span class="step-badge">&#x26a0;</span> MCP - Slow Server
            </a>
        </div>

        <!--- Guardrails --->
        <div class="nav-section">
            <a href="step4_guardrails.cfm" class='<cfif variables.currentStep EQ "step4">active</cfif>'>
                <span class="step-badge">4</span> Safety Guardrails
            </a>
        </div>

        <div class="nav-divider"></div>

        <!--- RAG --->
        <div class="nav-section">
            <a href="step5_rag_ingestion.cfm" class='<cfif variables.currentStep EQ "step5">active</cfif>'>
                <span class="step-badge">5</span> Knowledge Ingestion
            </a>
            <a href="step6_rag_retrieval.cfm" class='<cfif variables.currentStep EQ "step6">active</cfif>'>
                <span class="step-badge">6</span> Knowledge Retrieval
            </a>
            <a href="step6a_rag_problem.cfm" class='<cfif variables.currentStep EQ "step6a">active</cfif> sub'>
                <span class="step-badge">&#x26a0;</span> RAG - Poor Config
            </a>
        </div>

        <div class="nav-divider"></div>

        <!--- Full Agent + Load Generator --->
        <div class="nav-section">
            <a href="step7_full_agent.cfm" class='<cfif variables.currentStep EQ "step7">active</cfif>'>
                <span class="step-badge">7</span> Full Care Agent
            </a>
            <a href="step8_load_generator.cfm" class='<cfif variables.currentStep EQ "step8">active</cfif>'>
                <span class="step-badge">8</span> Load Generator
            </a>
        </div>
    </nav>

    <cfscript>
    variables.pmtTabUrls = {
        "LLMs":          "http://localhost:9101/ai-services/home?tab=chatmodels",
        "Agents":        "http://localhost:9101/ai-services/home",
        "RAG":           "http://localhost:9101/ai-services/home?tab=rag",
        "Vector Stores": "http://localhost:9101/ai-services/home?tab=vectordb",
        "MCP Clients":   "http://localhost:9101/ai-services/home?tab=mcp_clients",
        "MCP Servers":   "http://localhost:9101/ai-services/home?tab=mcp_servers",
        "Trace Viewer":  "http://localhost:9101/ai-services/home"
    };
    variables.pmtDefaultUrl = "http://localhost:9101/ai-services/home";
    </cfscript>

    <a href="<cfoutput>#variables.pmtDefaultUrl#</cfoutput>" target="_blank" class="pmt-btn">
        &#128200; Open PMT Dashboard &nearr;
    </a>

    <cfif len(trim(variables.pmtTabs))>
    <div class="pmt-tabs-hint">
        <div class="pmt-hint-label">&#128202; PMT tabs to watch</div>
        <cfoutput>
        <cfloop list="#variables.pmtTabs#" item="tab">
            <cfset tabUrl = structKeyExists(variables.pmtTabUrls, trim(tab)) ? variables.pmtTabUrls[trim(tab)] : variables.pmtDefaultUrl>
            <a href="#tabUrl#" target="_blank" class="tab-chip">#trim(tab)#</a>
        </cfloop>
        </cfoutput>
    </div>
    </cfif>
</div>
