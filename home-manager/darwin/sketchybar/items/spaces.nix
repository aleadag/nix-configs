{ config, lib, pkgs, ... }:
pkgs.writeShellApplication {
  name = "sketchybar-items-spaces";
  runtimeInputs = with pkgs; [ sketchybar ];
  text = with config.home-manager.desktop.theme;
    with import ../utils.nix { inherit lib; };
    let
      pluginsSpace = pkgs.callPackage ../plugins/space.nix { inherit pkgs; };
    in
    # bash
    ''
      SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10")

      sid=0
      for i in "''${!SPACE_ICONS[@]}"
      do
        sid=$((i+1))
        sketchybar --add space      space.$sid left \
                   --set space.$sid associated_space=$sid \
                                    icon="''${SPACE_ICONS[i]}" \
                                    icon.padding_left=10 \
                                    icon.padding_right=15 \
                                    padding_left=2 \
                                    padding_right=2 \
                                    label.padding_right=20 \
                                    icon.highlight_color=${fixColor colors.green} \
                                    label.font="sketchybar-app-font:Regular:16.0" \
                                    label.background.height=26 \
                                    label.background.drawing=on \
                                    label.background.color=${fixColor colors.overlay0} \
                                    label.background.corner_radius=8 \
                                    label.drawing=off \
                                    script="${lib.getExe pluginsSpace}" \
                  --subscribe       space.$sid mouse.clicked
      done

      sketchybar --add bracket spaces '/space\..*/' \
                 --set spaces  background.color=${fixColor colors.surface0} \
                               background.border_color=${fixColor colors.surface2} \
                               background.border_width=2 \
                               background.drawing=on


      sketchybar   --add item       separator left \
                   --set separator  icon= \
                                    icon.font="${fonts.symbols.name}:Regular:16.0" \
                                    padding_left=17 \
                                    padding_right=10 \
                                    label.drawing=off \
                                    associated_display=active \
                                    click_script='${lib.getExe pkgs.yabai} -m space --create
                                                  ${lib.getExe pkgs.sketchybar} --trigger space_change' \
                                    icon.color=${fixColor colors.blue}
    '';
}
