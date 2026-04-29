{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.ghostty;
  ghosttyMod = if cfg.useSuperKeybindings then "super" else "ctrl+shift";
in
{
  options.home-manager.desktop.ghostty = {
    enable = lib.mkEnableOption "Ghostty config" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
    useSuperKeybindings = lib.mkEnableOption "keybindings with Super/Command";
    fontSize = lib.mkOption {
      type = lib.types.float;
      description = "Font size.";
      default = if config.home-manager.darwin.enable then 14.0 else 12.0;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableZshIntegration = config.programs.zsh.enable;
      package = lib.mkDefault (
        if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty
      );
      settings = {
        font-size = cfg.fontSize;

        confirm-close-surface = false;
        scrollback-limit = 10000;

        window-padding-x = 5;
        window-padding-y = 5;
        window-inherit-working-directory = true;
        tab-inherit-working-directory = true;
        split-inherit-working-directory = true;
        window-inherit-font-size = true;
        window-show-tab-bar = "always"; # without window decoration, we will always show tabbar

        link-previews = true;

        # https://github.com/sahaj-b/ghostty-cursor-shaders
        custom-shader = toString ./cursor_warp.glsl;

        keybind = [
          "${ghosttyMod}+n=new_tab"
          "${ghosttyMod}+enter=new_window"
          "${ghosttyMod}+backspace=reset_font_size"
          "${ghosttyMod}+,=move_tab:-1"
          "${ghosttyMod}+.=move_tab:1"
          "alt+q=goto_tab:1"
          "alt+w=goto_tab:2"
          "alt+e=goto_tab:3"
          "alt+r=goto_tab:4"
          "alt+t=goto_tab:5"
          "alt+y=goto_tab:6"
          "alt+u=goto_tab:7"
          "alt+i=goto_tab:8"
          "alt+o=goto_tab:9"
          "alt+p=goto_tab:10"
          "alt+h=previous_tab"
          "alt+l=next_tab"
        ];
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        window-decoration = "none";
        gtk-custom-css = toString (
          pkgs.writeText "ghostty-linux-tabs.css"
            # css
            ''
              /* Ghostty GTK tabs on top: shrink from the bottom, don't push into the titlebar. */
              tabbar {
                margin-top: 0;
                margin-bottom: -16px;
              }

              tabbar tabbox {
                transform: translateY(-8px);
              }

              tabbar tabbox tab {
                min-height: 20px;
                margin-top: 4px;
                margin-bottom: 4px;
              }

              tabbar tabbox button,
              windowcontrols button {
                min-height: 20px;
              }
            ''
        );
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        font-thicken = true;
        font-thicken-strength = 100;
        macos-titlebar-style = "tabs";
      };
    };
  };
}
