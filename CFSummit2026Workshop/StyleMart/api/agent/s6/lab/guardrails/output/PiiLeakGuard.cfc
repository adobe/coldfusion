component {

  /**
   * Output guardrail — runs AFTER generation. Param name MUST be aiMessage.
   *
   * Detect leaked email / phone / card-like patterns in model output.
   * Fatal — no safe re-answer for a leak. RecoveryEmailService swaps the
   * unsafe draft for a safe-fallback body when ANY output guard returns fatal.
   *
   * NO ATTENDEE TODO HERE.
   * Why: modern LLMs almost never emit fabricated PII (alignment training
   * + StyleMart's system prompt both refuse before the guard runs). A live
   * chat-based demo would never trip this guard, so the attendees would see
   * no chip-row difference between an empty stub and a working impl. Instead
   * of asking attendees to write code they'd never see fire, this is shipped
   * pre-wired so the guard set is complete and the trace panel always shows
   * the no-pii-leak chip (passed:true on every clean run).
   *
   * To DEMO this guard reliably, use the verify-guardrail.cfm harness:
   *   /api/agent/s6/lab/verify-guardrail.cfm
   *     ?mode=lab&kind=output&path=guardrails/output/PiiLeakGuard.cfc
   *     &prompt=Contact me at jordan@example.com or 555-123-4567.
   * The harness calls validate() directly with attacker-shaped strings, which
   * bypasses model alignment so attendees can SEE the regex catch the leak.
   */
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
