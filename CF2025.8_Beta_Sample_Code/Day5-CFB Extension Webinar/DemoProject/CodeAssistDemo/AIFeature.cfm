<cfscript>
  /*  chatModel = ChatModel( {
        provider = "anthropic",
        modelname = "",
        httpclient = { executorpool = { size = "" } } //anthropic : claude-sonnet-4.5  stopsequences ; openapi : seed
        //openai gpt-4o-mini
    })

    agent = Agent({
        chatmodel = chatModel, chatmemory = {  }  , inputguardrails = [
            { cfc = "" }, { cfc = "" }, { cfc = "" }
        ]
    })*/

    chatmodel=ChatModel({provider = "openai", modelname = "gpt-4o-mini", httpclient = {executorpool = {size = "10" }}})

    agetnt=Agent({
        chatmodel = chatmodel, chatmemory = { maxmessages = 20 }, tools = [
            { cfc = ""}, { mcpclient = mcpclient }, { methods = methods }
        ]
    })

</cfscript>