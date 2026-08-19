component {
    this.name = "StyleMartSetup";
    this.sessionManagement = false;
    this.mappings["/commonutils"] = getDirectoryFromPath(getCurrentTemplatePath()) & "../../commonutils";
}
