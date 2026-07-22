{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.antigravity-cli;
  shared = import ./shared.nix { inherit flake lib pkgs; };
  inherit (shared.permissions) allowedShellCommands deniedShellCommands;

  allowedCommands = map (command: "command(${command})") allowedShellCommands;
  deniedCommands = map (command: "command(${command})") deniedShellCommands;
in
{
  options.home-manager.dev.coding-agents = {
    antigravity-cli.enable = lib.mkEnableOption "Antigravity CLI config" // {
      default =
        config.home-manager.dev.coding-agents.enable
        || config.home-manager.dev.coding-agents.gemini-cli.enable;
    };

    gemini-cli.enable = lib.mkEnableOption "Antigravity CLI config (deprecated alias)";
  };

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      package = pkgs.llm-agents.antigravity-cli;

      enableMcpIntegration = true;
      context = {
        CONTEXT = shared.context;
        YEGGE = shared.yeggeInstructions;
      };
      defaultModel = "gemini-3.6-flash";
      permissions = {
        allow = allowedCommands ++ [
          "write_file(/)"
          "read_file(/)"
          "read_file(/nix/store)"
        ];
        deny = deniedCommands;
      };
      skills =
        shared.obsidianSkills
        // lib.optionalAttrs config.home-manager.cli.jujutsu.enable shared.jujutsuSkills
        // shared.localSkills
        // shared.pluginSkills;
      settings = {
        artifactReviewPolicy = "agent-decides";
        enableTelemetry = false;
      };
    };
  };
}
