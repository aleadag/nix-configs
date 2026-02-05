{
  pkgs,
  lib,
  config,
  ...
}:
let
  caffeine-toggle = pkgs.writeShellApplication {
    name = "caffeine-toggle";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      systemd
      libnotify
    ];
    text = ''
      # Use a specific name for the inhibitor process to easily find it
      INHIBITOR_NAME="caffeine-inhibitor"

      if pgrep -f "$INHIBITOR_NAME" > /dev/null; then
        pkill -f "$INHIBITOR_NAME"
        notify-send -u normal -t 3000 "Caffeine" "Disabled 💤"
      else
        # Start systemd-inhibit in background
        # We use 'sleep infinity' and give it a recognizable process name
        systemd-inhibit \
          --what=idle \
          --who="caffeine-toggle" \
          --why="User requested" \
          --mode=block \
          bash -c "exec -a $INHIBITOR_NAME sleep infinity" &        notify-send -u normal -t 3000 "Caffeine" "Enabled ☕️"
      fi

      # Signal waybar to update custom/caffeine if it exists
      pkill -RTMIN+9 waybar || true
    '';
  };
in
{
  config = lib.mkIf config.home-manager.window-manager.wayland.enable {
    home.packages = [ caffeine-toggle ];
  };
}
