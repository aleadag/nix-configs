{ config, pkgs, lib, ... }:

{
  options.home-manager.desktop.kitty = {
    enable = lib.mkEnableOption "Kitty config" // {
      default = config.home-manager.desktop.enable;
    };
    fontSize = lib.mkOption {
      type = lib.types.float;
      description = "Font size.";
      default = 12.0;
    };
    opacity = lib.mkOption {
      type = lib.types.float;
      description = "Background opacity.";
      default = 0.9;
    };
  };

  config = lib.mkIf config.home-manager.desktop.kitty.enable {
    programs.kitty = {
      enable = true;
      keybindings = { "ctrl+shift+0" = "change_font_size all 0"; };
      font = {
        inherit (config.home-manager.desktop.theme.fonts.symbols) package name;
        size = config.home-manager.desktop.kitty.fontSize;
      };
      theme = "Catppuccin-Frappe";
      settings = {
        # Scrollback
        scrollback_lines = 10000;
        scrollback_pager = "${lib.getExe' pkgs.page "page"} -f";

        # Reduce lag
        sync_to_monitor = false;
        repaint_delay = 10;
        input_delay = 0;

        # Bell
        visual_bell_duration = "0.0";
        enable_audio_bell = false;
        window_alert_on_bell = true;
        bell_on_tab = true;

        # Misc
        editor = config.home-manager.desktop.defaultEditor;
        strip_trailing_spaces = "smart";
        clipboard_control =
          "write-clipboard write-primary read-clipboard read-primary";
        background_opacity = toString config.home-manager.desktop.kitty.opacity;

        # Fix for Wayland slow scrolling
        touch_scroll_multiplier = "5.0";

        # For nnn
        allow_remote_control = lib.mkIf config.programs.nnn.enable true;
        listen_on = "unix:/tmp/kitty";

        # For macOS
        macos_option_as_alt = "yes";

        shell = lib.mkIf config.programs.fish.enable "${config.programs.fish.package}/bin/fish -l";
      };
    };

    programs.zsh.initExtra = lib.mkIf config.programs.zsh.enable /* bash */ ''
      # Do not enable those alias in non-kitty terminal
      if [[ -n "$KITTY_PID" ]]; then
        alias imgcat="kitty +kitten icat"
        alias ssh="kitty +kitten ssh $@"
        alias ssh-compat="TERM=xterm-256color \ssh"
      fi
    '';
  };
}
