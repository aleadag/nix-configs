{
  config,
  flake,
  lib,
  ...
}:

let
  cfg = config.home-manager.window-manager.paneru;
in
{
  imports = [ flake.inputs.paneru.homeModules.paneru ];

  config = lib.mkIf cfg.enable {
    services.paneru.enable = true;
    services.paneru.config = # lua
      ''
        paneru.setup {
          options = {
            animation_speed = 50.0,
            auto_center = true,
            focus_follows_mouse = false,
            mouse_follows_focus = false,
            preset_column_widths = {
              0.25,
              0.33,
              0.5,
              0.66,
              0.75,
            },
            virtual_workspace_animations = true,
          },

          bindings = {
            ["window focus west"] = "cmd - h",
            ["window focus east"] = "cmd - l",
            ["window focus north"] = "cmd - k",
            ["window focus south"] = "cmd - j",
            ["window swap west"] = "cmd + shift - h",
            ["window swap east"] = "cmd + shift - l",
            ["window swap first"] = "cmd + shift - k",
            ["window swap last"] = "cmd + shift - j",
            ["window focus first"] = "cmd - home",
            ["window focus last"] = "cmd - end",
            ["window virtualnum 1"] = "cmd - q",
            ["window virtualnum 2"] = "cmd - w",
            ["window virtualnum 3"] = "cmd - e",
            ["window virtualnum 4"] = "cmd - r",
            ["window virtualnum 5"] = "cmd - t",
            ["window virtualnum 6"] = "cmd - y",
            ["window virtualnum 7"] = "cmd - u",
            ["window virtualnum 8"] = "cmd - i",
            ["window virtualnum 9"] = "cmd - o",
            ["window virtualnum 10"] = "cmd - p",
            ["window virtualmovenum 1"] = "cmd + shift - q",
            ["window virtualmovenum 2"] = "cmd + shift - w",
            ["window virtualmovenum 3"] = "cmd + shift - e",
            ["window virtualmovenum 4"] = "cmd + shift - r",
            ["window virtualmovenum 5"] = "cmd + shift - t",
            ["window virtualmovenum 6"] = "cmd + shift - y",
            ["window virtualmovenum 7"] = "cmd + shift - u",
            ["window virtualmovenum 8"] = "cmd + shift - i",
            ["window virtualmovenum 9"] = "cmd + shift - o",
            ["window virtualmovenum 10"] = "cmd + shift - p",
            ["window nextdisplay"] = "cmd + ctrl + shift - n",
            ["mouse nextdisplay"] = "cmd + ctrl + shift - m",
            ["window center"] = "cmd + shift - c",
            ["window resize"] = "cmd - .",
            ["window fullwidth"] = "cmd + shift - m",
            ["window manage"] = "cmd + ctrl - t",
            ["window stack"] = "cmd - [",
            ["window unstack"] = "cmd - ]",
            ["quit"] = "ctrl + alt - delete",
          },

          decorations = {
            active = {
              border = {
                enabled = true,
                color = "#${config.lib.stylix.colors.base0D}",
              },
            },
          },

          windows = {
            syspref = {
              -- Title RegExp pattern is required.
              title = ".*",
              bundle_id = "com.apple.systempreferences",
              -- Do not manage this window, e.g. it will be floating.
              floating = true,
            },
          },
        }
      '';
  };
}
