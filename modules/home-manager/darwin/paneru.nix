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
        preset_column_widths = [
          0.25
          0.33
          0.5
          0.66
          0.75
        ];
        swipe_gesture_fingers = 4;
        animation_speed = 4000;
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
        window_nextdisplay = "cmd + ctrl + shift - n";
        window_center = "cmd - c";
        window_resize = "cmd - .";
        window_fullwidth = "cmd + shift - m";
        window_manage = "cmd + ctrl - t";
        window_stack = "cmd - [";
        window_unstack = "cmd - ]";
        quit = "ctrl + alt - delete";
      };
    };
  };
}
