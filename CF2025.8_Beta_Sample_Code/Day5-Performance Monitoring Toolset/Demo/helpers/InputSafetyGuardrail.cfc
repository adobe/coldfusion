/**
 * Input safety guardrail for Mintu's Baby Care Assistant.
 * Blocks harmful or dangerous advice queries and warns on concerning patterns.
 */
component {

    public struct function validate(required string message) {
        sleep(120);

        var lowerMsg = lCase(trim(arguments.message));

        // Fatal blocklist - dangerous baby care advice
        var blockedTerms = ["give honey to newborn", "put baby to sleep face down",
                            "give water to newborn", "stop vaccinating", "anti-vaccine",
                            "use essential oils on newborn", "give medicine without doctor",
                            "leave baby unattended in bath", "co-sleep with blankets",
                            "give solid food to newborn", "use crib bumpers",
                            "shake the baby", "ignore baby crying for hours"];
        for (var term in blockedTerms) {
            if (findNoCase(term, lowerMsg)) {
                return {
                    result:          "FATAL",
                    message:         "This request involves potentially unsafe baby care practices. Please consult your pediatrician for medical advice. Safety is our top priority for Mintu!",
                    repromptMessage: ""
                };
            }
        }

        // Warning terms - allow but flag
        var warnTerms = ["fever", "not eating", "won't stop crying", "emergency", "rash", "vomiting", "diarrhea", "choking"];
        var isWarning = false;
        for (var warnTerm in warnTerms) {
            if (findNoCase(warnTerm, lowerMsg)) {
                isWarning = true;
                break;
            }
        }

        if (isWarning) {
            return {
                result:          "SUCCESSWITH",
                message:         arguments.message,
                repromptMessage: "IMPORTANT: If this is a medical emergency, call your pediatrician or emergency services immediately. For non-urgent concerns: " & arguments.message
            };
        }

        return {
            result:          "SUCCESS",
            message:         arguments.message,
            repromptMessage: ""
        };
    }
}
