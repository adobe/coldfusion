component {

  /**
   * Input guardrail — runs BEFORE retrieval/LLM. Param name MUST be userMessage.
   *
   * Block classic prompt-injection meta-attacks ("ignore previous instructions",
   * "you are now ...", "reveal your system prompt", etc).
   */
  public struct function validate( required string userMessage ) {
    var trace = new api.agent.s6.GuardrailTrace();
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = trace.userTurn( arguments.userMessage );

    // ===== ATTENDEE TODO ZONE (Detect prompt-injection meta-attacks) =============
    //
    // On a hit, return "fatal" — meta-attacks have no safe re-answer, so
    // don't use repromptMessage.
    //
    // Phrase list (provided verbatim — case-insensitive substring match):
    //   var PHRASES = [
    //     "previous instructions",         // covers every "ignore (your|all the|those) previous instructions" variant
    //     "you are now",
    //     "reveal your system prompt",
    //     "disregard your guidelines",
    //     "forget all rules",
    //     "ignore your guidelines",
    //     "act as if",
    //     "pretend you are"
    //   ];
    //
    // Why "previous instructions" alone is enough: substring match is position-
    // agnostic, so it catches "ignore previous instructions", "ignore your
    // previous instructions", and "please ignore all the previous instructions"
    // without enumerating each.
    //
    // Negative test: "can you ignore the size filter and show me anything in stock?"
    //   must STILL return success — no "previous instructions" substring.
    //
    // Hint:
    //   for (var p in PHRASES) {
    //     if (findNoCase(p, msg)) {
    //       out.result  = "fatal";
    //       out.message = "I can only follow my normal StyleMart shopping instructions.";
    //       break;
    //     }
    //   }
    //
    // ── YOUR CODE GOES BELOW ──
    /* TODO-S6-3 */

    // ===== END ATTENDEE TODO ZONE ================================================

    trace.report( "prompt-injection", "input", out );
    return out;
  }
}
