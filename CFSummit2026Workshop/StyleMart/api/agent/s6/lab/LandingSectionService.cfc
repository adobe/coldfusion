component rest="true" restpath="/s6/lab/landing" {

  /**
   * G2 — generate a landing-section asset for {userId, cartId, sessionId}.
   * Spec §11.6. Returns the gen_landing_* asset shape.
   *
   * Lab skeleton — three TODO blocks (LS1/LS2/LS3) for attendees to fill.
   * Helpers below are pre-wired [SCAFFOLD] and not attendee-edited.
   */
  remote struct function generate(
    required string userId    restargsource="form",
    required string cartId    restargsource="form",
    required string sessionId restargsource="form"
  ) httpmethod="POST" restpath="generate" produces="application/json" {

    guardRequest( arguments.userId, arguments.cartId, arguments.sessionId );

    try {
      // ===== ATTENDEE TODO ZONE =================================================

      // TODO-S6-10a: Load context via Layer-1 REST self-calls and verify in-stock.
      //   For each cart item: MCP getInventory; drop out-of-stock; record swap suggestions.
      //
      //   local.cfg = loadS6Config();
      //   var prefs = l1Get("/commerce/users/" & arguments.userId & "/preferences");
      //   var cartData = l1Get("/commerce/carts/" & arguments.cartId);
      //   var verified = []; var swaps = [];
      //   for ( var item in cartData.items ?: [] ) {
      //     var inv = tryMcp("cf-commerce","getInventory",{productId:item.productId},{});
      //     if ( isStockAvailable(inv) ) arrayAppend(verified,item);
      //     else                          arrayAppend(swaps, suggestSwap(item, inv));
      //   }
      //   local.context = {
      //     userId: arguments.userId, cartId: arguments.cartId, sessionId: arguments.sessionId,
      //     preferences: prefs,
      //     cart:        { items: verified, itemIds: verified.map((i)=>i.productId) },
      //     outOfStockSwaps: swaps,
      //     tripContext: { city: prefs.tripCity ?: "", month: monthAsName(now()),
      //                    forecast: tryMcp("ext-weather","getForecast",{city:prefs.tripCity ?: ""},"") }
      //   };
      local.cfg     = loadS6Config();
      local.context = {} /* TODO-S6-10a */;

      // TODO-S6-10b: Render the landing-section prompt template with the context.
      //   var promptTemplate = fileRead( expandPath( local.cfg.landingSection.promptTemplateFile ) );
      //   local.fullPrompt = renderTemplate( promptTemplate, local.context );
      local.fullPrompt = "" /* TODO-S6-10b */;

      // TODO-S6-10c: Invoke the SAME guardrailed agent used by ChatService.
      //   request.guardrailResults = [];
      //   var raw     = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
      //   var parsed  = parseModelJson( isStruct(raw) ? raw.message ?: "" : toString(raw) );
      //   var results = normalizeGuardrailResults( request.guardrailResults );
      //   var asset   = assembleLandingAsset( parsed, local.context, results );
      //   return persistAsset( asset, results );
      return {} /* TODO-S6-10c */;

      // ===== END ATTENDEE TODO ZONE =============================================
    }
    catch ( any e ) {
      throw( type    = "GeneratedAssetException",
             message = "Landing section generation failed: " & e.message,
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
    if ( !isStruct( arguments.inv ) ) return true; // fallback: optimistic
    if ( structKeyExists( arguments.inv, "anyInStock" ) ) return arguments.inv.anyInStock;
    if ( structKeyExists( arguments.inv, "variants" )  && isArray( arguments.inv.variants ) ) {
      return arguments.inv.variants.some( (v) => v.inStock ?: false );
    }
    return true; // unknown shape: don't block the page
  }

  private struct function suggestSwap( required struct item, required any inv ) {
    // Minimal workshop fallback: same productId, no specific swap variant.
    return {
      "original":     arguments.item.productId ?: "",
      "originalName": arguments.item.name      ?: "",
      "imageUrl":     arguments.item.imageUrl  ?: "",
      "suggested":    "",
      "reason":       "out-of-stock"
    };
  }

  /**
   * The landing's product list must be a 1:1 reflection of the verified cart — the
   * model only authors the copy. Build items from the cart (server-controlled
   * name/price/image) and attach the model's per-item evidence by productId.
   */
  private array function buildLandingItems( required array verified, required any parsedItems ) {
    var evidenceByPid = {};
    if ( isArray( arguments.parsedItems ) ) {
      for ( var pi in arguments.parsedItems ) {
        var pid = pi.productId ?: "";
        if ( len( pid ) ) {
          evidenceByPid[ pid ] = isArray( pi.evidence ?: "" ) ? pi.evidence : [];
        }
      }
    }
    var out = [];
    for ( var it in arguments.verified ) {
      var cartPid = it.productId ?: "";
      arrayAppend( out, {
        "productId": cartPid,
        "name":      it.name     ?: "",
        "price":     it.unitPrice ?: ( it.price ?: 0 ),
        "imageUrl":  it.imageUrl ?: "",
        "size":      it.size     ?: "",
        "color":     it.color    ?: "",
        "quantity":  it.quantity ?: 1,
        "evidence":  ( structKeyExists( evidenceByPid, cartPid ) && arrayLen( evidenceByPid[ cartPid ] ) )
                       ? evidenceByPid[ cartPid ] : [ "reviews" ]
      } );
    }
    return out;
  }

  private struct function buildPricing( required any cartData, required struct prefs, required string userId ) {
    var couponCode = "";
    if ( isStruct( arguments.cartData ) && structKeyExists( arguments.cartData, "appliedCoupon" )
         && isStruct( arguments.cartData.appliedCoupon ) ) {
      couponCode = arguments.cartData.appliedCoupon.code ?: "";
    }
    var loyaltyTier = arguments.prefs.loyaltyTier ?: "";
    if ( !len( loyaltyTier ) ) {
      try {
        var loy = l1Get( "/commerce/users/" & arguments.userId & "/loyalty" );
        loyaltyTier = loy.tierName ?: ( loy.name ?: "" );
      } catch ( any e ) { loyaltyTier = ""; }
    }
    return {
      "subtotal":      arguments.cartData.subtotal      ?: 0,
      "discountTotal": arguments.cartData.discountTotal ?: 0,
      "total":         arguments.cartData.total         ?: 0,
      "currency":      arguments.cartData.currency      ?: "USD",
      "couponCode":    couponCode,
      "loyaltyTier":   loyaltyTier
    };
  }

  private string function monthAsName( required date d ) {
    return dateFormat( arguments.d, "mmmm" );
  }

  private string function renderTemplate( required string template, required struct context ) {
    var rendered = arguments.template;
    rendered = replace( rendered, "{{preferences}}",     serializeJSON( arguments.context.preferences ?: {} ),     "all" );
    rendered = replace( rendered, "{{cart}}",            serializeJSON( arguments.context.cart ?: {} ),            "all" );
    rendered = replace( rendered, "{{outOfStockSwaps}}", serializeJSON( arguments.context.outOfStockSwaps ?: [] ), "all" );
    rendered = replace( rendered, "{{tripContext}}",     serializeJSON( arguments.context.tripContext ?: {} ),     "all" );
    return rendered;
  }

  private struct function agentConfigForGeneration() {
    var cfg = loadS6Config();

    var model = ChatModel({
      PROVIDER:    cfg.provider,
      APIKEY:      application.OPENAI_API_KEY,
      BASEURL:     cfg.baseUrl ?: "",
      MODELNAME:   cfg.modelName,
      TEMPERATURE: cfg.landingSection.temperature ?: 0.5,
      TOPP:        cfg.topP ?: 0.9,
      MAXTOKENS:   cfg.landingSection.maxTokens ?: 700
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

  /**
   * Spec §11.4 + asset contract: every gen_landing_* must carry the same 3 base output
   * guardrail rows as the recovery email PLUS the new no-misleading-scarcity outcome.
   * Anything outside REQUIRED is dropped from the asset — but still ran by agent().
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
             message="Model returned non-JSON output (expected the gen_landing_* contract shape)." );
    }
  }

  private struct function assembleLandingAsset(
    required struct parsed,
    required struct context,
    required array  guardrailResults
  ) {
    return {
      "assetId":     "gen_landing_" & arguments.context.userId & "_" & lCase( replace( createUUID(), "-", "", "all" ) ),
      "type":        "landing-section",
      "sessionId":   arguments.context.sessionId,
      "cartId":      arguments.context.cartId,
      "userId":      arguments.context.userId,
      "title":       arguments.parsed.title       ?: "Your Saved Capsule",
      "subtitle":    arguments.parsed.subtitle    ?: "",
      "rationale":   arguments.parsed.rationale   ?: "",
      "items":       buildLandingItems( arguments.context.cart.items ?: [], arguments.parsed.items ?: [] ),
      "pricing":     arguments.context.pricing ?: {},
      "outOfStockSwaps": arguments.context.outOfStockSwaps ?: [],
      "sourceInputs": {
        "preferenceIds": [ "pref_" & arguments.context.userId ],
        "cartItemIds":   arguments.context.cart.itemIds       ?: [],
        "ragSourceIds":  arguments.parsed.citedSourceIds      ?: [],
        "mcpToolCalls":  arguments.parsed.usedMcpCalls        ?: []
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
