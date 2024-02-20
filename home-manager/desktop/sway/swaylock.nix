{ config, pkgs, lib, ... }:

{
  options.home-manager.desktop.sway.swaylock.enable = lib.mkEnableOption "swaylock config" // {
    default = config.home-manager.desktop.sway.enable;
  };

  config = lib.mkIf config.home-manager.desktop.sway.swaylock.enable {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock;
      settings = with config.home-manager.desktop.theme.colors; {
        font = config.home-manager.desktop.theme.fonts.gui.name;
        indicator-caps-lock = true;
        show-keyboard-layout = true;
        # https://stackoverflow.com/a/506662
        # image = with pkgs; toString
        #   (runCommand "wallpaper-pixelated" { buildInputs = [ imagemagick ]; } ''
        #     convert -scale 1% -scale 10000% ${config.home-manager.desktop.theme.wallpaper.path} $out
        #   '');
        # scaling = config.home-manager.desktop.theme.wallpaper.scale;

        inside-color = mantle;
        line-color = mantle;
        ring-color = text;
        text-color = text;

        inside-clear-color = yellow;
        line-clear-color = yellow;
        ring-clear-color = base;
        text-clear-color = base;

        inside-caps-lock-color = surface1;
        line-caps-lock-color = surface1;
        ring-caps-lock-color = base;
        text-caps-lock-color = base;

        inside-ver-color = blue;
        line-ver-color = blue;
        ring-ver-color = base;
        text-ver-color = base;

        inside-wrong-color = red;
        line-wrong-color = red;
        ring-wrong-color = base;
        text-wrong-color = base;

        caps-lock-bs-hl-color = red;
        caps-lock-key-hl-color = teal;
        bs-hl-color = red;
        key-hl-color = teal;
        separator-color = "#00000000"; # transparent
        layout-bg-color = "#00000050"; # semi-transparent black

        indicator-radius = 80;
        indicator-thickness = 10;
      };
    };
  };
}
