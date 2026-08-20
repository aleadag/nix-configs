{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.antigravity-cli;
  shared = import ./shared.nix {
    inherit
      config
      flake
      lib
      pkgs
      ;
  };
  inherit (shared.permissions)
    allowedShellCommands
    commonExternalDirectories
    commonNetworkDomains
    deniedShellCommands
    ;

  allowedCommands = map (command: "command(${command})") allowedShellCommands;
  deniedCommands = map (command: "command(${command})") deniedShellCommands;
  networkDomains = lib.unique (map (lib.removePrefix "*.") commonNetworkDomains);
  allowedNetworkReads = map (domain: "read_url(${domain})") networkDomains;
  allowedDirectoryPermissions = map (directory: "read_file(${directory})") commonExternalDirectories;
  deniedDirectoryPermissions = map (directory: "write_file(${directory})") commonExternalDirectories;

  statusLineScript = pkgs.writeShellScript "agy-statusline" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.jq
        pkgs.coreutils
      ]
    }:$PATH"
    ${builtins.readFile ./scripts/statusline.sh}
  '';
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
    mutableConfig.files."${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json" = {
      source = config.home.file.".gemini/antigravity-cli/settings.json".source;
    };

    programs.antigravity-cli = {
      enable = true;
      package = pkgs.llm-agents.antigravity-cli;

      enableMcpIntegration = true;
      context = {
        CONTEXT = shared.context;
        YEGGE = shared.yeggeInstructions;
      };
      defaultModel = "gemini-3.7-flash";
      permissions = {
        allow = allowedCommands ++ allowedDirectoryPermissions ++ allowedNetworkReads;
        deny = deniedCommands ++ deniedDirectoryPermissions;
      };
      skills = shared.guardedSkillsWithPlugins;
      settings = {
        agentMode = "accept-edits";
        altScreenMode = "always";
        artifactReviewPolicy = "agent-decides";
        enableTelemetry = false;
        notifications = false;
        showFeedbackSurvey = false;
        statusLine = {
          command = "${statusLineScript}";
          enabled = true;
        };
      };
    };
  };
}
