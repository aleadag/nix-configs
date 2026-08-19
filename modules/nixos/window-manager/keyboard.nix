{
  config,
  lib,
  ...
}:

let
  cfg = config.nixos.window-manager.keyboard;
in
{
  options.nixos.window-manager.keyboard = {
    layout = lib.mkOption {
      type = lib.types.str;
      description = "Keyboard layout.";
      default = "us";
    };
    variant = lib.mkOption {
      type = lib.types.str;
      description = "Keyboard layout variant.";
      default = "intl";
    };
    options = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "XKB options.";
      default = [
        "caps:escape"
        "grp:win_space_toggle"
      ];
    };
  };

  config = lib.mkIf config.nixos.window-manager.enable {
    nixos.home.extraModules = {
      home.keyboard = {
        inherit (cfg) layout variant options;
      };
    };

    # Configure the virtual console keymap
    console.keyMap = lib.mkDefault "us";
  };
}
