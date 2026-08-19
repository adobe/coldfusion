component {

  public struct function validate( required string aiMessage ) {
    var KEYWORDS = [
      "today only", "limited time", "lowest price ever", "while supplies last",
      "deal of the year", "flash sale"
    ];

    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = arguments.aiMessage;

    var hit = reFindNoCase( "\b\d{1,2}\s*%\s*(off|discount|savings)\b", msg ) > 0;
    if ( !hit ) {
      for ( var k in KEYWORDS ) {
        if ( findNoCase( k, msg ) ) { hit = true; break; }
      }
    }

    if ( hit ) {
      out.result          = "failure";
      out.message         = "Discount language must reference real, eligible coupons only.";
      out.repromptMessage = "Re-answer referencing ONLY the shopper's real eligible coupons "
                          & "(from getEligibleCoupons). Do not invent promotions, percentages, "
                          & "or urgency phrases like 'today only' or 'limited time'.";
    }

    new api.agent.s6.GuardrailTrace().report( "no-fake-discount", "output", out );
    return out;
  }
}
