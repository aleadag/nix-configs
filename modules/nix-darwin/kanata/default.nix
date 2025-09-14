{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  cfg = config.nix-darwin.kanata;
  driverKitExtVersion = "5.0.0";
  kanataConfigFile = ../../../configs/kanata.kbd;
  karabinerDriverKitExtDestPath = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app";
  karabinerFilesPath = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
  kanataWrapper =
    pkgs.writeShellScript "kanata-wrapper" # bash
      ''
        set -euo pipefail

        echo "Starting kanata wrapper..."

        # Start Karabiner daemon in background
        exec sudo '${karabinerFilesPath}/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon' &
        echo "Started Karabiner daemon in background"

        # Wait for daemon to initialize
        sleep 2

        # Verify daemon is running
        if ! pgrep -f "Karabiner-VirtualHIDDevice-Daemon" > /dev/null; then
            echo "Warning: Karabiner daemon may not have started properly"
        fi

        echo "Starting kanata..."

        # Start Kanata (this becomes the main process)
        exec sudo ${getExe pkgs.kanata} --cfg ${kanataConfigFile} --nodelay
      '';
in
{
  options.nix-darwin.kanata = {
    enable = lib.mkEnableOption "kanata sudoers configuration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.applications.text = pkgs.lib.mkForce ''
      DEST_PATH="${karabinerDriverKitExtDestPath}"
      echo "Checking if Karabiner DriverKit VirtualHIDDevice needs to be installed..."
      echo "Checking destination path: $DEST_PATH"
      echo "Expected version: ${driverKitExtVersion}"
      if [ -d "$DEST_PATH" ]; then
          # purposely keep stderr to see if issues fetching version occur
          CURRENT_VERSION=$(defaults read "$DEST_PATH/Contents/Info" CFBundleVersion | tr -d '\n')
      else
          CURRENT_VERSION="null"
      fi
      if [ ! -d "$DEST_PATH" ] || [ "$CURRENT_VERSION" != "${driverKitExtVersion}" ]; then
          echo "Current version found: $CURRENT_VERSION"
          echo "Destination path does not exist or version mismatch."
          echo "Installing Karabiner DriverKit VirtualHIDDevice..."
          /usr/sbin/installer -pkg "${pkgs.karabiner-driverkit-virtualhiddevice}/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg" -target /
          MACOS_PATH="$DEST_PATH/Contents/MacOS"
          echo "Removing quarantine attributes..."
          xattr -dr com.apple.quarantine "$DEST_PATH"
          echo activating dext...
          $MACOS_PATH/Karabiner-VirtualHIDDevice-Manager activate
          printf '\x1b[0;31mPlease grant Input Monitoring permissions to ${pkgs.bash}/bin in System Preferences > Security & Privacy > Privacy > Input Monitoring\x1b[0m\n'
          # use absolute path to force use of native macos stat
          USER="$(/usr/bin/stat -f "%u" /dev/console)"
          # should not already exist if service is created by this module (nix module cleans itself on uninstall)
          if launchctl print "gui/$USER/org.nixos.kanata" >/dev/null; then
            printf '\x1b[0;31mFound running kanata user agent. Unloading in case input monitoring permissions are missing on latest activation - will need to manually reload with..\x1b[0m\n'
            printf '\x1b[0;31mlaunchctl bootstrap "gui/%s" "~/Library/LaunchAgents/org.nixos.kanata.plist"\x1b[0m\n' "$USER"
            # Use sudo to run launchctl as the user who owns the GUI session
            # best effort to unload the service if it's running
            sudo -u "#$USER" launchctl bootout "gui/$USER/org.nixos.kanata" 2>/dev/null || true
            printf '\x1b[0;31mAttempted to unload user agent with launchctl bootout...\x1b[0m\n'
          fi
          echo "Completed check for launchd agent for 'gui/$USER/org.nixos.kanata'"
      fi
      echo "Completed Karabiner DriverKit VirtualHIDDevice activation"
    '';

    # Create sudoers file for kanata to run without password
    environment.etc."sudoers.d/kanata".source = pkgs.runCommand "sudoers-kanata" { } ''
      KANATA_BIN="${getExe pkgs.kanata}"
      KANATA_SHASUM=$(sha256sum "$KANATA_BIN" | cut -d' ' -f1)
      KARABINER_DAEMON="${karabinerFilesPath}/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon"
      KARABINER_DAEMON_ESCAPED=$(echo "$KARABINER_DAEMON" | sed 's/ /\\ /g')
      cat <<EOF > "$out"
      %admin ALL=(root) NOPASSWD: sha256:$KANATA_SHASUM $KANATA_BIN
      %admin ALL=(root) NOPASSWD: $KARABINER_DAEMON_ESCAPED
      EOF
    '';

    # User launch agent for kanata service
    launchd.user.agents.kanata = {
      command = "${kanataWrapper}";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = false;
        StandardOutPath = "/tmp/kanata.out.log";
        StandardErrorPath = "/tmp/kanata.err.log";
      };
    };
  };
}
