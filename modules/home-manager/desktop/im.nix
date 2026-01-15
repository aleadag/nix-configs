{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.desktop.im;
  fcitx5-rime-with-data = pkgs.fcitx5-rime.override {
    rimeDataPkgs = with pkgs; [
      rime-data # base data with default.yaml, punctuation.yaml, etc.
      rime-ice
      rime-moegirl
      rime-zhwiki
    ];
  };
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
        addons = [ fcitx5-rime-with-data ];
        waylandFrontend = config.home-manager.window-manager.wayland.enable;
        settings = {
          globalOptions = {
            Hotkey = {
              EnumerateWithTriggerKeys = true;
              EnumerateSkipFirst = false;
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
              ActiveByDefault = false;
              ShareInputState = "No";
              PreeditEnabledByDefault = true;
              ShowInputMethodInformation = true;
              showInputMethodInformationWhenFocusIn = false;
              CompactInputMethodInformation = true;
              ShowFirstInputMethodInformation = true;
              DefaultPageSize = 6;
              OverrideXkbOption = false;
              PreloadInputMethod = true;
            };
          };

          inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "rime";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1".Name = "rime";
          };

          addons = {
            rime.globalSection.SwitchKey = "Control+F4";
            unicode.sections = {
              TriggerKey."0" = "Control+Alt+Shift+U";
              DirectUnicodeMode."0" = "Shift+Super+U";
            };
          };
        };
      };
    };

    xdg.dataFile."fcitx5/rime/default.custom.yaml".text = # yaml
      ''
        patch:
          schema_list:
            - schema: rime_ice
          menu:
            page_size: 6
          ascii_composer:
            switch_key:
              Shift_L: commit_code
              Shift_R: commit_code
      '';
  };
}
