{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.window-manager.wayland.niri;
  menu = lib.getExe config.programs.fuzzel.package;
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  niri = if cfg.package != null then lib.getExe' cfg.package "niri" else "niri";
  niriPowerMenu = pkgs.writeShellApplication {
    name = "niri-power-menu";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      action="$(
        printf '%s\t%s\n' \
          '🚪' 'Exit' \
          '🔒' 'Lock-screen' \
          '☕️' 'Caffeine' \
          '⏸️' 'Suspend' \
          '😴' 'Sleep' \
          '💤' 'Hibernate' \
          '🔄' 'Reboot' \
          '📴' 'Shutdown' | ${menu} -d --tabs=4
      )"

      case "$action" in
        *Exit) ${niri} msg action quit ;;
        *Lock-screen) ${loginctl} lock-session ;;
        *Caffeine) caffeine-toggle ;;
        *Suspend) ${systemctl} suspend ;;
        *Sleep) ${systemctl} sleep ;;
        *Hibernate) ${systemctl} hibernate ;;
        *Reboot) ${systemctl} reboot ;;
        *Shutdown) ${systemctl} poweroff ;;
        *) exit 0 ;;
      esac
    '';
  };
  inherit (config.home-manager.window-manager.default) terminal browser;
  wallpaperMode = config.stylix.imageScalingMode;
  layout = if config.home.keyboard != null then config.home.keyboard.layout else null;
  variant = if config.home.keyboard != null then config.home.keyboard.variant else null;
  xkbOptions =
    if config.home.keyboard != null then lib.concatStringsSep "," config.home.keyboard.options else "";
  action = name: {
    ${name} = { };
  };
  settings = {
    input = {
      keyboard = {
        numlock = { };
        xkb =
          lib.optionalAttrs (layout != null) { inherit layout; }
          // lib.optionalAttrs (variant != null) { inherit variant; }
          // lib.optionalAttrs (xkbOptions != "") { options = xkbOptions; };
      };
      touchpad = {
        tap = { };
        dwt = { };
        natural-scroll = { };
        scroll-method = "two-finger";
        middle-emulation = { };
      };
      mouse.accel-profile = "flat";
      workspace-auto-back-and-forth = { };
    };

    layout = {
      gaps = 8;
      center-focused-column = "always";
      preset-column-widths._children = map (proportion: { inherit proportion; }) [
        0.33333
        0.5
        0.66667
      ];
      default-column-width.proportion = 0.66667;
      focus-ring.width = 2;
      border = {
        off = { };
        width = 2;
      };
      shadow = {
        off = { };
        softness = 30;
        spread = 5;
        offset._props = {
          x = 0;
          y = 5;
        };
      };
    };

    _children = [
      { spawn-sh-at-startup = "xrdb -merge ~/.Xresources"; }
      {
        spawn-at-startup = [
          (lib.getExe pkgs.swaybg)
          "-i"
          (toString config.stylix.image)
          "-m"
          wallpaperMode
        ];
      }
      {
        window-rule = {
          match._props = {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          };
          open-floating = true;
        };
      }
    ];
    hotkey-overlay.skip-at-startup = { };

    # Ask clients to omit client-side decorations when possible. Explicit CSD requests are still
    # honored. Marking clients as tiled can also remove rounded corners and fix border or
    # focus-ring rendering behind semitransparent windows. Restart applications after changing this.
    prefer-no-csd = { };

    screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S-screenshot.png";

    binds = {
      "Mod+Ctrl+Slash" = action "show-hotkey-overlay";
      "Mod+D" = {
        spawn-sh = menu;
        _props.hotkey-overlay-title = "Run an Application";
      };
      "Mod+Return" = {
        spawn-sh = terminal;
        _props.hotkey-overlay-title = "Open Terminal";
      };
      "Mod+B" = {
        spawn-sh = browser;
        _props.hotkey-overlay-title = "Open Browser";
      };
      "Mod+Shift+Escape" = {
        spawn = lib.getExe niriPowerMenu;
        _props.hotkey-overlay-title = "Power Menu";
        _props.allow-inhibiting = false;
      };
      "Super+Alt+L" = {
        spawn = [
          loginctl
          "lock-session"
        ];
        _props.hotkey-overlay-title = "Lock the Screen";
        _props.allow-inhibiting = false;
      };

      "XF86AudioRaiseVolume" = {
        spawn-sh = "${lib.getExe pkgs.pamixer} --set-limit 150 --allow-boost -i 5";
        _props.allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        spawn-sh = "${lib.getExe pkgs.pamixer} --set-limit 150 --allow-boost -d 5";
        _props.allow-when-locked = true;
      };
      "XF86AudioMute" = {
        spawn-sh = "${lib.getExe pkgs.pamixer} --toggle-mute";
        _props.allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        spawn-sh = "${lib.getExe pkgs.pamixer} --toggle-mute --default-source";
        _props.allow-when-locked = true;
      };
      "XF86AudioPlay" = {
        spawn-sh = "${lib.getExe pkgs.playerctl} play-pause";
        _props.allow-when-locked = true;
      };
      "XF86AudioStop" = {
        spawn-sh = "${lib.getExe pkgs.playerctl} stop";
        _props.allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        spawn-sh = "${lib.getExe pkgs.playerctl} previous";
        _props.allow-when-locked = true;
      };
      "XF86AudioNext" = {
        spawn-sh = "${lib.getExe pkgs.playerctl} next";
        _props.allow-when-locked = true;
      };
      "XF86MonBrightnessUp" = {
        spawn-sh = "${lib.getExe pkgs.brightnessctl} --class=backlight set +5%";
        _props.allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        spawn-sh = "${lib.getExe pkgs.brightnessctl} --class=backlight set -5%";
        _props.allow-when-locked = true;
      };

      "Mod+S" = action "toggle-overview" // {
        _props.repeat = false;
      };
      "Mod+Shift+Slash" = action "close-window" // {
        _props.repeat = false;
      };

      "Mod+Left" = action "focus-column-left";
      "Mod+Down" = action "focus-window-down";
      "Mod+Up" = action "focus-window-up";
      "Mod+Right" = action "focus-column-right";
      "Mod+H" = action "focus-column-left";
      "Mod+J" = action "focus-window-down";
      "Mod+K" = action "focus-window-up";
      "Mod+L" = action "focus-column-right";

      "Mod+Shift+Left" = action "move-column-left";
      "Mod+Shift+Down" = action "move-window-down";
      "Mod+Shift+Up" = action "move-window-up";
      "Mod+Shift+Right" = action "move-column-right";
      "Mod+Shift+H" = action "move-column-left";
      "Mod+Shift+J" = action "move-window-down";
      "Mod+Shift+K" = action "move-window-up";
      "Mod+Shift+L" = action "move-column-right";

      "Mod+Home" = action "focus-column-first";
      "Mod+End" = action "focus-column-last";
      "Mod+Ctrl+Home" = action "move-column-to-first";
      "Mod+Ctrl+End" = action "move-column-to-last";

      "Mod+Ctrl+Left" = action "move-workspace-to-monitor-left";
      "Mod+Ctrl+Down" = action "move-workspace-to-monitor-down";
      "Mod+Ctrl+Up" = action "move-workspace-to-monitor-up";
      "Mod+Ctrl+Right" = action "move-workspace-to-monitor-right";
      "Mod+Ctrl+H" = action "move-workspace-to-monitor-left";
      "Mod+Ctrl+J" = action "move-workspace-to-monitor-down";
      "Mod+Ctrl+K" = action "move-workspace-to-monitor-up";
      "Mod+Ctrl+L" = action "move-workspace-to-monitor-right";

      "Mod+Ctrl+Shift+Left" = action "focus-monitor-left";
      "Mod+Ctrl+Shift+Down" = action "focus-monitor-down";
      "Mod+Ctrl+Shift+Up" = action "focus-monitor-up";
      "Mod+Ctrl+Shift+Right" = action "focus-monitor-right";
      "Mod+Ctrl+Shift+H" = action "focus-monitor-left";
      "Mod+Ctrl+Shift+J" = action "focus-monitor-down";
      "Mod+Ctrl+Shift+K" = action "focus-monitor-up";
      "Mod+Ctrl+Shift+L" = action "focus-monitor-right";

      "Mod+Page_Down" = action "focus-workspace-down";
      "Mod+Page_Up" = action "focus-workspace-up";
      "Mod+Shift+Page_Down" = action "move-column-to-workspace-down";
      "Mod+Shift+Page_Up" = action "move-column-to-workspace-up";

      "Mod+WheelScrollDown" = action "focus-workspace-down" // {
        _props.cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = action "focus-workspace-up" // {
        _props.cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollDown" = action "move-column-to-workspace-down" // {
        _props.cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollUp" = action "move-column-to-workspace-up" // {
        _props.cooldown-ms = 150;
      };
      "Mod+WheelScrollRight" = action "focus-column-right";
      "Mod+WheelScrollLeft" = action "focus-column-left";
      "Mod+Ctrl+WheelScrollRight" = action "move-column-right";
      "Mod+Ctrl+WheelScrollLeft" = action "move-column-left";
      "Mod+Shift+WheelScrollDown" = action "focus-column-right";
      "Mod+Shift+WheelScrollUp" = action "focus-column-left";
      "Mod+Ctrl+Shift+WheelScrollDown" = action "move-column-right";
      "Mod+Ctrl+Shift+WheelScrollUp" = action "move-column-left";

      "Mod+Q".focus-workspace = 1;
      "Mod+W".focus-workspace = 2;
      "Mod+E".focus-workspace = 3;
      "Mod+R".focus-workspace = 4;
      "Mod+T".focus-workspace = 5;
      "Mod+Y".focus-workspace = 6;
      "Mod+U".focus-workspace = 7;
      "Mod+I".focus-workspace = 8;
      "Mod+O".focus-workspace = 9;
      "Mod+P".focus-workspace = 10;
      "Mod+Shift+Q".move-column-to-workspace = 1;
      "Mod+Shift+W".move-column-to-workspace = 2;
      "Mod+Shift+E".move-column-to-workspace = 3;
      "Mod+Shift+R".move-column-to-workspace = 4;
      "Mod+Shift+T".move-column-to-workspace = 5;
      "Mod+Shift+Y".move-column-to-workspace = 6;
      "Mod+Shift+U".move-column-to-workspace = 7;
      "Mod+Shift+I".move-column-to-workspace = 8;
      "Mod+Shift+O".move-column-to-workspace = 9;
      "Mod+Shift+P".move-column-to-workspace = 10;

      "Mod+Tab" = action "focus-workspace-previous" // {
        _props.hotkey-overlay-title = "Switch Focus Between Workspaces";
      };
      "Mod+BracketLeft" = action "consume-or-expel-window-left";
      "Mod+BracketRight" = action "consume-or-expel-window-right";
      "Mod+Period" = action "switch-preset-column-width";
      "Mod+Shift+Period" = action "switch-preset-window-height";
      "Mod+Ctrl+Period" = action "reset-window-height";
      "Mod+Ctrl+M" = action "maximize-column";
      "Mod+F" = action "fullscreen-window";
      "Mod+Shift+M" = action "maximize-window-to-edges" // {
        _props.hotkey-overlay-title = "Maximize Window";
      };
      "Mod+Ctrl+F" = action "expand-column-to-available-width";
      "Mod+C" = action "center-column";
      "Mod+Ctrl+C" = action "center-visible-columns";
      "Mod+Minus".set-column-width = "-10%";
      "Mod+Equal".set-column-width = "+10%";
      "Mod+Shift+Minus".set-window-height = "-10%";
      "Mod+Shift+Equal".set-window-height = "+10%";
      "Mod+Shift+F" = action "toggle-window-floating";
      "Mod+Shift+V" = action "switch-focus-between-floating-and-tiling";
      "Mod+Ctrl+T" = action "toggle-column-tabbed-display";
      "Print" = action "screenshot";
      "Ctrl+Print" = action "screenshot-screen";
      "Alt+Print" = action "screenshot-window";
      "Mod+Escape" = action "toggle-keyboard-shortcuts-inhibit" // {
        _props.allow-inhibiting = false;
      };
      "Ctrl+Alt+Delete" = action "quit";
      "Mod+Shift+Alt+P" = action "power-off-monitors";
    };

    environment = {
      NIXOS_OZONE_WL = "1";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
    }
    // lib.optionalAttrs (config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5") {
      XMODIFIERS = "@im=fcitx";
    };

    xwayland-satellite = {
      path = lib.getExe pkgs.xwayland-satellite;
    };
  };
in
{
  options.home-manager.window-manager.wayland.niri = {
    enable = lib.mkEnableOption "Niri config" // {
      default = config.home-manager.window-manager.wayland.enable;
    };
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.niri;
      defaultText = lib.literalExpression "pkgs.niri";
      description = "The niri package to use. Set to null to use the system-provided package.";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.niri = {
      enable = true;
      inherit (cfg) package;
      systemd.enable = cfg.package != null;
      settings = lib.mkMerge [
        settings
        (lib.mkIf config.stylix.enable {
          cursor = lib.mkIf (config.stylix.cursor != null) {
            xcursor-size = lib.mkDefault config.stylix.cursor.size;
            xcursor-theme = lib.mkDefault config.stylix.cursor.name;
          };
          layout.border = with config.lib.stylix.colors.withHashtag; {
            active-color = lib.mkDefault base0D;
            inactive-color = lib.mkDefault base03;
          };
        })
      ];
    };

    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
