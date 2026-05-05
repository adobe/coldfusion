component {
    public struct function validate(required string userMessage) {
        var patterns = ["ssn", "social security", "credit card", "password"];
        for (var pattern in patterns) {
            if (findNoCase(pattern, arguments.userMessage)) {
                return { result: "fatal", message: "Sensitive data detected: " & pattern, repromptMessage: "" };
            }
        }
        return { result: "success", message: "No sensitive data found", repromptMessage: "" };
    }
}
