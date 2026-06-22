component output=false {
    variables.salt = "";

    public HashUtil function init(string salt = "") {
        variables.salt = arguments.salt;
        return this;
    }

    public string function sha256(any value = "") {
        return lcase(hash(toStringSafe(arguments.value) & variables.salt, "SHA-256", "UTF-8"));
    }

    public string function hashNullable(any value = "") {
        if (!structKeyExists(arguments, "value") || isNull(arguments.value)) {
            return "";
        }

        var text = toStringSafe(arguments.value);
        if (!len(trim(text))) {
            return "";
        }

        return sha256(text);
    }

    private string function toStringSafe(any value = "") {
        if (!structKeyExists(arguments, "value") || isNull(arguments.value)) {
            return "";
        }
        if (isSimpleValue(arguments.value)) {
            return toString(arguments.value);
        }
        return serializeJSON(arguments.value);
    }
}
