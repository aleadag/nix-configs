# Refer to:
# - https://github.com/anujc4/dotfiles/tree/master/macos_wm
# - https://github.com/heywoodlh/nixos-configs/tree/master/darwin/modules
# - https://github.com/reo101/rix101/tree/master/modules/nix-darwin/yabai
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-darwin.yabai;
  catppuccin = import ./catppuccin.nix;
in
{
  config = lib.mkIf cfg.enable {
    services = {
      yabai = {
        enable = true;
        package = pkgs.yabai;
        enableScriptingAddition = true;
        config = {
          external_bar = "all:32:0";
          window_border = "on";
          mouse_follows_focus = "off";
          focus_follows_mouse = "off";
          window_zoom_persist = "off";
          window_placement = "second_child";
          window_topmost = "off";
          window_shadow = "float";
          window_opacity = "on";
          window_opacity_duration = "0.15";
          active_window_opacity = "1.0";
          normal_window_opacity = "0.95";
          window_border_blur = "off";
          window_border_width = "2";
          window_border_hidpi = "off";
          window_border_radius = "0";
          window_animation_duration = "0.22";
          active_window_border_color = catppuccin.frappe.mauve;
          normal_window_border_color = catppuccin.frappe.surface0;
          insert_feedback_color = catppuccin.frappe.green;
          split_ratio = "0.50";
          auto_balance = "off";
          mouse_modifier = "cmd";
          mouse_action1 = "move";
          mouse_action2 = "resize";
          mouse_drop_action = "swap";
          top_padding = "10";
          bottom_padding = "10";
          left_padding = "10";
          right_padding = "10";
          window_gap = "8";
          layout = "bsp";
        };
        extraConfig =
          # bash
          ''
            # Unload the macOS WindowManager process
            launchctl unload -F /System/Library/LaunchAgents/com.apple.WindowManager.plist > /dev/null 2>&1 &

            sudo yabai --load-sa
            yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
            yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
            yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces"
            yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces"
            yabai -m signal --add event=window_destroyed action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"
            yabai -m signal --add event=application_terminated action="yabai -m query --windows --window &> /dev/null || yabai -m window --focus mouse"
            yabai -m signal --add event=display_resized action="launchctl stop org.nixos.sketchybar && launchctl start org.nixos.sketchybar"
            yabai -m signal --add event=system_woke action="sh -c 'sleep 1; sketchybar --reload'"

            # Exclude problematic apps from being managed:
            yabai -m rule --add app="^(LuLu|Vimac|Calculator|Software Update|Dictionary|VLC|System Preferences|System Settings|zoom.us|Photo Booth|Archive Utility|Python|LibreOffice|App Store|Steam|Alfred|Activity Monitor|TencentMeeting)$" manage=off
            yabai -m rule --add label="Finder" app="^Finder$" title="(Co(py|nnect)|Move|Info|Pref)" manage=off
            yabai -m rule --add label="Safari" app="^Safari$" title="^(General|(Tab|Password|Website|Extension)s|AutoFill|Se(arch|curity)|Privacy|Advance)$" manage=off
            yabai -m rule --add label="System Information" app="System Information" title="System Information" manage=off
            yabai -m rule --add label="Select file to save to" app="^Inkscape$" title="Select file to save to" manage=off

            echo "yabai configuration loaded.."
          '';
      };

      jankyborders = {
        enable = true;
        active_color = catppuccin.frappe.mauve;
        inactive_color = catppuccin.frappe.surface1;
        style = "round";
        width = 6.0;
        hidpi = false;
      };
    };
  };
}
