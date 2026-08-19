component rest="true" restpath="/generated" produces="application/json" {

    remote struct function getAsset(
        required string assetId restargsource="path"
    ) httpmethod="GET" restpath="{assetId}" {
        var assets = getAssetFixtures();
        if (structKeyExists(assets, arguments.assetId)) {
            return assets[arguments.assetId];
        }
        throw(type="RestError", errorcode="404", message="Asset not found");
    }

    remote struct function generateRecoveryEmail(
        string mode = "lab" restargsource="query"
    ) httpmethod="POST" restpath="recovery-email" {

        if ( !listFindNoCase( "lab,ref", arguments.mode ) ) {
            throw( type="ProblemException", errorCode="invalid_request",
                   message="mode must be 'lab' or 'ref'." );
        }

        var body = parseRequestBody();
        var serviceName = "api.agent.s6." & arguments.mode & ".RecoveryEmailService";
        return createObject( "component", serviceName )
                  .generate( body.userId, body.cartId, body.sessionId );
    }

    private struct function parseRequestBody() {
        var raw = "";
        try { raw = toString( getHttpRequestData().content ); } catch ( any e ) { raw = ""; }
        if ( !len( raw ) ) {
            throw( type="ProblemException", errorCode="invalid_request",
                   message="Request body required: { userId, cartId, sessionId }." );
        }
        var body = {};
        try { body = deserializeJSON( raw ); }
        catch ( any e ) {
            throw( type="ProblemException", errorCode="invalid_request",
                   message="Request body must be JSON: { userId, cartId, sessionId }." );
        }
        for ( var k in [ "userId", "cartId", "sessionId" ] ) {
            if ( !structKeyExists( body, k ) || !len( body[ k ] ?: "" ) ) {
                throw( type="ProblemException", errorCode="invalid_request",
                       message="Missing field: " & k );
            }
        }
        return body;
    }

    remote struct function generateLandingSection(
        string mode = "lab" restargsource="query"
    ) httpmethod="POST" restpath="landing-section" {

        if ( !listFindNoCase( "lab,ref", arguments.mode ) ) {
            throw( type="ProblemException", errorCode="invalid_request",
                   message="mode must be 'lab' or 'ref'." );
        }

        var body = parseRequestBody();
        var serviceName = "api.agent.s6." & arguments.mode & ".LandingSectionService";
        return createObject( "component", serviceName )
                  .generate( body.userId, body.cartId, body.sessionId );
    }

    remote struct function generateUpsellPitch(
        string mode = "lab" restargsource="query"
    ) httpmethod="POST" restpath="upsell-pitch" {

        if ( !listFindNoCase( "lab,ref", arguments.mode ) ) {
            throw( type="ProblemException", errorCode="invalid_request",
                   message="mode must be 'lab' or 'ref'." );
        }

        var body = parseRequestBody();
        var serviceName = "api.agent.s6." & arguments.mode & ".UpsellPitchService";
        return createObject( "component", serviceName )
                  .generate( body.userId, body.cartId, body.sessionId );
    }

    private struct function getAssetFixtures() {
        return {
            "gen_email_jordan_london": {
                "assetId": "gen_email_jordan_london",
                "type": "recovery-email",
                "subject": "Still thinking about your London capsule?",
                "previewText": "Your wardrobe is waiting. Free returns within 30 days.",
                "fromName": "StyleMart",
                "fromEmail": "hello@stylemart.example",
                "toName": "Jordan",
                "toEmail": "jordan@example.com",
                "date": "2026-05-23T10:45:00Z",
                "bodyHtml": "<p>Hi Jordan,</p><p>You were putting together a 5-day London capsule under $500. Here's what we'd suggest:</p><ul><li>Navy travel blazer — machine-washable wool blend, in stock in size M</li><li>White cotton tee — your preferred fabric, easy-care</li><li>Dark wash 32 jeans — reviewers love these for travel</li><li>Walking sneaker — top-rated for all-day comfort</li></ul><p>Cool 8-14C with rain expected — these layer well. Free returns within 30 days.</p>",
                "sourceInputs": {
                    "preferenceIds": ["pref_usr_demo_001"],
                    "cartItemIds": ["var_01HZX01T001_M_navy", "var_01HZX01T002_M_white"],
                    "ragSourceIds": ["chunk_5", "chunk_6"],
                    "mcpToolCalls": ["mcpcall_001", "mcpcall_002"]
                },
                "guardrailResults": [
                    {"rule": "no-unsupported-fit-guarantee", "passed": true},
                    {"rule": "no-fake-discount", "passed": true},
                    {"rule": "no-pii-leak", "passed": true}
                ],
                "createdAt": "2026-05-23T10:45:00Z"
            },
            "gen_landing_jordan_london": {
                "assetId": "gen_landing_jordan_london",
                "type": "landing-section",
                "title": "Your London Capsule, Jordan",
                "subtitle": "Curated for a 5-day smart-casual conference trip.",
                "items": [
                    {"productId": "prd_01HZX01T001", "name": "Navy Travel Blazer", "price": 189, "imageUrl": "assets/img/placeholders/jacket-navy.svg", "evidence": ["reviews", "sizing", "weather"]},
                    {"productId": "prd_01HZX01T002", "name": "White Cotton Tee", "price": 32, "imageUrl": "assets/img/placeholders/tshirt-white.svg", "evidence": ["sizing", "fabric"]},
                    {"productId": "prd_01HZX01T003", "name": "Dark Wash 32 Jeans", "price": 78, "imageUrl": "assets/img/placeholders/jeans-darkwash.svg", "evidence": ["reviews", "sizing"]},
                    {"productId": "prd_01HZX01T004", "name": "Walking Sneaker", "price": 124, "imageUrl": "assets/img/placeholders/sneaker-gray.svg", "evidence": ["reviews", "comfort"]}
                ],
                "rationale": "Each piece in this capsule was chosen for travel: machine-washable fabrics, neutral colors that mix-and-match, and items you'll wear repeatedly across 5 days. Sneakers were picked for all-day walking comfort.",
                "sourceInputs": {
                    "preferenceIds": ["pref_usr_demo_001"],
                    "ragSourceIds": ["chunk_5", "chunk_6"],
                    "mcpToolCalls": ["mcpcall_001", "mcpcall_002"]
                },
                "createdAt": "2026-05-23T10:45:00Z"
            },
            "gen_upsell_jordan_london": {
                "assetId": "gen_upsell_jordan_london",
                "type": "upsell-pitch",
                "title": "Complete your London capsule",
                "addOns": [
                    {"productId": "prd_addon_socks", "name": "Merino Travel Socks", "price": 18, "imageUrl": "assets/img/placeholders/socks-gray.svg", "evidence": "Top-rated for blister-free walking days."},
                    {"productId": "prd_addon_umbrella", "name": "Compact Travel Umbrella", "price": 24, "imageUrl": "assets/img/placeholders/umbrella-black.svg", "evidence": "London forecast: occasional rain."},
                    {"productId": "prd_addon_cubes", "name": "Packing Cube Set", "price": 30, "imageUrl": "assets/img/placeholders/cubes-beige.svg", "evidence": "Pairs with your 5-day capsule."}
                ],
                "totalAdded": 72,
                "loyaltyApplied": true,
                "rationaleChips": ["reviews", "weather", "memory"],
                "guardrailResults": [
                    {"rule": "no-unsupported-fit-guarantee", "passed": true},
                    {"rule": "no-fake-discount", "passed": true},
                    {"rule": "no-pii-leak", "passed": true}
                ],
                "createdAt": "2026-05-23T10:45:00Z"
            }
        };
    }
}
