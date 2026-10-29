{ flake, pkgs }:
let
  inherit (pkgs) lib;
  home =
    extra:
    (flake.inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { inherit flake; };
      modules = [
        flake.inputs.stylix.homeModules.stylix
        ../modules/home-manager/window-manager/wayland/niri.nix
        {
          options.home-manager.window-manager = {
            wayland.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            default = lib.mkOption {
              type = lib.types.attrs;
              default = {
                terminal = "test-terminal";
                browser = "test-browser";
              };
            };
          };
          config = {
            home = {
              username = "niri-test";
              homeDirectory = "/home/niri-test";
              stateVersion = "26.05";
            };
            stylix.enable = false;
          };
        }
        extra
      ];
    }).config;
  enabled = home { };
  systemProvided = home { home-manager.window-manager.wayland.niri.package = null; };
  keyboard = home {
    home.keyboard = {
      layout = "us";
      variant = "intl";
      options = [ "caps:escape" ];
    };
  };
  disabled = home { home-manager.window-manager.wayland.niri.enable = false; };
in
assert enabled.wayland.windowManager.niri.enable;
assert systemProvided.wayland.windowManager.niri.enable;
assert systemProvided.wayland.windowManager.niri.package == null;
assert !systemProvided.wayland.windowManager.niri.systemd.enable;
assert systemProvided.systemd.user.packages == [ ];
assert systemProvided.warnings == [ ];
assert
  (systemProvided.xdg.portal.config.niri or { }) == {
    default = "gnome;gtk";
    "org.freedesktop.impl.portal.Access" = "gtk";
    "org.freedesktop.impl.portal.Notification" = "gtk";
    "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };
assert enabled.xdg.portal.config == { };
assert !(disabled.xdg.configFile ? "niri/config.kdl");
assert lib.all (a: a.assertion) (enabled.assertions ++ systemProvided.assertions);
pkgs.runCommand "niri-config-check" { nativeBuildInputs = [ pkgs.niri ]; } ''
  niri validate --config ${enabled.xdg.configFile."niri/config.kdl".source}
  niri validate --config ${systemProvided.xdg.configFile."niri/config.kdl".source}
  niri validate --config ${keyboard.xdg.configFile."niri/config.kdl".source}
  grep -F 'layout "us"' ${keyboard.xdg.configFile."niri/config.kdl".source}
  grep -F 'variant "intl"' ${keyboard.xdg.configFile."niri/config.kdl".source}
  grep -F 'options "caps:escape"' ${keyboard.xdg.configFile."niri/config.kdl".source}
  touch "$out"
''
