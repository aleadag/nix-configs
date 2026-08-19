{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.home-manager.window-manager.wayland.sway;
  # Aliases
  alt = "Mod1";
  modifier = "Mod4";

  terminal-cwd = pkgs.writeShellApplication {
    name = "terminal-cwd";

    runtimeInputs = with pkgs; [
      coreutils
      jq
      procps
      sway
    ];

    text = ''
      set +o errexit
      terminal='${config.home-manager.window-manager.default.terminal}'
      terminal_name="''${terminal##*/}"
      pid="$(swaymsg -t get_tree | jq -e ".. | select(.type? and .focused? and .app_id==\"$terminal_name\") | .pid")"
      if [[ -n "$pid" ]]; then
        ppid="$(pgrep --newest --parent "$pid")"
        exec "$terminal" "$(readlink "/proc/$ppid/cwd" || echo "$HOME")"
      fi
      exec "$terminal"
    '';
  };

  browser = config.home-manager.window-manager.default.browser;
  dunstctl = lib.getExe' pkgs.dunst "dunstctl";
  pamixer = lib.getExe pkgs.pamixer;
  playerctl = lib.getExe pkgs.playerctl;
  brightnessctl = lib.getExe pkgs.brightnessctl;
  caffeineToggle = "caffeine-toggle";
  menu = lib.getExe config.programs.fuzzel.package;

  screenShotName =
    with config.xdg.userDirs;
    "${pictures}/$(${lib.getExe' pkgs.coreutils "date"} +%Y-%m-%d_%H-%M-%S)-screenshot.png";
  displayLayoutMode = " : [a]uto, [g]ui";
  powerManagementMode = " : [l]ock, [e]xit, [s]uspend, [h]ibernate, [c]affeine, [R]eboot, [S]hutdown";
  resizeMode = " : [h]  , [j]  , [k]  , [l] ";
  workspaces = [
    {
      ws = "q";
      name = "1:  ";
    }
    {
      ws = "w";
      name = "2:  ";
    }
    {
      ws = "e";
      name = "3:  ";
    }
    {
      ws = "r";
      name = "4:  ";
    }
    {
      ws = "t";
      name = "5:  ";
    }
    {
      ws = "y";
      name = "6:  ";
    }
    {
      ws = "u";
      name = "7:  ";
    }
    {
      ws = "i";
      name = "8:  ";
    }
    {
      ws = "o";
      name = "9:  ";
    }
    {
      ws = "p";
      name = "10:  ";
    }
  ];
  mapDirection =
    {
      prefixKey ? null,
      leftCmd,
      downCmd,
      upCmd,
      rightCmd,
    }:
    with lib.strings;
    {
      "${optionalString (prefixKey != null) "${prefixKey}+"}Left" = leftCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Down" = downCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Up" = upCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Right" = rightCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}h" = leftCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}j" = downCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}k" = upCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}l" = rightCmd;
    };
  mapDirectionDefault =
    {
      prefixKey ? null,
      prefixCmd,
    }:
    mapDirection {
      inherit prefixKey;
      leftCmd = "${prefixCmd} left";
      downCmd = "${prefixCmd} down";
      upCmd = "${prefixCmd} up";
      rightCmd = "${prefixCmd} right";
    };
  workspaceBindings =
    { prefixKey, prefixCmd }:
    lib.concatMapStringsSep "\n" (
      { ws, name }:
      ''bindsym ${prefixKey}+${toString ws} ${prefixCmd} "${name}"''
    ) workspaces;
  terminal = lib.getExe terminal-cwd;
  msg = lib.getExe' pkgs.sway "swaymsg";
  fullScreenShot = ''
    ${lib.getExe pkgs.grim} "${screenShotName}" && \
    ${lib.getExe pkgs.libnotify} -u normal -t 5000 'Full screenshot taken'
  '';
  areaScreenShot = ''
    ${lib.getExe pkgs.grim} -g "$(${lib.getExe pkgs.slurp})" "${screenShotName}" && \
    ${lib.getExe pkgs.libnotify} -u normal -t 5000 'Area screenshot taken'
  '';
  exitMode = {
    "Escape" = "mode default";
    "Return" = "mode default";
  };
in
{
  options.home-manager.window-manager.wayland.sway.enable = lib.mkEnableOption "Sway config" // {
    default = config.home-manager.window-manager.wayland.enable;
  };

  options.home-manager.window-manager.wayland.sway.nvidia.enable =
    lib.mkEnableOption "NVIDIA Sway support";

  config = lib.mkIf cfg.enable {
    wayland.windowManager.sway = {
      enable = true;

      extraConfig = with config.home.pointerCursor; ''
        ${workspaceBindings {
          prefixKey = modifier;
          prefixCmd = "workspace number";
        }}
        ${workspaceBindings {
          prefixKey = "${modifier}+Shift";
          prefixCmd = "move container to workspace number";
        }}

        seat * xcursor_theme ${name} ${toString size}
      '';

      config = {
        bars = [ ];
        inherit modifier menu terminal;
        keybindings = {
          "${modifier}+Return" = "exec ${terminal}";
          "${modifier}+b" = "exec ${browser}";
          "${modifier}+d" = "exec ${menu}";
          "${modifier}+a" = "focus parent";
          "${modifier}+z" = "focus child";
          "${modifier}+v" = "split horizontal";
          "${modifier}+g" = "split vertical";
          "${modifier}+f" = "fullscreen toggle";
          "${modifier}+minus" = "gaps inner current minus 6";
          "${modifier}+equal" = "gaps inner current plus 6";
          "${modifier}+period" = ''mode "${resizeMode}"'';
          "${alt}+Tab" = "exec swayr switch-workspace";
          "${modifier}+Tab" = "workspace back_and_forth";
          "${modifier}+Shift+slash" = "kill";
          "${modifier}+Shift+f" = "floating toggle";
          "${modifier}+Shift+comma" = "focus mode_toggle";
          "${modifier}+Shift+c" = "reload, exec systemctl --user restart kanshi";
          "${modifier}+Shift+Escape" = ''mode "${powerManagementMode}"'';
          "${modifier}+Ctrl+s" = "layout splitv";
          "${modifier}+Ctrl+v" = "layout splith";
          "${modifier}+Ctrl+t" = "layout toggle tabbed stacking";
          "${modifier}+Ctrl+escape" = "exec ${dunstctl} close";
          "${modifier}+Ctrl+Shift+escape" = "exec ${dunstctl} close-all";
          "${modifier}+Ctrl+Space" = "input type:touchpad events toggle enabled disabled";
          "XF86AudioRaiseVolume" = "exec --no-startup-id ${pamixer} --set-limit 150 --allow-boost -i 5";
          "XF86AudioLowerVolume" = "exec --no-startup-id ${pamixer} --set-limit 150 --allow-boost -d 5";
          "XF86AudioMute" = "exec --no-startup-id ${pamixer} --toggle-mute";
          "XF86AudioMicMute" = "exec --no-startup-id ${pamixer} --toggle-mute --default-source";
          "XF86MonBrightnessUp" = "exec --no-startup-id ${brightnessctl} --class=backlight set +5%";
          "XF86MonBrightnessDown" = "exec --no-startup-id ${brightnessctl} --class=backlight set -5%";
          "XF86AudioPlay" = "exec --no-startup-id ${playerctl} play-pause";
          "XF86AudioStop" = "exec --no-startup-id ${playerctl} stop";
          "XF86AudioNext" = "exec --no-startup-id ${playerctl} next";
          "XF86AudioPrev" = "exec --no-startup-id ${playerctl} previous";
          "Print" = "exec --no-startup-id ${fullScreenShot}";
          "Shift+Print" = "exec --no-startup-id ${areaScreenShot}";
          "${modifier}+F8" = ''mode "${displayLayoutMode}"'';
        }
        // (mapDirectionDefault {
          prefixKey = modifier;
          prefixCmd = "focus";
        })
        // (mapDirectionDefault {
          prefixKey = "${modifier}+Shift";
          prefixCmd = "move";
        })
        // (mapDirectionDefault {
          prefixKey = "${modifier}+Ctrl";
          prefixCmd = "move workspace to output";
        });
        modes = {
          ${resizeMode} =
            (mapDirection {
              leftCmd = "resize shrink width 192 px or 5 ppt";
              downCmd = "resize shrink height 192 px or 5 ppt";
              upCmd = "resize grow height 192 px or 5 ppt";
              rightCmd = "resize grow width 192 px or 5 ppt";
            })
            // {
              "Up" = "move up 192 px";
              "Left" = "move left 192 px";
              "Down" = "move down 192 px";
              "Right" = "move right 192 px";
              "${modifier}+r" = "mode default";
              "${modifier}" = "mode default";
              "space" = "mode default";
            }
            // exitMode;
          ${powerManagementMode} = {
            l = "mode default, exec systemd-run --user loginctl lock-session";
            e = "mode default, exec ${msg} exit";
            s = "mode default, exec systemd-run --user systemctl suspend";
            h = "mode default, exec systemd-run --user systemctl hibernate";
            c = "mode default, exec ${caffeineToggle}";
            "Shift+r" = "mode default, exec systemd-run --user systemctl reboot";
            "Shift+s" = "mode default, exec systemd-run --user systemctl poweroff";
          }
          // exitMode;
          ${displayLayoutMode} = {
            a = "mode default, exec systemctl restart --user kanshi.service";
            g = "mode default, exec ${lib.getExe pkgs.wdisplays}";
          }
          // exitMode;
        };
        defaultWorkspace = (builtins.head workspaces).name;
        workspaceAutoBackAndForth = true;
        workspaceLayout = "tabbed";
        window = {
          border = 1;
          hideEdgeBorders = "smart";
          titlebar = false;
        };
        focus.followMouse = false;
        input =
          let
            layout = config.home.keyboard.layout or null;
            variant = config.home.keyboard.variant or null;
            options = config.home.keyboard.options or [ "" ];
          in
          {
            "type:keyboard" = {
              xkb_layout = lib.mkIf (layout != null) layout;
              xkb_variant = lib.mkIf (variant != null) variant;
              xkb_options = lib.mkIf (options != [ "" ]) (lib.concatStringsSep "," options);
              repeat_delay = "300";
            };
            "type:pointer" = {
              accel_profile = "flat";
            };
            "type:touchpad" = {
              middle_emulation = "enabled";
              natural_scroll = "enabled";
              scroll_method = "two_finger";
              tap = "enabled";
            };
          };
      };

      extraSessionCommands =
        # bash
        ''
          # Source home-manager session vars
          . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
          # Vulkan renderer
          export WLR_RENDERER=vulkan,gles2,pixman
          # Chrome/Chromium/Electron
          export NIXOS_OZONE_WL=1
          # SDL
          export SDL_VIDEODRIVER=wayland
          # Fix for some Java AWT applications (e.g. Android Studio),
          # use this if they aren't displayed properly:
          export _JAVA_AWT_WM_NONREPARENTING=1
        '';

      systemd = {
        enable = true;
        xdgAutostart = true;
      };

      wrapperFeatures.gtk = true;

      extraOptions = lib.optionals cfg.nvidia.enable [
        "--unsupported-gpu"
      ];
    };
  };
}
