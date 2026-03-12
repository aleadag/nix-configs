{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.codex;
  sharedPermissions = import ./permissions.nix { inherit lib; };
  renderPrefixRule = pattern: ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
in
{
  options.home-manager.dev.codex = {
    enable = lib.mkEnableOption "Codex config" // {
      default = config.home-manager.dev.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mcp-nixos ];
    home.file.".codex/rules/basic.rules".text =
      lib.concatMapStringsSep "\n" renderPrefixRule sharedPermissions.codexAllowedPrefixRules + "\n";

    programs.codex = {
      enable = true;
      package = pkgs.llm-agents.codex;
      settings = {
        analytics.enabled = false;
        check_for_update_on_startup = false;
        mcp_servers = {
          nixos = {
            command = lib.getExe pkgs.mcp-nixos;
          };
        };
      };
      custom-instructions = builtins.readFile ./CONTEXT.md;
      skills = ./skills;
    };
  };
}
