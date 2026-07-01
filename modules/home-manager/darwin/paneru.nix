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
        window_virtual_south = "cmd + alt - u";
        window_virtual_north = "cmd + alt - i";
        window_virtualmove_south = "cmd + alt + shift - u";
        window_virtualmove_north = "cmd + alt + shift - i";
        window_virtualnum_1 = "cmd + alt - q";
        window_virtualnum_2 = "cmd + alt - w";
        window_virtualnum_3 = "cmd + alt - e";
        window_virtualnum_4 = "cmd + alt - r";
        window_virtualnum_5 = "cmd + alt - t";
        window_virtualmovenum_1 = "cmd + alt + shift - q";
        window_virtualmovenum_2 = "cmd + alt + shift - w";
        window_virtualmovenum_3 = "cmd + alt + shift - e";
        window_virtualmovenum_4 = "cmd + alt + shift - r";
        window_virtualmovenum_5 = "cmd + alt + shift - t";
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
