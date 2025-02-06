{
  config,
  lib,
  pkgs,
  ...
}:
pkgs.writeShellApplication {
  name = "sketchybar-plugins-yabai";
  runtimeInputs = with pkgs; [
    yabai
    jq
    sketchybar
  ];
  text =
    with config.home-manager.desktop.theme;
    with import ../utils.nix { inherit lib; };
    let
      icons = import ../icons.nix;
      iconMap = pkgs.callPackage ./icon-map.nix { inherit pkgs; };
    in
    # bash
    ''
      window_state() {
        WINDOW=$(yabai -m query --windows --window)
        CURRENT=$(echo "$WINDOW" | jq '.["stack-index"]')

        args=()
        if [[ $CURRENT -gt 0 ]]; then
          LAST=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')
          args+=(--set "$NAME" icon=${icons.yabai_stack} icon.color=${fixColor colors.red} label.drawing=on label.color=${fixColor colors.text} label="$(printf "[%s/%s]" "$CURRENT" "$LAST")")
        else
          args+=(--set "$NAME" label.drawing=off)
          case "$(echo "$WINDOW" | jq '.["is-floating"]')" in
            "false")
              if [ "$(echo "$WINDOW" | jq '.["has-fullscreen-zoom"]')" = "true" ]; then
                args+=(--set "$NAME" icon=${icons.yabai_fullscreen_zoom} icon.color=${fixColor colors.green})
              elif [ "$(echo "$WINDOW" | jq '.["has-parent-zoom"]')" = "true" ]; then
                args+=(--set "$NAME" icon=${icons.yabai_parent_zoom} icon.color=${fixColor colors.blue})
              else
                args+=(--set "$NAME" icon=${icons.yabai_grid} icon.color=${fixColor colors.yellow})
              fi
              ;;
            "true")
              args+=(--set "$NAME" icon=${icons.yabai_float} icon.color=${fixColor colors.peach})
              ;;
          esac
        fi

        sketchybar -m "''${args[@]}"
      }

      windows_on_spaces () {
        CURRENT_SPACES="$(yabai -m query --displays | jq -r '.[].spaces | @sh')"

        args=()
        while read -r line
        do
          for space in $line
          do
            icon_strip=" "
            apps=$(yabai -m query --windows --space "$space" | jq -r ".[].app")
            if [ "$apps" != "" ]; then
              while IFS= read -r app; do
                icon_strip+=" $(${lib.getExe iconMap} "$app")"
              done <<< "$apps"
            fi
            args+=(--set space."$space" label="$icon_strip" label.drawing=on)
          done
        done <<< "$CURRENT_SPACES"

        sketchybar -m "''${args[@]}"
      }

      mouse_clicked() {
        yabai -m window --toggle float
        yabai -m window --grid 4:4:1:1:2:2
        window_state
      }

      case "$SENDER" in
        "mouse.clicked") mouse_clicked
        ;;
        "forced") exit 0
        ;;
        "window_focus") window_state
        ;;
        "windows_on_spaces") windows_on_spaces
        ;;
      esac
    '';
}
