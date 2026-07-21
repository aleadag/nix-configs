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
      default = { };
      description = "Agent Deck configuration (converted to TOML)";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      llm-agents.agent-deck
      tmux
    ];

    xdg.configFile."agent-deck/config.toml".source =
      configToml.generate "agent-deck-config.toml" cfg.settings;
  };
}
