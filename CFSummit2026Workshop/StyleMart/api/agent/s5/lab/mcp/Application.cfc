component {
    this.name = "agent_s5_mcp";
    this.datasource = "stylemart";
    this.sessionManagement = false;

    this.mappings = {
        "/api": getDirectoryFromPath(getCurrentTemplatePath()) & "../../../../"
    };
}
