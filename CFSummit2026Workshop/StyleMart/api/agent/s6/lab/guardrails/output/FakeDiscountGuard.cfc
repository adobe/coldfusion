component {

  /**
   * Output guardrail — runs AFTER generation. Param name MUST be aiMessage.
   *
   * Detect fabricated urgency / discount language in model output.
   */
  public struct function validate( required string aiMessage ) {
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = arguments.aiMessage;

    // ===== ATTENDEE TODO ZONE (Detect fabricated discount language) ==============

    // TODO-S6-6: On a hit, set out.result = "failure" with a repromptMessage that
    //   steers the model back to real eligible coupons.
    //   Patterns (any one trips):
    //     • regex: \b\d{1,2}\s*%\s*(off|discount|savings)\b
    //     • keywords: "today only","limited time","lowest price ever",
    //                 "while supplies last","deal of the year","flash sale"
    //   Hint:
    //     out.result          = "failure";
    //     out.message         = "Discount language must reference real, eligible coupons only.";
    //     out.repromptMessage = "Re-answer referencing ONLY the shopper's real eligible coupons "
    //                         & "(from getEligibleCoupons). Do not invent promotions, percentages, "
    //                         & "or urgency phrases like 'today only' or 'limited time'.";
    /* TODO-S6-6 */

    // ===== END ATTENDEE TODO ZONE ================================================

    new api.agent.s6.GuardrailTrace().report( "no-fake-discount", "output", out );
    return out;
  }
}
