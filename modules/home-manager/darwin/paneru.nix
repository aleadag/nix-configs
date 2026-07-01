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
    services.paneru.settings = {
      options = {
        animation_speed = 150;
        auto_center = true;
        focus_follows_mouse = false;
        mouse_follows_focus = false;
        preset_column_widths = [
          0.25
          0.33
          0.5
          0.66
          0.75
        ];
      };

      bindings = {
        window_focus_west = "cmd - h";
        window_focus_east = "cmd - l";
        window_focus_north = "cmd - k";
        window_focus_south = "cmd - j";
        window_swap_west = "cmd + shift - h";
        window_swap_east = "cmd + shift - l";
        window_swap_first = "cmd + shift - k";
        window_swap_last = "cmd + shift - j";
        window_focus_first = "cmd - home";
        window_focus_last = "cmd - end";
        window_virtualnum_1 = "cmd - q";
        window_virtualnum_2 = "cmd - w";
        window_virtualnum_3 = "cmd - e";
        window_virtualnum_4 = "cmd - r";
        window_virtualnum_5 = "cmd - t";
        window_virtualnum_6 = "cmd - y";
        window_virtualnum_7 = "cmd - u";
        window_virtualnum_8 = "cmd - i";
        window_virtualnum_9 = "cmd - o";
        window_virtualnum_10 = "cmd - p";
        window_virtualmovenum_1 = "cmd + shift - q";
        window_virtualmovenum_2 = "cmd + shift - w";
        window_virtualmovenum_3 = "cmd + shift - e";
        window_virtualmovenum_4 = "cmd + shift - r";
        window_virtualmovenum_5 = "cmd + shift - t";
        window_virtualmovenum_6 = "cmd + shift - y";
        window_virtualmovenum_7 = "cmd + shift - u";
        window_virtualmovenum_8 = "cmd + shift - i";
        window_virtualmovenum_9 = "cmd + shift - o";
        window_virtualmovenum_10 = "cmd + shift - p";
        window_nextdisplay = "cmd + ctrl + shift - n";
        window_center = "cmd + shift - c";
        window_resize = "cmd - .";
        window_fullwidth = "cmd + shift - m";
        window_manage = "cmd + ctrl - t";
        window_stack = "cmd - [";
        window_unstack = "cmd - ]";
        quit = "ctrl + alt - delete";
      };

      windows = {
        syspref = {
          # Title RegExp pattern is required.
          title = ".*";
          bundle_id = "com.apple.systempreferences";
          # Do not manage this window, e.g. it will be floating.
          floating = true;
        };
      };
    };
  };
}
