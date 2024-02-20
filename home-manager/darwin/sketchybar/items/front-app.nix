{ config, lib, pkgs, ... }:
with import ../icons.nix;
with config.home-manager.desktop.theme;
let
  iconFont = "SF Pro";
  pluginsYabai = pkgs.callPackage ../plugins/yabai.nix { inherit config lib pkgs; };
  fixColor = color: "0xff${lib.removePrefix "#" color}";
in
pkgs.writeShellApplication {
  name = "sketchybar-items-front-app";
  runtimeInputs = with pkgs; [ sketchybar ];
  text =
    ''
      # shellcheck disable=SC2016
      FRONT_APP_SCRIPT='sketchybar --set $NAME label="$INFO"'

      sketchybar --add       event        window_focus \
                 --add       event        windows_on_spaces \
                 --add       item         system.yabai left \
                 --set       system.yabai script="${lib.getExe pluginsYabai}" \
                                          icon.font="${iconFont}:Normal:20.0" \
                                          label.drawing=off \
                                          icon.width=40 \
                                          icon="${yabai_grid}" \
                                          icon.color="${fixColor colors.pink}" \
                                          associated_display=active \
                 --subscribe system.yabai window_focus \
                                          windows_on_spaces \
                                          mouse.clicked \
                 --add       item         front_app left \
                 --set       front_app    script="$FRONT_APP_SCRIPT" \
                                          icon.drawing=off \
                                          padding_left=0 \
                                          label.color="${fixColor colors.text}" \
                                          label.font="${iconFont}:Black:13.0" \
                                          associated_display=active \
                 --subscribe front_app    front_app_switched
    '';
}
