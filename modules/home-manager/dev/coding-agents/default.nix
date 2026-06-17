{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./claude-code.nix
    ./codex.nix
    ./antigravity-cli.nix
    ./mcp.nix
    ./openspec.nix
  ];

  options.home-manager.dev.coding-agents.enable = lib.mkEnableOption "coding agent config" // {
    default = config.home-manager.dev.enable;
  };

  config = lib.mkIf config.home-manager.dev.coding-agents.enable {
    home.packages = [ pkgs.ctx7 ];
  };
}
