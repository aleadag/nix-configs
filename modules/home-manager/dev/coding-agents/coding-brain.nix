{
  config,
  lib,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.coding-brain;
in
{
  options.home-manager.dev.coding-agents.coding-brain = {
    enable = lib.mkEnableOption "Coding Brain" // {
      default = config.home-manager.dev.coding-agents.codex.enable;
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
