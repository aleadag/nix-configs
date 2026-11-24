{
  config,
  lib,
  libEx,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.coding-agents;

in
{
  imports = [
    ./antigravity-cli.nix
    ./agent-steward
    ./beads.nix
    ./claude-code.nix
    ./codex.nix
    ./collie.nix
    ./herdr.nix
    ./pi
    ./mcp.nix
    ./permissions.nix
  ];

  options.home-manager.dev.coding-agents = {
    enable = lib.mkEnableOption "coding agent config" // {
      default = config.home-manager.dev.enable;
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Skills to provide across coding agents (mapping of skill name to skill directory path)";
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = "Attribute set of coding agent plugins providing bundled skills, lifecycle hooks, and manifests.";
    };

    skillScriptRelativePaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Discovered relative script paths across all enabled skills";
    };

    context = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = builtins.readFile ./CONTEXT.md;
      description = "Shared coding agent context";
    };

    strataHost = lib.mkOption {
      type = lib.types.str;
      default = "rtx5090";
      description = "Hostname of the Strata model server shared by coding agents";
    };

    strataPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "HTTP port of the Strata model server";
    };

    strataModel = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.8-flash-next-coder-iq1_m";
      description = "Model id served by the Strata model server";
    };

  };

  config = lib.mkMerge [
    {
      home-manager.dev.coding-agents.skillScriptRelativePaths = libEx.validateSkillScriptRelativePaths (
        libEx.discoverSkillScripts cfg.skills
      );
    }
    (lib.mkIf cfg.enable {
      home-manager.dev.coding-agents.skills = {
        commit-message = ./skills/commit-message;
      };

      home.packages = with pkgs; [
        ctx7
        defuddle
      ];
    })
  ];
}
