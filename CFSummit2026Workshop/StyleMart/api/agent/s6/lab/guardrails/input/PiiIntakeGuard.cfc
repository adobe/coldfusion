component {

  /**
   * Input guardrail — runs BEFORE retrieval/LLM. Param name MUST be userMessage.
   *
   * Block shoppers from sending sensitive PII (card numbers, SSNs, passwords)
   * into the chat. Pairs symmetrically with the output-side PiiLeakGuard:
   * stop PII going IN, stop PII coming OUT.
   *
   * Why "fatal": once a card or SSN reaches the model context window, it can
   * land in logs, memory, RAG indices, or downstream traces. Re-prompting
   * doesn't undo that. Stop the turn entirely and redirect to checkout.
   */
  public struct function validate( required string userMessage ) {
    var trace = new api.agent.s6.GuardrailTrace();
    var out = { result: "success", message: "", repromptMessage: "" };
    var msg = trace.userTurn( arguments.userMessage );

    // ===== ATTENDEE TODO ZONE (Detect PII in shopper input) =====================
    //
    // Goal: when the shopper sends a card number, SSN, or volunteers a
    // password/PIN, set out.result = "fatal" with a redirect to secure checkout.
    //
    // Detection signals — if ANY one of these trips, it's a hit:
    //   1) Card-number regex   ->  e.g. "4111 1111 1111 1111", "4111-1111-1111-1111"
    //   2) SSN regex           ->  e.g. "123-45-6789"
    //   3) Password/PIN keyword phrase  ->  e.g. "my password is hunter2"
    //
    // ── REGEX (provided — copy these verbatim) ──
    //   Card:   "\b(?:\d[ -]*?){13,16}\b"
    //     • 13–16 digits with optional spaces / dashes between them
    //     • catches Visa/MC/Amex shapes without parsing checksums
    //
    //   SSN:    "\b\d{3}-\d{2}-\d{4}\b"
    //     • literal US SSN dashed shape; word boundaries on both sides
    //
    // ── KEYWORDS list (provided — copy this verbatim) ──
    //   var KEYWORDS = [
    //     "my password is", "password is",
    //     "my pin is",      "pin is",
    //     "my ssn is",      "social security number"
    //   ];
    //
    // ── HELPFUL BLOCK (provided — copy this verbatim when hit==true) ──
    //   out.result  = "fatal";
    //   out.message = "Please don't share card numbers, SSNs, or passwords here. "
    //               & "Cart and payment happen on the secure checkout page.";
    //
    // ── YOUR CODE GOES BELOW ──
    // Steps to implement:
    //   1. var hit = false;
    //   2. Use reFindNoCase(<card regex>, msg) > 0 to set `hit` on a card match.
    //   3. If !hit, reFindNoCase(<SSN regex>, msg) > 0 to catch an SSN.
    //   4. If !hit, loop the KEYWORDS array; findNoCase(k, msg) sets hit=true and break.
    //   5. If hit, paste the HELPFUL BLOCK above to populate out.result and out.message.
    //
    // Negative tests (must STILL return success):
    //   • "size 8 in red"             — no PII anywhere
    //   • "I'm in the 90210 zip code" — 5 digits, well under the card regex floor
    //   • "call me at extension 412"  — no card/SSN shape, no keyword
    /* TODO-S6-4 */

    // ===== END ATTENDEE TODO ZONE ================================================

    trace.report( "pii-intake", "input", out );
    return out;
  }
}
