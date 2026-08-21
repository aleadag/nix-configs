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
    ./codex.nix
    ./coding-brain.nix
    ./opencode.nix
    ./mcp.nix
    flake.inputs.coding-brain.homeManagerModules.default
  ];

  options.home-manager.dev.coding-agents = {
    enable = lib.mkEnableOption "coding agent config" // {
      default = config.home-manager.dev.enable;
    };

    permissions.containers.enable = lib.mkEnableOption "Podman-backed container command permissions";
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ctx7
      defuddle
      llm-agents.beads
      llm-agents.mardi-gras
    ];
  };
}
