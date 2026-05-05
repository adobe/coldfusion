//Application.cfc
component output="true" displayname=""  {
    this.name = "Sample Application"
    void function onRequestStart(){
		//Having Multiple Exception Handlers
		cferror(type="exception", exception="etype2", template="eType2Page.cfm")
    	cferror(type="exception", exception="etype1", template="eType1Page.cfm")
	}
}
