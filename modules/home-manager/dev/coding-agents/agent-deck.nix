{
  config,
  flake,
  lib,
  libEx,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.agent-deck;
  configToml = pkgs.formats.toml { };
in
{
  options.home-manager.dev.coding-agents.agent-deck = {
    enable = lib.mkEnableOption "Agent Deck CLI tool" // {
      default = config.home-manager.dev.coding-agents.enable;
    };

    settings = lib.mkOption {
      inherit (configToml) type;
      default = {
        default_tool = "codex";
        theme = "dark";
        claude = {
          command = "claude-zai";
          dangerous_mode = false;
        };
        gemini = {
          command = "agy";
        };
        global_search = {
          enabled = true;
          recent_days = 90;
          tier = "auto";
        };
        logs = {
          max_size_mb = 10;
          max_lines = 10000;
        };
        ui = {
          preview_pct = 65;
        };
        updates = {
          auto_update = false;
          check_enabled = false;
        };
      };
      description = "Agent Deck configuration (converted to TOML)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.llm-agents.agent-deck ];
    home-manager.cli.tmux.enable = lib.mkDefault true;

    home-manager.dev.coding-agents = {
      skills = libEx.loadSkills (flake.inputs.agent-deck-src + "/skills");
      permissions.allowedCommands = [ "agent-deck" ];
    };

    xdg.configFile."agent-deck/config.toml".source =
      configToml.generate "agent-deck-config.toml" cfg.settings;
  };
}
