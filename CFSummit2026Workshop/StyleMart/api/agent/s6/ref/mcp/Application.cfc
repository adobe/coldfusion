component {
    this.name = "agent_s6_mcp";
    this.datasource = "stylemart";
    this.sessionManagement = false;

    this.mappings = {
        "/api": getDirectoryFromPath(getCurrentTemplatePath()) & "../../../../"
    };
}
