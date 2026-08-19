component {

  public struct function validate( required string aiMessage ) {
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = arguments.aiMessage;

    var leaked = reFindNoCase( "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", msg ) > 0
              || reFindNoCase( "\b\+?\d[\d .-]{7,}\d\b", msg ) > 0
              || reFindNoCase( "\b(?:\d[ -]*?){13,16}\b", msg ) > 0;

    if ( leaked ) {
      out.result  = "fatal";
      out.message = "I can't include personal contact or payment details in this message.";
    }

    new api.agent.s6.GuardrailTrace().report( "no-pii-leak", "output", out );
    return out;
  }
}
