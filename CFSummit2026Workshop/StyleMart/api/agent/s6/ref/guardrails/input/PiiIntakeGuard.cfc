component {

  public struct function validate( required string userMessage ) {
    var KEYWORDS = [
      "my password is", "password is",
      "my pin is",      "pin is",
      "my ssn is",      "social security number"
    ];

    var trace = new api.agent.s6.GuardrailTrace();
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = trace.userTurn( arguments.userMessage );

    var hit = reFindNoCase( "\b(?:\d[ -]*?){13,16}\b", msg ) > 0
           || reFindNoCase( "\b\d{3}-\d{2}-\d{4}\b", msg ) > 0;

    if ( !hit ) {
      for ( var k in KEYWORDS ) {
        if ( findNoCase( k, msg ) ) { hit = true; break; }
      }
    }

    if ( hit ) {
      out.result  = "fatal";
      out.message = "Please don't share card numbers, SSNs, or passwords here. "
                  & "Cart and payment happen on the secure checkout page.";
    }

    trace.report( "pii-intake", "input", out );
    return out;
  }
}
