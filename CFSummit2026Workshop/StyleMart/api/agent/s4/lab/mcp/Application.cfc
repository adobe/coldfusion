component {
    this.name = "agent_s4_mcp";
    this.datasource = "stylemart";
    this.sessionManagement = false;

    this.mappings = {
        "/api": getDirectoryFromPath(getCurrentTemplatePath()) & "../../../../"
    };
}
