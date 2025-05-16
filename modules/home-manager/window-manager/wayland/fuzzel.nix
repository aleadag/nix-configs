{ config, lib, ... }:

let
  cfg = config.home-manager.window-manager.wayland.fuzzel;
in
{
  options.home-manager.window-manager.wayland.fuzzel.enable = lib.mkEnableOption "Fuzzel config" // {
    default = config.home-manager.window-manager.wayland.enable;
  };

  config = lib.mkIf cfg.enable {
    programs.fuzzel = {
      enable = true;
      settings = with config.theme.fonts; {
        main = {
          inherit (config.home-manager.window-manager.default) terminal;
          font = "${gui.name}:style=regular:size=14";
          icon-theme = config.gtk.iconTheme.name;
          lines = 15;
          horizontal-pad = 10;
          vertical-pad = 10;
          line-height = 28;
        };
        key-bindings = {
          # Unmap delete-line-forward since its Control+k mapping conflicts
          # with custom prev mapping, and also unmap delete-line-backward for
          # consistency
          delete-line-backward = "none";
          delete-line-forward = "none";
          prev = "Up Control+p Control+k";
          next = "Down Control+n Control+j";
        };
      };
    };
  };
}
