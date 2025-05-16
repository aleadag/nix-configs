{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.home-manager.window-manager.x11.rofi.enable = lib.mkEnableOption "rofi config" // {
    default = config.home-manager.window-manager.x11.enable;
  };

  config = lib.mkIf config.home-manager.window-manager.x11.rofi.enable {
    programs.rofi = {
      inherit (config.home-manager.window-manager.default) terminal;
      enable = true;
      package =
        with pkgs;
        rofi.override {
          plugins = [
            rofi-calc
            rofi-emoji
          ];
        };
      font = with config.theme.fonts; "${gui.package} 14";

      extraConfig = {
        show-icons = true;
        modi = "drun,emoji,ssh";
        kb-row-up = "Up,Control+k";
        kb-row-down = "Down,Control+j";
        kb-accept-entry = "Control+m,Return,KP_Enter";
        kb-remove-to-eol = "Control+Shift+e";
        kb-mode-next = "Shift+Right,Control+Tab";
        kb-mode-previous = "Shift+Left,Control+Shift+Tab";
        kb-remove-char-back = "BackSpace";
      };
    };
  };
}
