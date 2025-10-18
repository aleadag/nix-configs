{
  config,
  lib,
  pkgs,
  areaScreenShot,
  fullScreenShot,
  menu,
  msg,
  browser ? config.home-manager.window-manager.default.browser,
  dunstctl ? (lib.getExe' pkgs.dunst "dunstctl"),
  fileManager ? config.home-manager.window-manager.default.fileManager,
  light ? (lib.getExe pkgs.acpilight),
  pamixer ? (lib.getExe pkgs.pamixer),
  playerctl ? (lib.getExe pkgs.playerctl),
  terminal ? config.home-manager.window-manager.default.terminal,
  statusCommand ? null,
  alt ? "Mod1",
  modifier ? "Mod4",
  bars ? [
    {
      inherit statusCommand;

      position = "top";
    }
  ],
  extraBindings ? { },
  extraWindowOptions ? { },
  extraFocusOptions ? { },
  extraModes ? { },
  extraConfig ? "",
  workspaces ? [
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
  ],
}:
let
  # Modes
  powerManagementMode = " : Screen [l]ock, [e]xit, [s]uspend, [h]ibernate, [R]eboot, [S]hutdown";
  resizeMode = " : [h]  , [j]  , [k]  , [l] ";

  # Helpers
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
      # Arrow keys
      "${optionalString (prefixKey != null) "${prefixKey}+"}Left" = leftCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Down" = downCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Up" = upCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Right" = rightCmd;
      # Vi-like keys
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
    (mapDirection {
      inherit prefixKey;
      leftCmd = "${prefixCmd} left";
      downCmd = "${prefixCmd} down";
      upCmd = "${prefixCmd} up";
      rightCmd = "${prefixCmd} right";
    });

  mapWorkspacesStr =
    with builtins;
    with lib.strings;
    {
      workspaces,
      prefixKey ? null,
      prefixCmd,
    }:
    (concatStringsSep "\n" (
      map (
        { ws, name }:
        ''bindsym ${
          optionalString (prefixKey != null) "${prefixKey}+"
        }${toString ws} ${prefixCmd} "${name}"''
      ) workspaces
    ));
in
{
  helpers = {
    inherit mapDirection mapDirectionDefault mapWorkspacesStr;
  };

  config = {
    inherit
      bars
      modifier
      menu
      terminal
      ;

    keybindings = {
      # ===== MAIN LAYER (Super key) - Core functionality =====

      # Terminal
      "${modifier}+Return" = "exec ${terminal}";

      # Browser
      "${modifier}+m" = "exec ${browser}";

      # Switch to a window by letter, like Tmux "Q" or Vimium "F"
      ## Containers // Visually Switch by Letter // 🪟 B ##
      "${modifier}+b" = "exec --no-startup-id wmfocus";

      "${modifier}+d" = "exec ${menu}";

      ## Containers // Focus Parent Container // 🪟 A ##
      "${modifier}+a" = "focus parent";
      ## Containers // Focus Child Container // 🪟 C ##
      "${modifier}+c" = "focus child";

      ## Containers // Move Focus Direction // 🪟 HJKL ##
      # Focus direction handled by mapDirectionDefault below

      ## Containers // Vertical Split // 🪟 V ##
      "${modifier}+v" = "split horizontal";

      ## Containers // Horizontal Split // 🪟 S ##
      "${modifier}+s" = "split vertical";

      # Window management
      "${modifier}+f" = "fullscreen toggle";

      ## Workspaces // Increase Gaps // 🪟 = ##
      "${modifier}+minus" = "gaps inner current minus 6";
      "${modifier}+equal" = "gaps inner current plus 6";

      # Resize mode entry (as recommended in blog)
      "${modifier}+period" = ''mode "${resizeMode}"'';

      # QWERTY Workspace Navigation handled by mapWorkspacesStr in extraConfig

      # Workspace switching improvements (as recommended)
      "${alt}+Tab" = "exec swayr switch-workspace";
      "${modifier}+Tab" = "exec swayr switch-window"; # Window switcher menu

      # ===== DANGER LAYER (Super+Shift) - Destructive actions =====

      # Window killing
      "${modifier}+Shift+slash" = "kill";

      # Window movement handled by mapDirectionDefault below

      # Layout controls moved to non-conflicting keys (v/s moved to main layer)
      "${modifier}+Shift+f" = "floating toggle";

      "${modifier}+Shift+comma" = "focus mode_toggle";

      # Move windows to workspaces handled by mapWorkspacesStr in extraConfig

      # Sway Session // Reload Config File
      "${modifier}+Shift+c" = "reload, exec systemctl --user restart kanshi";

      # System control
      "${modifier}+Shift+Escape" = ''mode "${powerManagementMode}"'';

      # ===== UTILITY LAYER (Super+Ctrl) - App launching and tools =====

      # Layout controls in utility layer
      "${modifier}+Ctrl+s" = "layout splitv";
      "${modifier}+Ctrl+v" = "layout splith";
      # I usually use tabbed, but if I press the key again, toggle to stacking
      "${modifier}+Ctrl+t" = "layout toggle tabbed stacking";

      ## Workspaces // Move to Monitor Direction // 🪟 <Ctrl> HJKL ##
      # Move workspace to output direction handled by mapDirectionDefault below

      # Notification management (utility layer)
      "${modifier}+Ctrl+escape" = "exec ${dunstctl} close";
      "${modifier}+Ctrl+Shift+escape" = "exec ${dunstctl} close-all";

      # Touchpad toggle (utility layer)
      "${modifier}+Ctrl+Space" = "input type:touchpad events toggle enabled disabled";

      # ===== MEDIA AND SYSTEM KEYS =====

      # Audio controls
      "XF86AudioRaiseVolume" = "exec --no-startup-id ${pamixer} --set-limit 150 --allow-boost -i 5";
      "XF86AudioLowerVolume" = "exec --no-startup-id ${pamixer} --set-limit 150 --allow-boost -d 5";
      "XF86AudioMute" = "exec --no-startup-id ${pamixer} --toggle-mute";
      "XF86AudioMicMute" = "exec --no-startup-id ${pamixer} --toggle-mute --default-source";
      "XF86MonBrightnessUp" = "exec --no-startup-id ${light} -inc 5";
      "XF86MonBrightnessDown" = "exec --no-startup-id ${light} -dec 5";
      "XF86AudioPlay" = "exec --no-startup-id ${playerctl} play-pause";
      "XF86AudioStop" = "exec --no-startup-id ${playerctl} stop";
      "XF86AudioNext" = "exec --no-startup-id ${playerctl} next";
      "XF86AudioPrev" = "exec --no-startup-id ${playerctl} previous";

      # Screenshots
      "Print" = "exec --no-startup-id ${fullScreenShot}";
      "Shift+Print" = "exec --no-startup-id ${areaScreenShot}";
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
    })
    // extraBindings;

    modes =
      let
        exitMode = {
          "Escape" = "mode default";
          "Return" = "mode default";
        };
      in
      {
        ${resizeMode} =
          (mapDirection {
            leftCmd = "resize shrink width 192 px or 5 ppt";
            downCmd = "resize shrink height 192 px or 5 ppt";
            upCmd = "resize grow height 192 px or 5 ppt";
            rightCmd = "resize grow width 192 px or 5 ppt";
          })
          // {
            ## Resize/Move Mode // Move Floating Windows by 192px // <Up><Down><Left><Right> ##
            "Up" = "move up 192 px";
            "Left" = "move left 192 px";
            "Down" = "move down 192 px";
            "Right" = "move right 192 px";

            # back to normal: Enter, Escape, Super, Space or Super-R
            ## Resize/Move Mode // Exit Mode // <Return>, <Esc>, <Space> ##
            "${modifier}+r" = "mode default";
            "${modifier}" = "mode default";
            "space" = "mode default";
          }
          // exitMode;
        ${powerManagementMode} =
          let
            # $ swaymsg exec "loginctl lock-session &>/tmp/out"
            # $ cat /tmp/out
            # Failed to issue method call: Unknown object '/org/freedesktop/login1/session/auto'.
            systemctl = "systemd-run --user systemctl";
            loginctl = "systemd-run --user loginctl";
          in
          {
            l = "mode default, exec ${loginctl} lock-session";
            e = "mode default, exec ${msg} exit";
            s = "mode default, exec ${systemctl} suspend";
            h = "mode default, exec ${systemctl} hibernate";
            "Shift+r" = "mode default, exec ${systemctl} reboot";
            "Shift+s" = "mode default, exec ${systemctl} poweroff";
          }
          // exitMode;
      }
      // extraModes;

    defaultWorkspace = (builtins.head workspaces).name;
    workspaceAutoBackAndForth = true;
    workspaceLayout = "tabbed";

    window = {
      border = 1;
      hideEdgeBorders = "smart";
      titlebar = false;
    }
    // extraWindowOptions;

    focus = {
      followMouse = false;
    }
    // extraFocusOptions;
  };

  # QWERTY workspace navigation using mapWorkspacesStr
  # https://github.com/nix-community/home-manager/issues/695
  extraConfig =
    let
      workspaceStr = builtins.concatStringsSep "\n" [
        (mapWorkspacesStr {
          inherit workspaces;
          prefixKey = modifier;
          prefixCmd = "workspace number";
        })
        (mapWorkspacesStr {
          inherit workspaces;
          prefixKey = "${modifier}+Shift";
          prefixCmd = "move container to workspace number";
        })
      ];
    in
    ''
      ${workspaceStr}
      ${extraConfig}
    '';
}
