component rest="true" restpath="/s6/lab/upsell" {

  /**
   * G3 — generate an upsell-pitch asset for {userId, cartId, sessionId}.
   * Spec §11.7. Returns the gen_upsell_* asset shape.
   *
   * Lab skeleton — three TODO blocks (UP1/UP2/UP3) for attendees to fill.
   */
  remote struct function generate(
    required string userId    restargsource="form",
    required string cartId    restargsource="form",
    required string sessionId restargsource="form"
  ) httpmethod="POST" restpath="generate" produces="application/json" {

    guardRequest( arguments.userId, arguments.cartId, arguments.sessionId );

    try {
      // ===== ATTENDEE TODO ZONE =================================================

      // TODO-S6-11a: Build a candidate pool of in-stock, not-in-cart products
      //               in `accessories` / `travel-essentials` with >=1 review.
      //   local.cfg     = loadS6Config();
      //   var prefs     = l1Get("/commerce/users/" & arguments.userId & "/preferences");
      //   var cartData  = l1Get("/commerce/carts/" & arguments.cartId);
      //   var inCartIds = cartData.itemIds ?: [];
      //   var poolRaw   = l1Get("/commerce/products?category=accessories&pageSize=20");
      //   var pool      = poolRaw.items
      //                     .filter( (p) => !arrayFindNoCase(inCartIds, p.productId) )
      //                     .filter( (p) => (p.reviewCount ?: 0) > 0 );
      //   var candidates = [];
      //   for ( var p in pool ) {
      //     if ( arrayLen(candidates) >= 6 ) break;
      //     var inv = tryMcp("cf-commerce","getInventory",{productId:p.productId},{});
      //     if ( isStockAvailable(inv) ) arrayAppend(candidates, p);
      //   }
      //   local.context = {
      //     userId: arguments.userId, cartId: arguments.cartId, sessionId: arguments.sessionId,
      //     cart: cartData, cartItems: cartData.items ?: [], candidates: candidates,
      //     tripContext: { city: prefs.tripCity ?: "", forecast: tryMcp("ext-weather","getForecast",{city:prefs.tripCity ?: ""},"") }
      //   };
      local.cfg     = loadS6Config();
      local.context = {} /* TODO-S6-11a */;

      // TODO-S6-11b: Render the upsell-pitch prompt template with the context.
      //   var promptTemplate = fileRead( expandPath( local.cfg.upsellPitch.promptTemplateFile ) );
      //   local.fullPrompt = renderTemplate( promptTemplate, local.context );
      local.fullPrompt = "" /* TODO-S6-11b */;

      // TODO-S6-11c: Invoke the SAME guardrailed agent. Validate every addOn.productId
      //               is in the candidate pool — reject hallucinated products at the
      //               service layer, even if guardrails passed.
      //   request.guardrailResults = [];
      //   var raw     = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
      //   var parsed  = parseModelJson( isStruct(raw) ? raw.message ?: "" : toString(raw) );
      //   var validated = enforceCandidatePool( parsed, local.context.candidates );  // throws if hallucinated
      //   var results = normalizeGuardrailResults( request.guardrailResults );
      //   var asset   = assembleUpsellAsset( validated, local.context, results );
      //   return persistAsset( asset, results );
      return {} /* TODO-S6-11c */;

      // ===== END ATTENDEE TODO ZONE =============================================
    }
    catch ( any e ) {
      throw( type    = "GeneratedAssetException",
             message = "Upsell pitch generation failed: " & e.message,
             extendedInfo = e.type );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  //  Helpers below — pre-wired [SCAFFOLD]. Attendees do not edit these.
  // ──────────────────────────────────────────────────────────────────────────────

  variables.MODE = "lab";

  private struct function loadS6Config() {
    var configDir = getDirectoryFromPath( getCurrentTemplatePath() ) & "../config/";
    var raw = fileRead( configDir & "ai.lab.json" );
    var cfg = deserializeJSON( raw );
    cfg._configDir = configDir;
    return cfg;
  }

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
  }

  private struct function l1Get( required string path ) {
    var url  = "http://localhost:8500/api" & arguments.path;
    cfhttp( method="GET", url=url, result="local.resp", timeout=5 );
    var resp = local.resp;
    if ( resp.statusCode contains "200" ) return deserializeJSON( resp.fileContent );
    throw( type="ProblemException", errorCode="upstream_failure",
           message="L1 self-call failed: " & arguments.path & " -> " & resp.statusCode );
  }

  private any function tryMcp( required string server, required string toolName, required struct args, any fallback="" ) {
    try {
      var mcp = createObject( "component", "api.agent.s6." & variables.MODE & ".mcp.CommerceOpsServer" );
      if ( arguments.toolName == "getInventory"       && structKeyExists( mcp, "getInventory"       ) ) return mcp.getInventory(       argumentCollection = arguments.args );
      if ( arguments.toolName == "getEligibleCoupons" && structKeyExists( mcp, "getEligibleCoupons" ) ) return mcp.getEligibleCoupons( argumentCollection = arguments.args );
      return arguments.fallback;
    } catch ( any e ) { return arguments.fallback; }
  }

  private boolean function isStockAvailable( required any inv ) {
    if ( !isStruct( arguments.inv ) ) return true;
    if ( structKeyExists( arguments.inv, "anyInStock" ) ) return arguments.inv.anyInStock;
    if ( structKeyExists( arguments.inv, "variants" ) && isArray( arguments.inv.variants ) ) {
      return arguments.inv.variants.some( (v) => v.inStock ?: false );
    }
    return true;
  }

  private string function renderTemplate( required string template, required struct context ) {
    var rendered = arguments.template;
    rendered = replace( rendered, "{{cartItems}}",   serializeJSON( arguments.context.cartItems   ?: [] ), "all" );
    rendered = replace( rendered, "{{candidates}}",  serializeJSON( arguments.context.candidates  ?: [] ), "all" );
    rendered = replace( rendered, "{{tripContext}}", serializeJSON( arguments.context.tripContext ?: {} ), "all" );
    return rendered;
  }

  private struct function agentConfigForGeneration() {
    var cfg = loadS6Config();

    var model = ChatModel({
      PROVIDER:    cfg.provider,
      APIKEY:      application.OPENAI_API_KEY,
      BASEURL:     cfg.baseUrl ?: "",
      MODELNAME:   cfg.modelName,
      TEMPERATURE: cfg.upsellPitch.temperature ?: 0.6,
      TOPP:        cfg.topP ?: 0.9,
      MAXTOKENS:   cfg.upsellPitch.maxTokens ?: 600
    });

    var agentConfig = {
      CHATMODEL:  model,
      CHATMEMORY: {
        TYPE: cfg.chatMemory.type ?: "messageWindowChatMemory",
        MAXMESSAGES: cfg.chatMemory.maxMessages ?: 20,
        PERUSER: cfg.chatMemory.perUser ?: true
      }
    };

    var guardBase = "/api/agent/s6/" & variables.MODE & "/";
    if ( structKeyExists( cfg, "guardrails" ) ) {
      if ( isArray( cfg.guardrails.input ?: [] ) ) {
        agentConfig.INPUTGUARDRAILS = cfg.guardrails.input.map( (p) => expandPath( guardBase & p ) );
      }
      if ( isArray( cfg.guardrails.output ?: [] ) ) {
        agentConfig.OUTPUTGUARDRAILS = cfg.guardrails.output.map( (p) => expandPath( guardBase & p ) );
      }
    }

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
             message="Model returned non-JSON output (expected the gen_upsell_* contract shape)." );
    }
  }

  /**
   * Reject hallucinated productIds at the service layer (spec §11.7 trust-but-verify).
   * If the model picks any productId not in {{candidates}}, throw — guardrails are
   * NOT a substitute for output-schema enforcement.
   */
  private struct function enforceCandidatePool( required struct parsed, required array candidates ) {
    var poolIds = [];
    for ( var c in arguments.candidates ) arrayAppend( poolIds, c.productId ?: "" );
    var addOns = arguments.parsed.addOns ?: [];
    if ( !isArray( addOns ) || arrayLen( addOns ) != 3 ) {
      throw( type="UpsellShapeException",
             message="addOns must have exactly 3 entries (got " & arrayLen( addOns ) & ")." );
    }
    for ( var a in addOns ) {
      if ( !arrayFindNoCase( poolIds, a.productId ?: "" ) ) {
        throw( type="UpsellHallucinationException",
               message="Model picked productId '" & ( a.productId ?: "<empty>" ) & "' which is not in the candidate pool." );
      }
    }
    return arguments.parsed;
  }

  private struct function assembleUpsellAsset(
    required struct parsed,
    required struct context,
    required array  guardrailResults
  ) {
    var addOns = arguments.parsed.addOns ?: [];
    var totalAdded = 0;
    for ( var a in addOns ) totalAdded += ( a.price ?: 0 );

    return {
      "assetId":        "gen_upsell_" & arguments.context.userId & "_" & lCase( replace( createUUID(), "-", "", "all" ) ),
      "type":           "upsell-pitch",
      "sessionId":      arguments.context.sessionId,
      "cartId":         arguments.context.cartId,
      "userId":         arguments.context.userId,
      "title":          arguments.parsed.title ?: "Complete your capsule",
      "addOns":         addOns,
      "rationaleChips": arguments.parsed.rationaleChips ?: ["reviews"],
      "totalAdded":     totalAdded,
      "loyaltyApplied": true,
      "sourceInputs": {
        "preferenceIds": [ "pref_" & arguments.context.userId ],
        "cartItemIds":   arguments.context.cart.itemIds ?: [],
        "ragSourceIds":  arguments.parsed.citedSourceIds ?: [],
        "mcpToolCalls":  arguments.parsed.usedMcpCalls   ?: []
      },
      "guardrailResults": arguments.guardrailResults,
      "createdAt":      dateTimeFormat( now(), "iso8601" )
    };
  }

  private struct function persistAsset( required struct asset, required array guardrailResults ) {
    transaction {
      queryExecute(
        "INSERT INTO generated_assets (asset_id, type, session_id, user_id, cart_id,
                                       body_html, source_inputs, guardrail_results, created_at)
         VALUES (:aid, :type, :sid, :uid, :cid, :body, :srcs, :grs, :ts)",
        {
          aid:  { value: arguments.asset.assetId,                          cfsqltype: "cf_sql_varchar"     },
          type: { value: arguments.asset.type,                             cfsqltype: "cf_sql_varchar"     },
          sid:  { value: arguments.asset.sessionId,                        cfsqltype: "cf_sql_varchar"     },
          uid:  { value: arguments.asset.userId,                           cfsqltype: "cf_sql_varchar"     },
          cid:  { value: arguments.asset.cartId,                           cfsqltype: "cf_sql_varchar"     },
          body: { value: serializeJSON( arguments.asset ),                 cfsqltype: "cf_sql_longvarchar" },
          srcs: { value: serializeJSON( arguments.asset.sourceInputs ),    cfsqltype: "cf_sql_longvarchar" },
          grs:  { value: serializeJSON( arguments.guardrailResults ),      cfsqltype: "cf_sql_longvarchar" },
          ts:   { value: now(),                                            cfsqltype: "cf_sql_timestamp"   }
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
            rid:    { value: gr.rule,                                                  cfsqltype: "cf_sql_varchar"     },
            phase:  { value: "output",                                                 cfsqltype: "cf_sql_varchar"     },
            result: { value: gr.result ?: ( gr.passed ? "success" : "failure" ),       cfsqltype: "cf_sql_varchar"     },
            msg:    { value: gr.message ?: "",                                         cfsqltype: "cf_sql_longvarchar" },
            rep:    { value: gr.repromptMessage ?: "",                                 cfsqltype: "cf_sql_longvarchar" },
            ts:     { value: now(),                                                    cfsqltype: "cf_sql_timestamp"   }
          },
          { datasource: "stylemart" }
        );
      }
    }
    return arguments.asset;
  }
}
