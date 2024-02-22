{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "yabai-save-recent-space";
  runtimeInputs = with pkgs; [ yabai jq ];
  text = ''
    # Get the index of the previous space
    previous_window_index=$(yabai -m query --spaces | jq -r ".[] | select(.id == $YABAI_RECENT_SPACE_ID) | .index")

    # Store the index in a temporary file
    echo "$previous_window_index" > /tmp/recent_space
  '';
}
