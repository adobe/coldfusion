component displayname="mcp Tools" hint="A CFC for echoing the message sent to it" {
     /**
     * A CFC for echoing the message sent to it.
     * @param messageText to be echoed
     * @return Struct with success status and message
     */

    remote any function echoMessage(required string messageText) {

        success = arguments.messageText.trim().len() == 0 ? false : true

        result = {
            success: success,
            message: arguments.messageText & " from CF MCP Server"
        };
        return serializeJSON(result);
    }

}
