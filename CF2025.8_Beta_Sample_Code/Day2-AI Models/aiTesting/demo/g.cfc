component {

    struct function validate( required string output ) {

        local.text = arguments.output;

        // Block Social Security Numbers (e.g. 123-45-6789)
        if (reFind("\b\d{3}-\d{2}-\d{4}\b", local.text)) {
            // FIX: key must be "result" (string), not "success" (boolean)
            return {
                result  : "failure",
                message : "Response blocked: contains a Social Security Number pattern."
            };
        }

        // Block 16-digit credit card numbers (with or without spaces/dashes)
        if (reFind("\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b", local.text)) {
            // FIX: key must be "result" (string), not "success" (boolean)
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
            // FIX: key must be "result", not "success"
            return { result: "successWith", message: "Message redacted", repromptMessage: local.redacted };
        }

        // FIX: key must be "result" with string value, not "success: true"
        return { result: "success", message: "Input validation passed" };
    }

}