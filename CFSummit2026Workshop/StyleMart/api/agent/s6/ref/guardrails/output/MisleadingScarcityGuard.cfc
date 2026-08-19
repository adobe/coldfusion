component {

  public struct function validate( required string aiMessage ) {
    var SCARCITY_PHRASES = [
      "limited time", "while supplies last", "today only",
      "going fast", "act fast", "selling out", "few remaining",
      "hurry", "last chance"
    ];

    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = arguments.aiMessage;

    var hit = reFindNoCase( "\bonly\s+\d+\s+left\b", msg ) > 0;
    if ( !hit ) {
      for ( var p in SCARCITY_PHRASES ) {
        if ( findNoCase( p, msg ) ) { hit = true; break; }
      }
    }

    if ( hit ) {
      out.result          = "failure";
      out.message         = "Upsell copy used misleading scarcity/urgency language.";
      out.repromptMessage = "Rewrite the add-on pitch WITHOUT any urgency or scarcity claims "
                          & "(no 'limited time', 'only N left', 'selling fast', etc.). "
                          & "Justify each pick only with review evidence, weather, or saved preferences.";
    }

    new api.agent.s6.GuardrailTrace().report( "no-misleading-scarcity", "output", out );
    return out;
  }
}
