{
  config,
  flake,
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
    action.${name} = [ ];
  };
  typedSettings = {
    input = {
      keyboard = {
        numlock = true;
        xkb =
          lib.optionalAttrs (layout != null) { inherit layout; }
          // lib.optionalAttrs (variant != null) { inherit variant; }
          // lib.optionalAttrs (xkbOptions != "") { options = xkbOptions; };
      };
      touchpad = {
        tap = true;
        dwt = true;
        natural-scroll = true;
        scroll-method = "two-finger";
        middle-emulation = true;
      };
      mouse.accel-profile = "flat";
      workspace-auto-back-and-forth = true;
    };

    layout = {
      gaps = 8;
      center-focused-column = "always";
      preset-column-widths = map (proportion: { inherit proportion; }) [
        0.33333
        0.5
        0.66667
      ];
      default-column-width.proportion = 0.66667;
      focus-ring = {
        enable = true;
        width = 2;
      };
      border = {
        enable = false;
        width = 2;
      };
      shadow = {
        enable = false;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
      };
    };

    spawn-at-startup = [
      { sh = "xrdb -merge ~/.Xresources"; }
      {
        argv = [
          (lib.getExe pkgs.swaybg)
          "-i"
          (toString config.stylix.image)
          "-m"
          wallpaperMode
        ];
      }
    ];
    hotkey-overlay.skip-at-startup = true;
    screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S-screenshot.png";

    window-rules = [
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
      }
    ];

    binds = {
      "Mod+Ctrl+Slash" = action "show-hotkey-overlay";
      "Mod+D" = {
        action.spawn-sh = menu;
        hotkey-overlay.title = "Run an Application";
      };
      "Mod+Return" = {
        action.spawn-sh = terminal;
        hotkey-overlay.title = "Open Terminal";
      };
      "Mod+M" = {
        action.spawn-sh = browser;
        hotkey-overlay.title = "Open Browser";
      };
      "Mod+Shift+Escape" = {
        action.spawn = lib.getExe niriPowerMenu;
        hotkey-overlay.title = "Power Menu";
        allow-inhibiting = false;
      };
      "Super+Alt+L" = {
        action.spawn = [
          loginctl
          "lock-session"
        ];
        hotkey-overlay.title = "Lock the Screen";
        allow-inhibiting = false;
      };

      "XF86AudioRaiseVolume" = {
        action.spawn-sh = "${lib.getExe pkgs.pamixer} --set-limit 150 --allow-boost -i 5";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn-sh = "${lib.getExe pkgs.pamixer} --set-limit 150 --allow-boost -d 5";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn-sh = "${lib.getExe pkgs.pamixer} --toggle-mute";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action.spawn-sh = "${lib.getExe pkgs.pamixer} --toggle-mute --default-source";
        allow-when-locked = true;
      };
      "XF86AudioPlay" = {
        action.spawn-sh = "${lib.getExe pkgs.playerctl} play-pause";
        allow-when-locked = true;
      };
      "XF86AudioStop" = {
        action.spawn-sh = "${lib.getExe pkgs.playerctl} stop";
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        action.spawn-sh = "${lib.getExe pkgs.playerctl} previous";
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        action.spawn-sh = "${lib.getExe pkgs.playerctl} next";
        allow-when-locked = true;
      };
      "XF86MonBrightnessUp" = {
        action.spawn-sh = "${lib.getExe pkgs.brightnessctl} --class=backlight set +5%";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action.spawn-sh = "${lib.getExe pkgs.brightnessctl} --class=backlight set -5%";
        allow-when-locked = true;
      };

      "Mod+S" = action "toggle-overview" // {
        repeat = false;
      };
      "Mod+Shift+Slash" = action "close-window" // {
        repeat = false;
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
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = action "focus-workspace-up" // {
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollDown" = action "move-column-to-workspace-down" // {
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollUp" = action "move-column-to-workspace-up" // {
        cooldown-ms = 150;
      };
      "Mod+WheelScrollRight" = action "focus-column-right";
      "Mod+WheelScrollLeft" = action "focus-column-left";
      "Mod+Ctrl+WheelScrollRight" = action "move-column-right";
      "Mod+Ctrl+WheelScrollLeft" = action "move-column-left";
      "Mod+Shift+WheelScrollDown" = action "focus-column-right";
      "Mod+Shift+WheelScrollUp" = action "focus-column-left";
      "Mod+Ctrl+Shift+WheelScrollDown" = action "move-column-right";
      "Mod+Ctrl+Shift+WheelScrollUp" = action "move-column-left";

      "Mod+Q".action.focus-workspace = 1;
      "Mod+W".action.focus-workspace = 2;
      "Mod+E".action.focus-workspace = 3;
      "Mod+R".action.focus-workspace = 4;
      "Mod+T".action.focus-workspace = 5;
      "Mod+Y".action.focus-workspace = 6;
      "Mod+U".action.focus-workspace = 7;
      "Mod+I".action.focus-workspace = 8;
      "Mod+O".action.focus-workspace = 9;
      "Mod+P".action.focus-workspace = 10;
      "Mod+Shift+Q".action.move-column-to-workspace = 1;
      "Mod+Shift+W".action.move-column-to-workspace = 2;
      "Mod+Shift+E".action.move-column-to-workspace = 3;
      "Mod+Shift+R".action.move-column-to-workspace = 4;
      "Mod+Shift+T".action.move-column-to-workspace = 5;
      "Mod+Shift+Y".action.move-column-to-workspace = 6;
      "Mod+Shift+U".action.move-column-to-workspace = 7;
      "Mod+Shift+I".action.move-column-to-workspace = 8;
      "Mod+Shift+O".action.move-column-to-workspace = 9;
      "Mod+Shift+P".action.move-column-to-workspace = 10;

      "Mod+Tab" = action "focus-workspace-previous" // {
        hotkey-overlay.title = "Switch Focus Between Workspaces";
      };
      "Mod+BracketLeft" = action "consume-or-expel-window-left";
      "Mod+BracketRight" = action "consume-or-expel-window-right";
      "Mod+Period" = action "switch-preset-column-width";
      "Mod+Shift+Period" = action "switch-preset-window-height";
      "Mod+Ctrl+Period" = action "reset-window-height";
      "Mod+Ctrl+M" = action "maximize-column";
      "Mod+F" = action "fullscreen-window";
      "Mod+Shift+M" = action "maximize-window-to-edges" // {
        hotkey-overlay.title = "Maximize Window";
      };
      "Mod+Ctrl+F" = action "expand-column-to-available-width";
      "Mod+C" = action "center-column";
      "Mod+Ctrl+C" = action "center-visible-columns";
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+Shift+Minus".action.set-window-height = "-10%";
      "Mod+Shift+Equal".action.set-window-height = "+10%";
      "Mod+Shift+F" = action "toggle-window-floating";
      "Mod+Shift+V" = action "switch-focus-between-floating-and-tiling";
      "Mod+Ctrl+T" = action "toggle-column-tabbed-display";
      "Print" = action "screenshot";
      "Ctrl+Print" = action "screenshot-screen";
      "Alt+Print" = action "screenshot-window";
      "Mod+Escape" = action "toggle-keyboard-shortcuts-inhibit" // {
        allow-inhibiting = false;
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
      enable = true;
      path = lib.getExe pkgs.xwayland-satellite-unstable;
    };
  };
in
{
  imports = [
    flake.inputs.niri.homeModules.niri
    flake.inputs.niri.homeModules.stylix
  ];

  options.home-manager.window-manager.wayland.niri = {
    enable = lib.mkEnableOption "Niri config" // {
      default = config.home-manager.window-manager.wayland.enable;
    };
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.niri-unstable;
      defaultText = lib.literalExpression "pkgs.niri-unstable";
      description = "The niri package to use. Set to null to use the system-provided package.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (!pkgs.stdenv.hostPlatform.isLinux) {
      stylix.targets.niri.enable = false;
    })
    (lib.mkIf cfg.enable {
      programs.niri = {
        package = if cfg.package != null then cfg.package else pkgs.niri;
        enable = cfg.package != null;
        settings = typedSettings;
      };

      systemd.user.packages = lib.optional (cfg.package != null) cfg.package;
    })
  ];
}
