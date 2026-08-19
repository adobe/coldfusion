component rest="true" restpath="/s6/lab/email" {

  /**
   * G1 — generate a recovery email for {userId, cartId, sessionId}.
   * Contract §5.6. Returns the gen_email_* asset shape.
   *
   * Lab skeleton — three TODO blocks (RE1/RE2/RE3) for attendees to fill.
   * Helpers below (parseModelJson, assembleAsset, persistAsset, localizeBody, guardRequest,
   * loadS6Config, l1Get, tryMcp, renderTemplate, agentConfigForGeneration, normalizeGuardrailResults)
   * are pre-wired [SCAFFOLD] and not attendee-edited.
   */
  remote struct function generate(
    required string userId    restargsource="form",
    required string cartId    restargsource="form",
    required string sessionId restargsource="form"
  ) httpmethod="POST" restpath="generate" produces="application/json" {

    guardRequest( arguments.userId, arguments.cartId, arguments.sessionId );

    try {
      // ===== ATTENDEE TODO ZONE =================================================

      // TODO-S6-9a: Load context via Layer-1 REST self-calls (NOT direct table queries).
      //   Read cart via K1 and preferences via P1; coupons + weather via MCP (best-effort).
      //   Build a struct that ALSO carries userId/cartId/sessionId for assembleAsset().
      //
      //   local.cfg = loadS6Config();
      //   local.context = {
      //     userId:          arguments.userId,
      //     cartId:          arguments.cartId,
      //     sessionId:       arguments.sessionId,
      //     preferences:     l1Get("/commerce/users/" & arguments.userId & "/preferences"),
      //     cart:            l1Get("/commerce/carts/" & arguments.cartId),
      //     eligibleCoupons: tryMcp("cf-commerce","getEligibleCoupons",{userId:arguments.userId}, []),
      //     weather:         tryMcp("ext-weather","getForecast",{city:""}, "")
      //   };
      local.cfg     = loadS6Config();
      local.context = {} /* TODO-S6-9a */;

      // TODO-S6-9b: Render the recovery-email prompt template with the context.
      //   var promptTemplate = fileRead( expandPath( local.cfg.recoveryEmail.promptTemplateFile ) );
      //   var fullPrompt = renderTemplate( promptTemplate, local.context );
      local.fullPrompt = "" /* TODO-S6-9b */;

      // TODO-S6-9c: Invoke the SAME guardrailed agent used by ChatService.
      //   Collect results from request.guardrailResults (NOT from the chat() return).
      //   request.guardrailResults = [];
      //   var raw     = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
      //   var parsed  = parseModelJson( raw.message );
      //   var results = normalizeGuardrailResults( request.guardrailResults );
      //   var asset   = assembleAsset( parsed, local.context, results );
      //   return persistAsset( asset, results );
      return {} /* TODO-S6-9c */;

      // ===== END ATTENDEE TODO ZONE =============================================
    }
    catch ( any e ) {
      throw( type    = "GeneratedAssetException",
             message = "Recovery email generation failed: " & e.message,
             extendedInfo = e.type );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  //  Helpers below — pre-wired [SCAFFOLD]. Attendees do not edit these.
  // ──────────────────────────────────────────────────────────────────────────────

  variables.SAFE_FALLBACK_BODY =
    "<p>We saved the items in your cart. Sign in to StyleMart to review them and complete checkout.</p>";

  private struct function loadS6Config() {
    var configDir = getDirectoryFromPath( getCurrentTemplatePath() ) & "../config/";
    var raw = fileRead( configDir & "ai.lab.json" );
    var cfg = deserializeJSON( raw );
    cfg._configDir = configDir;
    return cfg;
  }

  /**
   * Pre-flight server-side validation. Throws ProblemException with errorCode set; the REST
   * error handler maps each code to its problem+json status (§10.1).
   */
  private void function guardRequest(
    required string userId,
    required string cartId,
    required string sessionId
  ) {
    if ( !len( arguments.userId ) || !len( arguments.cartId ) || !len( arguments.sessionId ) ) {
      throw( type="ProblemException", errorCode="invalid_request",
             message="userId, cartId, sessionId all required." );
    }
    var requester = cgi.HTTP_X_SHOPPER_ID ?: "";
    if ( len( requester ) && requester != arguments.userId ) {
      throw( type="ProblemException", errorCode="forbidden",
             message="X-Shopper-Id mismatch." );
    }
    // Extra checks (user_not_found / cart_not_found / session_expired / cart_empty / email_missing)
    // would fire here in production. For workshop scope, the L1 self-calls in RE1 will surface
    // these via their own 4xx; we re-raise as problem+json there.
  }

  private struct function l1Get( required string path ) {
    var url = "http://localhost:8500/api" & arguments.path;
    cfhttp( method="GET", url=url, result="local.resp", timeout=5 );
    var resp = local.resp;
    if ( resp.statusCode contains "200" ) return deserializeJSON( resp.fileContent );
    throw( type="ProblemException", errorCode="upstream_failure",
           message="L1 self-call failed: " & arguments.path & " -> " & resp.statusCode );
  }

  private any function tryMcp( required string server, required string toolName, required struct args, any fallback="" ) {
    try {
      // Placeholder — production wiring would route through the MCP client used by ChatService.
      // For workshop scope, attendees see the call shape; the fallback fires when mcp wiring is offline.
      var mcp = createObject( "component", "api.agent.s6.lab.mcp.CommerceOpsServer" );
      if ( arguments.toolName == "getEligibleCoupons" && structKeyExists( mcp, "getEligibleCoupons" ) ) {
        return mcp.getEligibleCoupons( argumentCollection = arguments.args );
      }
      return arguments.fallback;
    } catch ( any e ) { return arguments.fallback; }
  }

  private string function renderTemplate( required string template, required struct context ) {
    var rendered = arguments.template;
    rendered = replace( rendered, "{{preferences}}",     serializeJSON( arguments.context.preferences ?: {} ),     "all" );
    rendered = replace( rendered, "{{cart}}",            serializeJSON( arguments.context.cart ?: {} ),            "all" );
    rendered = replace( rendered, "{{eligibleCoupons}}", serializeJSON( arguments.context.eligibleCoupons ?: [] ), "all" );
    rendered = replace( rendered, "{{weather}}",         toString( arguments.context.weather ?: "" ),              "all" );
    rendered = replace( rendered, "{{preferences.tripCity}}",
                        toString( arguments.context.preferences.tripCity ?: "" ), "all" );
    return rendered;
  }

  private struct function agentConfigForGeneration() {
    var cfg = loadS6Config();
    var MODE = "lab"; // ref/RecoveryEmailService overrides this to "ref"

    var model = ChatModel({
      PROVIDER:    cfg.provider,
      APIKEY:      application.OPENAI_API_KEY,
      BASEURL:     cfg.baseUrl ?: "",
      MODELNAME:   cfg.modelName,
      TEMPERATURE: cfg.recoveryEmail.temperature ?: 0.6,
      TOPP:        cfg.topP ?: 0.9,
      MAXTOKENS:   cfg.recoveryEmail.maxTokens ?: 600
    });

    var agentConfig = {
      CHATMODEL:  model,
      CHATMEMORY: {
        TYPE: cfg.chatMemory.type ?: "messageWindowChatMemory",
        MAXMESSAGES: cfg.chatMemory.maxMessages ?: 20,
        PERUSER: cfg.chatMemory.perUser ?: true
      }
    };

    var guardBase = "/api/agent/s6/" & MODE & "/";
    if ( structKeyExists( cfg, "guardrails" ) ) {
      if ( isArray( cfg.guardrails.input ?: [] ) ) {
        agentConfig.INPUTGUARDRAILS = cfg.guardrails.input.map( (p) => expandPath( guardBase & p ) );
      }
      if ( isArray( cfg.guardrails.output ?: [] ) ) {
        agentConfig.OUTPUTGUARDRAILS = cfg.guardrails.output.map( (p) => expandPath( guardBase & p ) );
      }
    }

    // RAG: reuse the same vector store ChatService uses.
    if ( structKeyExists( application, "ragVectorStore" ) && isObject( application.ragVectorStore ) ) {
      agentConfig.retrievalAugmentor = {
        queryRouter: {
          contentRetrievers: [{
            vectorStore: application.ragVectorStore,
            maxResults: cfg.rag.maxResults ?: 4,
            minScore:   cfg.rag.minScore ?: 0.5,
            description: "StyleMart catalog/policy/reviews/orders"
          }]
        },
        contentInjector: {
          promptTemplate: cfg.rag.contentInjectorTemplate ?: "Context: {{contents}}
Question: {{userMessage}}",
          metadataKeys: ["file_name"]
        }
      };
    }

    return agentConfig;
  }

  /**
   * The contract requires three OUTPUT guardrail entries on every gen_email_* (§5.6),
   * even on a clean run. Pull only output rows from request.guardrailResults; if any
   * expected rule is missing, default to passed:true (clean run).
   */
  private array function normalizeGuardrailResults( required array raw ) {
    var REQUIRED = ["no-unsupported-fit-guarantee","no-fake-discount","no-pii-leak","no-misleading-scarcity"];
    var byRule = {};
    for ( var r in arguments.raw ) {
      if ( ( r.phase ?: "" ) == "output" ) byRule[ r.rule ] = r;
    }
    var out = [];
    for ( var rule in REQUIRED ) {
      if ( structKeyExists( byRule, rule ) ) {
        arrayAppend( out, {
          "rule":            rule,
          "passed":          byRule[ rule ].passed,
          "result":          byRule[ rule ].result,
          "message":         byRule[ rule ].message ?: "",
          "repromptMessage": byRule[ rule ].repromptMessage ?: ""
        });
      } else {
        arrayAppend( out, { "rule": rule, "passed": true, "result": "success", "message": "", "repromptMessage": "" } );
      }
    }
    return out;
  }

  private struct function parseModelJson( required string raw ) {
    // Models sometimes wrap JSON in markdown fences or add prose. Extract the
    // outermost { ... } object before parsing.
    var jsonText = trim( arguments.raw );
    var startIdx = jsonText.indexOf( "{" );
    var endIdx   = jsonText.lastIndexOf( "}" );
    if ( startIdx >= 0 && endIdx > startIdx ) {
      jsonText = jsonText.substring( startIdx, endIdx + 1 );
    }
    try { return deserializeJSON( jsonText ); }
    catch ( any e ) {
      throw( type="ModelOutputException",
             message="Model returned non-JSON output (expected the gen_email_* contract shape)." );
    }
  }

  private string function localizeBody( required string bodyHtml ) {
    // Production would re-format $-amounts and ISO timestamps to en-US. Workshop pass-through.
    return arguments.bodyHtml;
  }

  private struct function assembleAsset(
    required struct parsed,
    required struct context,
    required array  guardrailResults
  ) {
    var hadFatal = arguments.guardrailResults.some( (r) => ( r.result ?: "" ) == "fatal" );
    var finalBody = hadFatal ? variables.SAFE_FALLBACK_BODY : localizeBody( arguments.parsed.bodyHtml ?: "" );

    return {
      "assetId":     "gen_email_" & arguments.context.userId & "_" & lCase( replace( createUUID(), "-", "", "all" ) ),
      "type":        "recovery-email",
      "sessionId":   arguments.context.sessionId,
      "cartId":      arguments.context.cartId,
      "userId":      arguments.context.userId,
      "subject":     arguments.parsed.subject     ?: "Your saved items at StyleMart",
      "previewText": arguments.parsed.previewText ?: "",
      "fromName":    "StyleMart",
      "fromEmail":   "hello@stylemart.example",
      "toName":      arguments.context.preferences.firstName ?: "there",
      "toEmail":     arguments.context.preferences.email     ?: "draft@stylemart.example",
      "date":        dateTimeFormat( now(), "iso8601" ),
      "bodyHtml":    finalBody,
      "sourceInputs": {
        "preferenceIds": [ "pref_" & arguments.context.userId ],
        "cartItemIds":   arguments.context.cart.itemIds       ?: [],
        "ragSourceIds":  arguments.parsed.citedSourceIds ?: [],
        "mcpToolCalls":  arguments.parsed.usedMcpCalls    ?: []
      },
      "guardrailResults": arguments.guardrailResults,
      "createdAt":   dateTimeFormat( now(), "iso8601" )
    };
  }

  private struct function persistAsset( required struct asset, required array guardrailResults ) {
    transaction {
      queryExecute(
        "INSERT INTO generated_assets (asset_id, type, session_id, user_id, cart_id,
                                       body_html, source_inputs, guardrail_results, created_at)
         VALUES (:aid, :type, :sid, :uid, :cid, :body, :srcs, :grs, :ts)",
        {
          aid:  { value: arguments.asset.assetId,                 cfsqltype: "cf_sql_varchar"     },
          type: { value: arguments.asset.type,                    cfsqltype: "cf_sql_varchar"     },
          sid:  { value: arguments.asset.sessionId,               cfsqltype: "cf_sql_varchar"     },
          uid:  { value: arguments.asset.userId,                  cfsqltype: "cf_sql_varchar"     },
          cid:  { value: arguments.asset.cartId,                  cfsqltype: "cf_sql_varchar"     },
          body: { value: arguments.asset.bodyHtml,                cfsqltype: "cf_sql_longvarchar" },
          srcs: { value: serializeJSON( arguments.asset.sourceInputs ),     cfsqltype: "cf_sql_longvarchar" },
          grs:  { value: serializeJSON( arguments.guardrailResults ),       cfsqltype: "cf_sql_longvarchar" },
          ts:   { value: now(),                                   cfsqltype: "cf_sql_timestamp"   }
        },
        { datasource: "stylemart" }
      );
      for ( var gr in arguments.guardrailResults ) {
        queryExecute(
          "INSERT INTO guardrail_events (event_id, session_id, rule_id, phase, result, message, reprompt_message, created_at)
           VALUES (:eid, :sid, :rid, :phase, :result, :msg, :rep, :ts)",
          {
            eid:    { value: "ge_" & lCase( replace( createUUID(), "-", "", "all" ) ), cfsqltype: "cf_sql_varchar"     },
            sid:    { value: arguments.asset.sessionId,                                cfsqltype: "cf_sql_varchar"     },
            rid:    { value: gr.rule,                                                   cfsqltype: "cf_sql_varchar"     },
            phase:  { value: "output",                                                  cfsqltype: "cf_sql_varchar"     },
            result: { value: gr.result ?: ( gr.passed ? "success" : "failure" ),        cfsqltype: "cf_sql_varchar"     },
            msg:    { value: gr.message ?: "",                                          cfsqltype: "cf_sql_longvarchar" },
            rep:    { value: gr.repromptMessage ?: "",                                  cfsqltype: "cf_sql_longvarchar" },
            ts:     { value: now(),                                                     cfsqltype: "cf_sql_timestamp"   }
          },
          { datasource: "stylemart" }
        );
      }
    }
    return arguments.asset;
  }
}
