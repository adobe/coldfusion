<!--- Loads any guardrail CFC by mode-relative path and runs validate() against a prompt. Returns JSON. --->
<cfscript>
  param name="url.mode"   default="ref";    // lab | ref
  param name="url.path"   default="";       // e.g. guardrails/input/DiscountFabricationGuard.cfc
  param name="url.prompt" default="";
  param name="url.kind"   default="input";  // input | output

  cfheader( name="Content-Type", value="application/json" );

  fullPath = expandPath( "/api/agent/s6/" & url.mode & "/" & url.path );
  if ( !fileExists( fullPath ) ) { writeOutput( serializeJSON({ "error":"not_found", "path":fullPath }) ); abort; }

  // Load CFC by absolute path.
  dotted = "api.agent.s6." & url.mode & "." & replace( replace( url.path, "/", ".", "all" ), ".cfc", "", "one" );
  guard = createObject( "component", dotted );

  request.guardrailResults = [];
  // Harness runs in a fresh request scope (not the frozen per-user chat context), so
  // request.userText is a reliable stand-in for the shopper's turn here. userTurn()
  // uses it as the marker-less fallback so input guards inspect the supplied prompt.
  request.userText = url.prompt;
  out = ( url.kind == "input" )
    ? guard.validate( userMessage = url.prompt )
    : guard.validate( aiMessage   = url.prompt );

  writeOutput( serializeJSON({
    "result":           out.result,
    "message":          out.message ?: "",
    "repromptMessage":  out.repromptMessage ?: "",
    "request_results":  request.guardrailResults
  }) );
</cfscript>
