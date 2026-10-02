{
  flake,
  pkgs,
  extra ? { },
  secretPath ? "synthetic secret.key",
}:
(flake.inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = { inherit flake; };
  modules = [
    ../modules/home-manager/dev/coding-agents/agent-steward/default.nix
    ({ lib, ... }: {
      options = {
        home-manager.dev.coding-agents = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
          };
          herdr = {
            enable = lib.mkEnableOption "synthetic Herdr";
            plugins = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
            };
          };
          skills = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            default = { };
          };
        };
        home-manager.sops.enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
        sops.secrets = lib.mkOption {
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }: {
                options = {
                  key = lib.mkOption {
                    type = lib.types.str;
                    default = name;
                  };
                  mode = lib.mkOption {
                    type = lib.types.str;
                    default = "0400";
                  };
                  path = lib.mkOption {
                    type = lib.types.str;
                    default = secretPath;
                  };
                };
              }
            )
          );
        };
      };
      config.home = {
        username = "steward-test";
        homeDirectory =
          if pkgs.stdenv.hostPlatform.isDarwin then "/Users/steward-test" else "/home/steward-test";
        stateVersion = "24.11";
      };
    })
    extra
  ];
}).config
