/**
 * PiiGuardrail.cfc
 * Output guardrail that validates AI responses before they reach the customer.
 * Blocks SSN and credit card patterns. Redacts email addresses.
 *
 * Valid result values for CF 2025 output guardrails:
 *   "success"     — pass through unchanged
 *   "successWith" — pass through with modified content (repromptMessage = new text)
 *   "failure"     — block completely
 */
component {

    struct function validate( required string output ) {

        local.text = arguments.output;

        // Block Social Security Numbers (e.g. 123-45-6789)
        if (reFind("\b\d{3}-\d{2}-\d{4}\b", local.text)) {
            return {
                result  : "failure",
                message : "Response blocked: contains a Social Security Number pattern."
            };
        }

        // Block 16-digit credit card numbers (with or without spaces/dashes)
        if (reFind("\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b", local.text)) {
            return {
                result  : "failure",
                message : "Response blocked: contains a payment card number pattern."
            };
        }

        // Redact email addresses — replace local part with [protected]
        local.redacted = reReplace(
            local.text,
            "[a-zA-Z0-9._%+\-]+@([a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})",
            "[protected]@\1",
            "ALL"
        );

        if (local.redacted neq local.text) {
            return { result: "successWith", message: "PII detected and redacted", repromptMessage: local.redacted };
        }

        return { result: "success", message: "Output validation passed - no PII detected" };
    }

}
