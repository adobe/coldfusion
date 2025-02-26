<cfscript>
    jsonRecord='{
        "name": "Sherlock",
        "NAME": "Holmes",
        "age": "36",
        "address":{
            "Number":"221B",
            "Street":"Baker Street",
            "City":"London"
        }
    }'
    deserializedRecord=deserializeJSON(json=jsonRecord,preserveCaseForStructKey=false)
    writeDump(deserializedRecord)
    // preserveCaseForStructKey=TRUE or FALSE. FALSE by default
    writeOutput("<br/>" & "Output with preserveCaseForStructKey=TRUE" & "<br/>")
    deserializedRecordCaseStructKey=deserializedRecordCaseStructKey=deserializeJSON(json=jsonRecord,preserveCaseForStructKey=true)
    writeDump(deserializedRecordCaseStructKey)
</cfscript>