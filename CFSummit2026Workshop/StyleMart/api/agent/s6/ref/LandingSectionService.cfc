component rest="true" restpath="/s6/ref/landing" {

  /**
   * G2 — generate a landing-section asset for {userId, cartId, sessionId}.
   * Spec §11.6. Returns the gen_landing_* asset shape. 
   */
  remote struct function generate(
    required string userId    restargsource="form",
    required string cartId    restargsource="form",
    required string sessionId restargsource="form"
  ) httpmethod="POST" restpath="generate" produces="application/json" {

    guardRequest( arguments.userId, arguments.cartId, arguments.sessionId );

    try {
      local.cfg = loadS6Config();

      var prefs = {};
      try { prefs = l1Get( "/commerce/users/" & arguments.userId & "/preferences" ); }
      catch ( any e ) { prefs = { "firstName":"there", "email":"draft@stylemart.example", "tripCity":"" }; }

      var cartData = { "items":[], "itemIds":[] };
      try { cartData = l1Get( "/commerce/carts/" & arguments.cartId ); }
      catch ( any e ) { cartData = { "items":[], "itemIds":[] }; }

      var verified = [];
      var swaps    = [];
      for ( var item in cartData.items ?: [] ) {
        var inv = tryMcp( "cf-commerce", "getInventory", { productId: item.productId ?: "" }, {} );
        if ( isStockAvailable( inv ) ) {
          arrayAppend( verified, item );
        } else {
          arrayAppend( swaps, suggestSwap( item, inv ) );
        }
      }

      local.context = {
        "userId":          arguments.userId,
        "cartId":          arguments.cartId,
        "sessionId":       arguments.sessionId,
        "preferences":     prefs,
        "cart":            { "items": verified, "itemIds": verified.map( (i) => i.productId ?: "" ) },
        "outOfStockSwaps": swaps,
        "tripContext":     {
          "city":     resolveTripCity( prefs ),
          "month":    monthAsName( now() ),
          "forecast": tryMcp( "ext-weather", "getForecast", { city: resolveTripCity( prefs ) }, {} )
        }
      };
      // Carry the email's value story (loyalty + coupon + total) through to the page.
      local.context.pricing = buildPricing( cartData, prefs, arguments.userId );
      var promptTemplate = fileRead( expandPath( local.cfg.landingSection.promptTemplateFile ) );
      local.fullPrompt = renderTemplate( promptTemplate, local.context );
      request.guardrailResults = [];

      // Isolate the model call + JSON parse: an output guardrail block (the agent
      // reprompts then aborts) or non-JSON output is NOT a server error. Degrade
      // gracefully to a valid asset (safe default text fields + the real cart items)
      // so the page renders instead of a 500. Genuine infra failures (config load,
      // cart lookup, DB persist) stay in the outer try and still surface as errors.
      var parsed = {};
      try {
        var raw       = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
        var modelText = isStruct( raw ) ? ( raw.message ?: "" ) : toString( raw );
        parsed        = parseModelJson( modelText );
      }
      catch ( any genErr ) {
        parsed = {};
      }

      var results = normalizeGuardrailResults( request.guardrailResults );
      var asset   = assembleLandingAsset( parsed, local.context, results );
      asset       = embedUpsell( asset, local.context );
      return persistAsset( asset, results );
    }
    catch ( any e ) {
      throw( type    = "GeneratedAssetException",
             message = "Landing section generation failed: " & e.message,
             extendedInfo = e.type );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  //  Helpers — same as lab, with MODE="ref".
  // ──────────────────────────────────────────────────────────────────────────────

  variables.MODE = "ref";

  private struct function loadS6Config() {
    var configDir = getDirectoryFromPath( getCurrentTemplatePath() ) & "../config/";
    var raw = fileRead( configDir & "ai.ref.json" );
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
      if ( arguments.toolName == "getForecast" ) {
        return forecastViaMcp( arguments.args.city ?: "" );
      }
      var mcp = createObject( "component", "api.agent.s6." & variables.MODE & ".mcp.CommerceOpsServer" );
      if ( arguments.toolName == "getInventory"       && structKeyExists( mcp, "getInventory"       ) ) return mcp.getInventory(       argumentCollection = arguments.args );
      if ( arguments.toolName == "getEligibleCoupons" && structKeyExists( mcp, "getEligibleCoupons" ) ) return mcp.getEligibleCoupons( argumentCollection = arguments.args );
      return arguments.fallback;
    } catch ( any e ) { return arguments.fallback; }
  }

  /**
   * Fetch the current forecast for a city from the live weather MCP server
   * (tool getWeatherForecastByCity — Open-Meteo, global). The tool returns a JSON string
   * in the standard {content:[{text}]} envelope; we parse it. Empty struct on failure.
   */
  private struct function forecastViaMcp( required string city ) {
    if ( !len( trim( arguments.city ) ) ) return {};
    var client = weatherMcpClient();
    if ( isNull( client ) ) return {};
    var res = client.callTool( { "name": "getWeatherForecastByCity", "arguments": { "city": arguments.city } } );
    if ( isStruct( res ) && isArray( res.content ?: "" ) && arrayLen( res.content ) ) {
      var txt = res.content[ 1 ].text ?: "";
      if ( len( txt ) ) return deserializeJSON( txt );
    }
    return {};
  }

  /** Lazily create + cache (application scope) the stdio weather MCP client. */
  private any function weatherMcpClient() {
    if ( structKeyExists( application, "s6WeatherMcpClient" ) ) return application.s6WeatherMcpClient;
    lock name="s6WeatherMcpInit" type="exclusive" timeout="15" {
      if ( !structKeyExists( application, "s6WeatherMcpClient" ) ) {
        var rawPath    = getDirectoryFromPath( getCurrentTemplatePath() ) & "../config/schema/weather-mcp.json";
        var configPath = createObject( "java", "java.io.File" ).init( rawPath ).getCanonicalPath();
        var clients    = MCPClient( { configFile: configPath } );
        if ( !isArray( clients ) ) clients = [ clients ];
        if ( arrayLen( clients ) ) application.s6WeatherMcpClient = clients[ 1 ];
      }
    }
    return application.s6WeatherMcpClient ?: javacast( "null", "" );
  }

  // Workshop persona is a London trip; deterministic fallback for the weather demo.
  variables.DEFAULT_TRIP_CITY = "London";

  /**
   * Resolve the shopper's trip city. Unwraps the nested preferences struct, accepts an
   * explicit tripCity, scans occasion/destination/climate for a known city, then falls
   * back to the workshop's canonical London trip.
   */
  private string function resolveTripCity( required struct prefs ) {
    var p = isStruct( arguments.prefs.preferences ?: "" ) ? arguments.prefs.preferences : arguments.prefs;
    if ( len( trim( p.tripCity ?: "" ) ) ) return trim( p.tripCity );
    var haystack = lCase( ( p.occasion ?: "" ) & " " & ( p.destination ?: "" ) & " " & ( p.climate ?: "" ) );
    var cities = [ "London", "Paris", "New York", "Tokyo", "Berlin", "Varanasi", "Mumbai" ];
    for ( var c in cities ) {
      if ( findNoCase( c, haystack ) ) return c;
    }
    return variables.DEFAULT_TRIP_CITY;
  }

  private boolean function isStockAvailable( required any inv ) {
    if ( !isStruct( arguments.inv ) ) return true;
    if ( structKeyExists( arguments.inv, "anyInStock" ) ) return arguments.inv.anyInStock;
    if ( structKeyExists( arguments.inv, "variants" )  && isArray( arguments.inv.variants ) ) {
      return arguments.inv.variants.some( (v) => v.inStock ?: false );
    }
    return true;
  }

  private struct function suggestSwap( required struct item, required any inv ) {
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
   * model only authors the copy. We build items from the cart (server-controlled
   * name/price/image) and attach the model's per-item evidence by productId. This
   * is the landing's equivalent of the upsell's enforceCandidatePool().
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

  /**
   * Build the pricing summary from the cart (subtotal/discount/total/coupon) plus the
   * shopper's loyalty tier (best-effort). Mirrors the recovery email's value line.
   */
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

    var vectorStores = application.ragVectorStoresRef ?: {};
    if ( !structIsEmpty( vectorStores ) ) {
      var contentRetrievers = [];
      if ( structKeyExists( vectorStores, "policy" ) ) {
        arrayAppend( contentRetrievers, {
          vectorStore: vectorStores.policy,
          maxResults: 6,
          minScore: 0.4,
          description: "Store policies: returns, exchanges, refunds, shipping costs, sale item restrictions, gift returns, size guides, care instructions"
        } );
      }
      if ( structKeyExists( vectorStores, "catalog" ) ) {
        arrayAppend( contentRetrievers, {
          vectorStore: vectorStores.catalog,
          maxResults: 3,
          minScore: 0.6,
          description: "Product catalog with names, descriptions, prices, materials, available sizes and colors"
        } );
      }
      if ( structKeyExists( vectorStores, "reviews" ) ) {
        arrayAppend( contentRetrievers, {
          vectorStore: vectorStores.reviews,
          maxResults: 3,
          minScore: 0.6,
          description: "Customer product reviews with ratings, review text, and purchase verification"
        } );
      }
      if ( structKeyExists( vectorStores, "orders" ) ) {
        arrayAppend( contentRetrievers, {
          vectorStore: vectorStores.orders,
          maxResults: 2,
          minScore: 0.5,
          description: "Order history and purchase records for the current user"
        } );
      }

      agentConfig.retrievalAugmentor = {
        queryRouter: {
          type: "languageModel",
          contentRetrievers: contentRetrievers,
          routingModel: model
        },
        contentInjector: {
          // Generation services need strict JSON output, so we must NOT reuse the
          // conversational chat contentInjectorTemplate (which reframes the prompt as
          // a "User question" to answer in prose and breaks the gen_* contract).
          // Prepend retrieved context and keep the original prompt — which ends with
          // "Output JSON only" — as the final, dominant instruction.
          promptTemplate: "--- RETRIEVED REVIEW CONTEXT (cite relevant items by file_name) ---
{{contents}}
--- END CONTEXT ---

{{userMessage}}",
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
             message="Model returned non-JSON output (expected the gen_landing_* contract shape)." );
    }
  }

  /**
   * Server-side merge of the former Asset 3 (Upsell Pitch). Reuses UpsellPitchService
   * as the single source of truth for add-ons and embeds them into the landing asset,
   * so the client renders the capsule AND the suggested add-ons from ONE response.
   * Best-effort: an upsell failure/block never fails the landing — it just yields an
   * empty add-ons list.
   */
  private struct function embedUpsell( required struct asset, required struct context ) {
    try {
      var up = createObject( "component", "api.agent.s6.ref.UpsellPitchService" )
                 .generate( arguments.context.userId, arguments.context.cartId, arguments.context.sessionId );
      arguments.asset[ "addOns" ]          = up.addOns ?: [];
      arguments.asset[ "addOnsTotal" ]     = up.totalAdded ?: 0;
      arguments.asset[ "addOnsChips" ]     = up.rationaleChips ?: [];
      arguments.asset[ "addOnsGuardrails" ] = up.guardrailResults ?: [];
    }
    catch ( any e ) {
      arguments.asset[ "addOns" ]      = [];
      arguments.asset[ "addOnsTotal" ] = 0;
      arguments.asset[ "addOnsChips" ] = [];
      arguments.asset[ "addOnsGuardrails" ] = [];
    }
    return arguments.asset;
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
      "weatherContext": arguments.context.tripContext.forecast ?: {},
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
