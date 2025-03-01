{
  config,
  lib,
  pkgs,
  areaScreenShot,
  fullScreenShot,
  menu,
  browser ? config.home-manager.desktop.default.browser,
  dunstctl ? (lib.getExe' pkgs.dunst "dunstctl"),
  fileManager ? config.home-manager.desktop.default.fileManager,
  light ? "xbacklight", # needs to be installed system-wide
  pamixer ? (lib.getExe pkgs.pamixer),
  playerctl ? (lib.getExe pkgs.playerctl),
  terminal ? config.home-manager.desktop.default.terminal,
  statusCommand ? null,
  alt ? "Mod1",
  modifier ? "Mod4",
  bars ? with config.home-manager.desktop.theme.colors; [
    {
      inherit fonts statusCommand;

      position = "top";
      colors = {
        background = base;
        separator = mantle;
        statusline = surface2;
        activeWorkspace = {
          border = surface1;
          background = surface1;
          text = base;
        };
        bindingMode = {
          border = yellow;
          background = yellow;
          text = base;
        };
        focusedWorkspace = {
          border = blue;
          background = blue;
          text = base;
        };
        inactiveWorkspace = {
          border = mantle;
          background = mantle;
          inherit text;
        };
        urgentWorkspace = {
          border = red;
          background = red;
          text = base;
        };
      };
    }
  ],
  fonts ? with config.home-manager.desktop.theme.fonts; {
    names = lib.flatten [
      gui.name
      icons.name
    ];
    style = "Regular";
    size = 8.0;
  },
  extraBindings ? { },
  extraWindowOptions ? { },
  extraFocusOptions ? { },
  extraModes ? { },
  extraConfig ? "",
  workspaces ? [
    {
      ws = 1;
      name = "1:  ";
    }
    {
      ws = 2;
      name = "2:  ";
    }
    {
      ws = 3;
      name = "3:  ";
    }
    {
      ws = 4;
      name = "4:  ";
    }
    {
      ws = 5;
      name = "5:  ";
    }
    {
      ws = 6;
      name = "6:  ";
    }
    {
      ws = 7;
      name = "7:  ";
    }
    {
      ws = 8;
      name = "8:  ";
    }
    {
      ws = 9;
      name = "9:  ";
    }
    {
      ws = 0;
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
  helpers = { inherit mapDirection mapDirectionDefault mapWorkspacesStr; };

  config = {
    inherit
      bars
      fonts
      modifier
      menu
      terminal
      ;

    colors = with config.home-manager.desktop.theme.colors; {
      background = lavender;
      focused = {
        background = blue;
        border = blue;
        childBorder = teal;
        indicator = blue;
        text = base;
      };
      focusedInactive = {
        background = mantle;
        border = mantle;
        childBorder = mantle;
        indicator = surface1;
        inherit text;
      };
      placeholder = {
        background = base;
        border = base;
        childBorder = base;
        indicator = base;
        inherit text;
      };
      unfocused = {
        background = base;
        border = mantle;
        childBorder = mantle;
        indicator = mantle;
        inherit text;
      };
      urgent = {
        background = red;
        border = red;
        childBorder = red;
        indicator = red;
        text = base;
      };
    };

    keybindings =
      {
        "${modifier}+Return" = "exec ${terminal}";
        "${modifier}+Shift+q" = "kill";
        "${alt}+F4" = "kill";

        "${modifier}+n" = "exec ${browser}";
        "${modifier}+m" = "exec ${fileManager}";

        "${modifier}+d" = "exec ${menu}";

        "${modifier}+f" = "fullscreen toggle";
        "${modifier}+v" = "split v";
        "${modifier}+b" = "split h";

        "${modifier}+s" = "layout stacking";
        "${modifier}+w" = "layout tabbed";
        "${modifier}+e" = "layout toggle split";

        "${modifier}+semicolon" = "focus mode_toggle";
        "${modifier}+Shift+semicolon" = "floating toggle";

        "${modifier}+a" = "focus parent";

        "${modifier}+Shift+minus" = "move scratchpad";
        "${modifier}+minus" = "scratchpad show";

        "${modifier}+r" = ''mode "${resizeMode}"'';
        "${modifier}+Escape" = ''mode "${powerManagementMode}"'';

        "${modifier}+Shift+c" = "reload";
        "${modifier}+Shift+r" = "restart";

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

        "XF86Tools" = "input type:touchpad events toggle enabled disabled";

        "Print" = "exec --no-startup-id ${fullScreenShot}";
        "Shift+Print" = "exec --no-startup-id ${areaScreenShot}";

        "Ctrl+escape" = "exec ${dunstctl} close";
        "Ctrl+Shift+escape" = "exec ${dunstctl} close-all";
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
        prefixKey = "Ctrl+${alt}";
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
            leftCmd = "resize shrink width 10px or 10ppt";
            downCmd = "resize grow height 10px or 10ppt";
            upCmd = "resize shrink height 10px or 10ppt";
            rightCmd = "resize grow width 10px or 10ppt";
          })
          // exitMode;
        ${powerManagementMode} = {
          l = "mode default, exec loginctl lock-session";
          e = "mode default, exec loginctl terminate-session $XDG_SESSION_ID";
          s = "mode default, exec systemctl suspend";
          h = "mode default, exec systemctl hibernate";
          "Shift+r" = "mode default, exec systemctl reboot";
          "Shift+s" = "mode default, exec systemctl poweroff";
        } // exitMode;
      }
      // extraModes;

    workspaceAutoBackAndForth = true;
    workspaceLayout = "tabbed";

    window = {
      border = 1;
      hideEdgeBorders = "smart";
      titlebar = false;
    } // extraWindowOptions;

    focus = {
      followMouse = false;
    } // extraFocusOptions;
  };

  # Until this issue is fixed we need to map workspaces directly to config file
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
