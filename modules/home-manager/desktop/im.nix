{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.desktop.im;
in
{
  options.home-manager.desktop.im = {
    enable = lib.mkEnableOption "Input method config" // {
      default = config.home-manager.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [ fcitx5-chinese-addons ];
        waylandFrontend = config.home-manager.window-manager.wayland.enable;
        settings = {
          globalOptions = {
            Hotkey = {
              EnumerateWithTriggerKeys = true;
              EnumerateSkipFirst = false;
              ModifierOnlyKeyTimeout = 250;
            };
            "Hotkey/EnumerateForwardKeys" = {
              "0" = "Super+space";
            };
            "Hotkey/EnumerateBackwardKeys" = {
              "0" = "Super+Shift+space";
            };
            "Hotkey/PrevPage" = {
              "0" = "Up";
            };
            "Hotkey/NextPage" = {
              "0" = "Down";
            };
            "Hotkey/PrevCandidate" = {
              "0" = "Shift+Tab";
            };
            "Hotkey/NextCandidate" = {
              "0" = "Tab";
            };
            Behavior = {
              # Active By Default
              ActiveByDefault = false;
              # Share Input State
              ShareInputState = "No";
              # Show preedit in application
              PreeditEnabledByDefault = true;
              # Show Input Method Information when switch input method
              ShowInputMethodInformation = true;
              # Show Input Method Information when changing focus
              showInputMethodInformationWhenFocusIn = false;
              # Show compact input method information
              CompactInputMethodInformation = true;
              # Show first input method information
              ShowFirstInputMethodInformation = true;
              # Default page size
              DefaultPageSize = 5;
              # Override Xkb Option
              OverrideXkbOption = false;
              # Preload input method to be used by default
              PreloadInputMethod = true;
            };
          };

          inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "pinyin";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1".Name = "pinyin";
          };
        };
      };
    };
  };
}
