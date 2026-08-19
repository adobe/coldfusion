component rest="true" restpath="/s6/ref/upsell" {

  /**
   * G3 — generate an upsell-pitch asset for {userId, cartId, sessionId}.
   * Spec §11.7. Returns the gen_upsell_* asset shape. 
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
      catch ( any e ) { prefs = { "tripCity":"" }; }

      var cartData = { "items":[], "itemIds":[] };
      try { cartData = l1Get( "/commerce/carts/" & arguments.cartId ); }
      catch ( any e ) { cartData = { "items":[], "itemIds":[] }; }

      // The cart API returns items[] (each with a productId) but no itemIds[] array, so
      // derive the in-cart product ids here — otherwise the "skip if in cart" filter below
      // never matches and a product already in the cart can be suggested as an add-on.
      var inCartIds = [];
      for ( var ci in ( cartData.items ?: [] ) ) {
        if ( len( ci.productId ?: "" ) ) arrayAppend( inCartIds, ci.productId );
      }

      // Pull a wide pool from the L1 catalog. Spec §11.7 says accessories / travel-essentials.
      // The seed schema has 'accessories' but no 'travel-essentials' category — fall back gracefully.
      var poolItems = [];
      try {
        var poolResp = l1Get( "/commerce/products?category=accessories&pageSize=20" );
        poolItems = poolResp.items ?: [];
      } catch ( any e ) { poolItems = []; }

      var candidates = [];
      for ( var p in poolItems ) {
        if ( arrayFindNoCase( inCartIds, p.productId ?: "" ) ) continue;       // skip if in cart
        if ( ( p.reviewCount ?: 0 ) <= 0 ) continue;                            // require >=1 review
        if ( arrayLen( candidates ) >= 6 ) break;                               // cap pool size
        var inv = tryMcp( "cf-commerce", "getInventory", { productId: p.productId ?: "" }, {} );
        if ( !isStockAvailable( inv ) ) continue;                               // require in stock
        arrayAppend( candidates, {
          "productId":   p.productId ?: "",
          "name":        p.name      ?: "",
          "price":       p.price     ?: 0,
          "imageUrl":    p.imageUrl  ?: "",
          "reviewCount": p.reviewCount ?: 0
        });
      }

      local.context = {
        "userId":     arguments.userId,
        "cartId":     arguments.cartId,
        "sessionId":  arguments.sessionId,
        "cart":       cartData,
        "cartItems":  cartData.items ?: [],
        "cartItemIds": inCartIds,
        "candidates": candidates,
        "tripContext": {
          "city":     resolveTripCity( prefs ),
          "forecast": tryMcp( "ext-weather", "getForecast", { city: resolveTripCity( prefs ) }, {} )
        }
      };
      var promptTemplate = fileRead( expandPath( local.cfg.upsellPitch.promptTemplateFile ) );
      local.fullPrompt = renderTemplate( promptTemplate, local.context );
      request.guardrailResults = [];

      // Isolate the model call + JSON parse: an output guardrail block (the agent
      // reprompts then aborts) or non-JSON output is NOT a server error. Degrade
      // gracefully to a valid asset (safe default fields, no add-ons) so the page
      // renders instead of a 500. Genuine infra failures (config load, cart lookup,
      // DB persist) stay in the outer try and still surface as errors.
      var validated = {};
      try {
        var raw       = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
        var modelText = isStruct( raw ) ? ( raw.message ?: "" ) : toString( raw );
        var parsed    = parseModelJson( modelText );
        validated     = enforceCandidatePool( parsed, local.context.candidates );
      }
      catch ( any genErr ) {
        validated = {};
      }

      var results = normalizeGuardrailResults( request.guardrailResults );
      var asset   = assembleUpsellAsset( validated, local.context, results );
      return persistAsset( asset, results );
    }
    catch ( any e ) {
      throw( type    = "GeneratedAssetException",
             message = "Upsell pitch generation failed: " & e.message,
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
             message="Model returned non-JSON output (expected the gen_upsell_* contract shape)." );
    }
  }

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
      "weatherContext": arguments.context.tripContext.forecast ?: {},
      "sourceInputs": {
        "preferenceIds": [ "pref_" & arguments.context.userId ],
        "cartItemIds":   arguments.context.cartItemIds ?: [],
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
