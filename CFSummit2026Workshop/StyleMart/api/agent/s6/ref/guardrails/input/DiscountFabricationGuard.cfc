component {

  /**
   * Input guardrail — runs BEFORE retrieval/LLM. Param name MUST be userMessage.
   *
   * Block any prompt that asks Mira to apply/create/invent a discount.
   * On a hit, fetch the user's REAL eligible coupons via the cf-commerce MCP
   * tool and interpolate them into the message so the block is helpful.
   *
   * "fatal" because pricing must NEVER be fabricated — even after a re-prompt.
   * There's no safe re-answer.
   */
  public struct function validate( required string userMessage ) {

    // Keyword phrases — exact substring match via findNoCase below.
    var KEYWORDS = [
      "apply a discount", "give me a discount", "promo code", "make it cheaper",
      "discount code", "knock off"
    ];

    var trace = new api.agent.s6.GuardrailTrace();
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = trace.userTurn( arguments.userMessage );

    // Detection signal 1 — numeric percent-off pattern.
    //   \b              — word boundary so "off" inside "office" doesn't match
    //   \d{1,2}         — 1–2 digit number (5, 10, 90)
    //   \s*%?\s*        — optional whitespace, optional % sign, optional whitespace
    //   (off|discount)  — literal "off" or "discount"
    //   \b              — closing word boundary
    var hit = reFindNoCase( "\b\d{1,2}\s*%?\s*(off|discount)\b", msg ) > 0;

    // Detection signal 2 — exact keyword phrase match.
    if ( !hit ) {
      for ( var k in KEYWORDS ) {
        if ( findNoCase( k, msg ) ) { hit = true; break; }
      }
    }

    // Detection signal 3 — "apply" AND "discount" co-occurrence fallback.
    // Catches phrasing like "could you go ahead and apply that 10 dollar discount
    // for me" or "please apply the discount we talked about" — both words present
    // anywhere in msg trips the guard (findNoCase is position-agnostic).
    if ( !hit && findNoCase( "apply", msg ) && findNoCase( "discount", msg ) ) hit = true;

    if ( hit ) {
      var offers = getEligibleCouponsText( request.userId ?: "" );
      out.result  = "fatal";
      out.message = "I can't apply discounts that aren't in our coupon catalog."
                  & ( len( offers ) ? " Your current eligible offers are: " & offers & "." : "" );
    }

    trace.report( "discount-fabrication", "input", out );
    return out;
  }

  /**
   * Best-effort MCP lookup. Returns "" if MCP is unavailable — the block still fires.
   */
  private string function getEligibleCouponsText( required string userId ) {
    if ( !len( arguments.userId ) ) return "";
    try {
      var mcp = createObject( "component", "api.agent.s6.ref.mcp.CommerceOpsServer" );
      var result = mcp.getEligibleCoupons( userId = arguments.userId );
      if ( isStruct( result ) && structKeyExists( result, "coupons" ) && isArray( result.coupons ) ) {
        var labels = [];
        for ( var c in result.coupons ) {
          arrayAppend( labels, ( c.code ?: "" ) & ( len( c.description ?: "" ) ? " (" & c.description & ")" : "" ) );
        }
        return arrayToList( labels, ", " );
      }
    } catch ( any e ) { /* swallow — graceful degrade */ }
    return "";
  }
}
