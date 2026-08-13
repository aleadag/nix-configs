{
  config,
  lib,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents.opencode;
  shared = import ./shared.nix {
    inherit
      config
      flake
      lib
      pkgs
      ;
  };
in
{
  options.home-manager.dev.coding-agents.opencode = {
    enable = lib.mkEnableOption "OpenCode CLI tool" // {
      default = config.home-manager.dev.coding-agents.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;
      package = pkgs.llm-agents.opencode;
      inherit (shared) context;
      settings = {
        autoshare = false;
        autoupdate = false;
        model = "deepseek/deepseek-v4-pro";
      };
      skills =
        lib.optionalAttrs config.home-manager.cli.jujutsu.enable shared.jujutsuSkills
        // shared.obsidianSkills
        // shared.localSkills;
    };
  };
}
