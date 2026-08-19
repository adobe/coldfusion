component {
    this.name = "agent_s5_mcp";
    this.datasources = {};
    this.sessionManagement = false;

    public boolean function onApplicationStart() { return true; }
    public boolean function onRequestStart(required string targetPage) { return true; }
}
