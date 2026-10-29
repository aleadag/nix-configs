{ flake, pkgs }:

let
  inherit (pkgs) lib;
  permissions =
    extra:
    (flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ../modules/home-manager/dev/coding-agents/permissions.nix
        {
          home = {
            username = "permissions-test";
            homeDirectory = "/home/permissions-test";
            stateVersion = "24.11";
          };
        }
        extra
      ];
    }).config.home-manager.dev.coding-agents.permissions;

  standalone = permissions { };
  contributed = permissions {
    home-manager.dev.coding-agents.permissions.commonExternalDirectories = [
      "/agent/config"
    ];
  };
in
assert lib.assertMsg (
  standalone.commonExternalDirectories == [ "/nix/store" ]
) "Shared permissions must evaluate without any agent modules";
assert lib.assertMsg (
  lib.sort builtins.lessThan contributed.commonExternalDirectories == [
    "/agent/config"
    "/nix/store"
  ]
) "Agent directory contributions must merge with shared read-only directories";
assert lib.assertMsg (
  lib.elem "git push" standalone.deniedShellCommands
  && !(lib.elem "git push" standalone.allowedShellCommands)
) "Standalone permissions must retain command restrictions";
pkgs.runCommandLocal "coding-agent-permissions-check" { } ''
  touch "$out"
''
