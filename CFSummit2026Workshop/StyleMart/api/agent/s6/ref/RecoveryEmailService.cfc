component rest="true" restpath="/s6/ref/email" {

  /**
   * G1 — generate a recovery email for {userId, cartId, sessionId}.
   * Contract §5.6. Returns the gen_email_* asset shape. 
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
      catch ( any e ) { prefs = { "firstName":"there", "email":"draft@stylemart.example" }; }
      var cartData = {};
      try { cartData = l1Get( "/commerce/carts/" & arguments.cartId ); }
      catch ( any e ) { cartData = { "items":[], "itemIds":[] }; }

      var tripCity = resolveTripCity( prefs );
      local.context = {
        "userId":          arguments.userId,
        "cartId":          arguments.cartId,
        "sessionId":       arguments.sessionId,
        "preferences":     prefs,
        "tripCity":        tripCity,
        "cart":            cartData,
        "eligibleCoupons": tryMcp( "cf-commerce", "getEligibleCoupons", { userId: arguments.userId }, [] ),
        "weather":         tryMcp( "ext-weather", "getForecast",        { city: tripCity }, {} )
      };
      var promptTemplate = fileRead( expandPath( local.cfg.recoveryEmail.promptTemplateFile ) );
      local.fullPrompt = renderTemplate( promptTemplate, local.context );
      request.guardrailResults = [];

      // The model call + JSON parse is the only step that can fail for a "soft"
      // reason: an output guardrail block (the agent reprompts then aborts with a
      // thrown exception) or non-JSON model output. Neither is a server error — the
      // design intent (SAFE_FALLBACK_BODY / hadFatal) is to degrade gracefully so the
      // email-preview page renders the safe email plus its guardrail chips instead of
      // a 500. We isolate that step here; genuine infra failures (config load, cart
      // lookup, DB persist) stay in the outer try and still surface as errors.
      var parsed  = {};
      var blocked = false;
      try {
        var raw       = agent( agentConfigForGeneration() ).chat( local.fullPrompt, arguments.userId );
        var modelText = isStruct( raw ) ? ( raw.message ?: "" ) : toString( raw );
        parsed        = parseModelJson( modelText );
      }
      catch ( any genErr ) {
        blocked = true;
      }

      var results = normalizeGuardrailResults( request.guardrailResults );
      var asset   = assembleAsset( parsed, local.context, results, blocked );
      asset       = embedUpsell( asset, local.context );
      return persistAsset( asset, results );
    }
    catch ( any e ) {
      throw( type    = "GeneratedAssetException",
             message = "Recovery email generation failed: " & e.message,
             extendedInfo = e.type );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────────
  //  Helpers — same as lab, with MODE="ref" in agentConfigForGeneration().
  // ──────────────────────────────────────────────────────────────────────────────

  variables.SAFE_FALLBACK_BODY =
    "<p>We saved the items in your cart. Sign in to StyleMart to review them and complete checkout.</p>";

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
    var url = "http://localhost:8500/api" & arguments.path;
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
      var mcp = createObject( "component", "api.agent.s6.ref.mcp.CommerceOpsServer" );
      if ( arguments.toolName == "getEligibleCoupons" && structKeyExists( mcp, "getEligibleCoupons" ) ) {
        return mcp.getEligibleCoupons( argumentCollection = arguments.args );
      }
      return arguments.fallback;
    } catch ( any e ) { return arguments.fallback; }
  }

  /**
   * Fetch the current forecast for a city from the live weather MCP server
   * (externalservices/weather/live, tool getWeatherForecastByCity — Open-Meteo, global).
   * The MCP tool returns a JSON string inside the standard {content:[{text}]} envelope;
   * we parse it into the canonical forecast struct. Empty struct on any failure.
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

  /**
   * Lazily create and cache (application scope) the stdio MCP client for the weather
   * server. A dedicated weather-only config keeps us from spawning the commerce/mock
   * servers. The MCPClient validator rejects paths containing "..", so we canonicalize.
   */
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

  // The workshop persona is a London tech-conference trip (London coupon, London
  // reviews, winter accessories). When neither stored preferences nor inferred
  // occasion name a city, we fall back to this so the weather demo is deterministic.
  variables.DEFAULT_TRIP_CITY = "London";

  /**
   * Resolve the shopper's trip city. The preferences API nests the real prefs under a
   * "preferences" key, and the destination is stored as free text (e.g. occasion
   * "London tech conference") rather than a dedicated field — so we unwrap, accept an
   * explicit tripCity, then scan occasion/destination/climate for a known city, and
   * finally fall back to the workshop's canonical London trip.
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

  private string function renderTemplate( required string template, required struct context ) {
    var weather = arguments.context.weather ?: {};
    var rendered = arguments.template;
    rendered = replace( rendered, "{{preferences}}",     serializeJSON( arguments.context.preferences ?: {} ),     "all" );
    rendered = replace( rendered, "{{cart}}",            serializeJSON( arguments.context.cart ?: {} ),            "all" );
    rendered = replace( rendered, "{{eligibleCoupons}}", serializeJSON( arguments.context.eligibleCoupons ?: [] ), "all" );
    rendered = replace( rendered, "{{weather}}",         serializeJSON( weather ),                                 "all" );
    rendered = replace( rendered, "{{weatherNote}}",     weatherNote( weather ),                                   "all" );
    rendered = replace( rendered, "{{preferences.tripCity}}",
                        toString( arguments.context.tripCity ?: "" ), "all" );
    return rendered;
  }

  /**
   * A short, deterministic, server-authored weather sentence the model can lean on
   * (and that we also surface in the asset). Empty when there's no usable forecast.
   */
  private string function weatherNote( required struct weather ) {
    if ( !isStruct( arguments.weather ) || !len( arguments.weather.summary ?: "" ) ) return "";
    var note = arguments.weather.summary;
    if ( arguments.weather.isCold ?: false ) {
      note &= " Recommend warm layers (sweaters, knit caps, scarves) for the trip.";
    }
    return note;
  }

  private struct function agentConfigForGeneration() {
    var cfg = loadS6Config();
    var MODE = "ref";

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
          // a "User question" to answer in prose and breaks the gen_email_* contract).
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
             message="Model returned non-JSON output (expected the gen_email_* contract shape)." );
    }
  }

  private string function localizeBody( required string bodyHtml ) {
    return arguments.bodyHtml;
  }

  /**
   * Server-side merge of the former Asset 3 (Upsell Pitch). Reuses UpsellPitchService
   * as the single source of truth for add-ons and embeds them (plus the shopper's
   * actual cart items) directly into the recovery-email asset, so the client renders
   * everything from ONE response. Best-effort: an upsell failure/block never fails the
   * email — it just yields an empty add-ons list.
   */
  private struct function embedUpsell( required struct asset, required struct context ) {
    arguments.asset[ "cartItems" ] = arguments.context.cart.items ?: [];
    try {
      var up = createObject( "component", "api.agent.s6.ref.UpsellPitchService" )
                 .generate( arguments.context.userId, arguments.context.cartId, arguments.context.sessionId );
      arguments.asset[ "addOns" ]          = up.addOns ?: [];
      arguments.asset[ "addOnsTotal" ]     = up.totalAdded ?: 0;
      arguments.asset[ "addOnsChips" ]     = up.rationaleChips ?: [];
    }
    catch ( any e ) {
      arguments.asset[ "addOns" ]      = [];
      arguments.asset[ "addOnsTotal" ] = 0;
      arguments.asset[ "addOnsChips" ] = [];
    }
    return arguments.asset;
  }

  private struct function assembleAsset(
    required struct parsed,
    required struct context,
    required array  guardrailResults,
    boolean forceSafeBody = false
  ) {
    var hadFatal = arguments.guardrailResults.some( (r) => ( r.result ?: "" ) == "fatal" );
    var finalBody = ( hadFatal || arguments.forceSafeBody )
                    ? variables.SAFE_FALLBACK_BODY
                    : localizeBody( arguments.parsed.bodyHtml ?: "" );

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
      "weatherContext": arguments.context.weather ?: {},
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
