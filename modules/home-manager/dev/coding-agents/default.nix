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
    ./agent-deck.nix
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
      home-manager.dev.coding-agents.agent-deck = {
        enable = true;
        settings = {
          default_tool = "codex";
          theme = "dark";
          claude = {
            command = "claude-zai";
            dangerous_mode = false;
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
      };
    })

    (lib.mkIf cfg.enable {
      home.packages = with pkgs; [
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
