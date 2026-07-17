{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./antigravity-cli.nix
    ./claude-code.nix
    ./codex.nix
    ./mcp.nix
  ];

  options.home-manager.dev.coding-agents.enable = lib.mkEnableOption "coding agent config" // {
    default = config.home-manager.dev.enable;
  };

  config = lib.mkIf config.home-manager.dev.coding-agents.enable {
    home.packages = with pkgs; [
      llm-agents.agent-deck
      tmux # requires by agent-deck
      ctx7
    ];
  };
}
