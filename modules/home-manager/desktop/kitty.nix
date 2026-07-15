{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.kitty;
  kittyPackage = pkgs.symlinkJoin {
    name = "${pkgs.kitty.name}-single-instance";
    paths = [ pkgs.kitty ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/kitty" \
        --run 'if [[ -z "''${TMPDIR:-}" ]]; then export TMPDIR="''${XDG_RUNTIME_DIR:?TMPDIR and XDG_RUNTIME_DIR are both unset}"; fi' \
        --run 'case "''${1:-}" in @ | +*) ;; *) set -- --single-instance "$@" ;; esac'
    '';
    inherit (pkgs.kitty) meta;
  };
in
{
  options.home-manager.desktop.kitty = {
    enable = lib.mkEnableOption "Kitty config" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
    scrollback-nvim.enable = lib.mkEnableOption "kitty-scrollback.nvim" // {
      default = config.home-manager.editor.neovim.enable;
    };
    useSuperKeybindings = lib.mkEnableOption "keybindings with Super/Command" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.window-manager.default.terminal = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
      lib.mkDefault (lib.getExe kittyPackage)
    );

    programs.kitty = {
      enable = true;
      package = lib.mkDefault kittyPackage;
      actionAliases = {
        "kitty_scrollback_nvim" =
          lib.optionalString cfg.scrollback-nvim.enable "kitten ${pkgs.vimPlugins.kitty-scrollback-nvim}/python/kitty_scrollback_nvim.py";
      };
      keybindings = {
        "kitty_mod+n" = "new_tab_with_cwd"; # moved from 't' to avoid conflict
        "kitty_mod+enter" = "new_window_with_cwd";
        "kitty_mod+backspace" = "change_font_size all 0";
        "alt+q" = "goto_tab 1";
        "alt+w" = "goto_tab 2";
        "alt+e" = "goto_tab 3";
        "alt+r" = "goto_tab 4";
        "alt+t" = "goto_tab 5";
        "alt+y" = "goto_tab 6";
        "alt+u" = "goto_tab 7";
        "alt+i" = "goto_tab 8";
        "alt+o" = "goto_tab 9";
        "alt+p" = "goto_tab 10";
        # https://github.com/jtroo/kanata/issues/1957
        "f24" = "discard_event";
        "ctrl+f24" = "discard_event";
        "shift+f24" = "discard_event";
        "ctrl+shift+f24" = "discard_event";
      }
      // lib.optionalAttrs cfg.scrollback-nvim.enable {
        "kitty_mod+h" = "kitty_scrollback_nvim";
        "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
      };
      settings = {
        kitty_mod = lib.mkIf cfg.useSuperKeybindings "super";

        # When using home-manager in standalone mode it is not always possible
        # to change the default shell for the user, so let's force it here
        shell = lib.mkIf (
          config.home-manager.cli.zsh.enable && config.targets.genericLinux.enable
        ) "${config.home.profileDirectory}/bin/zsh";

        # Scrollback
        scrollback_lines = 10000;

        # Reduce lag
        sync_to_monitor = false;
        repaint_delay = 10;
        input_delay = 0;

        allow_remote_control = "socket-only";
        listen_on = "unix:\${TMPDIR}/kitty";

        # Bell
        bell_on_tab = "🔔 ";
        enable_audio_bell = false;
        visual_bell_duration = "0.0";
        window_alert_on_bell = true;
        macos_dock_badge_on_bell = true;

        # Notification
        notify_on_cmd_finish = "unfocused";

        cursor_trail = 1;

        # Tabs
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_powerline_style = "round";
        tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{tab.last_focused_progress_percent}[{layout_name[:1]}] {index}:{title}";
        # always show tabs when not using window-manager
        tab_bar_min_tabs = lib.mkIf (!config.home-manager.window-manager.enable) 1;
        tab_title_max_length = 30;

        # Misc
        clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
        editor = lib.mkIf config.home-manager.window-manager.enable config.home-manager.window-manager.default.editor;
        # ctrl+shift+l / super+l
        enabled_layouts = "tall,fat,grid,horizontal,vertical,stack";
        hide_window_decorations = "titlebar-only";
        macos_menubar_title_max_length = 50;
        macos_quit_when_last_window_closed = true;
        macos_show_window_title_in = "window";
        strip_trailing_spaces = "smart";
        window_padding_width = 5;
        confirm_os_window_close = 0;

        # Simulate middle-click copy-and-paste, but instead of copying to
        # clipboard it copies to a private buffer
        copy_on_select = "select_buffer";
        "mouse_map middle release ungrabbed paste_from_buffer" = "select_buffer";

        # Fix for Wayland slow scrolling
        touch_scroll_multiplier = lib.mkIf config.home-manager.desktop.enable "5.0";
      }
      // lib.optionalAttrs cfg.scrollback-nvim.enable {
        shell_integration = true;
      };

      darwinLaunchOptions = [
        "--single-instance"
        # It seems macOS sometimes start a non-login shell, force it here
        "${lib.getExe config.programs.zsh.package} --login"
      ];

      shellIntegration.mode = "enabled";
    };

    programs.zsh.initContent =
      lib.mkIf config.programs.zsh.enable # bash
        ''
          # Do not enable those alias in non-kitty terminal
          if [[ -n "$KITTY_PID" ]]; then
            alias imgcat="kitty +kitten icat"
            alias ssh="kitty +kitten ssh $@"
            alias ssh-compat="TERM=xterm-256color \ssh"
          fi
        '';

    programs.fish.shellAbbrs = lib.mkIf config.programs.fish.enable rec {
      imgcat = "kitty +kitten icat";
      kssh = "kitty +kitten ssh";
      kssh-compat = "TERM=xterm-256color ${kssh}";
    };
  };
}
