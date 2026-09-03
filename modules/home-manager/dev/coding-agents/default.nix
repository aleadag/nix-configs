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
    ./beads.nix
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

    permissions = {
      containers.enable = lib.mkEnableOption "Podman-backed container command permissions";

      allowedCommands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra shell commands permitted across coding agents";
      };

      deniedCommands = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra dangerous commands explicitly denied across coding agents";
      };

      autoDiscoverPackages = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to automatically discover executable commands from home.packages";
      };

      packageBinaryOverrides = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = {
          python3 = [
            "python"
            "python3"
            "python3.14"
          ];
          coreutils = [
            "cat"
            "cp"
            "date"
            "diff"
            "echo"
            "head"
            "id"
            "ls"
            "mkdir"
            "mv"
            "pwd"
            "rm"
            "sleep"
            "sort"
            "stat"
            "tail"
            "test"
            "touch"
            "tr"
            "uname"
            "uniq"
            "wc"
            "whoami"
          ];
          bun = [
            "bun"
            "bunx"
          ];
          nodejs = [
            "corepack"
            "node"
            "npm"
            "npx"
            "pnpm"
          ];
          nodejs_20 = [
            "corepack"
            "node"
            "npm"
            "npx"
            "pnpm"
          ];
          nodejs_22 = [
            "corepack"
            "node"
            "npm"
            "npx"
            "pnpm"
          ];
          findutils = [
            "find"
            "xargs"
          ];
          diffutils = [
            "diff"
            "cmp"
          ];
          gnused = [ "sed" ];
          gnugrep = [ "grep" ];
          gnumake = [ "make" ];
        };
        description = "Mapping of package names/pnames to the binary commands they provide";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      ctx7
      defuddle
    ];
  };
}
