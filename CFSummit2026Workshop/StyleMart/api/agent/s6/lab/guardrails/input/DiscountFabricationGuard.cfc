component {

  /**
   * Input guardrail — runs BEFORE retrieval/LLM. Param name MUST be userMessage.
   *
   * Block any prompt that asks Mira to apply/create/invent a discount.
   * On a hit, fetch the user's REAL eligible coupons via the cf-commerce MCP
   * tool and interpolate them into the message so the block is helpful.
   */
  public struct function validate( required string userMessage ) {
    var trace = new api.agent.s6.GuardrailTrace();
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = trace.userTurn( arguments.userMessage );

    // ===== ATTENDEE ZONE (Detect discount-fabrication asks) =====================
    //
    // Goal: when the shopper asks Mira to apply / invent a discount, set
    //   out.result  = "fatal"
    //   out.message = "I can't apply discounts that aren't in our coupon catalog."
    //                 + (optional helpful list of REAL eligible coupons)
    //
    // We use "fatal" because pricing must NEVER be fabricated — even after a
    // re-prompt. There's no safe re-answer.
    //
    // Detection signals — if ANY one of these trips, it's a hit:
    //   1) Numeric percent-off pattern (regex)        ->  e.g. "90% off", "15 percent discount"
    //   2) Keyword phrase                              ->  e.g. "give me a discount"
    //   3) Fallback "apply" + "discount" co-occurrence ->  e.g. "can you apply that discount?"
    //
    // ── REGEX (provided — copy this verbatim) ──
    //   "\b\d{1,2}\s*%?\s*(off|discount)\b"
    //   • \b              — word boundary so "off" inside "office" doesn't match
    //   • \d{1,2}         — 1–2 digit number (5, 10, 90)
    //   • \s*%?\s*        — optional whitespace, optional % sign, optional whitespace
    //   • (off|discount)  — literal "off" or "discount"
    //   • \b              — closing word boundary
    //
    // ── KEYWORDS list (provided — copy this verbatim) ──
    //   var KEYWORDS = [
    //       "apply a discount", "give me a discount", "promo code",
    //       "make it cheaper",  "discount code",      "knock off"
    //   ];
    //
    // ── HELPFUL BLOCK (provided — copy this verbatim when hit==true) ──
    //   var offers = getEligibleCouponsText( request.userId ?: "" );  // already-implemented helper below
    //   out.result  = "fatal";
    //   out.message = "I can't apply discounts that aren't in our coupon catalog."
    //               & ( len(offers) ? " Your current eligible offers are: " & offers & "." : "" );
    //
    // ── YOUR CODE GOES BELOW ──
    // Steps to implement (write the actual CFML — don't just uncomment):
    //   1. var hit = false;
    //   2. Use reFindNoCase(<the regex above>, msg) > 0 to set `hit` if the regex matches.
    //   3. If !hit, loop the KEYWORDS array and findNoCase(k, msg) — set hit=true and break on first match.
    //   4. If still !hit, do the "apply" AND "discount" co-occurrence fallback.
    //      Even if the regex and the keyword list both miss, flag the message when
    //      it loosely contains BOTH the words "apply" and "discount" anywhere —
    //      this catches phrasing like "could you go ahead and apply that 10 dollar
    //      discount for me" or "please apply the discount we talked about".
    //      Concretely, the line you'd write is:
    //
    //          if ( !hit && findNoCase("apply", msg) && findNoCase("discount", msg) ) {
    //              hit = true;
    //          }
    //
    //      findNoCase just checks "does this substring appear anywhere in msg?" —
    //      position doesn't matter. Both words present anywhere = trip the guard.
    //   5. If hit, paste the HELPFUL BLOCK above to populate out.result and out.message.
    //
    // Tip: if you get stuck, look at any other input guard (PromptInjectionGuard /
    //      PiiIntakeGuard) for the keyword-loop pattern.
    /* TODO-S6-2 */

    // ===== END ATTENDEE ZONE ====================================================

    trace.report( "discount-fabrication", "input", out );
    return out;
  }

  /**
   * Best-effort MCP lookup. Returns "" if MCP is unavailable — the block still fires.
   */
  private string function getEligibleCouponsText( required string userId ) {
    if ( !len( arguments.userId ) ) return "";
    try {
      var mcp = createObject( "component", "api.agent.s6.lab.mcp.CommerceOpsServer" );
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
