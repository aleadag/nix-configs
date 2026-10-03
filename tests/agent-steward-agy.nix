{ flake, pkgs }:
let
  inherit (pkgs) lib;
  testPkgs = pkgs.extend (
    _: _: {
      llm-agents.antigravity-cli = pkgs.writeShellScriptBin "agy" "exit 1";
    }
  );
  home =
    stewardEnabled:
    import ./agent-steward-home.nix {
      inherit flake;
      pkgs = testPkgs;
      extra = { lib, ... }: {
        imports = [
          ../modules/home-manager/dev/coding-agents/antigravity-cli.nix
          ../modules/home-manager/meta/mutable-config.nix
        ];
        options.home-manager.dev.coding-agents = {
          permissions = lib.mkOption {
            type = lib.types.attrs;
            default = {
              allowedShellCommands = [ "pwd" ];
              deniedShellCommands = [ "rm -rf /" ];
              commonExternalDirectories = [ ];
              commonNetworkDomains = [ ];
              finalAllowedWriteDirectories = [ ];
            };
          };
          plugins = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            default = { };
          };
          context = lib.mkOption {
            type = lib.types.str;
            default = "Synthetic AGY context";
          };
          skillScriptRelativePaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
        config.home-manager.dev.coding-agents.agent-steward.enable = stewardEnabled;
      };
    };
  enabled = home true;
  disabled = home false;
  fixture = pkgs.writeText "agent-steward-agy-fixture.json" (
    builtins.toJSON {
      home = enabled.home.homeDirectory;
      state = enabled.xdg.stateHome;
      activation = enabled.home.activation.injectMutableSettings.data;
      directories = enabled.home.activation.initAgyQuotaDirectories.data or "";
      statusLine = enabled.programs.antigravity-cli.settings.statusLine;
      settings = enabled.home.file.".gemini/antigravity-cli/settings.json".source;
    }
  );
in
assert lib.length (lib.attrNames disabled.mutableConfig.files) == 1;
assert !(disabled.home.activation ? initAgyQuotaDirectories);
pkgs.runCommand "agent-steward-agy-check"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.bash
      pkgs.coreutils
    ];
  }
  ''
    python3 ${./agent-steward-agy.test.py} ${fixture}
    touch "$out"
  ''
