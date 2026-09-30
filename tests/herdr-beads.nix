{ flake, pkgs }:

let
  inherit (pkgs) lib;
  host =
    {
      x86_64-linux = "pvg1";
      aarch64-linux = "lckfb";
      aarch64-darwin = "home-mac";
    }
    .${pkgs.stdenv.hostPlatform.system};

  withConfig =
    herdr: beads:
    (flake.homeConfigurations.${host}.extendModules {
      modules = [
        {
          home-manager.dev.coding-agents = {
            herdr.enable = lib.mkForce herdr;
            beads.enable = lib.mkForce beads;
          };
        }
      ];
    }).config;

  enabled = withConfig true true;
  beadsDisabled = withConfig true false;
  herdrDisabled = withConfig false true;

  beadsPlugin = pkgs.herdr-beads;
  hasBeadsPlugin = config: lib.elem beadsPlugin config.home-manager.dev.coding-agents.herdr.plugins;

  dockBinding = {
    command = "herdr-beads.open-dock";
    key = "prefix+shift+b";
    type = "plugin_action";
  };
  boardBinding = {
    command = "herdr-beads.open-board";
    key = "prefix+shift+k";
    type = "plugin_action";
  };

  keyCommands = config: config.programs.herdr.settings.keys.command or [ ];
in
assert lib.assertMsg (hasBeadsPlugin enabled)
  "herdr-beads plugin must be in herdr.plugins when both herdr and beads are enabled";
assert lib.assertMsg (lib.elem dockBinding (
  keyCommands enabled
)) "herdr-beads dock keybinding must be present when beads is enabled";
assert lib.assertMsg (lib.elem boardBinding (
  keyCommands enabled
)) "herdr-beads board keybinding must be present when beads is enabled";
assert lib.assertMsg (
  !(hasBeadsPlugin beadsDisabled)
) "herdr-beads plugin must NOT be in herdr.plugins when beads is disabled";
assert lib.assertMsg (
  !(lib.elem dockBinding (keyCommands beadsDisabled))
) "herdr-beads dock keybinding must NOT be present when beads is disabled";
assert lib.assertMsg (
  !herdrDisabled.programs.herdr.enable
) "programs.herdr must be disabled when herdr.enable is false";
pkgs.runCommandLocal "herdr-beads-check" { } ''
  touch "$out"
''
