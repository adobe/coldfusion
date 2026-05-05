/**
 * Output PII protection guardrail for Mintu's Baby Care Assistant.
 * Redacts sensitive data patterns from AI responses.
 */
component {

    public struct function validate(required string message) {
        sleep(150);

        var sanitized  = arguments.message;
        var wasRedacted = false;

        // Redact SSN patterns
        var ssnPattern = "[0-9]{3}-[0-9]{2}-[0-9]{4}";
        if (reFind(ssnPattern, sanitized)) {
            sanitized   = reReplace(sanitized, ssnPattern, "[SSN REDACTED]", "ALL");
            wasRedacted = true;
        }

        // Redact phone numbers
        var phonePattern10 = "\b(\+1[\s\-]?)?(\([0-9]{3}\)|[0-9]{3})[\s\-]?[0-9]{3}[\s\-]?[0-9]{4}\b";
        if (reFind(phonePattern10, sanitized)) {
            sanitized   = reReplace(sanitized, phonePattern10, "[PHONE REDACTED]", "ALL");
            wasRedacted = true;
        }
        var phonePattern7 = "\b[0-9]{3}[\s\-][0-9]{4}\b";
        if (reFind(phonePattern7, sanitized)) {
            sanitized   = reReplace(sanitized, phonePattern7, "[PHONE REDACTED]", "ALL");
            wasRedacted = true;
        }

        // Redact email addresses
        var emailPattern = "[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}";
        if (reFind(emailPattern, sanitized)) {
            sanitized   = reReplace(sanitized, emailPattern, "[EMAIL REDACTED]", "ALL");
            wasRedacted = true;
        }

        if (wasRedacted) {
            return {
                result:          "SUCCESSWITH",
                message:         "PII redacted",
                repromptMessage: sanitized & " [Note: Sensitive information was automatically redacted to protect family privacy.]"
            };
        }

        return {
            result:          "SUCCESS",
            message:         "",
            repromptMessage: ""
        };
    }
}
