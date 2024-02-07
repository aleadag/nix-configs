{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    # Does not work in Arch Linux, need to install the version comes with yay
    enable = true;
    settings = {
      env.TERM = "xterm-256color";
      env.TERM_PROGRAM = "Alacritty";
      shell = {
        program = "${pkgs.zsh}/bin/zsh";
        args = [ "-l" "-c" "tmux attach || tmux" ];
      };
      font = let fontname = "JetBrainsMono Nerd Font";
      in {
        normal = {
          family = fontname;
          style = "Bold";
        };
        bold = {
          family = fontname;
          style = "Bold";
        };
        italic = {
          family = fontname;
          style = "Light";
        };
        size = 12;
      };
      # Colors (Solarized Dark)
      colors = {
        # default colors
        primary = {
          background = "#002b36"; # base03
          foreground = "#839496"; # base0
        };

        cursor = {
          text = "#002b36";
          cursor = "#839496";
        };

        normal = {
          black = "#073642"; # base02
          red = "#dc322f"; # red
          green = "#859900"; # green
          yellow = "#b58900"; # yellow
          blue = "#268bd2"; # blue
          magenta = "#d33682"; # magenta
          cyan = "#2aa198"; # cyan
          white = "#eee8d5"; # base2;
        };

        bright = {
          black = "#586e75"; # base01
          red = "#cb4b16"; # orange
          green = "#586e75"; # base01
          yellow = "#657b83"; # base00
          blue = "#839496"; # base0
          magenta = "#6c71c4"; # violet
          cyan = "#93a1a1"; # base1
          white = "#fdf6e3"; # base3
        };
      };
    };
  };
}
