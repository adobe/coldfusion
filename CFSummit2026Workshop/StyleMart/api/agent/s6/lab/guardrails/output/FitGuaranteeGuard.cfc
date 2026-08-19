component {

  /**
   * Output guardrail — runs AFTER generation. Param name MUST be aiMessage.
   *
   * LLM-as-judge pattern: ask a small model "yes or no — does this text
   * make/imply a fit guarantee?" Catches paraphrases the regex/keyword
   * pattern in the other output guards would miss (e.g. "made for your
   * body", "sized just right for you").
   *
   * Recoverable: set result="failure" and a repromptMessage so CF re-asks
   * the model with steering toward review-evidence answers.
   *
   * Failure mode: judge errors fail open (verdict=no) so an LLM outage
   * never blocks legitimate output.
   */

  variables.JUDGE_PROMPT = "You are a guardrail classifier. The text below is what an AI shopping assistant is about to send to a customer. Answer with ONE WORD: yes or no.

Answer ""yes"" if the text MAKES OR IMPLIES a fit guarantee — promises the item will fit perfectly, exactly, or ideally, or claims it is ""made for"" the shopper, without citing reviewer evidence.

Answer ""no"" if the text cites reviewer evidence (e.g. ""reviewers report a comfortable fit, true to size""), hedges fit claims with words like ""most"" / ""many find"" / ""generally"", or does not discuss fit at all.

Reply with ONLY the word ""yes"" or ""no"". No punctuation. No explanation.

MESSAGE:
<<<
{{aiMessage}}
>>>";

  public struct function validate( required string aiMessage ) {
    var out = { result: "success", message: "", repromptMessage: "" };

    // ===== ATTENDEE TODO ZONE (LLM-as-judge fit-guarantee detection) =============

    // TODO-S6-5: Call judgeSaysYes(arguments.aiMessage). On a "yes" verdict,
    //   set out.result = "failure" (recoverable — steers the model toward
    //   review-evidence answers) and out.repromptMessage so CF can re-ask
    //   the model with the steering instruction.
    //   Hint:
    //     if ( judgeSaysYes( arguments.aiMessage ) ) {
    //       out.result          = "failure";
    //       out.message         = "Fit guarantees aren't supported; answer from review evidence instead.";
    //       out.repromptMessage = "Re-answer using only retrieved review evidence "
    //                           & "(e.g. 'reviewers report comfortable fit, true to size'). "
    //                           & "Never promise a perfect or guaranteed fit.";
    //     }
    /* TODO-S6-5 */

    // ===== END ATTENDEE TODO ZONE ================================================

    new api.agent.s6.GuardrailTrace().report( "no-unsupported-fit-guarantee", "output", out );
    return out;
  }

  private boolean function judgeSaysYes( required string text ) {
    try {
      var cfg   = loadJudgeConfig();
      var judge = ChatModel({
        PROVIDER:    cfg.provider,
        APIKEY:      application.OPENAI_API_KEY,
        BASEURL:     cfg.baseUrl ?: "",
        MODELNAME:   cfg.modelName,
        TEMPERATURE: 0,
        MAXTOKENS:   4
      });
      var prompt = replace( variables.JUDGE_PROMPT, "{{aiMessage}}", arguments.text, "all" );
      var raw    = judge.chat( prompt );
      var reply  = lCase( trim( isStruct( raw ) ? ( raw.message ?: "" ) : toString( raw ) ) );
      var firstWord = reReplace( reply, "[^a-z]", "", "all" );
      return left( firstWord, 3 ) == "yes";
    } catch ( any e ) {
      return false; // fail open — never block on judge outage
    }
  }

  private struct function loadJudgeConfig() {
    if ( structKeyExists( application, "_s6FitJudgeCfgLab" ) ) return application._s6FitJudgeCfgLab;
    var dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "../../../config/";
    application._s6FitJudgeCfgLab = deserializeJSON( fileRead( dir & "ai.lab.json" ) );
    return application._s6FitJudgeCfgLab;
  }
}
