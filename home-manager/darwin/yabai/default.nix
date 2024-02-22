{ config, lib, pkgs, ... }:
{
  options.home-manager.darwin.yabai.enable = lib.mkEnableOption "yabai config" // {
    default = pkgs.stdenv.isDarwin && config.home-manager.darwin.enable;
  };

  config = lib.mkIf config.home-manager.darwin.enable {
    home.packages = with pkgs; [ yabai ];
    xdg.configFile."yabai/yabairc".source =
      lib.getExe (pkgs.writeShellApplication {
        name = "yabairc";
        runtimeInputs = with pkgs; [ yabai sketchybar ];
        text =
          let
            saveRecentSpace = pkgs.callPackage ./save-recent-space.nix { inherit pkgs; };
            stackSameNameApps = pkgs.callPackage ./stack-same-name-applications.nix { inherit pkgs; };
            floatSmallWindows = pkgs.callPackage ./float-small-windows.nix { inherit pkgs; };
          in
            /* bash */ ''
            #
            # for this to work you must configure sudo such that
            # it will be able to run the command without password
            #
            # see this wiki page for information:
            #  - https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition
            #
            yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
            sudo yabai --load-sa

            # global settings
            yabai -m config                                 \
                external_bar                 all:0:30       \
                menubar_opacity              1.0            \
                mouse_follows_focus          off            \
                focus_follows_mouse          off            \
                window_origin_display        default        \
                window_placement             second_child   \
                window_zoom_persist          on             \
                window_shadow                on             \
                window_animation_duration    0.0            \
                window_opacity_duration      0.0            \
                active_window_opacity        1.0            \
                normal_window_opacity        0.90           \
                window_opacity               off            \
                insert_feedback_color        0xffd75f5f     \
                split_ratio                  0.50           \
                split_type                   auto           \
                auto_balance                 off            \
                top_padding                  12             \
                bottom_padding               12             \
                left_padding                 12             \
                right_padding                12             \
                window_gap                   06             \
                layout                       bsp            \
                mouse_modifier               fn             \
                mouse_action1                move           \
                mouse_action2                resize         \
                mouse_drop_action            swap
            # Unmanaged apps
            app_titles="(Copy|Bin|About This Mac|Info|Finder Preferences|Preferences"
            app_titles+="|QuickTime Player)"
            yabai -m rule --add title="''${app_titles}" manage=off
            
            app_names="^(Calculator|Postgres|VLC|System Preferences"
            app_names+="|AppCleaner|1Password|WireGuard|System Settings|Tailscale"
            app_names+="|Logi Options|JetBrains Toolbox|Contexts|JetBrains Gateway"
            app_names+="|Logi Options\+|SteelSeries GG Client|Stats)$"
            yabai -m rule --add app="''${app_names}" manage=off

            # Only used when SIP is enabled. This is a in-house replacement for
            # `yabai -m window --focus recent`, used with the `switch_space.sh` script
            yabai -m signal --add label=space_changed event=space_changed \
                action="${lib.getExe saveRecentSpace}"

            # when a new window is created, stack it on top of the window of the same
            # application, if exists
            yabai -m signal --add label=stack_same_name_applications event=window_created \
                action="${lib.getExe stackSameNameApps}"

            yabai -m signal --add event=window_created action="${lib.getExe floatSmallWindows}"

            # sketchybar specific events
            yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
            yabai -m signal --add event=space_changed action="sketchybar --trigger windows_on_spaces"

            echo "yabai configuration loaded.."
          '';
      });
  };
}
