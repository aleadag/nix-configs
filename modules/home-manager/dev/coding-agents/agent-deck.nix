{
  config,
  lib,
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
      type = lib.types.attrs;
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
          tier = "auto";
          recent_days = 90;
        };
        logs = {
          max_size_mb = 10;
          max_lines = 10000;
        };
        ui = {
          preview_pct = 65;
        };
      };
      description = "Agent Deck configuration (converted to TOML)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      llm-agents.agent-deck
    ];
    home-manager.cli.tmux.enable = true;
    home.sessionVariables.AGENTDECK_COLOR = "truecolor";

    xdg.configFile."agent-deck/config.toml".source =
      configToml.generate "agent-deck-config.toml" cfg.settings;
  };
}
