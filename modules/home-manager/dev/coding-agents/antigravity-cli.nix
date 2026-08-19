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
    deniedShellCommands
    ;

  allowedCommands = map (command: "command(${command})") allowedShellCommands;
  deniedCommands = map (command: "command(${command})") deniedShellCommands;
  directoryPermissions =
    lib.concatMap (directory: [ "read_file(${directory})" ]) commonExternalDirectories
    ++ [
      "read_file(/)"
      "write_file(/)"
    ];

  statusLineScript = pkgs.writeShellScript "agy-statusline" (
    builtins.readFile ./scripts/statusline.sh
  );
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
    mutableConfig.files."${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json" =
      lib.mkIf (config.programs.antigravity-cli.settings != { })
        {
          format = "json";
          settings = config.programs.antigravity-cli.settings;
        };

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
        allow = allowedCommands ++ directoryPermissions;
        deny = deniedCommands;
      };
      skills = shared.guardedSkillsWithPlugins;
      settings = {
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
