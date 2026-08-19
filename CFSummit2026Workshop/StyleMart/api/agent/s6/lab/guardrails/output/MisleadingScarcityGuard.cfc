component {

  /**
   * Output guardrail — runs AFTER generation. Param name MUST be aiMessage.
   *
   * Detect upsell-copy urgency / scarcity language. Recoverable.
   */
  public struct function validate( required string aiMessage ) {
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = arguments.aiMessage;

    // ===== ATTENDEE TODO ZONE (Detect misleading scarcity language) ==============

    // TODO-S6-7: On a hit, set out.result = "failure" with a repromptMessage that
    //   strips urgency/scarcity claims.
    //   Patterns (any one trips):
    //     • regex: \bonly\s+\d+\s+left\b
    //     • phrases: "limited time","while supplies last","today only",
    //                "going fast","act fast","selling out","few remaining",
    //                "hurry","last chance"
    //   NEGATIVE test: "a few of my colleagues have these shoes" must NOT trip
    //                  even though "few" appears in 'few remaining' — phrase
    //                  boundaries differ. Use case-insensitive substring match
    //                  on the FULL phrase, not the word.
    //   Hint:
    //     out.result          = "failure";
    //     out.message         = "Upsell copy used misleading scarcity/urgency language.";
    //     out.repromptMessage = "Rewrite the add-on pitch WITHOUT any urgency or scarcity claims "
    //                         & "(no 'limited time', 'only N left', 'selling fast', etc.). "
    //                         & "Justify each pick only with review evidence, weather, or saved preferences.";
    /* TODO-S6-7 */

    // ===== END ATTENDEE TODO ZONE ================================================

    new api.agent.s6.GuardrailTrace().report( "no-misleading-scarcity", "output", out );
    return out;
  }
}
