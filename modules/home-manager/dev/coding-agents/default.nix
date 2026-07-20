{
  config,
  flake,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents;
in
{
  imports = [
    ./antigravity-cli.nix
    ./claude-code.nix
    ./codex.nix
    ./mcp.nix
    flake.inputs.codexctl.homeManagerModules.default
  ];

  options.home-manager.dev.coding-agents = {
    enable = lib.mkEnableOption "coding agent config" // {
      default = config.home-manager.dev.enable;
    };

    coding-brain.enable = lib.mkEnableOption "Coding Brain" // {
      default = cfg.codex.enable;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = with pkgs; [
        llm-agents.agent-deck
        tmux # requires by agent-deck
        ctx7
      ];
    })

    (lib.mkIf cfg.coding-brain.enable {
      programs.coding-brain = {
        enable = true;
        settings.brain = {
          endpoint = "http://localhost:11434/api/generate";
          model = "gemma4:e4b";
          auto = true;
          timeout_ms = 25000;
          terminal_auto_approve_fallback = false;
        };
      };
    })
  ];
}
