component {

  /**
   * LLM-as-judge output guard for unsupported fit guarantees.
   *
   * Other output guards (FakeDiscountGuard, MisleadingScarcityGuard,
   * PiiLeakGuard) demo the regex/keyword pattern. This one demos the
   * complementary pattern: a tiny LLM classifier asked one question with
   * a one-word answer ("yes" or "no"). Catches paraphrases regex misses
   * (e.g. "made for your body", "sized just right for you") at the cost
   * of one extra judge call per output.
   *
   * Failure mode: the judge fails open (verdict=no) so an LLM outage
   * never blocks legitimate output.
   */

  variables.JUDGE_PROMPT = "You are a guardrail classifier. The text below is what an AI shopping assistant 
                            is about to send to a customer. Answer with ONE WORD: yes or no.
                            Answer ""yes"" if the text MAKES OR IMPLIES a fit guarantee — promises the item will fit perfectly, exactly, or ideally, or claims it is ""made for"" the shopper, without citing reviewer evidence.
                            Answer ""no"" if the text cites reviewer evidence (e.g. ""reviewers report a comfortable fit, true to size""), hedges fit claims with words like ""most"" / ""many find"" / ""generally"", or does not discuss fit at all.

                            Reply with ONLY the word ""yes"" or ""no"". No punctuation. No explanation.

                            MESSAGE:
                            <<<
                            {{aiMessage}}
                            >>>";

  public struct function validate( required string aiMessage ) {
    var out = { result: "success", message: "", repromptMessage: "" };

    if ( judgeSaysYes( arguments.aiMessage ) ) {
      out.result          = "failure";
      out.message         = "Fit guarantees aren't supported; answer from review evidence instead.";
      out.repromptMessage = "Re-answer using only retrieved review evidence "
                          & "(e.g. 'reviewers report comfortable fit, true to size'). "
                          & "Never promise a perfect or guaranteed fit.";
    }

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
    if ( structKeyExists( application, "_s6FitJudgeCfg" ) ) return application._s6FitJudgeCfg;
    var dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "../../../config/";
    application._s6FitJudgeCfg = deserializeJSON( fileRead( dir & "ai.ref.json" ) );
    return application._s6FitJudgeCfg;
  }
}
